module shiftreg_tb();

// Inputs
logic clk;
logic rst_n;
logic en;
logic [11:0] pixel_in;
// Outputs
logic [11:0] pixel_out;


row_buffer iDUT (
    .clk(clk),
    .rst_n(rst_n),
    .en(en),
    .pixel_in(pixel_in),
    .pixel_out(pixel_out)
);

initial begin
    //Set initial value
    clk = 0;
    rst_n = 0;
    en = 0;
    pixel_in = 12'h000;

    @(negedge clk); // Wait for 2 clock cycles
    rst_n = 1; // Release reset



    //write pixel values to the buffer
    for(int i = 0; i < 640; i++) begin
        @(negedge clk);
        en = 1; // Enable the buffer
        pixel_in = i; // Feed in pixel values from 0 to 639
    end
    //check values
    for(int i = 0; i < 640; i++) begin
        @(negedge clk);
        en = 1; // Enable the buffer
        pixel_in = i; // Feed in pixel values from 0 to 639
        if(pixel_out !== i) begin
            $display("Test failed at pixel %d: expected %d, got %d", i, i, pixel_out);
        end
        else begin
            $display("Pixel %d passed: expected %d, got %d", i, i, pixel_out);
        end
    end

    $display("Test completed");
    $stop;
end

always #5 clk = ~clk; // 100MHz clock

endmodule

