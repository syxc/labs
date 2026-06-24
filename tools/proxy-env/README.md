# ProxyEnv — 代理环境变量自动管理

macOS LaunchAgent：启动时检测本地代理端口是否存在，自动设置或清除 `HTTP_PROXY`/`HTTPS_PROXY`/`ALL_PROXY`/`GH_PROXY`/`NO_PROXY` 环境变量。

## 工作原理

- 开机（或用户登录）时自动运行
- 依次尝试连接本地代理端口：`7890, 7891, 7892, 7893, 8080, 10809`
- 任一端口连通 → 通过 `launchctl setenv` 设置代理环境变量
- 所有端口不通 → `launchctl unsetenv` 清除环境变量（避免残留）

## 安装

```bash
git clone https://github.com/syxc/labs.git
cd labs/tools/proxy-env
chmod +x install.sh
./install.sh
```

安装完成后立即生效，后续每次登录自动运行。

## 验证

```bash
# 检查 LaunchAgent 是否加载成功
launchctl print gui/$(id -u)/com.user.proxy-env

# 查看日志
cat /tmp/proxy-env.log
```

## 卸载

```bash
launchctl bootout "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.user.proxy-env.plist"
rm "$HOME/Library/LaunchAgents/com.user.proxy-env.plist"
rm "$HOME/.local/bin/proxy-env"
```
