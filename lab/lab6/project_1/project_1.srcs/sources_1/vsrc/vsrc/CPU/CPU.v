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

wire   [ 0 : 0]            stall_pc;
wire   [31 : 0]            pc_if;
wire   [31 : 0]            pcadd4_if;
wire   [ 0 : 0]            flush_if_id;
wire   [ 0 : 0]            stall_if_id;

wire   [ 0 : 0]            flush_id_ex;
wire   [31 : 0]            pcadd4_id;
wire   [31 : 0]            pc_id;
wire   [31 : 0]            inst_id;
wire   [ 4 : 0]            alu_op_id;
wire   [ 3 : 0]            dmem_access_id;
wire   [ 4 : 0]            rf_ra0_id;
wire   [ 4 : 0]            rf_ra1_id;
wire   [31 : 0]            rf_rd0_id;
wire   [31 : 0]            rf_rd1_id;
wire   [31 : 0]            imm_id;
wire   [ 4 : 0]            rf_wa_id;
wire   [ 0 : 0]            rf_we_id;
wire   [ 1 : 0]            rf_wd_sel_id;
wire   [ 0 : 0]            alu_src0_sel_id;
wire   [ 0 : 0]            alu_src1_sel_id;
wire   [ 3 : 0]            br_type_id;
wire   [ 0 : 0]            commit_id;

wire   [31 : 0]            pcadd4_ex;
wire   [31 : 0]            pc_ex;
wire   [31 : 0]            npc_ex;
wire   [31 : 0]            inst_ex;
wire   [31 : 0]            rf_rd0_raw_ex;
wire   [31 : 0]            rf_rd1_raw_ex;
wire   [ 4 : 0]            rf_ra0_ex;
wire   [ 4 : 0]            rf_ra1_ex;
wire   [31 : 0]            rf_rd0_ex;
wire   [31 : 0]            rf_rd1_ex;
wire   [ 0: 0 ]            rf_rd0_fe;
wire   [ 0: 0 ]            rf_rd1_fe;
wire   [31 : 0]            rf_rd0_fd;
wire   [31 : 0]            rf_rd1_fd;
wire   [31 : 0]            imm_ex;
wire   [ 4 : 0]            rf_wa_ex;
wire   [ 0 : 0]            rf_we_ex;
wire   [ 1 : 0]            rf_wd_sel_ex;
wire   [ 0 : 0]            alu_src0_sel_ex;
wire   [ 0 : 0]            alu_src1_sel_ex;
wire   [31 : 0]            alu_src0_ex;
wire   [31 : 0]            alu_src1_ex;
wire   [ 3 : 0]            br_type_ex;
wire   [ 4 : 0]            alu_op_ex;
wire   [ 3 : 0]            dmem_access_ex;
wire   [ 1 : 0]            npc_sel_ex;
wire   [31 : 0]            alu_res_ex;
wire   [ 0 : 0]            commit_ex;

wire   [31 : 0]            pcadd4_mem;
wire   [31 : 0]            pc_mem;
wire   [31 : 0]            alu_res_mem;
wire   [31 : 0]            inst_mem;
wire   [31 : 0]            rf_rd1_mem;
wire   [ 4 : 0]            rf_wa_mem;
wire   [ 0 : 0]            rf_we_mem;
wire   [ 1 : 0]            rf_wd_sel_mem;
wire   [ 3 : 0]            dmem_access_mem;
wire   [31 : 0]            dmem_rd_out_mem;
wire   [ 0 : 0]            dmem_we_mem;
wire   [31 : 0]            dmem_addr_mem;
wire   [31 : 0]            dmem_wdata_mem;
wire   [ 0 : 0]            commit_mem;

