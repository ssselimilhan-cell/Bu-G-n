#!/usr/bin/env python3
"""Remove only the connected white canvas from the original BUGÜN wordmark."""
from collections import deque
from pathlib import Path
from PIL import Image

path = Path("assets/images/bugun_brand_wordmark.png.png")
image = Image.open(path).convert("RGBA")
pixels = image.load()
width, height = image.size
background = bytearray(width * height)
queue = deque()

def is_canvas_white(x, y):
    r, g, b, _ = pixels[x, y]
    return min(r, g, b) >= 245 and max(r, g, b) - min(r, g, b) <= 15

# Flood-fill only near-white pixels connected to the image boundary. This
# protects any white details enclosed inside the actual logo.
for x in range(width):
    for y in (0, height - 1):
        if is_canvas_white(x, y):
            idx = y * width + x
            if not background[idx]:
                background[idx] = 1
                queue.append((x, y))
for y in range(height):
    for x in (0, width - 1):
        if is_canvas_white(x, y):
            idx = y * width + x
            if not background[idx]:
                background[idx] = 1
                queue.append((x, y))

while queue:
    x, y = queue.popleft()
    for nx, ny in ((x-1,y), (x+1,y), (x,y-1), (x,y+1)):
        if 0 <= nx < width and 0 <= ny < height:
            idx = ny * width + nx
            if not background[idx] and is_canvas_white(nx, ny):
                background[idx] = 1
                queue.append((nx, ny))

# Make the connected canvas fully transparent.
for y in range(height):
    for x in range(width):
        if background[y * width + x]:
            r, g, b, _ = pixels[x, y]
            pixels[x, y] = (r, g, b, 0)

# De-matte the immediate anti-aliased edge against white. Only pixels touching
# the removed canvas are considered; the logo's interior RGB stays untouched.
edge = set()
for y in range(height):
    for x in range(width):
        if background[y * width + x]:
            for ny in range(max(0, y-1), min(height, y+2)):
                for nx in range(max(0, x-1), min(width, x+2)):
                    if not background[ny * width + nx]:
                        edge.add((nx, ny))

for x, y in edge:
    r, g, b, a = pixels[x, y]
    estimated_alpha = 255 - min(r, g, b)
    if 0 < estimated_alpha < 220:
        # Recover the foreground color from white-matted antialiasing.
        inv = 255 - estimated_alpha
        rr = max(0, min(255, round((r - inv) * 255 / estimated_alpha)))
        gg = max(0, min(255, round((g - inv) * 255 / estimated_alpha)))
        bb = max(0, min(255, round((b - inv) * 255 / estimated_alpha)))
        pixels[x, y] = (rr, gg, bb, estimated_alpha)

image.save(path, format="PNG", optimize=True)
transparent = sum(1 for y in range(height) for x in range(width) if pixels[x, y][3] == 0)
print(f"Processed original wordmark: {width}x{height}; transparent pixels: {transparent}")
