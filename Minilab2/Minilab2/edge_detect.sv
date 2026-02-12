// --------------------------------------------------------------------
// By: Henry Wysong
// Date: 02/xx/26
// --------------------------------------------------------------------
//   Project: ECE 554 - Minilab 2
//   File: edge_detect.sv
//   Description: This module performs edge detection on a grayscale image using the Sobel operator.

module edge_detect(
    input wire clk,
    input wire rst_n,
    input wire filter_type, // 0 for Sobel horizontal, 1 for Sobel vertical
    input wire valid,
    input wire [9:0] x_cntr, //must be >>1.
    input wire [9:0] y_cntr, //must be >>1. 
    input wire [11:0] pixel_in, // Grayscale pixel input
    output wire [11:0] pixel_out
);


// Internal signals
reg signed [14:0] edge_value_v; // Output of the edge detection filter (can be negative, so signed)
reg signed [14:0] edge_value_h; // Intermediate value for horizontal edge detection
reg [14:0] edge_value_v_u; // Output of the edge detection filter (can be negative, so signed)
reg [14:0] edge_value_h_u; // Intermediate value for horizontal edge detection
wire in_bounds; // Signal to indicate if the current pixel is within the valid image area for edge detection
assign in_bounds = (x_cntr > 1) && (x_cntr < 638) && (y_cntr > 1) && (y_cntr < 478) && valid; // Ensure we have enough pixels for the 3x3 window and that the input is valid

// 3x3 registers to hold the current and previous rows of pixel data for edge detection
reg signed [12:0] cur_pix_mat [0:2][0:2]; // Current 9 pixels for edge detection (3x3 matrix)

// wires holding output of each row buffer
wire [11:0] row1_out; // Output of the first row buffer (current row)
wire [11:0] row2_out; // Output of the second row buffer (previous row)

// Simple edge detection using a 3x3 Sobel operator
//Instantiate row buffers to hold the previous two rows of pixel data
row_buffer iR1 (        //current row buffer
    .clk(clk),
    .rst_n(rst_n),
    .en(valid),
    .pixel_in(pixel_in), // Feed the current pixel into the first row buffer
    .pixel_out(row1_out)
);

row_buffer iR2 (        //previous row buffer
    .clk(clk),
    .rst_n(rst_n),
    .en(valid),
    .pixel_in(row1_out), // Feed the output of the first row buffer into the second row buffer
    .pixel_out(row2_out) 
);


// Shift current window
always_ff @(posedge clk) begin
    if(valid) begin
        cur_pix_mat[2][0] <= pixel_in; // Current pixel
        cur_pix_mat[2][1] <= cur_pix_mat[2][0]; // Shift right
        cur_pix_mat[2][2] <= cur_pix_mat[2][1]; // Shift right

        cur_pix_mat[1][0] <= row1_out; // Previous row pixel
        cur_pix_mat[1][1] <= cur_pix_mat[1][0]; // Shift right
        cur_pix_mat[1][2] <= cur_pix_mat[1][1]; // Shift right

        cur_pix_mat[0][0] <= row2_out; // Previous previous row pixel
        cur_pix_mat[0][1] <= cur_pix_mat[0][0]; // Shift right
        cur_pix_mat[0][2] <= cur_pix_mat[0][1]; // Shift right
    end
end

always_ff @(posedge clk) begin
    if(in_bounds) begin
        // do the operation
        edge_value_h <= (cur_pix_mat[0][0] + {cur_pix_mat[0][1][12:0], 1'b0} + cur_pix_mat[0][2]) - (cur_pix_mat[2][0] + {cur_pix_mat[2][1][12:0], 1'b0} + cur_pix_mat[2][2]); // Sobel horizontal
        edge_value_v <= (cur_pix_mat[0][0] + {cur_pix_mat[1][0][12:0], 1'b0} + cur_pix_mat[2][0]) - (cur_pix_mat[0][2] + {cur_pix_mat[1][2][12:0], 1'b0} + cur_pix_mat[2][2]); // Sobel vertical
    end
    else begin
        edge_value_h <= 15'h0000;   // Output black for out-of-bounds pixels
        edge_value_v <= 15'h0000;
    end

    // Take absolute value for unsigned output
    edge_value_h_u <= edge_value_h[14] ? -edge_value_h : edge_value_h;
    edge_value_v_u <= edge_value_v[14] ? -edge_value_v : edge_value_v;

end

assign pixel_out = filter_type ? 
                (edge_value_v_u > 15'd4095 ? 12'hFFF : edge_value_v_u[11:0]) :
                (edge_value_h_u > 15'd4095 ? 12'hFFF : edge_value_h_u[11:0]); // Output the edge value, capped at 4095 for 12-bit output
endmodule
