`timescale 1ns/1ps

module tb_seq_detect_mealy;
    reg clk, rst, din;
    wire y;

    // DUT instantiation
    seq_detect_mealy dut (
        .clk(clk),
        .rst(rst),
        .din(din),
        .y(y)
    );

    // 1) Clock generation: 100 MHz -> 10 ns period
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // toggle every 5ns
    end

    // 2) Drive a bitstream with overlaps: 11011011101
    reg [10:0] bitstream = 11'b11011011101;
    integer i;

    initial begin
        // Dump file for GTKWave
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_seq_detect_mealy);

        // Initialize
        rst = 1;
        din = 0;#5;

        // Apply reset for a couple of cycles
        #15 rst = 0;

        // Send bits MSB -> LSB
        for (i = 10; i >= 0; i = i - 1) begin
            din = bitstream[i];
            #10; // one clock period
        end

        #20 $finish;
    end

    // 3) Log time, din, y
    initial begin
        $display("Time\tclk\trst\tdin\ty");
        $monitor("%0dns\t%b\t%b\t%b\t%b", $time, clk, rst, din, y);
    end

endmodule
