`timescale 1ns / 1ps

module myComp_tb;
    reg a;
    reg b;

    wire [1:3] out;

    myComp dut (
        .a(a),
        .b(b),
        .out(out)
    );

    initial begin
        $dumpfile("myComp.vcd");   
        $dumpvars(0, myComp_tb);    
   
        $display("a b | out[1] out[2] out[3]");
        $display("---------------------------");
        
        a = 0; b = 0; #10 $display("%b %b |   %b      %b      %b", a, b, out[1], out[2], out[3]);
        a = 0; b = 1; #10 $display("%b %b |   %b      %b      %b", a, b, out[1], out[2], out[3]);
        a = 1; b = 0; #10 $display("%b %b |   %b      %b      %b", a, b, out[1], out[2], out[3]);
        a = 1; b = 1; #10 $display("%b %b |   %b      %b      %b", a, b, out[1], out[2], out[3]);

        $finish;
    end
endmodule
