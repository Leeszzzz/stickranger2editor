# SR2Editor

Stick Ranger 2 存档编辑器的实现

## 功能

- **存档**：粘贴 `.rng2` 存档字符串解码（尾部校验和 + 数据校验和校验），编辑后一键重编码导出、复制到剪贴板；编码使用随机盐，同一状态每次密文不同但均有效
- **总览**：金币 / 经验 / 等级点击编辑（上限 16,777,215 / 16,777,215 / 99），队伍人数 1-4，金币拉满、全关卡、全成就、全勋章等快捷操作
- **角色**（×4）：技能点、当前 HP，7 项属性加点（近战 / 中程 / 远程 / 物理 / 元素 / 未知 / 闪避，上限 196，闪避 25），主手武器 / 副手技能 / 头盔 / 戒指 / 护符五个装备槽编辑（按槽位过滤物品 + 属性展示）
- **背包**：256 格物品，全部以**等级**语义记录（0 = 未获取，1+ = 等级）；搜索、分类筛选（拳套 / 剑 / 枪 / 弓 / 杖 / 技能 / 帽子 / 戒指 / 护符）、只看已有、一键添加当前页面未拥有
- **进度**：32 关卡按区域分组解锁；128 成就按关卡分组完成 / 清零（写入目标值）；10 勋章解锁；饭团（回血道具）数量；128 怪物图鉴三态（未遇 / 遇见 / 已查看）；自动移动、悬崖停止、关卡事件标记
- **数据**：从 dan-ball.jp 拉取最新 `ranger2.js` 重新解析物品 / 成就 / 关卡 / 勋章数据（`SharedPreferences` 持久化，可一键恢复内置数据）
- **像素百科界面**：旧纸底色 + 2px 墨线 + 硬投影 + 手绘 16×16 像素图标；宽屏为顶栏 + 左侧导航，窄屏为顶栏 + 底部页签
- **字体**：内置 Fusion Pixel 12px 中文像素字体（比例 + 等宽两个子集），正文 12px、标题 24/36/48px，全部为 12 的整数倍以保证像素清晰
- **主题**：浅色（羊皮纸）/ 深色（夜行档案）/ 跟随系统，自适应布局
- **物品图标**：从游戏 `item.png` 精灵图按 16×16 网格切块（`assets/icons/`，73 枚），背包 / 物品选择器 / 装备槽显示原版像素图标，无对应资产的物品回退为分类首字徽章

## 项目结构

```
sr2editor/
├── lib/
│   ├── main.dart                 # 入口：初始化目录数据与偏好，全局依赖注入
│   ├── app_info.dart             # 版本常量
│   ├── theme/
│   │   ├── app_theme.dart        # 主题入口
│   │   └── pixel_theme.dart      # 像素百科设计系统：调色板 / 字体 / 组件主题
│   ├── codec/save_codec.dart     # 编解码核心：自定义 Base64 + 滚动混淆 + RLE + 位域
│   ├── models/game_data.dart     # 物品 / 关卡 / 成就 / 勋章目录与分类规则
│   ├── services/
│   │   ├── data_repository.dart  # 数据覆盖持久化 + 主题偏好
│   │   └── data_updater.dart     # ranger2.js 解析（r[] / w[] / G[] / jf[] / hf[] / H[]）
│   ├── state/editor_controller.dart  # ChangeNotifier：持有 C[768]，暴露全部读改接口
│   └── ui/
│       ├── app_shell.dart        # 像素顶栏 / 左侧导航 / 底部页签（6 个目的地）
│       ├── screens/              # 存档工坊 / 总览 / 角色 / 物品数据库 / 进度 / 数据源
│       └── widgets/
│           ├── pixel_icons.dart  # 47 枚手绘 16×16 像素图标（CustomPainter）
│           ├── pixel_kit.dart    # 面板 / 按钮 / 页签 / 滑块 / 对话框 / 提示等组件库
│           ├── common.dart       # 统计卡 / 数字编辑器 / 空态等业务组件
│           ├── item_icon.dart    # 游戏精灵图 + 乘法染色
│           └── item_picker.dart  # 物品检索对话框
├── assets/                       # item_stats.json + achievement_data.json（随包内置）
├── assets/icons/                 # 物品精灵图切块 icon_NNN.png（索引 = 行*16+列）
├── assets/fonts/                 # Fusion Pixel 12px 子集（OFL 1.1）
└── test/                         # 编解码 + 控制器 + 图标资产单元测试（20 项）
```

## 界面设计

界面采用「像素百科 / 旧游戏攻略本」视觉：旧纸网格底纹、2px 墨线面板、4px 硬投影、
金色高亮与等宽数值字体。所有图标为 16×16 手绘位图，经 `CustomPainter` 以整数倍缩放，
不使用平滑的 Material 图标。

- 顶栏：深色木牌 + 像素书徽标 + 存档状态 + 主题切换
- 宽屏：228px 左侧档案导航；窄屏：56px 底部页签
- 页面：面包屑 + 48/36px 大标题 + 金色分节线 + 百科信息框
- 组件：`PixelPanel` / `PixelButton` / `PixelTabs` / `PixelSlider` / `PixelProgressBar` /
  `PixelDialog` / `PixelToast` 等，集中在 `ui/widgets/pixel_kit.dart`
- 字体子集见 `assets/fonts/README.md`；新增中文文案后需重新裁切

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
