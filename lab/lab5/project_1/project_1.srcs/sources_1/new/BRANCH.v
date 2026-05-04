`include "const_var.v"

module BRANCH(
    input                   [ 3 : 0]            br_type,

    input                   [31 : 0]            br_src0,
    input                   [31 : 0]            br_src1,

    output      reg         [ 1 : 0]            npc_sel
);

wire [0:0] slt_res, sltu_res;

SLT slt(br_src0, br_src1, slt_res);
SLTU sltu(br_src0, br_src1, sltu_res);

always @(*) begin
    case (br_type)
        `BR_JIRL:   npc_sel = `NPC_SEL_J;
        `BR_B   :   npc_sel = `NPC_SEL_OFFSET;
        `BR_BL  :   npc_sel = `NPC_SEL_OFFSET;
        `BR_BEQ :   npc_sel = (br_src0 == br_src1 ? `NPC_SEL_OFFSET : `NPC_SEL_ADD4);
        `BR_BNE :   npc_sel = (br_src0 != br_src1 ? `NPC_SEL_OFFSET : `NPC_SEL_ADD4);
        `BR_BLT :   npc_sel = (slt_res ? `NPC_SEL_OFFSET : `NPC_SEL_ADD4); 
        `BR_BGE :   npc_sel = (slt_res ? `NPC_SEL_ADD4 : `NPC_SEL_OFFSET); 
        `BR_BLTU:   npc_sel = (sltu_res ? `NPC_SEL_OFFSET : `NPC_SEL_ADD4); 
        `BR_BGEU:   npc_sel = (sltu_res ? `NPC_SEL_ADD4 : `NPC_SEL_OFFSET);
        default :   npc_sel = `NPC_SEL_ADD4;
        //if we input 0000, that means this isn't an BR instruction.
    endcase
end

endmodule