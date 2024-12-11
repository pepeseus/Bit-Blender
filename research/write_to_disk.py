import os
import subprocess

def write_disk_image(image_path, device_path):
    """
    Writes a disk image to the SD card.

    :param image_path: Path to the disk image file.
    :param device_path: Path to the SD card device.
    """
    try:
        with open(image_path, 'rb') as image, open(device_path, 'r+b') as device:
            print(f"Writing data from {image_path} to {device_path}...")
            # Read and write in chunks
            while chunk := image.read(4096):
                device.write(chunk)
        print(f"Disk image {image_path} successfully written to {device_path}.")
    except PermissionError:
        print("Permission denied. Try running the script as root.")
    except FileNotFoundError as e:
        print(f"File not found: {e}")
    except Exception as e:
        print(f"An error occurred: {e}")


def list_devices():
    try:
        # Run the 'diskutil list' command
        result = subprocess.run(['diskutil', 'list'], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

        if result.returncode != 0:
            print(f"Error: {result.stderr}")
            return

        # Output the device list
        print(result.stdout)

    except Exception as e:
        print(f"An error occurred: {e}")




if __name__ == "__main__":
    # Call the function
    list_devices()
    
    # Prompt user for device path and image path
    device_path = input("Enter the SD card device path (default: /dev/disk2): ") or "/dev/disk2"
    image_path = input("Enter the disk image path (default: sd_disk.img): ") or "sd_disk.img"

    # Call the function to write the disk image
    write_disk_image(image_path, device_path)
