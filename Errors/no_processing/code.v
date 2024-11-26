module image_negate(
    input wire clk
);

// Parameters
parameter WIDTH = 32;
parameter HEIGHT = 32;
parameter TOTAL_PIXELS = WIDTH * HEIGHT;

// BRAM IP instance - data storage from COE file
wire [7:0] bram_dout;
reg [15:0] bram_addr = 0;
blk_mem_gen_0 BRAM (
    .clka(clk),
    .addra(bram_addr),
    .douta(bram_dout)
);

// Input and output arrays
reg [7:0] input_array [0:TOTAL_PIXELS-1];
reg [7:0] output_array [0:TOTAL_PIXELS-1];

// Internal counters
reg [15:0] input_count = 0;
reg [15:0] output_count = 0;
reg [7:0] negated_pixel;

// Flags
reg input_done = 0;
reg output_done = 0;

// Input array loading from BRAM and handling the two-cycle delay
always @(posedge clk) begin
    if (!input_done) begin
        // Start populating input_array from the 3rd cycle onward (input_count >= 2)
        if (input_count >= 2) begin
            input_array[input_count - 2] <= bram_dout;
        end

        // Increment address and count
        input_count <= input_count + 1;
        bram_addr <= bram_addr + 1;

        // Mark input done after the last pixel is loaded (considering delay)
        if (input_count == TOTAL_PIXELS + 1) begin
            input_done <= 1;
            bram_addr <= 0; // Reset address to 0 for safety
        end
    end
end

// Negate the input array to generate the output array
always @(posedge clk) begin
    if (input_done && !output_done) begin
        negated_pixel = input_array[output_count];
        output_array[output_count] <= negated_pixel;
        output_count <= output_count + 1;
        if (output_count == TOTAL_PIXELS-1) begin
            output_done <= 1;
        end
    end
end

// Send output array data one by one to ILA for visualization and export
reg [7:0] ila_out;  // Connect this to the ILA for viewing pixel data
reg [15:0] ila_count = 0;
always @(posedge clk) begin
    if (output_done) begin
        ila_out <= output_array[ila_count];
        ila_count <= ila_count + 1;
    end
end

// Connect ILA IP
ila_0 ILA (
    .clk(clk),
    .probe0(ila_out)
);


endmodule

