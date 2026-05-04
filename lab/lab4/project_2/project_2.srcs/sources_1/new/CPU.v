`define HALT_INST               32'h80000000
`include "const_var.v"

module CPU (
    input                   [ 0 : 0]            clk,
    input                   [ 0 : 0]            rst,

    input                   [ 0 : 0]            global_en,

/* ------------------------------ Memory (inst) ----------------------------- */
    output                  [31 : 0]            imem_raddr,
    input                   [31 : 0]            imem_rdata,

/* ------------------------------ Memory (data) ----------------------------- */
    input                   [31 : 0]            dmem_rdata,
    output                  [ 0 : 0]            dmem_we,
    output                  [31 : 0]            dmem_addr,
    output                  [31 : 0]            dmem_wdata,

/* ---------------------------------- Debug --------------------------------- */
    output                  [ 0 : 0]            commit,
    output                  [31 : 0]            commit_pc,
    output                  [31 : 0]            commit_instr,
    output                  [ 0 : 0]            commit_halt,
    output                  [ 0 : 0]            commit_reg_we,
    output                  [ 4 : 0]            commit_reg_wa,
    output                  [31 : 0]            commit_reg_wd,
    output                  [ 0 : 0]            commit_dmem_we,
    output                  [31 : 0]            commit_dmem_wa,
    output                  [31 : 0]            commit_dmem_wd,

    input                   [ 4 : 0]            debug_reg_ra,
    output                  [31 : 0]            debug_reg_rd
);

wire [31 : 0]   cur_pc, cur_npc, pc_add4;
wire [1:0]      npc_sel;

