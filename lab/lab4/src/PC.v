module PC (
    input                   [ 0 : 0]            clk,
    input                   [ 0 : 0]            rst,
    input                   [ 0 : 0]            en,
    input                   [31 : 0]            npc,

    output      reg         [31 : 0]            pc
);

always @(posedge clk) begin
    if(rst)begin
        pc <= 32'h1C000000;
    end else begin
        if(en)
            pc <= npc;
    end
end

endmodule