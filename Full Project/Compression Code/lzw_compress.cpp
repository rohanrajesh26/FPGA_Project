// lzw_compress.cpp
#include "lzw_compress.h"

// Initialize the dictionary with single characters
void init_dictionary(short dictionary[MAX_DICT_SIZE][MAX_SEQ_LEN], short &dict_size) {
    init_dictionary_label0:for (short i = 0; i < 256; i++) {
        dictionary[i][0] = i;
        dictionary[i][1] = -1;
    }
    dict_size = 256;
}

// Find the longest match in the dictionary
short find_in_dictionary(short dictionary[MAX_DICT_SIZE][MAX_SEQ_LEN], short dict_size, short *seq, short seq_len) {
    find_in_dictionary_label0:for (short i = 0; i < dict_size; i++) {
	# pragma HLS unroll
        bool match = true;
        find_in_dictionary_label3:for (short j = 0; j < seq_len; j++) {
            if (dictionary[i][j] != seq[j]) {
                match = false;
                break;
            }
        }
        if (match && dictionary[i][seq_len] == -1) {
            return i;
        }
    }
    return -1;
}

// LZW compression function
void lzw_compress(short input_string[MAX_INPUT_SIZE], short input_size, short compressed_output[MAX_INPUT_SIZE], short &output_size) {
    // #pragma HLS INTERFACE ap_ctrl_none port=return
	#pragma HLS INTERFACE ap_ctrl_hs port=return

    short dictionary[MAX_DICT_SIZE][MAX_SEQ_LEN] = {{0}};
    short dict_size;
    init_dictionary(dictionary, dict_size);

    short current_string[MAX_SEQ_LEN] = {0};
    short current_length = 0;
    output_size = 0;

    lzw_compress_label2:for (short i = 0; i < input_size; i++) {
        short symbol = input_string[i];
        current_string[current_length] = symbol;
        current_length++;

        short match_index = find_in_dictionary(dictionary, dict_size, current_string, current_length);

        if (match_index == -1) {
            if (dict_size < MAX_DICT_SIZE) {
                for (short j = 0; j < current_length; j++) {
                    dictionary[dict_size][j] = current_string[j];
                }
                dictionary[dict_size][current_length] = -1;
                dict_size++;
            }
            compressed_output[output_size++] = find_in_dictionary(dictionary, dict_size, current_string, current_length - 1);

            current_string[0] = symbol;
            current_length = 1;
        }
    }
    compressed_output[output_size++] = find_in_dictionary(dictionary, dict_size, current_string, current_length);
}
