`include "const_var.v"

module NPCMUX(
    input [31 : 0]          pc_add4,
    input [31 : 0]          pc_offset,
    input [31 : 0]          pc_j,
    input [1 : 0]           npc_sel,
    output reg [31 : 0]     npc
);
    always @(*) begin
        case (npc_sel)
            `NPC_SEL_ADD4:      npc = pc_add4;
            `NPC_SEL_OFFSET:    npc = pc_offset;
            `NPC_SEL_J:         npc = pc_j;
            default:            npc = 32'h0000_0000;
        endcase
    end
endmodule