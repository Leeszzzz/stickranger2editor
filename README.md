# SR2Editor（Flutter 版）

Stick Ranger 2 存档编辑器的 Flutter 实现，Material 3 设计，洞穴靛蓝 + 琥珀主题（深 / 浅双模式）。
一套代码运行在 Windows / Android / Web / iOS / macOS / Linux。

## 功能

- **存档**：粘贴 `.rng2` 存档字符串解码（尾部校验和 + 数据校验和校验），编辑后一键重编码导出、复制到剪贴板；编码使用随机盐，同一状态每次密文不同但均有效
- **总览**：金币 / 经验 / 等级点击编辑（上限 16,777,215 / 16,777,215 / 99），队伍人数 1-4，金币拉满、全关卡、全成就、全勋章等快捷操作
- **角色**（×4）：技能点、当前 HP，7 项属性加点（近战 / 中程 / 远程 / 物理 / 元素 / 未知 / 闪避，上限 196，闪避 25），主手武器 / 副手技能 / 头盔 / 戒指 / 护符五个装备槽编辑（按槽位过滤物品 + 属性展示）
- **背包**：256 格物品，武器 / 技能类为**等级**语义（0 = 未获取，1+ = 等级），饰品为数量语义（0-63）；搜索、分类筛选（拳套 / 剑 / 枪 / 弓 / 杖 / 技能 / 帽子 / 戒指 / 护符）、只看已有、一键添加未拥有
- **进度**：32 关卡按区域分组解锁；128 成就按关卡分组完成 / 清零（写入目标值）；10 勋章解锁；饭团（回血道具）数量；128 怪物图鉴三态（未遇 / 遇见 / 已查看）；自动移动、悬崖停止、关卡事件标记
- **数据**：从 dan-ball.jp 拉取最新 `ranger2.js` 重新解析物品 / 成就 / 关卡 / 勋章数据（`SharedPreferences` 持久化，可一键恢复内置数据）
- **主题**：浅色 / 深色 / 跟随系统，自适应布局——宽屏左侧 NavigationRail，窄屏底部 NavigationBar

## 项目结构

```
sr2editor/
├── lib/
│   ├── main.dart                 # 入口：初始化目录数据与偏好，全局依赖注入
│   ├── theme/app_theme.dart      # Material 3 主题（fromSeed + 琥珀 tertiary）
│   ├── codec/save_codec.dart     # 编解码核心：自定义 Base64 + 滚动混淆 + RLE + 位域
│   ├── models/game_data.dart     # 物品 / 关卡 / 成就 / 勋章目录与分类规则
│   ├── services/
│   │   ├── data_repository.dart  # 数据覆盖持久化 + 主题偏好
│   │   └── data_updater.dart     # ranger2.js 解析（r[] / v[] / G[] / jf[] / hf[]）
│   ├── state/editor_controller.dart  # ChangeNotifier：持有 C[768]，暴露全部读改接口
│   └── ui/
│       ├── app_shell.dart        # 自适应导航骨架（6 个目的地）
│       ├── screens/              # 存档 / 总览 / 角色 / 背包 / 进度 / 数据
│       └── widgets/              # 统计卡 / 区块卡 / 数字编辑器 / 物品选择器
├── assets/                       # item_stats.json + achievement_data.json（随包内置）
└── test/codec_test.dart          # 编解码 + 控制器 + 目录单元测试（15 项）
```

## 编解码核心

- 自定义 Base64 字母表：`01WtCplxayfTvqchHmA9*JZOri6VN7L4w8dUGe.S3FIDzsnPbEkQXYMRgu25BjoK`
- 解码：尾 4 字符取盐 → 滚动减法还原 → 尾部校验和验证 → RLE 展开（值 ≤ 1 后跟重复计数）
- 编码：重算 C[1..2] 校验和 → RLE 压缩 → 随机 a/g 滚动加法 → 尾部 4 字符
- RLE 展开后为固定 **768 个 6-bit 值**；关键偏移：wb=59、ac=115、cc=181、
  hc=451、jc=485、lc=622、nc=752

## 开发

依赖：Flutter 3.41+（Dart 3.11+），无第三方状态管理 / UI 库，仅 `http` 与 `shared_preferences`。

```bash
flutter pub get        # 安装依赖
flutter run            # 运行（-d windows / chrome / <device-id>）
flutter test           # 单元测试（含与 Python 解码器对齐的基准存档断言）
flutter analyze        # 静态检查
```

### 构建

```bash
flutter build windows --release   # → build\windows\x64\runner\Release\sr2editor.exe
flutter build apk --release       # → build\app\outputs\flutter-apk\app-release.apk
flutter build web --release       # → build\web（本地静态服务即可托管）
```

Windows 构建需要开启系统「开发者模式」。

## 数据更新

- 应用内置 `assets/` 下的物品与成就数据
- 「数据」页可从官网 `ranger2.js?YYYYMMDD` 增量更新，结果通过 `SharedPreferences` 持久化，随时可恢复内置数据
- 除此之外应用完全离线工作，不上传任何数据

## 免责声明

仅供学习逆向工程与存档格式研究。修改存档前务必备份原始字符串，请勿用于破坏他人游戏体验或违反游戏服务条款的用途。
