module FORWARDING(
    input [ 0: 0 ]         rf_we_mem,
    input [ 0: 0 ]         rf_we_wb,
    input [ 4: 0 ]         rf_wa_mem,
    input [ 4: 0 ]         rf_wa_wb,
    input [31: 0 ]         rf_wd_mem,
    input [31: 0 ]         rf_wd_wb,
    input [ 4: 0 ]         rf_ra0_ex,
    input [ 4: 0 ]         rf_ra1_ex,

    output reg [ 0: 0 ]    rf_rd0_fe,
    output reg [ 0: 0 ]    rf_rd1_fe,
    output reg [31: 0 ]    rf_rd0_fd,
    output reg [31: 0 ]    rf_rd1_fd
);
//在mem阶段直接前递alu_res真的正确吗？
//若在mem阶段有一个Lw指令，在wb阶段有一个R-type指令，且它们的目的寄存器相同
//那么mem阶段直接前递alu_res会出问题？
//这个bug在SegCtrl中检测到Load_use冒险后通过插入nop解决了

always @(*) begin

    if(rf_we_mem && (rf_ra0_ex == rf_wa_mem) && rf_ra0_ex != 5'd0) begin
        rf_rd0_fe = 1'b1;
        rf_rd0_fd = rf_wd_mem;
    end else if(rf_we_wb && (rf_ra0_ex == rf_wa_wb) && rf_ra0_ex != 5'd0) begin
        rf_rd0_fe = 1'b1;
        rf_rd0_fd = rf_wd_wb;
    end else begin
        rf_rd0_fe = 1'b0;
        rf_rd0_fd = 32'b0;
    end

    if(rf_we_mem && (rf_ra1_ex == rf_wa_mem) && rf_ra1_ex != 5'd0) begin
        rf_rd1_fe = 1'b1;
        rf_rd1_fd = rf_wd_mem;
    end else if(rf_we_wb && (rf_ra1_ex == rf_wa_wb) && rf_ra1_ex != 5'd0) begin
        rf_rd1_fe = 1'b1;
        rf_rd1_fd = rf_wd_wb;
    end else begin
        rf_rd1_fe = 1'b0;
        rf_rd1_fd = 32'b0;
    end

end

endmodule
