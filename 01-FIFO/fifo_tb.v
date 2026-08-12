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

        // Let things settle, then finish
        #20;
        $finish;

    end


endmodule