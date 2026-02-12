from PIL import Image

# 1. Load image and convert to Grayscale
img = Image.open("C:\\Users\\owowhatsthis\\Pictures\\krita\\saddam.png").convert("L") 
width, height = img.size

# 2. Write to Hex file compatible with $readmemh
with open("image_in.hex", "w") as f:
    # Write pixel data row by row
    for y in range(height):
        for x in range(width):
            pixel = img.getpixel((x, y))
            f.write(f"{pixel:02x}\n") # Write as 2-digit hex (e.g., "A5")

print(f"Generated image_in.hex: {width}x{height} pixels")