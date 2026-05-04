module LineMux #(
    parameter WAY_NUM = 2,
    parameter WAY_WIDTH = 1,
    parameter LINE_WIDTH = 128
)(
    input  [LINE_WIDTH * WAY_NUM - 1 : 0]  src,
    input  [WAY_NUM - 1 : 0]  way_one_hot,
    output reg [LINE_WIDTH - 1 : 0] res
);

integer i;
always @(*)begin
    res = 0;
    for(i = 0; i < WAY_NUM; i =i + 1)
        res = res | ({LINE_WIDTH{way_one_hot[i]}} & src[i*LINE_WIDTH +: LINE_WIDTH]);
end
endmodule