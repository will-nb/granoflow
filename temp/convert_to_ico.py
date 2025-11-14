#!/usr/bin/env python3
"""
将 PNG 图标转换为 Windows ICO 格式
"""

from PIL import Image
import os
import sys

def convert_png_to_ico(png_path, ico_path, sizes=None):
    """
    将 PNG 转换为 ICO 格式
    
    Args:
        png_path: 源 PNG 文件路径
        ico_path: 输出 ICO 文件路径
        sizes: ICO 文件包含的尺寸列表，默认包含常用尺寸
    """
    if sizes is None:
        # Windows 系统托盘常用尺寸
        sizes = [16, 32, 48, 64, 128, 256]
    
    if not os.path.exists(png_path):
        print(f"❌ 源文件不存在: {png_path}")
        return False
    
    try:
        # 打开源图片
        img = Image.open(png_path).convert('RGBA')
        
        # 创建包含多个尺寸的 ICO 文件
        # 使用列表保存所有尺寸的图片
        ico_images = []
        for size in sizes:
            # 调整大小
            resized = img.resize((size, size), Image.LANCZOS)
            # ICO 格式支持 RGBA，保持透明通道
            ico_images.append(resized)
        
        # 保存为 ICO 格式，包含所有尺寸
        # 第一个图片作为主图片，其他作为附加图片
        if len(ico_images) > 1:
            ico_images[0].save(
                ico_path, 
                format='ICO', 
                sizes=[(s, s) for s in sizes]
            )
            # 尝试使用 append_images 参数
            try:
                ico_images[0].save(
                    ico_path, 
                    format='ICO',
                    append_images=ico_images[1:]
                )
            except:
                # 如果 append_images 不支持，使用 sizes 参数
                ico_images[0].save(
                    ico_path, 
                    format='ICO', 
                    sizes=[(s, s) for s in sizes]
                )
        else:
            ico_images[0].save(ico_path, format='ICO')
        print(f"✅ 成功转换: {png_path} -> {ico_path}")
        print(f"   包含尺寸: {sizes}")
        return True
        
    except Exception as e:
        print(f"❌ 转换失败: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    # 使用现有的 logo 文件
    source_file = "assets/logo/granostack-logo-transparent.png"
    output_file = "assets/logo/app_icon.ico"
    
    # 确保输出目录存在
    os.makedirs(os.path.dirname(output_file), exist_ok=True)
    
    success = convert_png_to_ico(source_file, output_file)
    sys.exit(0 if success else 1)

