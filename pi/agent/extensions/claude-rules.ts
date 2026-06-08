/**
 * Claude Rules Extension
 *
 * Implements Claude Code's .claude/rules/ loading behavior:
 * - Auto-discovers all .md files recursively in .claude/rules/ and ~/.claude/rules/
 * - Unconditional rules (no paths frontmatter) load at session start
 * - Path-scoped rules (with paths frontmatter) activate when reading matching files
 * - User-level rules (~/.claude/rules/) load before project rules (project can override)
 *
 * See: https://code.claude.com/docs/en/claude-directory
 */

import * as fs from 'node:fs';
import * as path from 'node:path';
import type { ExtensionAPI } from '@mariozechner/pi-coding-agent';

/**
 * Recursively find all .md files in a directory
 */
function findMarkdownFiles(dir: string, basePath: string = ''): string[] {
  const results: string[] = [];

  if (!fs.existsSync(dir)) {
    return results;
  }

  const entries = fs.readdirSync(dir, { withFileTypes: true });

  for (const entry of entries) {
    const relativePath = basePath ? `${basePath}/${entry.name}` : entry.name;

    if (entry.isDirectory()) {
      results.push(...findMarkdownFiles(path.join(dir, entry.name), relativePath));
    } else if (entry.isFile() && entry.name.endsWith('.md')) {
      results.push(relativePath);
    }
  }

  return results;
}

/**
 * Parse YAML frontmatter from markdown content
 * Returns { frontmatter: Record<string, any>, content: string }
 */
