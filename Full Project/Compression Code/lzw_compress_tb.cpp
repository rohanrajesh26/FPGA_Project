// lzw_compress_testbench.cpp
#include "lzw_compress.h"

void lzw_compress_testbench() {
    // short input_string[MAX_INPUT_SIZE] = {65, 66, 65, 66, 65, 66, 65, 66, 65};  // ASCII codes for "ABABABABA"
    short input_string[MAX_INPUT_SIZE] = {137,129,143,134,149,98,72,128,119,73,90,138,135,141,124,144,138,136,124,147,92,37,32,46,31,26,34,82,141,132,146,134,143,141,131,123,39,18,39,19,32,43,24,41,116,134,149,130,135,139,154,73,34,59,73,46,34,37,23,16,58,141,139,143,119,143,130,42,54,81,65,45,18,20,27,19,29,113,134,137,123,141,62,40,63,76,53,41,38,38,37,28,29,52,126,124,137,108,36,53,81,100,87,62,47,35,22,18,22,19,96,137,143,63,64,70,110,144,128,76,56,33,21,26,18,30,51,147,135,72,55,76,125,149,104,67,52,49,42,24,28,18,66,138,136,83,36,53,98,112,86,52,36,16,23,23,18,11,74,137,138,112,47,45,67,64,70,60,45,23,34,28,16,26,95,134,147,122,56,35,50,41,34,33,37,37,42,18,24,65,127,144,122,139,134,89,53,25,16,58,77,92,84,51,75,104,134,144,144,139,144,126,125,114,73,75,146,151,141,121,142,131,128,139,132,130,136,140,144,140,124,115,142,139,147,145,157,140,138,140,135,139,127,138,137,133,150,136,131,126,147,142,137,134,147};
    short input_size = 256;
    short compressed_output[MAX_INPUT_SIZE];
    short output_size;

    // Call the compression function
    lzw_compress(input_string, input_size, compressed_output, output_size);

    // Output the compressed data
    std::cout << "Input Size: " << input_size << std::endl;
    std::cout << "Compressed Data: ";
    for (short i = 0; i < output_size; i++) {
        std::cout << compressed_output[i] << " ";
    }
    std::cout << std::endl;
    std::cout << "Output Size: " << output_size << std::endl;
}

int main() {
    lzw_compress_testbench();
    return 0;
}
