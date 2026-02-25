module baud_rate_generator(
    input clk,
    input rst,
    input [1:0] IOADDR,
    input [7:0] DATABUS,
    output enable
);

    // ----------------------------------------
    // Internal registers
    // ----------------------------------------
    logic [7:0]  db_low;
    logic [7:0]  db_high;
    logic [15:0] divisor_buffer;
    logic [15:0] counter;

    // default divisor will be 50 MHz/(16*9600) -1 = 324
    localparam logic [15:0] DEFAULT_DIVISOR = 16'd324;

    // Divisor buffers, written to by the bus interface
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            db_low <= DEFAULT_DIVISOR [7:0];
            db_high <= DEFAULT_DIVISOR [15:8];
        end
        else begin

            if (IOADDR == 2'b10) db_low <= DATABUS;

            if (IOADDR == 2'b11) db_high <= DATABUS;

        end
    end

    assign divisor_buffer = {db_high, db_low};

    // Down counter and reloading it
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            counter <= DEFAULT_DIVISOR;
        end
        else begin
            if (counter == 16'd0) counter <= divisor_buffer;
            else counter <= counter - 1;
        end
    end

    assign enable = (counter == 16'd0);
    
endmodule