function parseFrontmatter(content: string): { frontmatter: Record<string, any>; content: string } {
  const match = content.match(/^---\n([\s\S]*?)\n---\n([\s\S]*)$/);
  if (!match) {
    return { frontmatter: {}, content };
  }

  const frontmatterStr = match[1];
  const body = match[2];

  const frontmatter: Record<string, any> = {};
  for (const line of frontmatterStr.split('\n')) {
    const kvMatch = line.match(/^(\w+):\s*(.+)$/);
    if (kvMatch) {
      const key = kvMatch[1];
      let value: any = kvMatch[2].trim();
      if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
        value = value.slice(1, -1);
      }
      if (value.startsWith('[') && value.endsWith(']')) {
        value = value
          .slice(1, -1)
          .split(',')
          .map((s: string) => s.trim().replace(/^["']/, '').replace(/["']$/, ''));
      }
      frontmatter[key] = value;
    }
  }

  return { frontmatter, content: body };
}

/**
 * Expand brace patterns like {ts,tsx} or {src,lib}
 */
function expandBraces(pattern: string): string[] {
  const braceMatch = pattern.match(/^(.+)\{([^}]+)\}(.*)$/);
  if (!braceMatch) {
    return [pattern];
  }

  const prefix = braceMatch[1];
  const options = braceMatch[2].split(',');
  const suffix = braceMatch[3];

  const results: string[] = [];
  for (const option of options) {
    results.push(prefix + option + suffix);
  }
  return results;
}

/**
 * Check if a file path matches a glob-like pattern
 * Supports: *, **, {a,b}
 */
function matchesPattern(filePath: string, pattern: string): boolean {
  const patterns = expandBraces(pattern);

  for (const p of patterns) {
    let regexStr = p
      .replace(/\./g, '\\.')
      .replace(/\*\*/g, '<<<DOUBLE_STAR>>>')
      .replace(/\*/g, '[^/]*')
      .replace(/<<<DOUBLE_STAR>>>/g, '.*');

    regexStr = `^${regexStr}$`;
    const regex = new RegExp(regexStr);

    if (regex.test(filePath)) {
      return true;
    }
  }

  return false;
}

/**
 * Read and parse rule files, extracting frontmatter
 */
function readRuleFiles(
  dir: string,
  files: string[],
): Array<{ path: string; frontmatter: Record<string, any>; content: string }> {
  const rules: Array<{ path: string; frontmatter: Record<string, any>; content: string }> = [];

  for (const file of files) {
    const fullPath = path.join(dir, file);
    try {
      const rawContent = fs.readFileSync(fullPath, 'utf8');
      const { frontmatter, content } = parseFrontmatter(rawContent);
      rules.push({ path: fullPath, frontmatter, content });
    } catch (e) {
      // Skip files that can't be read
    }
  }

  return rules;
}

interface CachedRules {
  userRules: Array<{ path: string; frontmatter: Record<string, any>; content: string }>;
  projectRules: Array<{ path: string; frontmatter: Record<string, any>; content: string }>;
}

export default function claudeRulesExtension(pi: ExtensionAPI) {
  let currentFilePath: string | undefined;
  let cachedRules: CachedRules | null = null;

  const userRulesDir = path.join(process.env.HOME || '', '.claude', 'rules');

  // Track current file being read (for path-scoped rules)
  pi.on('before_tool_call', (event, _ctx) => {
    if (event.toolName === 'read' || event.toolName === 'edit' || event.toolName === 'write') {
      const input = event.input as { path?: string };
      if (input.path) {
        currentFilePath = path.isAbsolute(input.path) ? path.relative(process.cwd(), input.path) : input.path;
      }
    }
  });

  // Load rules on session start - same timing as Claude Code
  pi.on('session_start', async (_event, ctx) => {
    const userRuleFiles = findMarkdownFiles(userRulesDir);
    const projectRulesDir = path.join(ctx.cwd, '.claude', 'rules');
    const projectRuleFiles = findMarkdownFiles(projectRulesDir);

    // Cache all rules
    cachedRules = {
      userRules: readRuleFiles(userRulesDir, userRuleFiles),
      projectRules: readRuleFiles(projectRulesDir, projectRuleFiles),
    };

    // Build notification showing loaded files
    const details: string[] = [];
    if (userRuleFiles.length > 0) {
      details.push(`~/.claude/rules/: ${userRuleFiles.join(', ')}`);
    }
    if (projectRuleFiles.length > 0) {
      details.push(`.claude/rules/: ${projectRuleFiles.map((f) => `./${f}`).join(', ')}`);
    }

    if (details.length > 0) {
      ctx.ui.notify(`Loaded rules: ${details.join(' | ')}`, 'info');
    }
  });

  // Inject rules into system prompt before each agent response
  pi.on('before_agent_start', async (event, _ctx) => {
    if (!cachedRules) return;

    const lines: string[] = [];
    let hasRules = false;

    // Helper to check if a rule should be active
    const isRuleActive = (rule: { frontmatter: Record<string, any> }): boolean => {
      // Rules without paths frontmatter are always active (unconditional)
      if (!rule.frontmatter.paths) return true;

      // Path-scoped rules only activate when working with matching files
      if (!currentFilePath) return false;

      const paths: string[] = Array.isArray(rule.frontmatter.paths) ? rule.frontmatter.paths : [rule.frontmatter.paths];
      return paths.some((pattern) => matchesPattern(currentFilePath, pattern));
    };

    // User-level rules first (lower priority)
    const activeUserRules = cachedRules.userRules.filter(isRuleActive);
    if (activeUserRules.length > 0) {
      hasRules = true;
      lines.push('', '### User Rules (from ~/.claude/rules/)', '');
      for (const rule of activeUserRules) {
        lines.push(rule.content, '');
      }
    }

    // Project-level rules second (higher priority, can override user rules)
    const activeProjectRules = cachedRules.projectRules.filter(isRuleActive);
    if (activeProjectRules.length > 0) {
      hasRules = true;
      lines.push('', '### Project Rules (from .claude/rules/)', '');
      for (const rule of activeProjectRules) {
        lines.push(rule.content, '');
      }
    }

    if (hasRules) {
      return {
        systemPrompt: event.systemPrompt + '\n' + lines.join('\n'),
      };
    }
  });
}
