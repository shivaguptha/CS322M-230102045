`timescale 1ns/1ps
module tb_link_top;

  reg clk, rst;
  wire done;

  link_top dut(.clk(clk), .rst(rst), .done(done));

  // Clock
  initial clk = 0;
  always #5 clk = ~clk;  // 100MHz

  // Test sequence
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_link_top);

    rst = 1; #20; rst = 0;

    $display("time  clk  req   ack   ack_cnt    data     last_byte   done");
    $monitor("%0t   %b    %b    %b   %b         %02h     %02h        %b",
      $time, clk, dut.master_inst.req, dut.slave_inst.ack,dut.slave_inst.ack_cnt,
      dut.master_inst.data, dut.slave_inst.last_byte, done);

    wait(done==1);
    #10;
    $finish;
  end

endmodule
