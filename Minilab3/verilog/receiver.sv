module receiver(
    input clk,
    input rst,
    input [1:0] IOADDR,
    input enable,
    input IOCS,
    input IORW,
    input RxD,
    output RDA,
    output [7:0] dout,
    output [1:0] state_out // for testing/debugging
);

typedef enum logic [1:0] {
    IDLE = 2'b00,
    START_BIT = 2'b01,
    DATA_BITS = 2'b10,
    STOP_BIT = 2'b11
} state_t;

state_t state, next_state;

assign state_out = state; // output current state for testing/debugging

logic [3:0] div_16_counter; // Counter for 16x baud rate
logic [2:0] metastable_data; // Shift register for metastability
logic [9:0] data_buffer; // Buffer to hold received data
logic [2:0] bit_count; // Counter for received bits
logic sample_trigger; // Trigger to sample data at the correct time
logic en_b_cntr; 

// actual baud counter                      !NOTE NEED TO FIX
always_ff @(posedge clk or negedge rst) begin
    if (!rst)
        div_16_counter <= '0;
    else if (en_b_cntr && enable)
        div_16_counter <= div_16_counter + 1'b1;
    else if (!en_b_cntr)
        div_16_counter <= '0;
end


// Shift register for metastability and data capture
always_ff @(posedge clk or negedge rst) begin
    if (!rst)
        data_buffer <= '0;
    else if (sample_trigger)    // Shift in the whole start + data + stop bits for each rx
        data_buffer <= {metastable_data[2], data_buffer[9:1]}; // Shift in new bit into MSB
end

// bit count
always_ff @(posedge clk or negedge rst)
    if (!rst)
        bit_count <= '0;
    else if (state == DATA_BITS && sample_trigger)
        bit_count <= bit_count + 1'b1;
    else if (state == IDLE)
        bit_count <= '0;

assign sample_trigger = (enable) && (div_16_counter == 4'd8); // Sample in the middle of the bit period


// Sample on edge of enable. Our bad rate is actually based on 
always_ff @(posedge clk or  negedge rst)
    if(!rst)
        metastable_data <= '0;
    else                 
        metastable_data <= {metastable_data[1:0], RxD};
    


// State machine reset and trans
always_ff @(posedge clk or negedge rst) 
    if (!rst) 
        state <= IDLE;
    else 
        state <= next_state;

// State machine combinational logic

always_comb begin
    next_state = state; // Default to hold state
    en_b_cntr = 0;      // Enable for the baud decimator


    case (state)
        IDLE: begin
//            if (enable && RxD == 0) begin // Start bit detected
            if (RxD == 0) begin // Start bit detected
                next_state = START_BIT;
                en_b_cntr = 1;      // Start counting for baud rate
            end
        end
        
        START_BIT: begin
            en_b_cntr = 1;

            if (sample_trigger) 
                next_state = DATA_BITS;
        end

        DATA_BITS: begin
            en_b_cntr = 1;
            if (sample_trigger)                 
                if (bit_count == 3'd7) // Last data bit received
                    next_state = STOP_BIT;

        end

        STOP_BIT: begin
            en_b_cntr = 1;
            if (sample_trigger)
                next_state = IDLE;
        end
        
        default: next_state = IDLE;
    endcase

end



assign dout = data_buffer[8:1]; // Output the 8 data bits (ignore start and stop bits)
assign RDA = (state == STOP_BIT) && sample_trigger; // Data is ready at the end of the stop bit sampling


endmodule