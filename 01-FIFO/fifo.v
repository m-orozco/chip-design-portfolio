module fifo #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 16
) (
    input wire                  clk,
    input wire                  rst_n, // active low reset
    input wire                  wr_en, // write enable
    input wire                  rd_en, // read enable
    input wire [DATA_WIDTH-1:0] data_in, // 8-bit data input
    output reg [DATA_WIDTH-1:0] data_out, // 8-bit data output
    output wire                 full, // FIFO full flag
    output wire                 empty   // FIFO empty flag
);