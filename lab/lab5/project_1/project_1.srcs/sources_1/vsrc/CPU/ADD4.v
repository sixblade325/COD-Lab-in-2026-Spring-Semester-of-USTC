module ADD4(
    input                   [31 : 0]        pc,
    output                  [31 : 0]        pcadd4
);
assign pcadd4 = pc + 4;
endmodule