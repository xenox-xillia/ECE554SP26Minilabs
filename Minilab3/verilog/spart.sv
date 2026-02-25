//set default_nettype to none to catch undeclared signals
`default_nettype none


//////////////////////////////////////////////////////////////////////////////////
// Company:         UW
// Engineer:        Henry Wysong-Grass
// 
// Create Date:     2026-02-12
// Design Name:     SPART (Special Purpose Asynchronous Receiver/Transmitter)
// Module Name:     spart 
//
// Revision: 
// Revision 1.00 - Dummy implementation
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////


module spart(
    input wire clk,
    input wire rst,
    input wire iocs,
    input wire iorw,
    output wire rda,
    output wire tbr,
    input wire [1:0] ioaddr,
    inout wire [7:0] databus,
    output wire txd,
    input wire rxd,
    output wire [1:0] state_out // for testing/debugging
    );
    // basically we just hook this up like the schematic shows us :3

    ///////////////
    // Internals //
    ///////////////
    logic enable;
    logic [7:0] rx_data;
    logic [7:0] data_out; // from bus interface to driver

    // instantiate receiver
    receiver iRECV(
        .clk(clk),
        .rst(rst),
        .IOADDR(ioaddr),
        .enable(enable),
        .IOCS(iocs),
        .IORW(iorw),
        .RxD(rxd),
        .RDA(rda),
        .dout(rx_data), // to bus interface
        .state_out(state_out) // for testing/debugging
     );


    // instantiate transmitter
    transmitter iTRANS(
        .clk(clk),
        .rst(rst),
        .IOADDR(ioaddr),
        .DATABUS(data_out), // from bus interface
        .IOCS(iocs),
        .IORW(iorw),
        .enable(enable),
        .TBR(tbr),
        .TxD(txd)
    );

    // instantiate bus interface
    bus_interface iBUS(
        .databus(databus),
        .rda(rda),
        .tbr(tbr),
        .iocs(iocs),
        .iorw(iorw),
        .receive_buffer(rx_data), // from receiver to bus interface
        .ioaddr(ioaddr),
        .data_out(data_out) // from bus interface to driver
    );


    // instantiate baud rate generator
    baud_rate_generator iBAUD(
        .clk(clk),
        .rst(rst),
        .IOADDR(ioaddr),
        .DATABUS(databus),
        .enable(enable) // to receiver and transmitter
    );



endmodule
