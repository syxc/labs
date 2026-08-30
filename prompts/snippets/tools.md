### Command reference

Confirm a tool is available before use: `which <tool>` or `npx <tool> --version`.

#### jina.ai: web extraction and search

```bash
# web extraction
curl https://r.jina.ai/https://URL -o out.txt

# search (reads key from $JINA_API_KEY)
curl -H "Authorization: Bearer $JINA_API_KEY" "https://s.jina.ai/?q=QUERY"
```

#### ducksearch: web search and content extraction

```bash
npx ducksearch search "query" [-n N] [-o]         # -o opens the first result
npx ducksearch fetch URL [-o out.txt] [--raw]     # recommend -o to save
```

`--version` reporting 1.0.2 is upstream hard-coded; the real version is `npm view ducksearch version`.

#### ghr: GitHub repository analysis

```bash
ghr {analyze|structure|search|read|readme|ls} <owner/repo>    # analyze may add -o out.json
ghr clean --all                                               # clear cache
```

#### network proxy

```bash
export https_proxy=http://127.0.0.1:7890 GH_PROXY=http://127.0.0.1:7890
```

#### chrome-devtools: browser control and debugging

Underlying CLI: navigation, interaction, screenshots, console, network, and heap snapshots. See `chrome-devtools --help` for subcommands and options.