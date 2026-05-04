module TOP (
    input                   [ 0 : 0]            clk,
    input                   [ 0 : 0]            rst,

    input                   [ 0 : 0]            enable,
    input                   [ 4 : 0]            in,
    input                   [ 1 : 0]            ctrl,

    output                  [ 3 : 0]            seg_data,
    output                  [ 2 : 0]            seg_an
);

reg [31:0] alu_src0, alu_src1, output_data;
reg [4:0] alu_op;
wire [31:0] alu_res, in_extended;

assign in_extended[31:4] = {28{in[4]}};
assign in_extended[3:0] = in[3:0];

ALU alu(alu_src0, alu_src1, alu_op, alu_res);

Segment segment(clk, rst, output_data, seg_data, seg_an);

always @(posedge clk) begin
    if(rst)begin
        alu_src0 <= 0;
        alu_src1 <= 0;
        alu_op <= 0;
        output_data <= 0;
    end else begin
        if(enable)begin
            case(ctrl)
                2'b00: alu_op <= in;
                2'b01: alu_src0 <= in_extended;
                2'b10: alu_src1 <= in_extended;
                2'b11: output_data <= alu_res;
            endcase
        end
    end
end

endmodule