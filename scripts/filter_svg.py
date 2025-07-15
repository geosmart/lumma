#!/usr/bin/env python3
import re

# 读取SVG文件
with open('/mnt/github/lumma/assets/icon/icon.svg', 'r') as f:
    content = f.read()

# 定义要保留的颜色（绿色和蓝色）
keep_colors = [
    # 绿色系
    '#06C691', '#07C692', '#07C693', '#26BC94', '#34C599', '#32C49D', '#33C39C', '#3AC09E', '#25BF93', '#1EC793', '#2DC598', '#2EC098', '#33C39C', '#36C59A', '#3AC09E', '#2EC098', '#28C89A', '#30C899', '#2DC598', '#2EC098', '#26BC94', '#07C692', '#07C693', '#06C691',

    # 蓝色系
    '#0C8EF7', '#088EF9', '#0A8EF8', '#088EF9', '#078EFA', '#0A8FF8', '#098FF9', '#0B8FF8', '#0A8FF8', '#088FF9', '#0C8EF6', '#0B8FF7', '#0A8FF8', '#0A8EF6', '#0A8EF6', '#0A8FF8', '#0B8FF6', '#0A8FF7', '#0B8FF8', '#0A8EF7', '#0C8FF6', '#0D90F6', '#088EF9', '#0D8FF5', '#098FF7', '#0A90F9', '#078FFA', '#0B8FF6', '#0A8FF9', '#0990F7', '#0C8FF6', '#0A8FF7', '#0990F9', '#0B90F7', '#0C8FF7', '#098FF8', '#098FF6', '#0A90F8', '#0F91F6', '#0B8EF5', '#0A90F9', '#0890F8', '#1492F3', '#0691FA', '#0B8FF6', '#158FF0', '#0C91F4', '#1693EE', '#0A92F4', '#1793F0', '#0490FA', '#1692F3', '#0691FA', '#0B8FF6', '#0990F7', '#0C8FF6', '#0A90F8', '#0B90F7', '#0C8FF7', '#098FF8', '#098FF6', '#0A90F8', '#0F91F6', '#0B8EF5', '#0A90F9', '#0890F8', '#1492F3', '#0691FA', '#0B8FF6', '#158FF0', '#0C91F4', '#1693EE', '#0A92F4', '#1793F0', '#0490FA', '#1692F3'
]

# 创建颜色匹配模式
green_pattern = r'fill="#0[67][A-F0-9]{4}"'
blue_pattern = r'fill="#0[8-9A-F][A-F0-9]{4}"'

# 分割SVG内容
lines = content.split('\n')
filtered_lines = []

for line in lines:
    # 保留SVG头部
    if line.startswith('<?xml') or line.startswith('<svg'):
        filtered_lines.append(line)
        continue

    # 如果是路径行，检查颜色
    if '<path' in line and 'fill=' in line:
        # 检查是否是绿色或蓝色
        if re.search(green_pattern, line) or re.search(blue_pattern, line):
            # 进一步检查是否是浅色（C、D、E、F开头的颜色代码通常是浅色）
            if not re.search(r'fill="#[C-F][A-F0-9]{5}"', line):
                filtered_lines.append(line)
    elif '</svg>' in line:
        filtered_lines.append(line)

# 写入新的SVG文件
new_content = '\n'.join(filtered_lines)

with open('/mnt/github/lumma/assets/icon/icon.svg', 'w') as f:
    f.write(new_content)

print("SVG文件已更新，只保留主要的绿色和蓝色路径")
