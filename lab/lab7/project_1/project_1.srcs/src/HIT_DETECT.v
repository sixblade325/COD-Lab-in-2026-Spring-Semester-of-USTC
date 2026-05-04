module HIT_DETECT #(
    parameter WAY_NUM = 2,
    parameter WAY_WIDTH = 1,
    parameter TAG_WIDTH = 25
)(
    input  [TAG_WIDTH-1:0]              req_tag,
    input  [WAY_NUM*TAG_WIDTH-1:0]      way_tags,
    input  [WAY_NUM-1:0]                way_valid,
    output                              hit,
    output [WAY_NUM-1:0]                hit_way_one_hot,
    output reg [WAY_WIDTH-1 : 0]        hit_way//这里如果WAY_NUM=1,WAY_WIDTH=0,会有一个严重bug
);

genvar i;
generate
    for(i=0; i<WAY_NUM; i=i+1)begin
        assign hit_way_one_hot[i] = way_valid[i] & (way_tags[i*TAG_WIDTH +: TAG_WIDTH] == req_tag);
    end
endgenerate
assign hit = |hit_way_one_hot;

integer j;
always @(*) begin
    hit_way = 0;
    for(j=0; j<WAY_NUM; j=j+1)
        if(hit_way_one_hot[j])hit_way = j;
end

endmodule