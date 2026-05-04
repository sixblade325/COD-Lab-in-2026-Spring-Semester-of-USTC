module SLT(
    input [31:0] a, b,
    output lt
);

wire[31:0] outs = a - b;

wire ovfs = ( ~( a[31] ^ (~b[31]) ) ) & ( (~b[31]) ^ outs[31]); 
assign lt = ( a[31] & (~b[31]) ) | ( (~ovfs) & outs[31] );
endmodule