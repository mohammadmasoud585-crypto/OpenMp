#!/usr/bin/env python3
"""
Simple test image generator for OpenMP convolution project
Creates a 2048x2048 test image with various patterns
"""

import numpy as np
from PIL import Image, ImageDraw, ImageFont
import os

def create_test_image(width=2048, height=2048):
    """Create a test image with various patterns"""
    
    # Create RGB image
    img = np.zeros((height, width, 3), dtype=np.uint8)
    
    # Add gradient background
    for y in range(height):
        for x in range(width):
            img[y, x, 0] = int(255 * x / width)  # Red gradient
            img[y, x, 1] = int(255 * y / height)  # Green gradient
            img[y, x, 2] = 128  # Constant blue
    
    # Convert to PIL Image for drawing
    pil_img = Image.fromarray(img)
    draw = ImageDraw.Draw(pil_img)
    
    # Draw circles
    for i in range(5):
        x = width // 6 * (i + 1)
        y = height // 3
        radius = 100
        color = (255 - i * 50, i * 50, 128)
        draw.ellipse([x-radius, y-radius, x+radius, y+radius], 
                     fill=color, outline=(255, 255, 255), width=3)
    
    # Draw rectangles
    for i in range(5):
        x1 = width // 6 * i + 50
        y1 = height * 2 // 3 - 100
        x2 = x1 + 150
        y2 = y1 + 150
        color = (i * 50, 255 - i * 50, 200)
        draw.rectangle([x1, y1, x2, y2], 
                      fill=color, outline=(0, 0, 0), width=3)
    
    # Draw lines
    for i in range(10):
        x1 = i * width // 10
        y1 = 0
        x2 = width - i * width // 10
        y2 = height
        color = (255, 255, 255) if i % 2 == 0 else (0, 0, 0)
        draw.line([x1, y1, x2, y2], fill=color, width=2)
    
    # Add text
    try:
        # Try to use a font, fall back to default if not available
        font = ImageFont.truetype("arial.ttf", 60)
    except:
        font = ImageFont.load_default()
    
    text = "OpenMP Convolution Test Image"
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    text_x = (width - text_width) // 2
    text_y = 50
    
    # Draw text with shadow
    draw.text((text_x + 2, text_y + 2), text, fill=(0, 0, 0), font=font)
    draw.text((text_x, text_y), text, fill=(255, 255, 255), font=font)
    
    return pil_img

def create_simple_patterns():
    """Create additional simple test patterns"""
    
    images = {}
    
    # Checkerboard pattern
    checker = np.zeros((2048, 2048, 3), dtype=np.uint8)
    square_size = 64
    for y in range(0, 2048, square_size):
        for x in range(0, 2048, square_size):
            if ((x // square_size) + (y // square_size)) % 2 == 0:
                checker[y:y+square_size, x:x+square_size] = [255, 255, 255]
    images['checkerboard'] = Image.fromarray(checker)
    
    # Horizontal stripes
    stripes_h = np.zeros((2048, 2048, 3), dtype=np.uint8)
    stripe_height = 32
    for y in range(0, 2048, stripe_height * 2):
        stripes_h[y:y+stripe_height] = [255, 255, 255]
    images['stripes_horizontal'] = Image.fromarray(stripes_h)
    
    # Vertical stripes
    stripes_v = np.zeros((2048, 2048, 3), dtype=np.uint8)
    stripe_width = 32
    for x in range(0, 2048, stripe_width * 2):
        stripes_v[:, x:x+stripe_width] = [255, 255, 255]
    images['stripes_vertical'] = Image.fromarray(stripes_v)
    
    # Gradient
    gradient = np.zeros((2048, 2048, 3), dtype=np.uint8)
    for x in range(2048):
        gradient[:, x] = [int(255 * x / 2048)] * 3
    images['gradient'] = Image.fromarray(gradient)
    
    return images

def main():
    # Create images directory if it doesn't exist
    os.makedirs('images', exist_ok=True)
    
    print("Generating test images...")
    
    # Create main test image
    print("Creating main test image (2048x2048)...")
    img = create_test_image(2048, 2048)
    img.save('images/input.png')
    print("  Saved: images/input.png")
    
    # Create smaller version for quick tests
    print("Creating small test image (512x512)...")
    img_small = create_test_image(512, 512)
    img_small.save('images/input_small.png')
    print("  Saved: images/input_small.png")
    
    # Create additional patterns
    print("Creating additional test patterns...")
    patterns = create_simple_patterns()
    for name, pattern_img in patterns.items():
        filename = f'images/{name}.png'
        pattern_img.save(filename)
        print(f"  Saved: {filename}")
    
    print("\nTest image generation completed!")
    print("You can now use these images with the convolution program:")
    print("  ./bin/convolution -i images/input.png -o results/output.png -k 3 -t 4")

if __name__ == '__main__':
    main()
