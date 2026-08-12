`timescale 1ns / 1ps

module fifo_tb;

    // Testbench signals - these drive the DUT's inputs, and capture its outputs
    reg         clk;
    reg         rst_n;
    reg         wr_en;
    reg         rd_en;
    reg [7:0]   data_in;
    wire [7:0]  data_out;
    wire        full;
    wire        empty;
    integer     i;

    // Instantiate the FIFO (device under test)
    fifo #(
        .DATA_WIDTH(8),
        .DEPTH(16)
    ) dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .wr_en      (wr_en),
        .rd_en      (rd_en),
        .data_in    (data_in),
        .data_out   (data_out),
        .full       (full),
        .empty      (empty)
    );

    // Clock generation
    always #5 clk = ~clk; // 100MHz clock

    // Waveform dump setup
    initial begin
        $dumpfile("fifo_tb.vcd");
        $dumpvars(0, fifo_tb);
    end

    // Test Stimulus
    initial begin
        // Initialize signals
        clk = 0;
        rst_n = 0;
        wr_en = 0;
        rd_en = 0;
        data_in = 0;

        // Hold reset for a couple of clock cycles
        #20;
        rst_n = 1;

        // Write one byte
        @(posedge clk);
        wr_en = 1;
        data_in = 8'hAA;
        @(posedge clk);
        wr_en = 0;

        // Let a cycle pass, then read it back
        @(posedge clk);
        rd_en = 1;
        @(posedge clk);
        rd_en = 0;

        // Test: fill FIFOT to full (16 writes into a 16-deep FIFO)
        for (i = 0; i < 16; i = i + 1) begin
            @(posedge clk);
            wr_en = 1;
            data_in = i;
        end
        @(posedge clk);
        wr_en = 0;

        // Check FIFO reports full after 16 writes
        if (full)
            $display("PASS: full asserted correctly after 16 writes at time %0t", $time);
        else
            $display("FAIL: full NOT asserted after 16 writes at time %0t", $time);

        // Attempt a 17th write - should be blocked by the full gaurd
        @(posedge clk);
        wr_en = 1;
        data_in = 8'hFF; // this value should NEVER make it into the mem
        @(posedge clk);
        wr_en = 0;

        // Let things settle, then finish
        #20;
        $finish;

    end


endmodule