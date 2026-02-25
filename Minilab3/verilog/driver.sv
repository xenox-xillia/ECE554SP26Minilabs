//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:        Henry Wysong
// 
// Create Date:    
// Design Name:    Processor Driver
// Module Name:    driver 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description:  For SPART integration
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module driver(
    input wire clk,
    input wire rst,
    input wire [1:0] br_cfg,        //buad rate config
    output wire iocs,
    output wire iorw,
    input wire rda,
    input wire tbr,
    output wire [1:0] ioaddr,
    inout wire [7:0] databus,
    output wire [2:0] state_out // for testing/debugging
    );


// SM states
typedef enum logic [2:0] {IDLE, RECEIVING, TRANSMITTING, CONFIG_BAUD_LOWER, CONFIG_BAUD_UPPER} state_t;

state_t state, next_state;

assign state_out = state; // output current state for testing/debugging

logic iocs_int;
logic iorw_int;
logic [1:0] ioaddr_int;
logic [7:0] databus_out;
logic [15:0] baud_internal;
logic [7:0] rx_data;
logic capture_data; // flag to capture data on next clock cycle
logic new_data; // flag to indicate new data is ready to transmit

//Monitor br_cfg switches
logic [1:0] br_cfg_prev;

always_ff @(posedge clk or negedge rst)
    if(!rst) 
        br_cfg_prev <= 2'b00;
    else
        br_cfg_prev <= br_cfg;

// Assign baud cntr value (precomputed division values for 50MHz clock)
always_comb 
    case(br_cfg)
        2'b00: baud_internal = 16'd650;     // 4800 baud
        2'b01: baud_internal = 16'd325;     // 9600 baud
        2'b10: baud_internal = 16'd162;     // 19200 baud
        2'b11: baud_internal = 16'd80;      // 38400 baud
    endcase
    


always_ff @(posedge clk or negedge rst)
    if (!rst)
        rx_data <= 8'b0; // Clear received data on reset
    else if (capture_data)
        rx_data <= databus;

always_ff @(posedge clk or negedge rst)
    if (!rst)
        new_data <= 0; // Clear new data flag on reset
    else if (capture_data)
        new_data <= 1; // Set new data flag when we capture new data
    else if (state == TRANSMITTING) 
        new_data <= 0; // Clear new data flag once we've transmitted it


// State machine logic and reset
always_ff @(posedge clk or negedge rst) begin
    if (!rst) begin
        state <= CONFIG_BAUD_LOWER;       // on reset configure baud rate and return to idle
    end
    else
        state <= next_state;
end

always_comb begin
    //Default signals
    next_state = state; // default to hold state
    databus_out = 8'bz; // default to high impedance
    iocs_int = 0;
    iorw_int = 0;
    ioaddr_int = 2'b00; // default address
    capture_data = 0; // default to not capture data

    case (state)
        IDLE: begin
            if(rda) begin                   // Receive data is ready
                next_state = RECEIVING;
                iocs_int = 1;
                iorw_int = 1; // read
            end
            else if(tbr && new_data) begin              // Transmit data is ready
                next_state = TRANSMITTING;
                iocs_int = 1;
                iorw_int = 0; // write
            end
            else if(br_cfg != br_cfg_prev) begin    //Changed baud rate
                next_state = CONFIG_BAUD_LOWER;
                iocs_int = 1;
                iorw_int = 0; // write
                ioaddr_int = 2'b10; // low division buffer
            end
            
        end
        

        RECEIVING: begin    
            next_state = IDLE; // return to idle after reading data and wait for tbr to transmit
            iocs_int = 1; // enable read
            iorw_int = 1; // read
            capture_data = 1; // flag to capture data
        end

        TRANSMITTING: begin
            next_state = IDLE;
            databus_out = rx_data;  // output data to be transmitted
            iocs_int = 1;           // enable 
            ioaddr_int = 2'b00;     // tx/rx registers
            iorw_int = 0;           // write
        end
        
        CONFIG_BAUD_LOWER: begin
            next_state = CONFIG_BAUD_UPPER;
            databus_out = baud_internal[7:0]; // lower 8 bits of baud division value
            ioaddr_int = 2'b10; // low division buffer
            iorw_int = 0; // write
            iocs_int = 1; // enable write
        end

        CONFIG_BAUD_UPPER: begin
            next_state = IDLE;
            databus_out = baud_internal[15:8]; // upper 8 bits of baud division value
            ioaddr_int = 2'b11; // high division buffer
            iorw_int = 0; // write
            iocs_int = 1; // enable write
        end

        default:
            next_state = IDLE;  //Should never be here

    endcase
    
end


//Assign outputs
assign iocs = iocs_int;
assign iorw = iorw_int;
assign ioaddr = ioaddr_int;
assign databus = (iocs_int && !iorw_int) ? databus_out : 8'bz; // drive databus only during write operations



endmodule
