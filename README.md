# SR2 EDITOR

[![Release](https://img.shields.io/github/v/release/Leeszzzz/stickranger2editor?style=flat-square&label=release)](https://github.com/Leeszzzz/stickranger2editor/releases/latest) [![Downloads](https://img.shields.io/github/downloads/Leeszzzz/stickranger2editor/total?style=flat-square&logo=github)](https://github.com/Leeszzzz/stickranger2editor/releases) [![License](https://img.shields.io/badge/license-MIT-3DA639?style=flat-square)](LICENSE)  
[![Flutter](https://img.shields.io/badge/Flutter-3.41-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev) [![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Android%20%7C%20Web-4B5563?style=flat-square)](#构建) [![Bilibili](https://img.shields.io/badge/Bilibili-Leesz-00A1D6?style=flat-square&logo=bilibili&logoColor=white)](https://space.bilibili.com/622550948)

面向 Dan-Ball《Stick Ranger 2》的本地存档编辑器，基于 Flutter 开发，支持 Windows、Android 与 Web。项目提供存档字符串的解码、编辑与重编码能力，并以像素百科（Pixel Wiki）风格呈现物品、角色、进度与图鉴数据。

本项目与 Dan-Ball 无关联，仅用于技术学习与交流。

## 功能

### 存档

- 解析 `.rng2` 存档字符串：自定义 Base64 解码、滚动混淆还原、尾部校验和校验、数据校验和校验与 RLE 展开
- 编辑后重新编码，自动重算校验和并注入随机盐；同一状态可生成不同密文，游戏均可正常识别
- 支持剪贴板导入与导出，内置可用于验证的示例存档

### 总览

- 金币、经验、等级与队伍人数编辑
- 金币、经验、等级可精确输入或批量设为上限
- 提供全关卡、全成就、全勋章等批量操作

### 角色

- 4 名角色的技能点与当前 HP
- 7 项属性加点：近战、中程、远程、物理、元素、未知属性与闪避，上限分别为 196 与 25
- 5 个装备槽：主手武器、副手技能、头盔、戒指、护符；按槽位过滤物品并展示属性

### 物品数据库

- 256 格背包，全部以等级语义记录：0 级表示未获取，1 级及以上表示当前等级
- 支持按名称或 ID 搜索，按拳套、剑、枪、弓、杖、技能、帽子、戒指、护符分类筛选
- 支持只看已有物品，以及添加当前页面中尚未拥有的物品

### 进度

- 关卡标记：存档包含 32 个标记，界面按区域展示可编辑的 1 至 21，批量操作会写入全部标记
- 128 项成就：按关卡分组，支持完成与清零，完成时写入各成就的目标值
- 10 枚勋章解锁
- 饭团（回血道具）数量
- 128 个怪物图鉴条目，支持未遇、已遇、已查看三种状态
- 自动移动、悬崖停止与关卡事件标记

### 数据源

- 内置物品、关卡、成就与勋章数据
- 可从 dan-ball.jp 获取最新 `ranger2.js` 并重新解析目录数据
- 更新结果通过 `SharedPreferences` 持久化，可随时恢复内置数据
- Web 端受浏览器 CORS 限制，数据更新功能仅在 Windows 与 Android 客户端可用

### 界面与资源

- 像素百科风格：旧纸网格底纹、墨线边框、硬投影、金色强调与像素字体
- 宽屏采用顶栏、左侧档案导航与内容区；窄屏采用顶栏、底部页签与内容区
- 浅色、深色与跟随系统三种主题
- 内置 Fusion Pixel 12px 中文像素字体（比例与等宽两个子集）
- 物品图标从游戏 `item.png` 按 16×16 网格切块，无对应资源时回退为分类首字徽章

## 项目结构

```
sr2editor/
├── lib/
│   ├── main.dart                 # 入口：初始化目录数据与偏好，注入全局依赖
│   ├── app_info.dart             # 版本常量
│   ├── theme/
│   │   ├── app_theme.dart        # 主题入口
│   │   └── pixel_theme.dart      # 像素百科设计系统：调色板、字体与组件主题
│   ├── codec/save_codec.dart     # 编解码核心：自定义 Base64、滚动混淆、RLE 与位域
│   ├── models/game_data.dart     # 物品、关卡、成就、勋章目录与分类规则
│   ├── services/
│   │   ├── data_repository.dart  # 数据覆盖持久化与主题偏好
│   │   └── data_updater.dart     # ranger2.js 解析（r[] / w[] / G[] / jf[] / hf[] / H[]）
│   ├── state/editor_controller.dart  # ChangeNotifier：持有 C[768]，提供全部读写接口
│   └── ui/
│       ├── app_shell.dart        # 像素顶栏、左侧导航与底部页签
│       ├── screens/              # 存档工坊、总览、角色、物品数据库、进度、数据源
│       └── widgets/
│           ├── pixel_icons.dart  # 47 枚 16×16 像素图标（CustomPainter）
│           ├── pixel_kit.dart    # 面板、按钮、页签、滑块、对话框、提示等组件
│           ├── common.dart       # 统计卡、数字编辑器、空态等业务组件
│           ├── item_icon.dart    # 游戏精灵图与乘法染色
│           └── item_picker.dart  # 物品检索对话框
├── assets/                       # item_stats.json 与 achievement_data.json
├── assets/icons/                 # 物品精灵图切块 icon_NNN.png（索引 = 行 * 16 + 列）
├── assets/fonts/                 # Fusion Pixel 12px 子集（OFL 1.1）
└── test/                         # 编解码、控制器与图标资产测试（20 项）
```

## 界面设计

界面采用像素百科与旧式游戏手册的视觉语言：旧纸网格底纹、2px 墨线面板、4px 硬投影、金色强调与等宽数值字体。所有图标为 16×16 位图，通过 `CustomPainter` 以整数倍缩放绘制，不使用平滑的 Material 图标。

- 顶栏：深色木牌底色、像素书徽标、存档状态与主题切换
- 宽屏：228px 左侧档案导航；窄屏：56px 底部页签
- 页面：面包屑、48/36px 标题、金色分节线与百科信息框
- 组件：`PixelPanel`、`PixelButton`、`PixelTabs`、`PixelSlider`、`PixelProgressBar`、`PixelDialog`、`PixelToast` 等，集中在 `ui/widgets/pixel_kit.dart`
- 字体：正文 12px，标题 24/36/48px，均为 12 的整数倍，以保持像素字形清晰
- 字体子集说明与重新裁切方式见 `assets/fonts/README.md`

## 存档编解码

- 自定义 Base64 字母表：`01WtCplxayfTvqchHmA9*JZOri6VN7L4w8dUGe.S3FIDzsnPbEkQXYMRgu25BjoK`
- 解码流程：尾部 4 字符取盐，滚动减法还原，验证尾部校验和，再执行 RLE 展开
- 编码流程：重算 C[1..2] 校验和，RLE 压缩，随机 a/g 滚动加法，写入尾部 4 字符
- RLE 展开后固定为 768 个 6-bit 值
- 关键字段偏移：`wb=59`、`ac=115`、`cc=181`、`hc=451`、`jc=485`、`lc=622`、`nc=752`

## 开发环境

- Flutter 3.41 及以上，Dart 3.11 及以上
- 依赖：`http`、`shared_preferences`、`url_launcher`
- 未引入第三方状态管理或 UI 框架

```bash
flutter pub get        # 安装依赖
flutter run            # 运行（-d windows / chrome / <device-id>）
flutter test           # 单元测试，包含与 Python 解码器对齐的基准存档断言
flutter analyze        # 静态检查
```

## 构建

### Windows

```bash
flutter build windows --release
```

产物：`build\windows\x64\runner\Release\sr2editor.exe`

Windows 构建需要开启系统“开发者模式”。

### Android

```bash
flutter build apk --release
```

产物：`build\app\outputs\flutter-apk\app-release.apk`

要求使用 JDK 17。在 Android SDK 许可已接受的情况下，Gradle 会自动安装所需的 NDK 28.2.13676358 与 CMake 3.22.1。若 Flutter 检测到 Android Studio 自带的更高版本 JDK，可通过以下命令指定 JDK 17：

```bash
flutter config --jdk-dir "C:\Program Files\Java\jdk-17"
```

### Web

```bash
flutter build web --release
```

产物：`build/web`，可由任意静态文件服务器托管。

## 数据更新

- 应用内置 `assets/` 下的物品与成就数据
- “数据源”页可从官网 `ranger2.js?YYYYMMDD` 增量更新目录数据，结果通过 `SharedPreferences` 持久化
- 可随时恢复内置数据
- 除数据更新外，应用完全离线运行，不上传存档或本地数据

## 许可证与第三方资源

本项目源代码采用 [MIT License](LICENSE) 授权。MIT 许可仅适用于本项目的源代码，不授予游戏素材、游戏数据、商标或存档格式的任何权利。

- Fusion Pixel Font 12px（比例与等宽）：Copyright (c) 2022, TakWolf (https://takwolf.com)，采用 SIL Open Font License 1.1 授权。上游为 https://github.com/TakWolf/fusion-pixel-font。仓库内的 `FusionPixel12.ttf` 与 `FusionPixelMono12.ttf` 为按当前文案裁切的子集，仍按 OFL 1.1 分发；完整许可证见 `assets/fonts/OFL.txt`。
- 游戏精灵图、物品与成就数据、存档格式来源于 Dan-Ball《Stick Ranger 2》，版权归原权利方所有，不在 MIT 许可范围内。本项目仅出于互操作性与学习研究目的使用相关内容。

## 免责声明与下架响应

本项目仅用于技术学习、交流与存档格式研究，不用于任何商业用途，与 Dan-Ball 无关联，不提供游戏本体或破解内容。

游戏中的人物、图像、名称、数据等版权归 Dan-Ball 所有。本项目仅出于互操作性与学习研究目的使用相关内容，不代表 Dan-Ball 的立场，也未获得其认可或授权。

如权利人认为本项目或其部分内容侵犯其合法权益，请通过 [GitHub Issues](https://github.com/Leeszzzz/stickranger2editor/issues) 联系作者。作者将在收到通知后及时核实，并根据要求删除相关内容或下架仓库。

修改存档前请备份原始字符串。请支持正版游戏。
