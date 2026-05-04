`include "const_var.v"
module SegCtrl(
    input       [ 0 : 0]        rf_we_ex,
    input       [ 1 : 0]        rf_wd_sel_ex,
    input       [ 4 : 0]        rf_wa_ex,
    input       [ 4 : 0]        rf_ra0_id,
    input       [ 4 : 0]        rf_ra1_id,
    input       [ 1 : 0]        npc_sel_ex,

    output reg  [ 0 : 0]        stall_pc,
    output reg  [ 0 : 0]        stall_if_id,
    output reg  [ 0 : 0]        flush_if_id,
    output reg  [ 0 : 0]        flush_id_ex
);//在ex阶段判断Load-Use冒险,插入nop,配合前递单元进行冒险处理

always @(*) begin

    if(npc_sel_ex != `NPC_SEL_ADD4) begin
        stall_pc = 1'b0;
        stall_if_id = 1'b0;
        flush_if_id = 1'b1;
        flush_id_ex = 1'b1;
    end else begin

        if(rf_we_ex && (rf_wd_sel_ex == 2'b10) && ((rf_wa_ex == rf_ra0_id) || (rf_wa_ex == rf_ra1_id)) && rf_wa_ex != 5'd0) begin
            stall_pc = 1'b1;
            stall_if_id = 1'b1;
            flush_if_id = 1'b0;
            flush_id_ex = 1'b1;//这里之前写锅了,应该flush_id_ex = 1'b1,因为要把ex阶段的指令清掉,插入nop
        end else begin
            stall_pc = 1'b0;
            stall_if_id = 1'b0;
            flush_if_id = 1'b0;
            flush_id_ex = 1'b0;
        end

    end
end

endmodule