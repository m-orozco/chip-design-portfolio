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
    reg [7:0]   data_out_before_read;

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

        // Test: read from empty - drain the FIFO completely first
        rd_en = 1;
        repeat (17) @(posedge clk); // clears all 17 items in buffer
        rd_en = 0;

        // FIFO should now be empty, attempt one more read
        if (empty)
            $display("Pass: empty asserted correctly after draining FIFO at time %0t", $time);
        else
            $display("FAIL: empty NOT asserted after draining FIFO at time %0t", $time);

        @(posedge clk);
        data_out_before_read = data_out; // snapshot data_out just before illegal read attempt
        rd_en = 1; // attempt to read from empty FIFO - should be blocked by the empty guard
        @(posedge clk);
        rd_en = 0;
        
        // Self-check: rd_en && !empty was false, so the read-logic always block
        // should not have fired, meaning data_out must be unchanged
        if (data_out !== data_out_before_read)
            $display("FAIL: underflow guard broken - data_out changed from %0d to %0d at time %0t", data_out_before_read, data_out, $time);
        else
            $display("PASS: underflow guard held - data_out unchanged (%0d) after read-from-empty at time %0t", data_out, $time);

        // Test: order preservation - write 5 distinct values, read them back,
        // confirm they come out in the same order (0, 1, 2, 3, 4)
        for (i = 0; i < 5; i = i + 1) begin
            @(posedge clk);
            wr_en = 1;
            data_in = i;
        end
        @(posedge clk);
        wr_en = 0;

        for (i = 0; i < 5; i = i + 1) begin
            @(posedge clk);
            rd_en = 1;
            @(posedge clk); // wait for registered data_out to update
            rd_en = 0;
            if (data_out !== i)
                $display("Fail: order mismatch - expected %0d, got %0d at time %0t", i, data_out, $time);
            else
                $display("Pass: correct value %0d read back in order at time %0t", i, $time);
            rd_en = 0;
        end

        // Test simultaneaous read + write in the same clock cycle
        // First, write 3 known values so the FIFO isn't empty
        for (i = 0; i < 3; i = i + 1) begin
            @(posedge clk);
            wr_en = 1;
            data_in = 8'd100 + i; // write 100, 101, 102
        end
        @(posedge clk);
        wr_en = 0;

        // Now assert wr_en and rd_en together for 3 cycles: write NEW values
        // (200, 201, 202) while simultaneaously reading the OLD values back (100, 101, 102)
        for (i = 0; i < 3; i = i + 1) begin
            @(posedge clk);
            wr_en = 1;
            rd_en = 1;
            data_in = 8'd200 + i; // write 200, 201, 202
            @(posedge clk); // wait for registered data_out to update
            wr_en = 0; // deassert immediately - don't let this leak into the next iterations first edge
            rd_en = 0;
            if (data_out !== (8'd100 + i))
                $display("FAIL: simultaneaous rd/wr - expected %0d, got %0d at time %0t", 8'd100 + i, data_out, $time);
            else
                $display("PASS: simultaneaous rd/wr - correct value %0d read back at time %0t", data_out, $time);
        end 

        // Drain the 3 values written during the simultaneaous phase (200, 201, 202)
        // to confirm they landed correctly and in order
        for (i = 0; i < 3;  i = i + 1) begin
            @(posedge clk);
            rd_en = 1;
            @(posedge clk); // wait for registered data_out to update
            rd_en = 0;
            if (data_out !== (8'd200 + i))
                $display("FAIL: post-simultaneaous drain - expected %0d, got %0d at time %0t", 8'd200 + i, data_out, $time);
            else
                $display("PASS: post-simultaneaous drain - correct value %0d at time %0t", data_out, $time);
        end

        // Let things settle, then finish
        #20;
        $finish;

    end


endmodule