module WB_PLRU #(
    parameter INDEX_WIDTH   = 3,
    parameter SET_NUM     = 8,
    parameter WAY_NUM       = 2,
    parameter WAY_WIDTH     = 1
)(
    input  [0 : 0]                  clk, rstn,
    input  [0 : 0]                  WB_we,
    input  [WAY_WIDTH - 1 : 0]      way_using,
    input  [INDEX_WIDTH - 1 : 0]    index,
    output [WAY_WIDTH - 1 : 0]      way_select,//这里如果WAY_NUM=1,WAY_WIDTH=0,会有一个严重bug
    output reg [WAY_NUM - 1 : 0]    way_select_one_hot
);

reg  [WAY_NUM - 1: 0] year [SET_NUM - 1: 0];
wire [WAY_WIDTH - 1 : 0] way_select_prev [WAY_WIDTH - 1 : 0];

integer i;
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        for (i = 0; i < SET_NUM; i = i + 1) begin
            year[i] <= 0;
        end
    end else if (WB_we) begin
        for(i = 0; i < WAY_WIDTH; i = i + 1) begin
            year[index][(1<<(WAY_WIDTH - 1 - i)) | (way_using >> (i + 1) )] <= !way_using[i] ;
        end
    end
end

assign way_select_prev[0] = 2 + year[index][1];
genvar j;
generate
    for(j = 1; j < WAY_WIDTH; j = j + 1)begin
        assign way_select_prev[j] = (way_select_prev[j - 1] << 1) | year[index][way_select_prev[j-1]];
    end
endgenerate

assign way_select = WAY_NUM == 1 ? 0 : way_select_prev[WAY_WIDTH - 1];
always @(*) begin
    way_select_one_hot = 0;
    way_select_one_hot[way_select] = 1'b1;
end

endmodule