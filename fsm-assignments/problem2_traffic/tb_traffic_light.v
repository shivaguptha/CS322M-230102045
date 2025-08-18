`timescale 1ns/1ps

module tb_traffic_light;
  reg clk;
  reg rst;
  reg tick;
  wire ns_g, ns_y, ns_r, ew_g, ew_y, ew_r;

  // DUT
  traffic_light dut(
    .clk(clk), .rst(rst), .tick(tick),
    .ns_g(ns_g), .ns_y(ns_y), .ns_r(ns_r),
    .ew_g(ew_g), .ew_y(ew_y), .ew_r(ew_r)
  );

  // Clock: 20 ns period = 50 MHz
  initial clk = 0;
  always #10 clk = ~clk;

  // Fast tick for simulation: pulse every 20 clk cycles
  integer cyc;
  initial begin
    cyc = 0;
    tick = 0;
  end
  always @(posedge clk) begin
    cyc <= cyc + 1;
    if (cyc % 20 == 0) tick <= 1;
    else tick <= 0;
  end

  // Stimulus
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_traffic_light);

    rst = 1; #40;  // hold reset for 2 clock cycles
    rst = 0;

    #4000;        // run simulation
    $finish;
  end

  // Display state at every tick
  always @(posedge clk) begin
    if (tick) begin
      $display("time=%0t ns_g=%0b ns_y=%0b ns_r=%0b ew_g=%0b ew_y=%0b ew_r=%0b",
               $time, ns_g, ns_y, ns_r, ew_g, ew_y, ew_r);
    end
  end

endmodule
