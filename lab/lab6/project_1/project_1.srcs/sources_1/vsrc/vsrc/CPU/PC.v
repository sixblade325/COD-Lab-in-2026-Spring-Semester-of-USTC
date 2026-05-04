module PC (
    input                   [ 0 : 0]            clk,
    input                   [ 0 : 0]            rst,
    input                   [ 0 : 0]            en,
    input                   [ 0 : 0]            stall,
    input                   [ 0 : 0]            flush,
    input                   [31 : 0]            npc,

    output      reg         [31 : 0]            pc
);

always @(posedge clk) begin
    if(rst)begin
        pc <= 32'h1C000000;
    end else begin
        if(en)begin
            if(flush)begin
                pc <= 32'h1C000000;
            end else if(!stall)
                pc <= npc;
        end
    end
end

endmodule