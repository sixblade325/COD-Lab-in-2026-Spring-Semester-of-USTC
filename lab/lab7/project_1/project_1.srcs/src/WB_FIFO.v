module WB_FIFO #(//In fact, I think this is equal to access cnt % WAY_NUM for every set.
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

reg [WAY_WIDTH - 1 : 0] que [SET_NUM - 1 : 0][WAY_NUM - 1 : 0];

integer i, j;
always @(posedge clk or negedge rstn) begin
    if(!rstn)begin
        for(i=0; i<SET_NUM; i=i+1)
            for(j=0; j<WAY_NUM; j=j+1)
                que[i][j] <= 0;
    end else begin
        if(WB_we)begin
            for(i=0; i<WAY_NUM - 1; i=i+1)
                que[index][i] <= que[index][i+1];
            que[index][WAY_NUM - 1] <= way_using;
        end
    end
end

assign way_select = que[index][0];
always @(*) begin
    way_select_one_hot = 0;
    way_select_one_hot[way_select] = 1'b1;
end

endmodule