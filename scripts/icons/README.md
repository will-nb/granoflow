# 图标生成脚本

## 使用方法

### 通过 anz 命令（推荐）
```bash
# 生成所有平台图标
./scripts/anz icons:generate
```

### 直接运行 Python 脚本
```bash
python3 scripts/icons/generate.py
```

## 功能说明

- 基于 `assets/logo/granostack-logo-transparent.png` 生成图标
- 支持平台：macOS、iOS、Android
- 使用 Navy Blue 主题色 (#1E4D67) 作为背景，提供优秀的白色前景对比度
- **macOS 设计规范**：生成正方形背景，macOS 系统会自动应用圆角矩形效果
- **无安全边距**：Logo 填满整个画布，确保 macOS 正确裁剪而非外接
- 使用高质量 LANCZOS 缩放算法

## 设计规范说明

### macOS 图标设计
- 遵循 Apple Human Interface Guidelines
- 图标本身为正方形，系统自动裁剪为圆角矩形
- 避免在图标内部绘制圆角，防止双重圆角效果
- **Navy Blue 背景**：与白色前景对比度达 7.2:1 (WCAG AAA 级别)

### 颜色选择
- **背景色**: Navy Blue (#1E4D67) - 海军蓝
- **前景色**: 白色 (#FFFFFF) - 纯白
- **对比度**: 7.2:1 (远超 WCAG AAA 标准)

## 输出位置

- macOS: `macos/Runner/Assets.xcassets/AppIcon.appiconset/`
- iOS: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- Android: `android/app/src/main/res/mipmap-*/`

## 技术细节

### 背景色
- 使用 Ocean Breeze 浅色主题的主色调：`#6EC6DA` (海盐蓝)
- RGB 值：`(110, 198, 218)`

### 缩放策略
- 12% 安全边距，确保小尺寸图标不会显得拥挤
- 等比缩放，保持 logo 原始宽高比
- 居中放置，在正方形画布中居中

### 生成算法
- 使用 PIL (Python Imaging Library) 进行图像处理
- LANCZOS 重采样算法，保证高质量缩放
- 自动处理透明通道 (RGBA)

## 依赖要求

- Python 3.x
- PIL (Pillow) 库
- 源文件：`assets/logo/granostack-logo-transparent.png`

## 安装依赖

```bash
pip install Pillow
```

## 故障排除

### 常见问题

1. **源文件不存在**
   - 确保 `assets/logo/granostack-logo-transparent.png` 文件存在
   - 检查文件路径是否正确

2. **Python 环境问题**
   - 确保已安装 Python 3.x
   - 确保已安装 Pillow 库

3. **权限问题**
   - 确保对目标目录有写入权限
   - 检查文件是否被其他程序占用

### 调试模式

如需查看详细输出，可以直接运行 Python 脚本：
```bash
python3 scripts/icons/generate.py
```

这将显示详细的生成过程和任何错误信息。
