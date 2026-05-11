# Proxy Injector

代理注入器 - 通过代理加载运行 Roblox 脚本

## 功能特性

- 🔒 **代理加载** - 所有脚本通过代理服务器加载，提高安全性
- 💾 **脚本保存** - 保存常用脚本，快速访问
- 📋 **剪贴板支持** - 从剪贴板直接运行脚本
- 🎯 **拖拽悬浮按钮** - 可拖动的悬浮按钮控制显示/隐藏
- 📱 **移动端优化** - 完美适配手机端 UI
- 🎨 **现代化界面** - 简洁美观的用户界面

## 使用方法

```lua
loadstring(game:HttpGet("https://api.959966.xyz/proxy?url=" .. game:GetService("HttpService"):UrlEncode("https://raw.githubusercontent.com/TongScriptX/ProxyInjector/main/ProxyInjector.lua")))()
```

## 界面说明

- **执行按钮** - 运行输入框中的脚本（URL或代码）
- **剪贴板按钮** - 从剪贴板读取并运行脚本
- **保存按钮** - 保存当前脚本到列表
- **脚本列表** - 显示已保存的脚本，点击运行，长按删除
- **悬浮按钮** - 拖动改变位置，点击显示/隐藏主界面

## 代理说明

所有脚本通过 `https://api.959966.xyz/proxy?url=` 代理加载，确保安全性和稳定性。

## 许可证

MIT License
