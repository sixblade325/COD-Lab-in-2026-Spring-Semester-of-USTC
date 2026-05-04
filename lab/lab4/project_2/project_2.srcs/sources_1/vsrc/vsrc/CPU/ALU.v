`include "const_var.v"

module ALU (
    input           signed  [31 : 0]            alu_src0,
    input           signed  [31 : 0]            alu_src1,
    input                   [ 4 : 0]            alu_op,

    output      reg         [31 : 0]            alu_res
);

wire slt_res, sltu_res;

SLT slt(alu_src0, alu_src1, slt_res);
SLTU sltu(alu_src0, alu_src1, sltu_res);

    always @(*) begin
        case(alu_op)
            `ALU_ADD  :
                alu_res = alu_src0 + alu_src1;
            `ALU_SUB  :
                alu_res = alu_src0 - alu_src1;
            `ALU_SLT  :
                alu_res = {{31{1'b0}}, slt_res};
            `ALU_SLTU :
                alu_res = {{31{1'b0}}, sltu_res};
            `ALU_AND  :
                alu_res = alu_src0 & alu_src1;
            `ALU_OR   :
                alu_res = alu_src0 | alu_src1;
            `ALU_XOR  :
                alu_res = alu_src0 ^ alu_src1;
            `ALU_SLL  :
                alu_res = alu_src0 << alu_src1[4:0];
            `ALU_SRL  :
                alu_res = alu_src0 >> alu_src1[4:0];
            `ALU_SRA  :
                alu_res = alu_src0 >>> alu_src1[4:0];
            `ALU_SRC0 :
                alu_res = alu_src0;
            `ALU_SRC1 :
                alu_res = alu_src1;
            default :
                alu_res = 32'H0;
        endcase
    end
endmodule