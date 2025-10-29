#!/usr/bin/env python3
"""
生成带有主题色背景的全平台图标
使用 Ocean Breeze 浅色主题的主色调作为背景
"""

import os
from PIL import Image

def create_icon_with_background(source_path, output_path, size, background_color):
    """创建带有主题色背景并按比例缩放的图标（无安全边距）"""
    if not os.path.exists(source_path):
        print(f"❌ 源文件不存在: {source_path}")
        return False

    try:
        img = Image.open(source_path).convert('RGBA')

        if isinstance(background_color, tuple) and len(background_color) == 3:
            bg = Image.new('RGBA', (size, size), (*background_color, 255))
        else:
            bg = Image.new('RGBA', (size, size), background_color)

        # 取消安全边距，让 logo 填满整个画布
        # 计算缩放比例，让 logo 适应整个画布
        scale = min(size / img.width, size / img.height)
        new_w = max(1, int(img.width * scale))
        new_h = max(1, int(img.height * scale))
        icon = img.resize((new_w, new_h), Image.LANCZOS)

        # 居中放置 logo
        x = (size - new_w) // 2
        y = (size - new_h) // 2
        bg.paste(icon, (x, y), icon)

        bg.save(output_path)
        print(f"✅ 生成图标: {os.path.basename(output_path)} ({size}x{size})")
        return True

    except Exception as e:
        print(f"❌ 生成图标失败: {e}")
        return False

def generate_macos_icons():
    """生成 macOS 图标"""
    print("🍎 生成 macOS 图标...")
    print("ℹ️  注意：macOS 系统会自动将正方形图标裁剪为圆角矩形")
    print("🎨 使用 Navy Blue 背景，提供更好的白色前景对比度")
    
    # 使用 Navy Blue 作为背景色，与白色前景对比度更好
    theme_color = (30, 77, 103)  # navyBlue #1E4D67
    
    source_file = "assets/logo/granostack-logo-transparent.png"
    target_dir = "macos/Runner/Assets.xcassets/AppIcon.appiconset"
    
    if not os.path.exists(source_file) or not os.path.exists(target_dir):
        print(f"❌ 源文件或目标目录不存在: {source_file} -> {target_dir}")
        return False
    
    icon_sizes = [
        (16, "app_icon_16.png"),
        (32, "app_icon_32.png"),
        (64, "app_icon_64.png"),
        (128, "app_icon_128.png"),
        (256, "app_icon_256.png"),
        (512, "app_icon_512.png"),
        (1024, "app_icon_1024.png"),
    ]
    
    success = True
    for size, filename in icon_sizes:
        output_path = os.path.join(target_dir, filename)
        # 使用正方形背景，让 macOS 系统处理圆角
        if not create_icon_with_background(source_file, output_path, size, theme_color):
            success = False
    
    return success

def generate_ios_icons():
    """生成 iOS 图标"""
    print("📱 生成 iOS 图标...")
    
    # 使用 Navy Blue 作为背景色
    theme_color = (30, 77, 103)  # navyBlue #1E4D67
    
    source_file = "assets/logo/granostack-logo-transparent.png"
    target_dir = "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    
    if not os.path.exists(source_file) or not os.path.exists(target_dir):
        print(f"❌ 源文件或目标目录不存在: {source_file} -> {target_dir}")
        return False
    
    icon_sizes = [
        (20, "Icon-App-20x20@1x.png"),
        (40, "Icon-App-20x20@2x.png"),
        (60, "Icon-App-20x20@3x.png"),
        (29, "Icon-App-29x29@1x.png"),
        (58, "Icon-App-29x29@2x.png"),
        (87, "Icon-App-29x29@3x.png"),
        (40, "Icon-App-40x40@1x.png"),
        (80, "Icon-App-40x40@2x.png"),
        (120, "Icon-App-40x40@3x.png"),
        (120, "Icon-App-60x60@2x.png"),
        (180, "Icon-App-60x60@3x.png"),
        (76, "Icon-App-76x76@1x.png"),
        (152, "Icon-App-76x76@2x.png"),
        (167, "Icon-App-83.5x83.5@2x.png"),
        (1024, "Icon-App-1024x1024@1x.png"),
    ]
    
    success = True
    for size, filename in icon_sizes:
        output_path = os.path.join(target_dir, filename)
        if not create_icon_with_background(source_file, output_path, size, theme_color):
            success = False
    
    return success

def generate_android_icons():
    """生成 Android 图标"""
    print("🤖 生成 Android 图标...")
    
    # 使用 Navy Blue 作为背景色
    theme_color = (30, 77, 103)  # navyBlue #1E4D67
    
    source_file = "assets/logo/granostack-logo-transparent.png"
    
    # Android mipmap 目录和对应的尺寸
    android_icon_configs = {
        "mipmap-mdpi": (48, "ic_launcher.png"),
        "mipmap-hdpi": (72, "ic_launcher.png"),
        "mipmap-xhdpi": (96, "ic_launcher.png"),
        "mipmap-xxhdpi": (144, "ic_launcher.png"),
        "mipmap-xxxhdpi": (192, "ic_launcher.png"),
    }
    
    success = True
    for density, (size, filename) in android_icon_configs.items():
        target_dir = f"android/app/src/main/res/{density}"
        if not os.path.exists(target_dir):
            os.makedirs(target_dir)
        
        output_path = os.path.join(target_dir, filename)
        if not create_icon_with_background(source_file, output_path, size, theme_color):
            success = False
    
    return success

def main():
    print("🚀 开始生成带有主题色背景的全平台应用图标...")
    print("🎨 使用 Navy Blue 主题色: #1E4D67 (海军蓝)")
    print("✨ 取消安全边距，让 logo 填满整个画布")
    
    source_file = "assets/logo/granostack-logo-transparent.png"
    
    if not os.path.exists(source_file):
        print(f"❌ 错误: 源 Logo 文件不存在: {source_file}")
        return
    
    success_count = 0
    total_platforms = 3
    
    if generate_macos_icons():
        success_count += 1
        print("✅ macOS 图标生成成功")
    else:
        print("❌ macOS 图标生成失败")
    
    if generate_ios_icons():
        success_count += 1
        print("✅ iOS 图标生成成功")
    else:
        print("❌ iOS 图标生成失败")
    
    if generate_android_icons():
        success_count += 1
        print("✅ Android 图标生成成功")
    else:
        print("❌ Android 图标生成失败")
    
    if success_count == total_platforms:
        print("🎉 所有平台图标生成完成！")
        print("🎨 所有图标都使用了 Navy Blue 主题色背景")
        print("✨ Logo 现在填满整个画布，macOS 将正确裁剪为圆角矩形")
    else:
        print(f"⚠️ 部分平台图标生成失败 ({success_count}/{total_platforms})")

if __name__ == "__main__":
    main()
