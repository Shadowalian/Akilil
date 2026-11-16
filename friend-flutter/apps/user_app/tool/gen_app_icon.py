from PIL import Image, ImageDraw
import os

SIZE = 1024
bg = (26, 159, 196, 255)  # #1A9FC4 aqua
fg = (255, 255, 255, 255)

img = Image.new("RGBA", (SIZE, SIZE), bg)
draw = ImageDraw.Draw(img)

scale = SIZE / 32.0
dots = [
    (16, 6.22222),
    (6.22222, 16),
    (25.7778, 16),
    (16, 25.7778),
]
r = 6.22222 * scale
for cx, cy in dots:
    x, y = cx * scale, cy * scale
    draw.ellipse([x - r, y - r, x + r, y + r], fill=fg)

paths = [
    r"c:\Users\user\Desktop\fd\friend-flutter\apps\user_app\assets\figma\app_icon.png",
    r"c:\Users\user\Desktop\fd\friend-flutter\apps\professional_app\assets\figma\app_icon.png",
]
for path in paths:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path, "PNG")
    print("wrote", path, os.path.getsize(path))
