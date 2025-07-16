from PIL import Image
import sys

def add_padding(input_path, output_path, padding_ratio=0.2, bg_color=(0, 0, 0, 0)):
    img = Image.open(input_path).convert("RGBA")
    w, h = img.size
    pad_w = int(w * padding_ratio)
    pad_h = int(h * padding_ratio)
    new_w = w + pad_w * 2
    new_h = h + pad_h * 2
    new_img = Image.new("RGBA", (new_w, new_h), bg_color)
    new_img.paste(img, (pad_w, pad_h))
    new_img.save(output_path)

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python pad_icon.py input.png output.png [padding_ratio]")
        sys.exit(1)
    input_path = sys.argv[1]
    output_path = sys.argv[2]
    padding_ratio = float(sys.argv[3]) if len(sys.argv) > 3 else 0.2
    add_padding(input_path, output_path, padding_ratio)
