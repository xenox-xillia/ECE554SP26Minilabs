module bus_interface(
    inout [7:0] databus,
    
    input wire rda,     // Receive Data Available
    input wire tbr,     // Transmit Buffer Ready
    input wire iocs,    // I/O Chip Select - Indicates that the current I/O operation is intended for the SPART.
    input wire iorw,    // I/O Read/Write - Indicates whether the current I/O operation is a read (1) or a write (0).
    input wire [7:0] receive_buffer,
    input wire [1:0] ioaddr,

    output wire [7:0] data_out // data sent from the processor to spart
    );


logic [7:0] status_reg;
assign status_reg = {6'b00_0000 , tbr, rda}; //mappings defined in writeup

// 3 state drivers for the databus
assign databus =    (!iocs || !iorw) ? 8'hZZ : (            // high impedance when chip select is low or during a write to the spart
                    (ioaddr == 2'b01) ? (status_reg): (receive_buffer)    // select between receive buffer and status register   
                    );

assign data_out = (ioaddr == 2'b01) ? (status_reg) : (databus); // output to the rest of spart



endmodule