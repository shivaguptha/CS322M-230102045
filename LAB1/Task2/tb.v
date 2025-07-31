`timescale 1ns / 1ps

module myEqualComp_tb;
    reg [3:0] a;
    reg [3:0] b;

    wire out;

    myEqualComp dut (
        .A(a),
        .B(b),
        .Equal(out)
    );

    initial begin
        $dumpfile("myEqualComp.vcd");   
        $dumpvars(0, myEqualComp_tb);    
   
       
        $display("---------------------------");
        
        a = 4'b1001; b = 4'b0011; #10 $display("A=%b , B=%b , Equal=%b", a, b, out);
        a = 4'b1001; b = 4'b1001; #10 $display("A=%b , B=%b , Equal=%b", a, b, out);
        a = 4'b1101; b = 4'b1011; #10 $display("A=%b , B=%b , Equal=%b", a, b, out);
        a = 4'b1111; b = 4'b1111; #10 $display("A=%b , B=%b , Equal=%b", a, b, out);
        a = 4'b0011; b = 4'b0011; #10 $display("A=%b , B=%b , Equal=%b", a, b, out);
        a = 4'b1011; b = 4'b1011; #10 $display("A=%b , B=%b , Equal=%b", a, b, out);

        $finish;
    end
endmodule
