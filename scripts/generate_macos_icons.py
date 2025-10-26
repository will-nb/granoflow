#!/usr/bin/env python3
"""
macOS 图标生成脚本
基于 assets/logo/granostack-logo-transparent.png 生成各种尺寸的 macOS 应用图标
"""

import os
import sys
from PIL import Image
import argparse

def generate_macos_icons():
    """生成 macOS 应用图标"""
    
    # 源文件路径
    source_file = "assets/logo/granostack-logo-transparent.png"
    
    # 目标目录
    target_dir = "macos/Runner/Assets.xcassets/AppIcon.appiconset"
    
    # 检查源文件是否存在
    if not os.path.exists(source_file):
        print(f"❌ 源文件不存在: {source_file}")
        return False
    
    # 检查目标目录是否存在
    if not os.path.exists(target_dir):
        print(f"❌ 目标目录不存在: {target_dir}")
        return False
    
    # 定义需要生成的图标尺寸
    icon_sizes = [
        (16, "app_icon_16.png"),
        (32, "app_icon_32.png"),
        (64, "app_icon_64.png"),
        (128, "app_icon_128.png"),
        (256, "app_icon_256.png"),
        (512, "app_icon_512.png"),
        (1024, "app_icon_1024.png"),
    ]
    
    try:
        # 打开源图片
        with Image.open(source_file) as img:
            print(f"✅ 源图片尺寸: {img.size}")
            
            # 确保图片有透明通道
            if img.mode != 'RGBA':
                img = img.convert('RGBA')
                print("✅ 转换为 RGBA 模式")
            
            # 生成各种尺寸的图标
            for size, filename in icon_sizes:
                target_path = os.path.join(target_dir, filename)
                
                # 创建正方形画布
                canvas = Image.new('RGBA', (size, size), (0, 0, 0, 0))
                
                # 计算缩放比例，保持宽高比
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
            
            print("🎉 所有 macOS 图标生成完成！")
            return True
            
    except Exception as e:
        print(f"❌ 生成图标时出错: {e}")
        return False

def main():
    """主函数"""
    parser = argparse.ArgumentParser(description='生成 macOS 应用图标')
    parser.add_argument('--source', default='assets/logo/granostack-logo-transparent.png',
                       help='源图片文件路径')
    parser.add_argument('--target', default='macos/Runner/Assets.xcassets/AppIcon.appiconset',
                       help='目标目录路径')
    
    args = parser.parse_args()
    
    print("🚀 开始生成 macOS 应用图标...")
    print(f"📁 源文件: {args.source}")
    print(f"📁 目标目录: {args.target}")
    
    success = generate_macos_icons()
    
    if success:
        print("✅ 图标生成成功！")
        sys.exit(0)
    else:
        print("❌ 图标生成失败！")
        sys.exit(1)

if __name__ == "__main__":
    main()
