module image_compress(
    input wire clk
);
    // Parameters
    parameter WIDTH = 16;
    parameter HEIGHT = 16;
    parameter TOTAL_PIXELS = WIDTH * HEIGHT;

    // BRAM signals - expanded for RGB
    wire [23:0] bram_dout;  // 24-bit width for RGB
    reg [15:0] bram_addr = 0;

    // BRAM IP instance - now 24-bit wide
    blk_mem_gen_0 BRAM (
        .clka(clk),
        .addra(bram_addr),
        .douta(bram_dout)
    );

    // Input arrays for RGB channels
    reg [7:0] input_array_r [0:TOTAL_PIXELS-1];
    reg [7:0] input_array_g [0:TOTAL_PIXELS-1];
    reg [7:0] input_array_b [0:TOTAL_PIXELS-1];
    reg [15:0] input_count = 0;
    reg input_done = 0;

    // LZW Compression signals for each channel
    reg ap_start_r = 0, ap_start_g = 0, ap_start_b = 0;
    wire ap_done_r, ap_done_g, ap_done_b;
    wire ap_idle_r, ap_idle_g, ap_idle_b;
    wire ap_ready_r, ap_ready_g, ap_ready_b;
    
    wire input_string_ce0_r, input_string_ce0_g, input_string_ce0_b;
    reg [9:0] custom_input_address_r = 0;
    reg [9:0] custom_input_address_g = 0;
    reg [9:0] custom_input_address_b = 0;
    
    reg [7:0] input_string_q0_r = 0;
    reg [7:0] input_string_q0_g = 0;
    reg [7:0] input_string_q0_b = 0;
    
    wire compressed_output_ce0_r, compressed_output_ce0_g, compressed_output_ce0_b;
    wire compressed_output_we0_r, compressed_output_we0_g, compressed_output_we0_b;
    reg [9:0] custom_output_address_r = 0;
    reg [9:0] custom_output_address_g = 0;
    reg [9:0] custom_output_address_b = 0;
    
    wire [15:0] compressed_output_d0_r, compressed_output_d0_g, compressed_output_d0_b;
    wire [15:0] output_size_r, output_size_g, output_size_b;
    wire output_size_ap_vld_r, output_size_ap_vld_g, output_size_ap_vld_b;
    reg [15:0] input_size = TOTAL_PIXELS;

    // Compressed data storage for each channel
    reg [15:0] compressed_array_r [0:TOTAL_PIXELS-1];
    reg [15:0] compressed_array_g [0:TOTAL_PIXELS-1];
    reg [15:0] compressed_array_b [0:TOTAL_PIXELS-1];
    reg [15:0] final_output_size_r, final_output_size_g, final_output_size_b;

    // State tracking
    reg processing_started = 0;
    reg compression_complete = 0;
    reg zero_filling_done_r = 0, zero_filling_done_g = 0, zero_filling_done_b = 0;
    
    // State for array writing
    reg [1:0] write_state_r = 0, write_state_g = 0, write_state_b = 0;
    integer zero_fill_index_r, zero_fill_index_g, zero_fill_index_b;

    // Input array loading from BRAM with two-cycle delay
    always @(posedge clk) begin
        if (!input_done) begin
            if (input_count >= 2) begin
                input_array_r[input_count - 2] <= bram_dout[23:16];  // Red channel
                input_array_g[input_count - 2] <= bram_dout[15:8];   // Green channel
                input_array_b[input_count - 2] <= bram_dout[7:0];    // Blue channel
            end
            input_count <= input_count + 1;
            bram_addr <= bram_addr + 1;

            if (input_count == TOTAL_PIXELS + 1) begin
                input_done <= 1;
                bram_addr <= 0;
            end
        end
    end

