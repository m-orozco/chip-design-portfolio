module fifo #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 16
) (
    input wire                  clk,
    input wire                  rst_n,
    input wire                  wr_en,
    input wire                  rd_en,
    input wire [DATA_WIDTH-1:0] data_in,
    input wire [DATA_WIDTH-1:0] data_out,
    output wire                 full,
    output wire                 empty   
);