module edge_detect_tb();

// Parameters matches your image size
localparam IMG_W = 640; // Change to your image width
localparam IMG_H = 480; // Change to your image height
localparam TOTAL_PIXELS = IMG_W * IMG_H;

logic clk;
logic rst_n;
logic filter_type; // 0 for Sobel horizontal, 1 for Sobel vertical
logic valid;
logic [9:0] x_cntr;
logic [9:0] y_cntr; //must be >>1.
logic [11:0] pixel_r;
logic [11:0] pixel_g;
logic [11:0] pixel_b;
wire [11:0] pixel_out;

logic [35:0] input_img [0:TOTAL_PIXELS-1]; // Assuming 12 bits per channel, packed into 36 bits

integer file_out;


// Instantiate the edge detection module
edge_detect iDUT(
    .clk(clk),
    .rst_n(rst_n),
    .filter_type(filter_type),
    .valid(valid),
    .x_cntr(x_cntr),
    .y_cntr(y_cntr),
    .pixel_r(pixel_r),
    .pixel_g(pixel_g),
    .pixel_b(pixel_b),
    .pixel_out(pixel_out)
);

// read in pixel data hex dump

initial begin


    // Load pixel data from a hex file into the input_img array
    $readmemh("image_in.hex", input_img); // Assuming pixel data is stored in a hex file, adjust as needed
    file_out = $fopen("image_out.hex", "w");

    // Initialize signals
    clk = 0;
    rst_n = 0;
    filter_type = 0;
    valid = 0;
    x_cntr = 0;
    y_cntr = 0;
    
    @(negedge clk);
    rst_n = 1; // Release reset after one clock cycle

    //Loop through the whole image
    for(int i = 0; i < TOTAL_PIXELS; i++) begin
        // Extract RGB values from the input image array
        {pixel_r, pixel_g, pixel_b} = input_img[i]; // Assuming the hex file is formatted correctly

        // Set valid signal high for the duration of the image processing
        valid = 1;

        // Update x and y counters based on the current pixel index
        x_cntr = i % IMG_W;
        y_cntr = i / IMG_W;

        @(negedge clk); // Wait for the next clock cycle to process the next pixel

        // Write the output pixel value to a hex file
        $fwrite(file_out, "%h\n", pixel_out); // Write output in hex format, adjust as needed
    end

    valid = 0; // Deassert valid after processing all pixels

    repeat(10) @(negedge clk); // Wait a few cycles to ensure all processing is complete

    $fclose(file_out); // Close the output file after processing all pixels
    file_out = $fopen("image_out_vert.hex", "w");

    // Test vertical edge detection by changing the filter type and reprocessing the image
    filter_type = 1; // Switch to vertical edge detection
    for(int i = 0; i < TOTAL_PIXELS; i++) begin
        // Extract RGB values from the input image array
        {pixel_r, pixel_g, pixel_b} = input_img[i]; // Assuming the hex file is formatted correctly

        // Set valid signal high for the duration of the image processing
        valid = 1;

        // Update x and y counters based on the current pixel index
        x_cntr = i % IMG_W;
        y_cntr = i / IMG_W;

        @(negedge clk); // Wait for the next clock cycle to process the next pixel

        // Write the output pixel value to a hex file
        $fwrite(file_out, "%h\n", pixel_out); // Write output in hex format, adjust as needed
    end

    valid = 0; // Deassert valid after processing all pixels

    repeat(10) @(negedge clk); // Wait a few cycles to ensure all processing is complete

    $fclose(file_out); // Close the output file after processing all pixels

    $stop; // Stop the simulation

end


always #5 clk = ~clk; // 100MHz clock

endmodule