// Completion flags for each channel
    reg done_r = 0;
    reg done_g = 0;
    reg done_b = 0;

    // Control ap_start and compression states for all channels
    always @(posedge clk) begin
        // Start compression
        if (input_done && !processing_started) begin
            ap_start_r <= 1;
            ap_start_g <= 1;
            ap_start_b <= 1;
            processing_started <= 1;
        end

        // Capture completion of each channel
        if (ap_done_r) begin
            ap_start_r <= 0;
            done_r <= 1;
        end
        
        if (ap_done_g) begin
            ap_start_g <= 0;
            done_g <= 1;
        end
        
        if (ap_done_b) begin
            ap_start_b <= 0;
            done_b <= 1;
        end

        // Set final completion when all channels are done
        if (done_r && done_g && done_b) begin
            compression_complete <= 1;
        end
    end

    // Input feeding logic for each channel
    always @(posedge clk) begin
        // Red channel
        if (input_string_ce0_r) begin
            input_string_q0_r <= input_array_r[custom_input_address_r];
            if (custom_input_address_r != 0) begin
                custom_input_address_r <= custom_input_address_r + 1;
            end
        end
        if (input_string_ce0_r && custom_input_address_r == 0) begin
            custom_input_address_r <= 1;
        end

        // Green channel
        if (input_string_ce0_g) begin
            input_string_q0_g <= input_array_g[custom_input_address_g];
            if (custom_input_address_g != 0) begin
                custom_input_address_g <= custom_input_address_g + 1;
            end
        end
        if (input_string_ce0_g && custom_input_address_g == 0) begin
            custom_input_address_g <= 1;
        end

        // Blue channel
        if (input_string_ce0_b) begin
            input_string_q0_b <= input_array_b[custom_input_address_b];
            if (custom_input_address_b != 0) begin
                custom_input_address_b <= custom_input_address_b + 1;
            end
        end
        if (input_string_ce0_b && custom_input_address_b == 0) begin
            custom_input_address_b <= 1;
        end
    end

    // LZW Compression IP instances - one for each channel
    lzw_compress_0 lzw_inst_r (
        .ap_clk(clk),
        .ap_rst(1'b0),
        .ap_start(ap_start_r),
        .ap_done(ap_done_r),
        .ap_idle(ap_idle_r),
        .ap_ready(ap_ready_r),
        .input_string_ce0(input_string_ce0_r),
        .input_string_q0(input_string_q0_r),
        .input_size(input_size),
        .compressed_output_ce0(compressed_output_ce0_r),
        .compressed_output_we0(compressed_output_we0_r),
        .compressed_output_d0(compressed_output_d0_r),
        .output_size(output_size_r),
        .output_size_ap_vld(output_size_ap_vld_r)
    );

    lzw_compress_0 lzw_inst_g (
        .ap_clk(clk),
        .ap_rst(1'b0),
        .ap_start(ap_start_g),
        .ap_done(ap_done_g),
        .ap_idle(ap_idle_g),
        .ap_ready(ap_ready_g),
        .input_string_ce0(input_string_ce0_g),
        .input_string_q0(input_string_q0_g),
        .input_size(input_size),
        .compressed_output_ce0(compressed_output_ce0_g),
        .compressed_output_we0(compressed_output_we0_g),
        .compressed_output_d0(compressed_output_d0_g),
        .output_size(output_size_g),
        .output_size_ap_vld(output_size_ap_vld_g)
    );

    lzw_compress_0 lzw_inst_b (
        .ap_clk(clk),
        .ap_rst(1'b0),
        .ap_start(ap_start_b),
        .ap_done(ap_done_b),
        .ap_idle(ap_idle_b),
        .ap_ready(ap_ready_b),
        .input_string_ce0(input_string_ce0_b),
        .input_string_q0(input_string_q0_b),
        .input_size(input_size),
        .compressed_output_ce0(compressed_output_ce0_b),
        .compressed_output_we0(compressed_output_we0_b),
        .compressed_output_d0(compressed_output_d0_b),
        .output_size(output_size_b),
        .output_size_ap_vld(output_size_ap_vld_b)
    );

    // Combined array writing logic for each channel
    always @(posedge clk) begin
        // Red channel
        case (write_state_r)
            0: begin
                if (compressed_output_ce0_r && compressed_output_we0_r) begin
                    compressed_array_r[custom_output_address_r] <= compressed_output_d0_r;
                    if (custom_output_address_r != 0) begin
                        custom_output_address_r <= custom_output_address_r + 1;
                    end
                end
                if (compressed_output_ce0_r && compressed_output_we0_r && custom_output_address_r == 0) begin
                    custom_output_address_r <= 1;
                end
                if (output_size_ap_vld_r) begin
                    final_output_size_r <= output_size_r;
                    write_state_r <= 1;
                    zero_fill_index_r <= output_size_r;
                end
            end
            1: begin
                if (zero_fill_index_r < TOTAL_PIXELS) begin
                    compressed_array_r[zero_fill_index_r] <= 16'h0000;
                    zero_fill_index_r <= zero_fill_index_r + 1;
                end else begin
                    write_state_r <= 2;
                    zero_filling_done_r <= 1;
                end
            end
            2: begin end
        endcase

        // Green channel
        case (write_state_g)
            0: begin
                if (compressed_output_ce0_g && compressed_output_we0_g) begin
                    compressed_array_g[custom_output_address_g] <= compressed_output_d0_g;
                    if (custom_output_address_g != 0) begin
                        custom_output_address_g <= custom_output_address_g + 1;
                    end
                end
                if (compressed_output_ce0_g && compressed_output_we0_g && custom_output_address_g == 0) begin
                    custom_output_address_g <= 1;
                end
                if (output_size_ap_vld_g) begin
                    final_output_size_g <= output_size_g;
                    write_state_g <= 1;
                    zero_fill_index_g <= output_size_g;
                end
            end
            1: begin
                if (zero_fill_index_g < TOTAL_PIXELS) begin
                    compressed_array_g[zero_fill_index_g] <= 16'h0000;
                    zero_fill_index_g <= zero_fill_index_g + 1;
                end else begin
                    write_state_g <= 2;
                    zero_filling_done_g <= 1;
                end
            end
            2: begin end
        endcase

        // Blue channel
        case (write_state_b)
            0: begin
                if (compressed_output_ce0_b && compressed_output_we0_b) begin
                    compressed_array_b[custom_output_address_b] <= compressed_output_d0_b;
                    if (custom_output_address_b != 0) begin
                        custom_output_address_b <= custom_output_address_b + 1;
                    end
                end
                if (compressed_output_ce0_b && compressed_output_we0_b && custom_output_address_b == 0) begin
                    custom_output_address_b <= 1;
                end
                if (output_size_ap_vld_b) begin
                    final_output_size_b <= output_size_b;
                    write_state_b <= 1;
                    zero_fill_index_b <= output_size_b;
                end
            end
            1: begin
                if (zero_fill_index_b < TOTAL_PIXELS) begin
                    compressed_array_b[zero_fill_index_b] <= 16'h0000;
                    zero_fill_index_b <= zero_fill_index_b + 1;
                end else begin
                    write_state_b <= 2;
                    zero_filling_done_b <= 1;
                end
            end
            2: begin end
        endcase
    end

    // Modified ILA capture logic for all channels
    reg [15:0] ila_out_r, ila_out_g, ila_out_b;
    reg [9:0] ila_count_r = 0, ila_count_g = 0, ila_count_b = 0;
    reg capture_active_r = 0, capture_active_g = 0, capture_active_b = 0;

    always @(posedge clk) begin
        // Red channel
        if (zero_filling_done_r && !capture_active_r) begin
            capture_active_r <= 1;
            ila_count_r <= 0;
            ila_out_r <= compressed_array_r[0];
        end 
        else if (capture_active_r) begin
            if (ila_count_r < final_output_size_r - 1) begin
                ila_count_r <= ila_count_r + 1;
                ila_out_r <= compressed_array_r[ila_count_r + 1];
            end else begin
                capture_active_r <= 0;
                ila_out_r <= 0;
            end
        end

        // Green channel
        if (zero_filling_done_g && !capture_active_g) begin
            capture_active_g <= 1;
            ila_count_g <= 0;
            ila_out_g <= compressed_array_g[0];
        end 
        else if (capture_active_g) begin
            if (ila_count_g < final_output_size_g - 1) begin
                ila_count_g <= ila_count_g + 1;
                ila_out_g <= compressed_array_g[ila_count_g + 1];
            end else begin
                capture_active_g <= 0;
                ila_out_g <= 0;
            end
        end

        // Blue channel
        if (zero_filling_done_b && !capture_active_b) begin
            capture_active_b <= 1;
            ila_count_b <= 0;
            ila_out_b <= compressed_array_b[0];
        end 
        else if (capture_active_b) begin
            if (ila_count_b < final_output_size_b - 1) begin
                ila_count_b <= ila_count_b + 1;
                ila_out_b <= compressed_array_b[ila_count_b + 1];
            end else begin
                capture_active_b <= 0;
                ila_out_b <= 0;
            end
        end
    end
    

    // Single ILA instance probing all RGB channels
    ila_0 ILA (
        .clk(clk),
        // Compressed data output for each channel
        .probe0(ila_out_r),          // [15:0]
        .probe1(ila_out_g),          // [15:0]
        .probe2(ila_out_b),          // [15:0]
        // Capture active flags
        .probe3(capture_active_r),    // [0:0]
        .probe4(capture_active_g),    // [0:0]
        .probe5(capture_active_b),    // [0:0]
        // Final output sizes
        .probe6(final_output_size_r), // [15:0]
        .probe7(final_output_size_g), // [15:0]
        .probe8(final_output_size_b)  // [15:0]
    );

endmodule
