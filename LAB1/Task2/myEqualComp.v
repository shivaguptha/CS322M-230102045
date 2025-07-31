module myEqualComp(
    input [3:0] A,
    input [3:0] B,
    output Equal
);

assign Equal = (A == B) ? 1'b1 : 1'b0;
    
endmodule