wire   [31 : 0]            pcadd4_wb;
wire   [31 : 0]            pc_wb;
wire   [31 : 0]            alu_res_wb;
wire   [31 : 0]            inst_wb;
wire   [ 1 : 0]            rf_wd_sel_wb;
wire   [ 4 : 0]            rf_wa_wb;
wire   [ 0 : 0]            rf_we_wb;
wire   [31 : 0]            rf_wd_wb;
wire   [31 : 0]            dmem_rd_out_wb;
wire   [ 0 : 0]            dmem_we_wb;
wire   [31 : 0]            dmem_addr_wb;
wire   [31 : 0]            dmem_wdata_wb;
wire   [ 0 : 0]            commit_wb;

//part1:IF
PC pc(
    .clk(clk),
    .rst(rst),
    .en(global_en),
    .stall(stall_pc),
    .flush(1'b0),
    .npc(npc_ex),
    .pc(pc_if)
);
assign imem_raddr = pc_if;

ADD4 add4(
    .pc(pc_if),
    .pcadd4(pcadd4_if)
);

wire [4 : 0] alu_op_id_useless;
wire [3 : 0] dmem_access_id_useless;
wire [4 : 0] rf_ra0_id_useless;
wire [4 : 0] rf_ra1_id_useless;
wire [31 : 0] rf_rd0_id_useless;
wire [31 : 0] rf_rd1_id_useless;
wire [31 : 0] imm_id_useless;
wire [4 : 0] rf_wa_id_useless;
wire [0 : 0] rf_we_id_useless;
wire [1 : 0] rf_wd_sel_id_useless;
wire [0 : 0] alu_src0_sel_id_useless;
wire [0 : 0] alu_src1_sel_id_useless;
wire [3 : 0] br_type_id_useless;
wire [31 : 0] alu_res_id_useless;
wire [31 : 0] dmem_rd_out_id_useless;
wire [0 : 0] dmem_we_id_useless;
wire [31 : 0] dmem_addr_id_useless;
wire [31 : 0] dmem_wdata_id_useless;

SEG_REG IF_ID(
    .clk(clk),
    .rst(rst),
    .en(global_en),
    .stall(stall_if_id),//attention
    .flush(flush_if_id),//attention
    .pcadd4(pcadd4_if),
    .pc(pc_if),
    .inst(imem_rdata),
    .alu_op(5'd0),
    .dmem_access(4'd0),
    .rf_ra0(5'd0),
    .rf_ra1(5'd0),
    .rf_rd0(32'd0),
    .rf_rd1(32'd0),
    .imm(32'd0),
    .rf_wa(5'd0),
    .rf_we(1'd0),
    .rf_wd_sel(2'd0),
    .alu_src0_sel(1'd0),
    .alu_src1_sel(1'd0),
    .br_type(4'd0),
    .alu_res(32'd0),
    .dmem_rd_out(32'd0),
    .dmem_we(1'd0),
    .dmem_addr(32'd0),
    .dmem_wdata(32'd0),
    .commit(1'b1),//attention

    .pcadd4_out(pcadd4_id),
    .pc_out(pc_id),
    .inst_out(inst_id),
    .commit_out(commit_id),

    .alu_op_out(alu_op_id_useless),
    .dmem_access_out(dmem_access_id_useless),
    .rf_ra0_out(rf_ra0_id_useless),
    .rf_ra1_out(rf_ra1_id_useless),
    .rf_rd0_out(rf_rd0_id_useless),
    .rf_rd1_out(rf_rd1_id_useless),
    .imm_out(imm_id_useless),
    .rf_wa_out(rf_wa_id_useless),
    .rf_we_out(rf_we_id_useless),
    .rf_wd_sel_out(rf_wd_sel_id_useless),
    .alu_src0_sel_out(alu_src0_sel_id_useless),
    .alu_src1_sel_out(alu_src1_sel_id_useless),
    .br_type_out(br_type_id_useless),
    .alu_res_out(alu_res_id_useless),
    .dmem_rd_out_out(dmem_rd_out_id_useless),
    .dmem_we_out(dmem_we_id_useless),
    .dmem_addr_out(dmem_addr_id_useless),
    .dmem_wdata_out(dmem_wdata_id_useless)
);

//part2:ID
DECODE decode(
    .inst(inst_id),
    .alu_op(alu_op_id),
    .dmem_access(dmem_access_id),
    .imm(imm_id),
    .rf_ra0(rf_ra0_id),
    .rf_ra1(rf_ra1_id),
    .rf_wa(rf_wa_id),
    .rf_we(rf_we_id),
    .rf_wd_sel(rf_wd_sel_id),
    .alu_src0_sel(alu_src0_sel_id),
    .alu_src1_sel(alu_src1_sel_id),
    .br_type(br_type_id)
);

REG_FILE reg_file(
    .clk(clk),
    .rf_ra0(rf_ra0_id),
    .rf_ra1(rf_ra1_id),
    .rf_wa(rf_wa_wb),
    .rf_we(rf_we_wb),
    .rf_wd(rf_wd_wb),
    .dbg_reg_ra(debug_reg_ra),
    .rf_rd0(rf_rd0_id),
    .rf_rd1(rf_rd1_id),
    .dbg_reg_rd(debug_reg_rd)
);

wire [31 : 0] alu_res_ex_useless;
wire [31 : 0] dmem_rd_out_ex_useless;
wire [0 : 0] dmem_we_ex_useless;
wire [31 : 0] dmem_addr_ex_useless;
wire [31 : 0] dmem_wdata_ex_useless;

SEG_REG ID_EX(
    .clk(clk),
    .rst(rst),
    .en(global_en),
    .stall(1'b0),//attention
    .flush(flush_id_ex),//attention
    .pcadd4(pcadd4_id),
    .pc(pc_id),
    .inst(inst_id),
    .alu_op(alu_op_id),
    .dmem_access(dmem_access_id),
    .rf_ra0(rf_ra0_id),
    .rf_ra1(rf_ra1_id),
    .rf_rd0(rf_rd0_id),
    .rf_rd1(rf_rd1_id),
    .imm(imm_id),
    .rf_wa(rf_wa_id),
    .rf_we(rf_we_id),
    .rf_wd_sel(rf_wd_sel_id),
    .alu_src0_sel(alu_src0_sel_id),
    .alu_src1_sel(alu_src1_sel_id),
    .br_type(br_type_id),
    .alu_res(32'd0),
    .dmem_rd_out(32'd0),
    .dmem_we(1'd0),
    .dmem_addr(32'd0),
    .dmem_wdata(32'd0),
    .commit(commit_id),

    .pcadd4_out(pcadd4_ex),
    .pc_out(pc_ex),
    .inst_out(inst_ex),
    .alu_op_out(alu_op_ex),
    .dmem_access_out(dmem_access_ex),
    .rf_ra0_out(rf_ra0_ex),
    .rf_ra1_out(rf_ra1_ex),
    .rf_rd0_out(rf_rd0_raw_ex),
    .rf_rd1_out(rf_rd1_raw_ex),
    .imm_out(imm_ex),
    .rf_wa_out(rf_wa_ex),
    .rf_we_out(rf_we_ex),
    .rf_wd_sel_out(rf_wd_sel_ex),
    .alu_src0_sel_out(alu_src0_sel_ex),
    .alu_src1_sel_out(alu_src1_sel_ex),
    .br_type_out(br_type_ex),
    .commit_out(commit_ex),

    .alu_res_out(alu_res_ex_useless),
    .dmem_rd_out_out(dmem_rd_out_ex_useless),
    .dmem_we_out(dmem_we_ex_useless),
    .dmem_addr_out(dmem_addr_ex_useless),
    .dmem_wdata_out(dmem_wdata_ex_useless)
);

//part3:EX
MUX1 rdmux0(rf_rd0_raw_ex, rf_rd0_fd, rf_rd0_fe, rf_rd0_ex);
MUX1 rdmux1(rf_rd1_raw_ex, rf_rd1_fd, rf_rd1_fe, rf_rd1_ex);
MUX1 mux1(rf_rd0_ex, pc_ex, alu_src0_sel_ex, alu_src0_ex);
MUX1 mux2(rf_rd1_ex, imm_ex, alu_src1_sel_ex, alu_src1_ex);


ALU alu(
    .alu_src0(alu_src0_ex),
    .alu_src1(alu_src1_ex),
    .alu_op(alu_op_ex),
    .alu_res(alu_res_ex)
);

BRANCH branch(
    .br_type(br_type_ex),
    .br_src0(rf_rd0_ex),
    .br_src1(rf_rd1_ex),
    .npc_sel(npc_sel_ex)
);

SegCtrl segctrl(
    .rf_we_ex(rf_we_ex),
    .rf_wd_sel_ex(rf_wd_sel_ex),
    .rf_wa_ex(rf_wa_ex),
    .rf_ra0_id(rf_ra0_id),
    .rf_ra1_id(rf_ra1_id),
    .npc_sel_ex(npc_sel_ex),

    .stall_pc(stall_pc),
    .stall_if_id(stall_if_id),
    .flush_if_id(flush_if_id),
    .flush_id_ex(flush_id_ex)
);

NPCMUX npc_mux(
    .pc_add4(pcadd4_if),
    .pc_offset(alu_res_ex),
    .pc_j(alu_res_ex & (~1)),
    .npc_sel(npc_sel_ex),
    .npc(npc_ex)
);

wire [4 : 0]        rf_ra0_mem_useless;
wire [4 : 0]        rf_ra1_mem_useless;
wire [4 : 0]        alu_op_mem_useless;
wire [31 : 0]       rf_rd0_mem_useless;
wire [31 : 0]       imm_mem_useless;
wire [0 : 0]        alu_src0_sel_mem_useless;
wire [0 : 0]        alu_src1_sel_mem_useless;
wire [3 : 0]        br_type_mem_useless;
wire [31 : 0]       dmem_rd_out_mem_useless;
wire [0 : 0]        dmem_we_mem_useless;
wire [31 : 0]       dmem_addr_mem_useless;
wire [31 : 0]       dmem_wdata_mem_useless;


SEG_REG EX_MEM(
    .clk(clk),
    .rst(rst),
    .en(global_en),
    .stall(1'b0),//attention
    .flush(1'b0),//attention
    .pcadd4(pcadd4_ex),
    .pc(pc_ex),
    .inst(inst_ex),
    .alu_op(5'd0),
    .dmem_access(dmem_access_ex),
    .rf_ra0(5'd0),
    .rf_ra1(5'd0),
    .rf_rd0(32'd0),
    .rf_rd1(rf_rd1_ex),
    .imm(32'd0),
    .rf_wa(rf_wa_ex),
    .rf_we(rf_we_ex),
    .rf_wd_sel(rf_wd_sel_ex),
    .alu_src0_sel(1'b0),
    .alu_src1_sel(1'b0),
    .br_type(4'd0),
    .alu_res(alu_res_ex),
    .dmem_rd_out(32'd0),
    .dmem_we(1'd0),
    .dmem_addr(32'd0),
    .dmem_wdata(32'd0),
    .commit(commit_ex),

    .pcadd4_out(pcadd4_mem),
    .pc_out(pc_mem),
    .alu_res_out(alu_res_mem),
    .inst_out(inst_mem),
    .rf_rd1_out(rf_rd1_mem),
    .rf_wa_out(rf_wa_mem),
    .rf_we_out(rf_we_mem),
    .rf_wd_sel_out(rf_wd_sel_mem),
    .dmem_access_out(dmem_access_mem),
    .commit_out(commit_mem),

    .alu_op_out(alu_op_mem_useless),
    .rf_ra0_out(rf_ra0_mem_useless),
    .rf_ra1_out(rf_ra1_mem_useless),
    .rf_rd0_out(rf_rd0_mem_useless),
    .imm_out(imm_mem_useless),
    .alu_src0_sel_out(alu_src0_sel_mem_useless),
    .alu_src1_sel_out(alu_src1_sel_mem_useless),
    .br_type_out(br_type_mem_useless),
    .dmem_rd_out_out(dmem_rd_out_mem_useless),
    .dmem_we_out(dmem_we_mem_useless),
    .dmem_addr_out(dmem_addr_mem_useless),
    .dmem_wdata_out(dmem_wdata_mem_useless)
);

//part4:MEM
SLU slu(
    .addr(alu_res_mem),
    .dmem_access(dmem_access_mem),
    .rd_in(dmem_rdata),
    .wd_in(rf_rd1_mem),
    .rd_out(dmem_rd_out_mem),
    .wd_out(dmem_wdata_mem)
);

assign          dmem_addr_mem = alu_res_mem;
assign          dmem_we_mem = (inst_mem[31 : 26] == 6'b001010 && (inst_mem[25 : 22] ==  `SD_STB|| inst_mem[25 : 22] ==`SD_STH|| inst_mem[25 : 22] == `SD_STW) );

assign          dmem_addr = dmem_addr_mem;
assign          dmem_wdata = dmem_wdata_mem;
assign          dmem_we = dmem_we_mem;

wire     [ 4: 0]    alu_op_wb_useless;
wire     [ 3: 0]    dmem_access_wb_useless;
wire     [ 4: 0]    rf_ra0_wb_useless;
wire     [ 4: 0]    rf_ra1_wb_useless;
wire     [31: 0]    rf_rd0_wb_useless;
wire     [31: 0]    rf_rd1_wb_useless;
wire     [31: 0]    imm_wb_useless;
wire     [ 0: 0]    alu_src0_sel_wb_useless;
wire     [ 0: 0]    alu_src1_sel_wb_useless;
wire     [ 3: 0]    br_type_wb_useless;

SEG_REG MEM_WB(
    .clk(clk),
    .rst(rst),
    .en(global_en),
    .stall(1'b0),//attention
    .flush(1'b0),//attention
    .pcadd4(pcadd4_mem),
    .pc(pc_mem),
    .inst(inst_mem),
    .alu_op(5'd0),
    .dmem_access(4'd0),
    .rf_ra0(5'd0),
    .rf_ra1(5'd0),
    .rf_rd0(32'd0),
    .rf_rd1(32'd0),
    .imm(32'd0),
    .rf_wa(rf_wa_mem),
    .rf_we(rf_we_mem),
    .rf_wd_sel(rf_wd_sel_mem),
    .alu_src0_sel(1'b0),
    .alu_src1_sel(1'b0),
    .br_type(4'd0),
    .alu_res(alu_res_mem),
    .dmem_rd_out(dmem_rd_out_mem),
    .dmem_we(dmem_we_mem),
    .dmem_addr(dmem_addr_mem),
    .dmem_wdata(dmem_wdata_mem),
    .commit(commit_mem),

    .pcadd4_out(pcadd4_wb),
    .pc_out(pc_wb),
    .inst_out(inst_wb),
    .alu_res_out(alu_res_wb),
    .rf_wa_out(rf_wa_wb),
    .rf_we_out(rf_we_wb),
    .rf_wd_sel_out(rf_wd_sel_wb),
    .dmem_rd_out_out(dmem_rd_out_wb),
    .dmem_we_out(dmem_we_wb),
    .dmem_addr_out(dmem_addr_wb),
    .dmem_wdata_out(dmem_wdata_wb),
    .commit_out(commit_wb),

    .alu_op_out(alu_op_wb_useless),
    .dmem_access_out(dmem_access_wb_useless),
    .rf_ra0_out(rf_ra0_wb_useless),
    .rf_ra1_out(rf_ra1_wb_useless),
    .rf_rd0_out(rf_rd0_wb_useless),
    .rf_rd1_out(rf_rd1_wb_useless),
    .imm_out(imm_wb_useless),
    .alu_src0_sel_out(alu_src0_sel_wb_useless),
    .alu_src1_sel_out(alu_src1_sel_wb_useless),
    .br_type_out(br_type_wb_useless)
);

//part5:WB
MUX2 regmux(
    .src0(pcadd4_wb),
    .src1(alu_res_wb),
    .src2(dmem_rd_out_wb),
    .src3(32'd0),
    .sel(rf_wd_sel_wb),
    .res(rf_wd_wb)
);

FORWARDING forwarding(
    .rf_we_mem(rf_we_mem),
    .rf_we_wb(rf_we_wb),
    .rf_wa_mem(rf_wa_mem),
    .rf_wa_wb(rf_wa_wb),
    .rf_wd_mem(alu_res_mem),
    .rf_wd_wb(rf_wd_wb),
    .rf_ra0_ex(rf_ra0_ex),
    .rf_ra1_ex(rf_ra1_ex),

    .rf_rd0_fe(rf_rd0_fe),
    .rf_rd1_fe(rf_rd1_fe),
    .rf_rd0_fd(rf_rd0_fd),
    .rf_rd1_fd(rf_rd1_fd)
);

reg  [ 0 : 0]   commit_reg          ;
reg  [31 : 0]   commit_pc_reg       ;
reg  [31 : 0]   commit_inst_reg    ;
reg  [ 0 : 0]   commit_halt_reg     ;
reg  [ 0 : 0]   commit_reg_we_reg   ;
reg  [ 4 : 0]   commit_reg_wa_reg   ;
reg  [31 : 0]   commit_reg_wd_reg   ;
reg  [ 0 : 0]   commit_dmem_we_reg  ;
reg  [31 : 0]   commit_dmem_wa_reg  ;
reg  [31 : 0]   commit_dmem_wd_reg  ;

//assign commit_if = 1'H1;    // 这个信号需要经过 IF/ID、ID/EX、EX/MEM、MEM/WB 段间寄存器，最终连接到 commit_reg 上

always @(posedge clk) begin
    if (rst) begin
        commit_reg          <= 1'H0;
        commit_pc_reg       <= 32'H0;
        commit_inst_reg     <= 32'H0;
        commit_halt_reg     <= 1'H0;
        commit_reg_we_reg   <= 1'H0;
        commit_reg_wa_reg   <= 5'H0;
        commit_reg_wd_reg   <= 32'H0;
        commit_dmem_we_reg  <= 1'H0;
        commit_dmem_wa_reg  <= 32'H0;
        commit_dmem_wd_reg  <= 32'H0;
    end
    else if (global_en) begin
        // 这里右侧的信号都是 MEM/WB 段间寄存器的输出
        commit_reg          <= commit_wb;
        commit_pc_reg       <= pc_wb;
        commit_inst_reg     <= inst_wb;
        commit_halt_reg     <= inst_wb == `HALT_INST;
        commit_reg_we_reg   <= rf_we_wb;
        commit_reg_wa_reg   <= rf_wa_wb;
        commit_reg_wd_reg   <= rf_wd_wb;
        commit_dmem_we_reg  <= dmem_we_wb;
        commit_dmem_wa_reg  <= dmem_addr_wb;
        commit_dmem_wd_reg  <= dmem_wdata_wb;
    end
end

assign commit               = commit_reg;
assign commit_pc            = commit_pc_reg;
assign commit_instr         = commit_inst_reg;
assign commit_halt          = commit_halt_reg;
assign commit_reg_we        = commit_reg_we_reg;
assign commit_reg_wa        = commit_reg_wa_reg;
assign commit_reg_wd        = commit_reg_wd_reg;
assign commit_dmem_we       = commit_dmem_we_reg;
assign commit_dmem_wa       = commit_dmem_wa_reg;
assign commit_dmem_wd       = commit_dmem_wd_reg;

// ......
endmodule