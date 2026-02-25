module transmitter(
    input clk,
    input rst,
    input [1:0] IOADDR,
    input [7:0] DATABUS,
    input IOCS,
    input IORW,
    input enable,
    output TBR,
    output TxD
);

    logic wr_tx, tx_buf_full, register_busy, shift_enable, baud_done, last_bit;
    logic [2:0] bit_count;
    logic [3:0] clk_baud;
    logic [7:0] transmit_buffer;
    logic [9:0] transmit_register;  // {stop bit, data, start bit}

    assign wr_tx = (IOADDR == 2'b00) && (IORW == 0) && IOCS;
    assign TBR = ~tx_buf_full;
    assign shift_enable = baud_done && register_busy;
    assign baud_done = clk_baud == 4'd15;
    assign last_bit = bit_count == 3'd7;
    assign TxD = transmit_register[0];

    ///////////////////
    // State Machine //
    ///////////////////
    typedef enum logic [1:0] {IDLE, START, DATA, STOP} state_t;
    state_t state, next_state, prev_state;

    always_ff @(posedge clk or negedge rst) begin
        if (!rst)
            state <= IDLE;
        else begin
            state <= next_state;
            prev_state <= state;
        end
    end

    always_comb begin
        next_state = state;
        case (state)

            IDLE: begin
                if (tx_buf_full) begin
                    next_state = START;
                end
            end

            START: begin
                if (baud_done && enable)
                    next_state = DATA;
            end

            DATA: begin
                if ((baud_done && enable) && last_bit) 
                    next_state = STOP;
            end

            STOP: begin
                if (baud_done && enable)
                    next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end
    

    ///////////////
    // Baud rate //
    ///////////////
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            clk_baud <= 0;
        end
        else begin
            if (enable && (state == START || state == DATA || state == STOP)) begin
                clk_baud++;
                // if (clk_baud == 4'd15) begin
                //     clk_baud <= 0;
                // end
            end
        end
    end

    /////////////////////
    // Transmit Buffer //
    /////////////////////

    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            transmit_buffer <= 8'd0;
            tx_buf_full     <= 1'b0;
        end
        else begin
            if (wr_tx) begin
                transmit_buffer <= DATABUS;
                tx_buf_full     <= 1'b1;
            end
            else if (state == START) begin
                tx_buf_full <= 1'b0;   // buffer consumed
            end
        end
    end

    ///////////////////////
    // Transmit Register //
    ///////////////////////

    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            transmit_register <= 10'b1111111111;
            register_busy   <= 1'b0;
        end
        else begin
            // LOAD shift register when starting transmission
            if (prev_state == IDLE && state == START) begin
                transmit_register <= {1'b1, transmit_buffer, 1'b0}; // stop, data, start
                register_busy   <= 1'b1;
            end

            // Shift during DATA/START/STOP
            else if (shift_enable && enable) begin
                transmit_register <= {1'b1, transmit_register[9:1]};
            end

            // Done transmitting
            if (state == STOP && baud_done)
                register_busy <= 1'b0;
        end
    end

    /////////////////
    // Bit Counter //
    /////////////////

    always_ff @(posedge clk or negedge rst) begin
        if (!rst)
            bit_count <= 3'd0;
        else if (state == DATA && baud_done && enable)
            bit_count <= bit_count + 1;
        else if (state == IDLE)
            bit_count <= 3'd0;
    end
endmodule