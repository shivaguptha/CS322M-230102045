// File: myComp.v
module myComp(
    input a,
    input b,
    output [1:3] out
);

    assign out[1] = a&(~b);
    assign out[2] = ~(a^b);
    assign out[3] = (~a)&b;

endmodule