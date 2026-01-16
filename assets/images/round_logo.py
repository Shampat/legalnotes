from PIL import Image, ImageDraw
import os

# Script is in the same folder as the image
input_file = "loggo.png"
output_file = "loggo_rounded.png"

# Paths
input_path = os.path.join(os.getcwd(), input_file)
output_path = os.path.join(os.getcwd(), output_file)

# Open the image
img = Image.open(input_path).convert("RGBA")

# Set corner radius (adjust for more or less rounding)
radius = 250  # try 50–100 for logos

# Create mask for rounded corners
mask = Image.new("L", img.size, 0)
draw = ImageDraw.Draw(mask)
draw.rounded_rectangle([(0, 0), img.size], radius=radius, fill=255)

# Apply mask
img.putalpha(mask)

# Save result
img.save(output_path, format="PNG")

print(f"Rounded image saved as {output_file} in {os.getcwd()}")
