// lzw_compress.h
#ifndef LZW_COMPRESS_H
#define LZW_COMPRESS_H

#include <iostream>
#define MAX_DICT_SIZE 2048  // reduced to handle smaller image complexity
#define MAX_SEQ_LEN 32     // reduced for small image patterns
#define MAX_INPUT_SIZE 256 // matches the number of pixels in a 32x32 image


void init_dictionary(short dictionary[MAX_DICT_SIZE][MAX_SEQ_LEN], short &dict_size);
short find_in_dictionary(short dictionary[MAX_DICT_SIZE][MAX_SEQ_LEN], short dict_size, short *seq, short seq_len);
void lzw_compress(short input_string[MAX_INPUT_SIZE], short input_size, short compressed_output[MAX_INPUT_SIZE], short &output_size);

#endif
