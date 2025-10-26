#!/usr/bin/env python3
"""
生成带有主题色背景的 macOS 图标
使用 Ocean Breeze 浅色主题的主色调作为背景
"""

import os
from PIL import Image, ImageDraw

def create_icon_with_background(source_path, output_path, size, background_color):
    """创建带有背景色的图标"""
    if not os.path.exists(source_path):
        print(f"❌ 源文件不存在: {source_path}")
        return False
    
    try:
        # 打开源图片
        img = Image.open(source_path)
        
        # 创建新的图片，带有背景色
        new_img = Image.new('RGBA', (size, size), background_color)
        
        # 计算居中位置
        x = (size - img.width) // 2
        y = (size - img.height) // 2
        
        # 将源图片粘贴到新图片上
        new_img.paste(img, (x, y), img if img.mode == 'RGBA' else None)
        
        # 保存新图标
        new_img.save(output_path)
        print(f"✅ 生成图标: {os.path.basename(output_path)} ({size}x{size})")
        return True
        
    except Exception as e:
        print(f"❌ 生成图标失败: {e}")
        return False

def generate_macos_icons_with_theme_bg():
    """生成带有主题色背景的 macOS 图标"""
    print("🍎 生成带有主题色背景的 macOS 图标...")
    
    # Ocean Breeze 浅色主题主色调 - 海盐蓝
    theme_color = (110, 198, 218)  # #6EC6DA
    
    source_file = "assets/logo/granostack-logo-transparent.png"
    target_dir = "macos/Runner/Assets.xcassets/AppIcon.appiconset"
    
    if not os.path.exists(source_file):
        print(f"❌ 源文件不存在: {source_file}")
        return False
    
    if not os.path.exists(target_dir):
        print(f"❌ 目标目录不存在: {target_dir}")
        return False
    
    # macOS 图标尺寸配置
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
        if not create_icon_with_background(source_file, output_path, size, theme_color):
            success = False
    
    if success:
        print(f"🎨 使用主题色背景: #{theme_color[0]:02X}{theme_color[1]:02X}{theme_color[2]:02X}")
        print("✅ 所有 macOS 图标生成完成！")
    else:
        print("❌ 部分图标生成失败")
    
    return success

def main():
    print("🚀 开始生成带有主题色背景的 macOS 图标...")
    
    if not generate_macos_icons_with_theme_bg():
        print("❌ macOS 图标生成失败")
        return
    
    print("🎉 所有图标生成完成！")

if __name__ == "__main__":
    main()
