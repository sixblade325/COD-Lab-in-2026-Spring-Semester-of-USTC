module SEG_REG(
    input       [ 0 : 0]        clk,
    input       [ 0 : 0]        rst,
    input       [ 0 : 0]        en,
    input       [ 0 : 0]        stall,
    input       [ 0 : 0]        flush,
    input       [ 31: 0]        pcadd4,
    input       [ 31: 0]        pc,
    input       [ 31: 0]        inst,
    input       [ 4 : 0]        alu_op,
    input       [ 3 : 0]        dmem_access,
    input       [ 31: 0]        rf_rd0,
    input       [ 31: 0]        rf_rd1,
    input       [ 31: 0]        imm,
    input       [ 4 : 0]        rf_wa,
    input       [ 0 : 0]        rf_we,
    input       [ 1 : 0]        rf_wd_sel,
    input       [ 0 : 0]        alu_src0_sel,
    input       [ 0 : 0]        alu_src1_sel,
    input       [ 3 : 0]        br_type,
    input       [ 31: 0]        alu_res,
    input       [ 31: 0]        dmem_rd_out,
    input       [ 0 : 0]        dmem_we,
    input       [31 : 0]        dmem_addr,
    input       [31 : 0]        dmem_wdata,
    input       [ 0 : 0]        commit,

    output reg  [ 31: 0]        pcadd4_out,
    output reg  [ 31: 0]        pc_out,
    output reg  [ 31: 0]        inst_out,
    output reg  [ 4 : 0]        alu_op_out,
    output reg  [ 3 : 0]        dmem_access_out,
    output reg  [ 31: 0]        rf_rd0_out,
    output reg  [ 31: 0]        rf_rd1_out,
    output reg  [ 31: 0]        imm_out,
    output reg  [ 4 : 0]        rf_wa_out,
    output reg  [ 0 : 0]        rf_we_out,
    output reg  [ 1 : 0]        rf_wd_sel_out,
    output reg  [ 0 : 0]        alu_src0_sel_out,
    output reg  [ 0 : 0]        alu_src1_sel_out,
    output reg  [ 3 : 0]        br_type_out,
    output reg  [ 31: 0]        alu_res_out,
    output reg  [ 31: 0]        dmem_rd_out_out,
    output reg  [ 0 : 0]        dmem_we_out,
    output reg  [31 : 0]        dmem_addr_out,
    output reg  [31 : 0]        dmem_wdata_out,
    output reg  [ 0 : 0]        commit_out
);

always @(posedge clk) begin
    if (rst) begin
        pcadd4_out <= 32'h1C000004;
        pc_out <= 32'h1C000000;
        inst_out <= 32'd0;
        alu_op_out <= 5'd0;
        dmem_access_out <= 4'd0;
        rf_rd0_out <= 32'd0;
        rf_rd1_out <= 32'd0;
        imm_out <= 32'd0;
        rf_wa_out <= 5'd0;
        rf_we_out <= 1'd0;
        rf_wd_sel_out <= 2'd0;
        alu_src0_sel_out <= 1'd0;
        alu_src1_sel_out <= 1'd0;
        br_type_out <= 4'd0;
        alu_res_out <= 32'd0;
        dmem_rd_out_out <= 32'd0;
        commit_out <= 1'd0;
    end else if (en) begin
        if (flush)begin
            pcadd4_out <= 32'h1C000004;
            pc_out <= 32'h1C000000;
            inst_out <= 32'h03400000;//attention
            alu_op_out <= 5'd0;
            dmem_access_out <= 4'd0;
            rf_rd0_out <= 32'd0;
            rf_rd1_out <= 32'd0;
            imm_out <= 32'd0;
            rf_wa_out <= 5'd0;
            rf_we_out <= 1'd0;
            rf_wd_sel_out <= 2'd0;
            alu_src0_sel_out <= 1'd0;
            alu_src1_sel_out <= 1'd0;
            br_type_out <= 4'd0;
            alu_res_out <= 32'd0;
            dmem_rd_out_out <= 32'd0;
            commit_out <= 1'd0;
        end else if (!stall)begin
                pcadd4_out <= pcadd4;
                pc_out <= pc;
                inst_out <= inst;
                alu_op_out <= alu_op;
                dmem_access_out <= dmem_access;
                rf_rd0_out <= rf_rd0;
                rf_rd1_out <= rf_rd1;
                imm_out <= imm;
                rf_wa_out <= rf_wa;
                rf_we_out <= rf_we;
                rf_wd_sel_out <= rf_wd_sel;
                alu_src0_sel_out <= alu_src0_sel;
                alu_src1_sel_out <= alu_src1_sel;
                br_type_out <= br_type;
                alu_res_out <= alu_res;
                dmem_rd_out_out <= dmem_rd_out;
                commit_out <= commit;
            end
    end
end

endmodule
