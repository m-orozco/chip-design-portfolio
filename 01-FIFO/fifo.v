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

// Internal memory array
reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

// Read/write pointers - extra MSB used to distunguish full from empty
reg [$clog2(DEPTH):0] wr_ptr; // write pointer
reg [$clog2(DEPTH):0] rd_ptr; // read pointer

// Write logic
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        wr_ptr <= 0;
    end else if (wr_en && !full) begin //prevents writing when full
        mem[wr_ptr[$clog2(DEPTH)-1:0]] <= data_in;
        wr_ptr <= wr_ptr + 1;
    end
end

// Read logic
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rd_ptr <= 0;
        data_out <= 0;
    end else if (rd_en && !empty) begin //prevents reading when empty
        data_out <= mem[rd_ptr[$clog2(DEPTH)-1:0]];
        rd_ptr <= rd_ptr + 1;
    end
end 

// Full/empty flag logic (combinational)
assign empty = (wr_ptr == rd_ptr);
assign full = (wr_ptr[$clog2(DEPTH)-1:0] == rd_ptr[$clog2(DEPTH)-1:0]) &&
                (wr_ptr[$clog2(DEPTH)] != rd_ptr[$clog2(DEPTH)]);  