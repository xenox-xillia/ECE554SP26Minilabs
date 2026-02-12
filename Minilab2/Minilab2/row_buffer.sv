module row_buffer(
    input clk,
    input rst_n,
    input en,
    input [11:0] pixel_in,
    output reg [11:0] pixel_out
);

// FIFO buffer to hold one row of pixel data
reg [11:0] buffer [0:639]; // Assuming a row of 640 pixels and 12 bit pixel
reg [9:0] write_ptr; // Pointer for writing to the buffer
reg [9:0] read_ptr;  // Pointer for reading from the buffer

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        write_ptr <= '0;
        read_ptr <= 10'd1; // Start reading from the first pixel
    end
    else if (en) begin
        // Write incoming pixel to the buffer
        buffer[write_ptr] <= pixel_in;
        write_ptr <= write_ptr == 639 ? 0 : write_ptr + 1'b1;
        read_ptr <= read_ptr == 639 ? 0 : read_ptr + 1'b1; // Move to the next pixel for output
        // Output the pixel from the buffer
        pixel_out <= buffer[read_ptr]; // Output the stored pixel with padding
    end

end


endmodule