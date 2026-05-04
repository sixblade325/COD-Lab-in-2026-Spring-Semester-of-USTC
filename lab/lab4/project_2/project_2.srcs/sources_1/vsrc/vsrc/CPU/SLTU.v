module SLTU(
    input [31:0] a, b,
    output ltu
);

wire lt;
SLT slt(
    .a({1'b0,a[30:0]}),
    .b({1'b0,b[30:0]}), 
    .lt(lt)
);

assign ltu = (a[31] ^ b[31]) ? ~a[31] : lt;

endmodule