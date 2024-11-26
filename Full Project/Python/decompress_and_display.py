import pandas as pd
from PIL import Image
import numpy as np

def lzw_decompress(compressed_input: list[int]) -> list[int]:
    """
    Decompress data using LZW algorithm.
    
    Args:
        compressed_input: List of integers representing compressed data
        
    Returns:
        List of integers representing decompressed data
        
    Raises:
        ValueError: If compressed input contains invalid codes
    """
    MAX_DICT_SIZE = 2048
    
    dictionary = {i: [i] for i in range(256)}
    dict_size = 256
    
    if not compressed_input:
        return []
    
    prev_code = compressed_input[0]
    decompressed_output = dictionary[prev_code].copy()
    
    for current_code in compressed_input[1:]:
        if current_code in dictionary:
            current_sequence = dictionary[current_code].copy()
        elif current_code == dict_size:
            current_sequence = dictionary[prev_code].copy()
            current_sequence.append(dictionary[prev_code][0])
        else:
            raise ValueError(f"Invalid compressed code: {current_code}")
            
        decompressed_output.extend(current_sequence)
        
        if dict_size < MAX_DICT_SIZE:
            new_entry = dictionary[prev_code].copy()
            new_entry.append(current_sequence[0])
            dictionary[dict_size] = new_entry
            dict_size += 1
            
        prev_code = current_code
        
    return decompressed_output

def read_and_decompress(file_path, width, height):
    df = pd.read_csv(file_path)
    
    def extract_active_segments(data):
        active_segment = []
        collecting = False
        for value in data:
            if value == '0':
                value = int(value)
                if collecting:
                    break
                collecting = True
            elif collecting:
                active_segment.append(int(value))
        # print(f"Compressed segment length: {len(active_segment)}")
        return lzw_decompress(active_segment) if active_segment else ""

    # Calculate original (uncompressed) size
    original_size = width * height * 3  # 3 channels, 1 byte per pixel per channel
    print(f"\nOriginal size: {original_size} bytes ({original_size/1024:.2f} KB)")

    # Extract decompressed segments
    print("\nCompressing data...")
    r_active = extract_active_segments(df['ila_out_r[15:0]'])
    g_active = extract_active_segments(df['ila_out_g[15:0]'])
    b_active = extract_active_segments(df['ila_out_b[15:0]'])
    
    # Calculate compressed size (16-bit codes)
    compressed_size = (int(df['final_output_size_r[15:0]'][1]) + 
                      int(df['final_output_size_g[15:0]'][1]) + 
                      int(df['final_output_size_b[15:0]'][1]))
    print(f"\nCompressed size: {compressed_size} bytes ({compressed_size/1024:.2f} KB)")
    
    # Calculate compression ratio
    compression_ratio = original_size / compressed_size if compressed_size > 0 else float('inf')
    print(f"Compression ratio: {compression_ratio:.2f}:1")
    print(f"Space saved: {((original_size - compressed_size) / original_size * 100):.2f}%")
    
    # Ensure lengths match
    min_length = min(len(r_active), len(g_active), len(b_active))
    r_active = r_active[:min_length]
    g_active = g_active[:min_length]
    b_active = b_active[:min_length]
    
    # Create RGB array
    rgb_array = np.zeros((height, width, 3), dtype=np.uint8)
    rgb_array[:, :, 0] = np.array(r_active).reshape((height, width))
    rgb_array[:, :, 1] = np.array(g_active).reshape((height, width))
    rgb_array[:, :, 2] = np.array(b_active).reshape((height, width))
    
    # Rotate the array 180 degrees
    rgb_array = np.rot90(rgb_array, k=2)
    
    # Convert to image and save
    img = Image.fromarray(rgb_array)
    img.save("output_image3.tiff")
    print("\nImage saved as 'output_image3.tiff'")

# Example usage
read_and_decompress("iladatanew.csv", width=16, height=16)
