#!/usr/bin/env python3
"""
全平台图标生成脚本
基于 assets/logo/granostack-logo-transparent.png 生成所有平台的图标
支持 macOS、iOS、Android
"""

import os
import sys
from PIL import Image
import argparse

def generate_macos_icons():
    """生成 macOS 应用图标"""
    print("🍎 生成 macOS 图标...")
    
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
    
    return generate_icons(source_file, target_dir, icon_sizes)

def generate_ios_icons():
    """生成 iOS 应用图标"""
    print("📱 生成 iOS 图标...")
    
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
    
    return generate_icons(source_file, target_dir, icon_sizes)

def generate_android_icons():
    """生成 Android 应用图标"""
    print("🤖 生成 Android 图标...")
    
    source_file = "assets/logo/granostack-logo-transparent.png"
    
    # Android 图标目录
    android_dirs = [
        ("android/app/src/main/res/mipmap-mdpi/", 48, "ic_launcher.png"),
        ("android/app/src/main/res/mipmap-hdpi/", 72, "ic_launcher.png"),
        ("android/app/src/main/res/mipmap-xhdpi/", 96, "ic_launcher.png"),
        ("android/app/src/main/res/mipmap-xxhdpi/", 144, "ic_launcher.png"),
        ("android/app/src/main/res/mipmap-xxxhdpi/", 192, "ic_launcher.png"),
    ]
    
    success = True
    for target_dir, size, filename in android_dirs:
        if not os.path.exists(target_dir):
            print(f"❌ Android 目录不存在: {target_dir}")
            success = False
            continue
        
        icon_sizes = [(size, filename)]
        if not generate_icons(source_file, target_dir, icon_sizes):
            success = False
    
    return success

def generate_icons(source_file, target_dir, icon_sizes):
    """生成图标的通用函数"""
    try:
        with Image.open(source_file) as img:
            if img.mode != 'RGBA':
                img = img.convert('RGBA')
            
            for size, filename in icon_sizes:
                target_path = os.path.join(target_dir, filename)
                
                # 创建正方形画布
                canvas = Image.new('RGBA', (size, size), (0, 0, 0, 0))
                
                # 计算缩放比例
                scale = min(size / img.width, size / img.height)
                new_width = int(img.width * scale)
                new_height = int(img.height * scale)
                
                # 缩放图片
                resized_img = img.resize((new_width, new_height), Image.Resampling.LANCZOS)
                
                # 居中放置
                x = (size - new_width) // 2
                y = (size - new_height) // 2
                canvas.paste(resized_img, (x, y), resized_img)
                
                # 保存图标
                canvas.save(target_path, 'PNG', optimize=True)
                print(f"✅ 生成图标: {filename} ({size}x{size})")
            
            return True
            
    except Exception as e:
        print(f"❌ 生成图标时出错: {e}")
        return False

def main():
    """主函数"""
    parser = argparse.ArgumentParser(description='生成全平台应用图标')
    parser.add_argument('--platform', choices=['macos', 'ios', 'android', 'all'], 
                       default='all', help='要生成图标的平台')
    parser.add_argument('--source', default='assets/logo/granostack-logo-transparent.png',
                       help='源图片文件路径')
    
    args = parser.parse_args()
    
    print("🚀 开始生成全平台应用图标...")
    print(f"📁 源文件: {args.source}")
    
    success = True
    
    if args.platform in ['macos', 'all']:
        if not generate_macos_icons():
            success = False
    
    if args.platform in ['ios', 'all']:
        if not generate_ios_icons():
            success = False
    
    if args.platform in ['android', 'all']:
        if not generate_android_icons():
            success = False
    
    if success:
        print("🎉 所有平台图标生成完成！")
        sys.exit(0)
    else:
        print("❌ 部分图标生成失败！")
        sys.exit(1)

if __name__ == "__main__":
    main()
