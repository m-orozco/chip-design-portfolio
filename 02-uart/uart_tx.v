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
    reg [$clog2(DIVISOR)-1:0] baud_cnt;
    wire baud_tick = (baud_cnt == DIVISOR-1);

    // ---- Baud tick generator ----
    // This block knows nothing about UART framing - it just produces a
    // one-cycle-wide "tick" every DIVISOR clk cycles, but only while the
    // FSM is actually doing something (state != IDLE). Holding it at 0
    // during IDLE means every new frame starts counting from a clean 0,
    // so the first bit period is always the full DIVISOR cycles long.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            baud_cnt <= 0;
        end else if (state == IDLE) begin
            baud_cnt <= 0;
        end else if (baud_tick) begin
            baud_cnt <= 0;
        end else begin
            baud_cnt <= baud_cnt + 1;
        end
    end

    // ---- Main FSM ----
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
           state        <= IDLE;
           tx           <= 1'b1;  // line idles high
           tx_busy      <= 1'b0;
           bit_idx      <= 3'd0;
           shift_reg    <= 8'd0;
        end else begin
            case (state)

                IDLE: begin
                    tx      <= 1'b1;  // line idles high
                    if (tx_start) begin
                        shift_reg <= tx_data;  // latch the byte to send
                        tx_busy   <= 1'b1;
                        state     <= START;
                    end
                end
                