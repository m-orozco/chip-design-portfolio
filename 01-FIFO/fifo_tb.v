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

endmodule