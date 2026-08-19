module uart_tx #(
    parameter CLK_FREQ = 921600,  
    parameter  BAUD_RATE = 115200
) (
    input wire         clk,
    input wire         rst_n,       // Active low reset
    input wire         tx_start,    // Start transmission signal/pulse
    input wire [7:0]   tx_data,     // Data to be transmitted
    output reg         tx,          // UART transmit line
    output reg         tx_busy      // Indicates if transmission is in progress
);

    // How many clk cycles = one bit period on the serial line.
    // e.g. 921600 Hz clock / 115200 baud = 8 clk cycles per bit.
    localparam integer DIVISOR = CLK_FREQ / BAUD_RATE;

    // FSM states. IDLE = line high, waiting for work.
    localparam integer IDLE     = 2'd0;
    localparam integer START    = 2'd1;
    localparam integer DATA     = 2'd2;
    localparam integer STOP     = 2'd3;

    reg [1:0] state;
    reg [7:0] shift_reg;          // holds the byte being shifter out, LSB first
    reg [2:0] bit_idx;           // counts which of the 8 data bits we're on (0-7)

    // Baud counter - counts clk cycles, ewraps every DIVISOR cycles.
    // Wide enough to hold DIVISOR-1 for any reasonable divisor.
    reg [15:0] baud_cnt;
    wire baud_tick = (baud_cnt == DIVISOR-1);