# Proxy Injector

通用 Roblox 代理注入器，支持直接执行 Lua 代码，或通过代理加载任意 `http/https` 脚本链接。

## 功能

- 通用代理：默认使用 `?url=` 格式代理任意目标链接
- 自动重写：执行远程脚本时，会重写脚本内常见的 `game:HttpGet(...)` 调用
- 可配置代理端点：支持在 UI 里修改代理地址模板
- 脚本收藏：保存常用链接或代码，随时载入/运行
- 新 UI：适配手机和桌面，悬浮按钮打开面板

## 使用

```lua
loadstring(game:HttpGet("https://api.959966.xyz/proxy?url=https%3A%2F%2Fraw.githubusercontent.com%2FTongScriptX%2FProxyInjector%2Fmain%2FProxyInjector.lua"))()
```

## 代理端点格式

默认端点：

```text
https://api.959966.xyz/proxy?url={url}
```

要求：

- 代理服务必须支持将目标链接作为查询参数转发
- 推荐使用 `{url}` 占位符，脚本会自动替换为 URL 编码后的真实地址
- 如果端点不含 `{url}`，但以 `url=` 结尾，脚本也会自动拼接编码后的地址

示例：

```text
https://your-proxy.example/proxy?url={url}
https://your-proxy.example/fetch?token=abc&url={url}
```

## 行为说明

- 输入框里填链接：先通过代理拉取脚本，再执行
- 输入框里填 Lua：直接执行，并重写其中常见的远程拉取调用
- “复制代理链接”：把当前输入链接转换成最终代理地址

## 限制

- 仅重写脚本中可静态识别的 `game:HttpGet("https://...")` / `game.HttpGet(game, "https://...")`
- 如果目标脚本动态拼接 URL，仍需要脚本自身配合统一走代理

## 许可证

MIT
