# 没在看 · NotLooking

<img src="docs/icon.png" width="112" alt="没在看：紫色背景上的眼睛斜杠图标" />

**你没在看，屏幕就懂了。**

戴着支持头部追踪的 AirPods，转头离开屏幕时自动模糊，转回即恢复。一个原生 macOS 菜单栏小工具，无需摄像头。

[English](README.en.md) · [下载](https://github.com/tuotuogao/NotLooking/releases) · [原项目 HeadOrbit](https://github.com/Cogria-AI/HeadOrbit)

## 这个版本改了什么

- **四步首次引导**：运动权限 → 连接耳机 → 3 秒倒数校准 → 实际转头测试。每一步都会检查状态，耳机断开不会误判为测试成功。
- **容易找到入口**：菜单栏显示眼睛斜杠和简短文字；再次打开应用可直接显示设置窗口。设置窗口打开时会显示 Dock 图标，关闭后继续在菜单栏运行。
- **应用内开机启动**：在引导完成页或“通用”中设置登录后自动启动；系统需要额外批准时会提供入口。
- **手动模糊强度**：左右方向分别调节 0–100% 的模糊强度，与压暗程度独立设置，支持两秒预览并自动保存。0% 为仅压暗，默认强度为 50%。
- **独立身份与更新地址**：应用名 NotLooking（中文“没在看”），标识 `io.github.tuotuogao.NotLooking`，从本仓库检查更新。
- 保留原项目的场景设置、坐姿提醒、头部按键动作、颈部活动及中英日语言切换。

## 使用

需要 macOS 14 或更新版本，以及支持头部追踪的 AirPods / Beats，例如 AirPods Pro、AirPods 3 / 4、AirPods Max。发布安装包同时包含 Apple Silicon 和 Intel 版本。耳机必须连接到这台 Mac，而不是切到手机。

1. 从 [Releases](https://github.com/tuotuogao/NotLooking/releases) 下载 DMG，把 NotLooking 拖入“应用程序”。
2. 打开“没在看”，按照窗口中的四步引导操作。
3. 运动权限通过后，戴好耳机并等待“正在追踪”。
4. 平视屏幕，完成 3 秒校准；开始测试，转头，再转回。
5. 测试通过后点击“开始使用”，可选开启“登录 Mac 时自动启动”。

默认向左或向右转头超过 **35°，持续 0.6 秒**触发模糊。触发角度、等待时间和压暗程度可在“隐私模糊”中分别调整。

如果图标被菜单栏挤掉，再次从“应用程序”打开“没在看”即可进入设置。“开始使用”引导也可以随时重新运行。

重新启动应用后，需要平视屏幕重新校准一次；校准前不会用不可靠的绝对角度触发动作。手动启动会直接打开校准页，登录启动时则在菜单栏提示。

此版本采用本地临时签名，尚未经过 Apple 公证。首次打开若被 macOS 阻止，请核对下载来源后，在系统设置“隐私与安全”中选择允许打开。

## 权限与数据

- **运动与健身**：用于读取耳机头部动作，是转头模糊唯一必需的隐私权限。
- **辅助功能**：仅头部动作模拟按键时需要；首次引导不会要求开启。
- 模糊不需要摄像头、麦克风或录屏权限。
- 动作数据在本机处理；常规运行不上传动作数据。更新检查会访问本仓库的 GitHub Releases。
- 转头模糊是避免意外暴露的辅助功能，不代替系统锁屏。系统私有模糊接口不可用时，会降级为压暗。

## 从源码构建

需要 Xcode 15 或更新版本和 [XcodeGen](https://github.com/yonaskolb/XcodeGen)。

```sh
git clone https://github.com/tuotuogao/NotLooking.git
cd NotLooking
brew install xcodegen
./build.sh
open build/Build/Products/Debug/NotLooking.app
```

动作逻辑与首次测试状态验证：

```sh
bash Tests/run-motion.sh
```

生成发布安装包：

```sh
./package.sh
```

输出 `dist/NotLooking-v1.0.0.dmg`。构建失败会返回失败状态，不会继续包装旧版本。启用本 Fork 的 GitHub Actions 后，发布 `v*` 标签会触发构建、测试，并附加 DMG 与校验值。

应用使用独立的偏好设置，不会自动导入 HeadOrbit 的权限和设置。以不同临时签名重新构建时，macOS 可能重新要求授权。

## 来源与许可证

本项目基于 [Cogria-AI/HeadOrbit](https://github.com/Cogria-AI/HeadOrbit) v2.1.0，保留原作者版权、MIT 许可证和提交历史。NotLooking 的首次使用引导、窗口入口、登录启动设置及品牌调整由 tuotuogao 维护。

原始说明保存在 [docs/upstream](docs/upstream/README.md)。[LICENSE](LICENSE) 中的原版权声明保持不变。
