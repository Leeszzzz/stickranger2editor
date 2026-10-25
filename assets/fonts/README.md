# 字体说明

本项目使用 **Fusion Pixel Font（缝合像素字体）12px 比例 / 等宽版**：

- 上游：<https://github.com/TakWolf/fusion-pixel-font>
- 版本：2026.10.25
- 授权：SIL Open Font License 1.1（见 `OFL.txt`）

为控制安装包体积，仓库内只保留按当前 UI 文案与游戏数据裁切的子集
（约 130 KB / 字体）。若后续新增中文文案，需要重新生成子集：

```bash
# 收集 lib / assets / test / web / README 中的全部字符，再用 pyftsubset 裁切
pyftsubset FusionPixel12.ttf \
  --text-file=corpus.txt \
  --output-file=out.ttf \
  --layout-features='*' \
  --glyph-names --symbol-cmap --legacy-cmap \
  --notdef-glyph --notdef-outline --recommended-glyphs
```

字体缺少 `≤`、`⚠` 等少量符号时，Flutter 会回退到系统字体，不影响使用。
