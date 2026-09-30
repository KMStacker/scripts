import sys
import os
import subprocess

# --- AUTO-INSTALLER START ---
def install_and_import_pillow():
    try:
        # Try to import Image from Pillow
        from PIL import Image, ImageOps
        return Image
    except ImportError:
        print("⚠️  Pillow library not found. Installing it now...")
        try:
            # Install Pillow using the current Python interpreter
            # This avoids PATH issues by asking "this python" to run pip
            subprocess.check_call([sys.executable, "-m", "pip", "install", "pillow"])
            
            print("✅ Installation successful! Continuing...")
            from PIL import Image
            return Image
        except Exception as e:
            print(f"❌ Could not install Pillow automatically. Error: {e}")
            sys.exit(1)

# Run the check and get the Image module
Image = install_and_import_pillow()
# --- AUTO-INSTALLER END ---

# Windows 11 default taskbar height (logical pixels)
BASE_TASKBAR_HEIGHT = 48

def process_image(image_path, screen_width, screen_height, scale_percent):
    try:
        # 1. Calculate physical taskbar height
        scale_factor = scale_percent / 100
        taskbar_px = int(round(BASE_TASKBAR_HEIGHT * scale_factor))
        
        # 2. Calculate target image height
        target_image_height = screen_height - taskbar_px
        
        print(f"Settings: {screen_width}x{screen_height} px, Scale: {scale_percent}%")
        print(f"Taskbar height: {taskbar_px} px")
        print(f"Resizing image to height: {target_image_height} px")

        # 3. Open and process image
        img = Image.open(image_path)
        
        # Resize image using LANCZOS for high quality
        img_resized = img.resize((screen_width, target_image_height), Image.Resampling.LANCZOS)
        
        # Create a new black background
        new_background = Image.new('RGB', (screen_width, screen_height), (0, 0, 0))
        
        # Paste the resized image at the top
        new_background.paste(img_resized, (0, 0))
        
        # 4. Save the file
        filename, ext = os.path.splitext(image_path)
        output_path = f"{filename}_{screen_width}x{screen_height}_fixed{ext}"
        new_background.save(output_path, quality=95)
        
        print(f"Done! Saved as: {output_path}")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    # Check if we have enough arguments (Script name + 4 args)
    if len(sys.argv) < 5:
        print("Error: Missing arguments.")
        print(" Usage:   python rescale_wallpaper_taskbar.py <image_path> <width> <height> <scale%> ")
        print(" Example: python rescale_wallpaper_taskbar.py wallpaper.png/(or path) 2880 1800 175 ")
    else:
        try:
            # Parse arguments
            path_arg = sys.argv[1]
            width_arg = int(sys.argv[2])
            height_arg = int(sys.argv[3])
            scale_arg = float(sys.argv[4])

            process_image(path_arg, width_arg, height_arg, scale_arg)
        
        except ValueError:
            print("Error: Width, Height, and Scale must be valid numbers.")