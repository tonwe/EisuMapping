# EisuMapping

一个精简的 macOS 菜单栏应用，用日文 JIS 键盘的两个输入模式键切换窗口，按住 Shift 时切换应用。

| 按键 | 映射 |
| --- | --- |
| 英数 `kVK_JIS_Eisu`（`0x66`） | 当前应用的上一个窗口 |
| かな `kVK_JIS_Kana`（`0x68`） | 当前应用的下一个窗口 |
| `Shift + 英数` | 上一个应用 |
| `Shift + かな` | 下一个应用 |

每次按键触发一次，长按不连发。单独按键只切换当前应用的窗口：窗口按首次发现的顺序循环，切到前台不会打乱顺序；只有一个窗口时不操作。跳过最小化窗口、浮动面板，存在模态对话框时不切换。不切换窗口内的标签页。

按住 Shift 时，在已运行、正常显示于 Dock 的应用间按启动顺序前后循环切换；不包含菜单栏工具和后台进程。直接激活目标应用，不模拟修饰键。

使用 macOS 辅助功能 API 直接切换窗口，不依赖键盘布局或系统窗口切换快捷键设置。兼容未声明标准窗口子类型的应用窗口；其他桌面或全屏窗口是否能切到前台，由 macOS 与目标应用决定。

带 `⌘`、`⌃`、`⌥` 或 `Fn` 的组合键保持原样，包括它们与 Shift 的组合。映射启用时，这两个键单独按下或与 Shift 组合不再触发原输入法动作；暂停或退出即可恢复。

## 构建与运行

需要 macOS 13 或更新版本，以及 Xcode 16 或更新版本（Swift 6）。无第三方依赖。

```sh
./scripts/build-app.sh
open build/EisuMapping.app
```

生成的应用同时支持 Apple Silicon 和 Intel。将 `build/EisuMapping.app` 拖到「应用程序」文件夹，再打开 `/Applications/EisuMapping.app`。后续请保持应用位置固定。

首次启动后，在「系统设置 → 隐私与安全性 → 辅助功能」中允许 **EisuMapping**。应用会自动检测授权，菜单栏状态变为「映射已启用」后即可使用。若授权后仍无法启动监听，请退出应用后重新打开。

菜单栏提供状态、暂停/启用、开机启动和退出。不显示 Dock 图标，没有主窗口、网络请求或按键记录功能。

## 开机启动

应用安装到「应用程序」文件夹后，点击菜单栏图标，勾选「开机启动」即可在登录 macOS 后自动运行；再次点击可关闭。默认不开启。

使用系统的 [SMAppService](https://developer.apple.com/documentation/servicemanagement/smappservice) 注册应用本身，不添加辅助程序或自建 LaunchAgent。菜单勾选状态直接读取系统设置；如果系统要求确认，会打开「系统设置 → 通用 → 登录项与扩展」，菜单显示「待系统允许」。

菜单顶部同时显示最近一次英数 / かな操作的结果。如果显示「尚未检测到英数 / かな按键」，说明尚未收到这两个键；如果显示「只有一个可切换窗口」，请在同一应用中打开至少两个独立窗口（浏览器的多个标签页仍然属于一个窗口）。窗口读取或切换失败时会显示原因，而不是只显示「映射已启用」。该状态仅保留在内存中，不记录其他按键或窗口标题。

构建前请先退出正在运行的 EisuMapping。脚本会在本机只有一个可用的 Apple Development / Developer ID Application / Mac Developer 证书时自动使用它签名；证书多于一个时必须显式选择。以后保持同一证书和应用位置，即可让 macOS 识别更新后的应用身份。也可显式指定证书：

```sh
SIGNING_IDENTITY='Apple Development: 你的证书名称' ./scripts/build-app.sh
```

没有开发者证书时才使用临时签名（也可通过 `SIGNING_IDENTITY=-` 显式选择）。临时签名绑定当前代码版本，重新构建后可能不再匹配旧授权，详见 [Apple 签名要求说明](https://developer.apple.com/documentation/technotes/tn3127-inside-code-signing-requirements)。

### 辅助功能开关已开启，应用仍显示等待权限

这可能是旧版临时签名的授权条目仍在列表中，而新版代码的身份已改变。一次性处理：

1. 退出 EisuMapping，在「系统设置 → 隐私与安全性 → 辅助功能」中选中旧的 EisuMapping，点击「−」移除；仅关闭再打开开关可能仍保留旧身份。
2. 点击「＋」，添加实际运行的 `/Applications/EisuMapping.app`，并开启权限。
3. 重新打开刚授权的应用。此后使用相同开发者证书构建，避免再切回临时签名。

## 开发与验证

```sh
open Package.swift
swift test
```

代码按职责分开，运行时无第三方依赖：

```text
Sources/
  EisuMapping/
    AppDelegate.swift               菜单栏、应用生命周期
    AccessibilityPermission.swift   辅助功能授权
    KeyboardMapper.swift            全局按键监听
    WindowSwitcher.swift            当前应用的窗口切换
    ApplicationSwitcher.swift       已运行应用的循环切换
    LaunchAtLogin.swift             系统登录项设置
    main.swift                      入口
  KeyMapping/
    KeyMapping.swift                按键状态与映射规则
    SwitchCycle.swift               窗口与应用的循环顺序
    WindowEligibility.swift         可切换窗口筛选
Tests/KeyMappingTests/               按键、窗口顺序及筛选回归测试
Resources/                          应用信息、图标
scripts/                            双架构构建与图标生成
```

使用 Xcode 工具链内置的 `swift-format` 保持格式一致：

```sh
xcrun swift-format format --in-place --recursive Sources Tests
```

使用原生 AppKit 菜单栏、[Quartz Event Services](https://developer.apple.com/documentation/coregraphics/quartz-event-services) 监听按键，以及辅助功能窗口 API 切换窗口。窗口查询在独立的 Swift actor 中处理，不阻塞按键监听。不需要常驻轮询键盘，仅等待权限时每两秒检查一次授权。

按键在 HID 事件入口拦截，避免晚于系统输入模式处理。应用图标源文件为 `scripts/make-icon.swift`，重新生成：

```sh
swift scripts/make-icon.swift .build/AppIcon.iconset
iconutil -c icns .build/AppIcon.iconset -o Resources/AppIcon.icns
```

手动验收（需要 JIS 键盘及辅助功能授权）：

1. 在同一个应用中打开三个独立窗口（例如 Finder），连续按かな应依次遍历三个窗口；按英数应按相反方向遍历，且不跳到其他应用。
2. 按住 Shift，分别按英数、かな，确认按相反方向切换应用；先松开 Shift 再松开英数/かな，不应触发输入模式切换。
3. 长按按键不应反复切换；暂停和退出后，两个键恢复原行为。
4. 撤销辅助功能权限，点击菜单确认权限提示；重新授权后确认恢复。
5. 关闭、新建、最小化窗口后继续切换，确认跳过已关闭或最小化的窗口；只有一个窗口时不操作。
6. 在已安装的应用菜单中切换「开机启动」，确认勾选状态与「系统设置 → 通用 → 登录项与扩展」一致；取消后不再随登录启动。
7. 带 `⌘`、`⌃`、`⌥` 或 `Fn` 的组合键（包括与 Shift 一起按）保持原行为；按住英数/かな期间增减 Shift 不应重复触发。

安全输入开启期间，macOS 可能阻止全局键盘监听，退出密码输入等安全输入场景后再使用。