assign          imem_raddr = cur_pc;
wire [31 : 0]   cur_inst = imem_rdata;
assign          dmem_we = (cur_inst[31 : 26] == 6'b001010 && (cur_inst[25 : 22] ==  `SD_STB|| cur_inst[25 : 22] ==`SD_STH|| cur_inst[25 : 22] == `SD_STW) );

wire    [ 4 : 0]            alu_op;
wire    [31 : 0]            imm;
wire    [31 : 0]            alu_res;
wire    [ 4 : 0]            rf_ra0;
wire    [ 4 : 0]            rf_ra1;
wire    [ 4 : 0]            rf_wa;
wire    [ 0 : 0]            rf_we;
wire    [ 0 : 0]            alu_src0_sel;
wire    [ 0 : 0]            alu_src1_sel;
wire    [ 3 : 0]            dmem_access, br_type;
wire    [ 1 : 0]            rf_wd_sel;

NPCMUX npc_mux(
    .pc_add4(pc_add4),
    .pc_offset(alu_res),
    .pc_j(alu_res),
    .npc_sel(npc_sel),
    .npc(cur_npc)
);

PC my_pc(
    .clk    (clk        ),
    .rst    (rst        ),
    .en     (global_en  ),
    .npc    (cur_npc    ),
    .pc     (cur_pc     )
);

ADD4 my_add4(
    .pc     (cur_pc     ),
    .npc    (pc_add4    )
);

DECODE my_decoder(
    .inst       (cur_inst   ),
    .alu_op     (alu_op     ),
    .dmem_access(dmem_access),
    .imm        (imm        ),
    .rf_ra0     (rf_ra0     ),
    .rf_ra1     (rf_ra1     ),
    .rf_wa      (rf_wa      ),
    .rf_we      (rf_we      ),
    .rf_wd_sel  (rf_wd_sel  ),
    .alu_src0_sel(alu_src0_sel),
    .alu_src1_sel(alu_src1_sel),
    .br_type    (br_type    )
);

wire    [31 : 0]            rf_wd;
wire    [31 : 0]            rf_rd0;
wire    [31 : 0]            rf_rd1;
wire    [31 : 0]            dbg_reg_rd;

wire    [31 : 0]   dmem_wd_in = rf_rd1;
wire    [31 : 0]   dmem_wd_out;
wire    [31 : 0]   dmem_rd_in = dmem_rdata;
wire    [31 : 0]   dmem_rd_out;

MUX2 reg_mux(
    .src0(pc_add4),
    .src1(alu_res),
    .src2(dmem_rd_out),
    .src3(32'h00000000),
    .sel(rf_wd_sel),
    .res(rf_wd)
);

REG_FILE globel_reg(
    .clk         (clk        ),
    .rf_ra0      (rf_ra0     ),
    .rf_ra1      (rf_ra1     ),   
    .rf_wa       (rf_wa      ),
    .rf_we       (rf_we      ),
    .rf_wd       (rf_wd      ),
    .dbg_reg_ra  (debug_reg_ra),
    .rf_rd0      (rf_rd0     ),
    .rf_rd1      (rf_rd1     ),
    .dbg_reg_rd  (dbg_reg_rd )
);
assign      debug_reg_rd = dbg_reg_rd;

BRANCH branch(
    .br_type(br_type),
    .br_src0(rf_rd0),
    .br_src1(rf_rd1),
    .npc_sel(npc_sel)
);

wire    [31 : 0]            alu_src0, alu_src1;

MUX1 mux0(
    .src0       (rf_rd0     ),
    .src1       (cur_pc     ),
    .sel        (alu_src0_sel),
    .res        (alu_src0   )
);

MUX1 mux1(
    .src0       (rf_rd1     ),
    .src1       (imm        ),
    .sel        (alu_src1_sel),
    .res        (alu_src1   )
);

ALU my_alu(
    .alu_src0   (alu_src0   ),
    .alu_src1   (alu_src1   ),
    .alu_op     (alu_op     ),
    .alu_res    (alu_res    )
);
assign dmem_addr = alu_res;
SLU slu(
    .addr(alu_res),
    .dmem_access(dmem_access),
    .rd_in(dmem_rd_in),
    .rd_out(dmem_rd_out),
    .wd_in(dmem_wd_in),
    .wd_out(dmem_wd_out)
);
assign      dmem_wdata = dmem_wd_out;

reg  [ 0 : 0]   commit_reg          ;
reg  [31 : 0]   commit_pc_reg       ;
reg  [31 : 0]   commit_instr_reg    ;
reg  [ 0 : 0]   commit_halt_reg     ;
reg  [ 0 : 0]   commit_reg_we_reg   ;
reg  [ 4 : 0]   commit_reg_wa_reg   ;
reg  [31 : 0]   commit_reg_wd_reg   ;
reg  [ 0 : 0]   commit_dmem_we_reg  ;
reg  [31 : 0]   commit_dmem_wa_reg  ;
reg  [31 : 0]   commit_dmem_wd_reg  ;

always @(posedge clk) begin
    if (rst) begin
        commit_reg          <= 1'H0;
        commit_pc_reg       <= 32'H0;
        commit_instr_reg    <= 32'H0;
        commit_halt_reg     <= 1'H0;
        commit_reg_we_reg   <= 1'H0;
        commit_reg_wa_reg   <= 5'H0;
        commit_reg_wd_reg   <= 32'H0;
        commit_dmem_we_reg  <= 1'H0;
        commit_dmem_wa_reg  <= 32'H0;
        commit_dmem_wd_reg  <= 32'H0;
    end
    else if (global_en) begin
        // !!!! 请注意根据自己的具体实现替换 <= 右侧的信号 !!!!
        commit_reg          <= 1'H1;                        // 不需要改动
        commit_pc_reg       <= cur_pc;                      // 需要为当前的 PC
        commit_instr_reg    <= cur_inst;                    // 需要为当前的指令
        commit_halt_reg     <= cur_inst == `HALT_INST;      // 注意！请根据指令集设置 HALT_INST！
        commit_reg_we_reg   <= rf_we;                       // 需要为当前的寄存器堆写使能
        commit_reg_wa_reg   <= rf_wa;                       // 需要为当前的寄存器堆写地址
        commit_reg_wd_reg   <= rf_wd;                       // 需要为当前的寄存器堆写数据
        commit_dmem_we_reg  <= dmem_we;                         
        commit_dmem_wa_reg  <= dmem_addr;                         
        commit_dmem_wd_reg  <= dmem_wdata;
    end
end

assign commit               = commit_reg;
assign commit_pc            = commit_pc_reg;
assign commit_instr         = commit_instr_reg;
assign commit_halt          = commit_halt_reg;
assign commit_reg_we        = commit_reg_we_reg;
assign commit_reg_wa        = commit_reg_wa_reg;
assign commit_reg_wd        = commit_reg_wd_reg;
assign commit_dmem_we       = commit_dmem_we_reg;
assign commit_dmem_wa       = commit_dmem_wa_reg;
assign commit_dmem_wd       = commit_dmem_wd_reg;

// ......
endmodule