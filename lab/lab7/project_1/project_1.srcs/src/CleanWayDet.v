module CleanWayDec #(
    parameter WAY_NUM = 2,
    parameter WAY_WIDTH = 1
)(
    input   [WAY_NUM - 1 : 0]       dirty,
    output  [0 : 0]                 clean,
    output reg [WAY_NUM - 1 : 0]    clean_way_one_hot,
    output reg [WAY_WIDTH - 1 : 0]  clean_way
);

assign clean = !( & dirty);

integer i;
reg found;

always @(*) begin
    clean_way_one_hot = {WAY_NUM{1'b0}};
    clean_way = 0;
    found = 1'b0;
    for (i = 0; i < WAY_NUM; i = i + 1) begin
        if (!found && !dirty[i]) begin
            clean_way_one_hot[i] = 1'b1;
            clean_way = i;
            found = 1'b1;
        end
    end
end

endmodule
