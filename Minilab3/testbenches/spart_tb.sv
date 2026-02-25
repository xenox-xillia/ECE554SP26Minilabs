module spart_tb ();

    // Internal signals
    logic clk;
    logic rst;
    logic iocs;
    logic iorw;
    logic rda;
    logic tbr;
    logic   [1:0] ioaddr;
    wire    [7:0] databus;
    logic   [1:0]br_cfg;

    // Testbench signals
    logic txd;  // Output of spart
    logic rxd;  // Input serial data to spart

    // Test transmission data
    logic [7:0] tx_data; // Data to transmit
    logic [7:0] rx_data; // Data to receive

    // Instantiate spart DUT
    spart iDUT_spart(
        .clk(clk),
        .rst(rst),
        .iocs(iocs),
        .iorw(iorw),
        .rda(rda),
        .tbr(tbr),
        .ioaddr(ioaddr),
        .databus(databus),
        .txd(txd),
        .rxd(rxd)
    );

    // Instantiate driver DUT
    driver iDriver(
        .clk(clk),
        .rst(rst),
        .br_cfg(br_cfg),
        .iocs(iocs),
        .iorw(iorw),
        .rda(rda),
        .tbr(tbr),
        .ioaddr(ioaddr),
        .databus(databus)
    );    

    int bit_cnt=0; // Counter for all bits

    initial begin
        // Initialize signals & reset
        clk = 0;
        rst = 0;
        rxd = 1; // Idle state for serial line
        br_cfg = 2'b00; // 4800 baud

        @(negedge clk);
        rst = 1; // Release reset
        iocs = 1;

        repeat(10) @(posedge clk); // Wait for some time to allow config
        
        // Check internal baud rates 
        if (iDriver.baud_internal != 16'd650)
            $display("Error: Default baud rate divisor incorrect. Expected 650, got %d", iDriver.baud_internal);
        else
            $display("Default baud rate divisor correctly set to 650 for 4800 baud.");
        if ((iDUT_spart.iBAUD.db_low != 8'h8A) || (iDUT_spart.iBAUD.db_high != 8'h02)) //0x028A
            $display("Error: Default baud rate divisor incorrect. Expected 0x028A, got 0x%d", {iDUT_spart.iBAUD.db_high, iDUT_spart.iBAUD.db_low});
        else
            $display("\t\tPASS:Default baud rate divisor correctly set to 650 for 4800 baud."); 


        // Change baud rate to 9600 and check divisor
        br_cfg = 2'b01; // Set to 9600 baud
        repeat(10) @(posedge clk); // Wait for some time to allow config
        if (iDriver.baud_internal != 16'd325)
            $display("Error: Baud rate divisor incorrect after setting to 9600 baud. Expected 325, got %d", iDriver.baud_internal);
        else
            $display("Baud rate divisor correctly set to 325 for 9600 baud.");
        if ((iDUT_spart.iBAUD.db_low != 8'h45) || (iDUT_spart.iBAUD.db_high != 8'h01)) //0x0145
            $display("Error: Baud rate divisor incorrect after setting to 9600 baud. Expected 0x0145, got 0x%d", {iDUT_spart.iBAUD.db_high, iDUT_spart.iBAUD.db_low});
        else
            $display("\t\tPASS:Baud correctly reconfigured to 9600 baud.");
            
        
        $display("\n////////////////////////////////////////////////");
        $display("//  BAUD RATE / CONFIGURATION TESTS COMPLETE  //");
        $display("////////////////////////////////////////////////\n\n");


        // Ensure we're in idle state before starting transmission tests
        if (iDriver.state != iDriver.IDLE)
            $display("Error: Driver not in IDLE state at start of transmission tests. Current state: %d", iDriver.state);
        else
            $display("\t\tPASS: Driver correctly in IDLE state at start of transmission tests.\n");


        // Simulate a transmission by writing data to the transmit buffer
        tx_data = 8'hAA; // Test byte to transmit (10101010)


        //Pull rxd low to simulate start bit

        @(negedge clk);
        rxd = 0;
        repeat(5208) @(negedge clk); // Wait for one baud period (which is trickily 16x the divisor or around 5208 clocks)

        for (int i = 0; i < 8; i++) begin
            bit_cnt = i;
            rxd = tx_data[i]; // Send bits LSB first
            repeat(5208) @(negedge clk); // One baud period
        end
        rxd = 1; // Stop bit
        // Now the waiting begins...


        // Setup timeout and get ready to receive txd output
        for (int i = 0; i < 100000; i++)begin       //wait ~21 baud periods for the data to be transmitted and received back (since we have a loopback)
            @(negedge clk);
            // Check for received data on each clock edge
            if (txd == 0) begin
                $display("Start bit detected on TxD at time %t", $time);
                repeat(7812) @(negedge clk); // Wait 1.5 baud periods to sample in the middle of the first data bit
                for (int j = 0; j < 8; j++) begin
                    rx_data[j] = txd; // Sample data bits
                    bit_cnt = j;
                    $display("Received bit %d: %b", j, rx_data[j]);
                    $display("\t\t\tTime: %t\n", $time);
                    repeat(5208) @(negedge clk); // Wait one baud period between bits
                end
                break; // Break out of the loop after receiving the byte
            end
        end


        // just wait a teensy bit
        repeat(10000) @(posedge clk);

        // Check if received data matches transmitted data
        if (rx_data != tx_data)
            $display("Error: Received data does not match transmitted data. Expected 0x%h, got 0x%h", tx_data, rx_data);
        else
            $display("\t\tPASS:Data transmission successful. Received 0x%h as expected.", rx_data);
        
        

        //Stop
        $stop;
    end
    



    // Clock generation
    always #5 clk = ~clk;

endmodule