#include <stdio.h>
#include <tiffio.h>
#include <stdint.h>

void write_coe_header(FILE *coeFile) {
    fprintf(coeFile, "memory_initialization_radix=2;\n");
    fprintf(coeFile, "memory_initialization_vector=\n");
}

void convert_tiff_to_coe(const char *tiff_filename, const char *coe_filename) {
    TIFF *tiff = TIFFOpen(tiff_filename, "r");
    if (!tiff) {
        fprintf(stderr, "Could not open TIFF file.\n");
        return;
    }

    uint32 width, height;
    TIFFGetField(tiff, TIFFTAG_IMAGEWIDTH, &width);
    TIFFGetField(tiff, TIFFTAG_IMAGELENGTH, &height);

    FILE *coeFile = fopen(coe_filename, "w");
    if (!coeFile) {
        fprintf(stderr, "Could not open COE file.\n");
        TIFFClose(tiff);
        return;
    }

    write_coe_header(coeFile);

    uint32* raster = (uint32*) _TIFFmalloc(width * height * sizeof(uint32));
    if (raster == NULL || !TIFFReadRGBAImage(tiff, width, height, raster, 0)) {
        fprintf(stderr, "Error reading TIFF image.\n");
        TIFFClose(tiff);
        fclose(coeFile);
        return;
    }

    for (uint32 row = 0; row < height; row++) {
        for (uint32 col = 0; col < width; col++) {
            uint32 pixel = raster[row * width + col];
            uint8_t r = TIFFGetR(pixel);
            uint8_t g = TIFFGetG(pixel);
            uint8_t b = TIFFGetB(pixel);
            
            // Convert each color component to an 8-bit binary string and write it to the COE file
            for (int i = 7; i >= 0; i--) {
                fprintf(coeFile, "%d", (r >> i) & 1);
            }
            for (int i = 7; i >= 0; i--) {
                fprintf(coeFile, "%d", (g >> i) & 1);
            }
            for (int i = 7; i >= 0; i--) {
                fprintf(coeFile, "%d", (b >> i) & 1);
            }
            fprintf(coeFile, ",\n");
        }
    }

    fseek(coeFile, -2, SEEK_CUR); // Remove the last comma and newline
    fprintf(coeFile, ";\n");

    _TIFFfree(raster);
    TIFFClose(tiff);
    fclose(coeFile);
    printf("COE file created successfully in binary format.\n");
}

int main() {
    const char *tiff_filename = "0019.tiff";
    const char *coe_filename = "rgbplane32.coe";
    convert_tiff_to_coe(tiff_filename, coe_filename);
    return 0;
}
