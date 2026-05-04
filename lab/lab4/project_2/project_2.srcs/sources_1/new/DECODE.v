`include "const_var.v"

module DECODE (
    input                   [31 : 0]            inst,

    output reg              [ 4 : 0]            alu_op,

    output                  [ 3 : 0]            dmem_access,

    output reg              [31 : 0]            imm,

    output reg              [ 4 : 0]            rf_ra0,
    output reg              [ 4 : 0]            rf_ra1,
    output                  [ 4 : 0]            rf_wa,
    output reg              [ 0 : 0]            rf_we,
    output reg              [ 1 : 0]            rf_wd_sel,

    output reg              [ 0 : 0]            alu_src0_sel,
    output reg              [ 0 : 0]            alu_src1_sel,

    output reg              [ 3 : 0]            br_type
);
localparam LU12I_W      =       7'b0001010;
localparam PCADDU12I    =       7'b0001110;
localparam SLTI         =       10'b0000001000;
localparam SLTUI        =       10'b0000001001;
localparam ADDI_W       =       10'b0000001010;
localparam ANDI         =       10'b0000001101;
localparam ORI          =       10'b0000001110;
localparam XORI         =       10'b0000001111;
localparam ADD_W        =       17'b00000000000100000;
localparam SUB_W        =       17'b00000000000100010;
localparam SLT          =       17'b00000000000100100;
localparam SLTU         =       17'b00000000000100101;
localparam AND          =       17'b00000000000101001;
localparam OR           =       17'b00000000000101010;
localparam XOR          =       17'b00000000000101011;
localparam SLL_W        =       17'b00000000000101110;
localparam SRL_W        =       17'b00000000000101111;
localparam SRA_W        =       17'b00000000000110000;
localparam SLLI_W       =       17'b00000000010000001;
localparam SRLI_W       =       17'b00000000010001001;
localparam SRAI_W       =       17'b00000000010010001;
localparam sel_rd0      =       1'b0;//rj
localparam sel_pc       =       1'b1;
localparam sel_rd1      =       1'b0;//rk
localparam sel_imm      =       1'b1;
localparam rf_sel_pc_add4 =     2'b00;
localparam rf_sel_alu_res =     2'b01;
localparam rf_sel_dmem_rdata =  2'b10;
localparam rf_sel_ZERO =        2'b11;

assign    dmem_access = inst[25 : 22];
assign    rf_wa  = inst[31:26] == 6'b010101 ? 5'b00001 : inst [ 4 : 0];//rd

always @(*) begin
    if(inst[31:25] == LU12I_W)begin
        rf_ra0 = 5'b00000; 
        rf_ra1 = inst[14:10];
    end else begin
        if(inst[31:30] == 2'b01)begin
            rf_ra0 = inst[9 : 5];
            rf_ra1 = inst[4 : 0];
        end else begin
            if(inst[31:26] == 6'b001010 && (inst[25 : 22] ==  `SD_STB|| inst[25 : 22] ==`SD_STH|| inst[25 : 22] == `SD_STW))begin
                rf_ra0 = inst[9 : 5];
                rf_ra1 = inst[4 : 0];
            end else begin
                rf_ra0 = inst[9 : 5];
                rf_ra1 = inst[14 : 10];
            end
        end
    end
end

always @(*) begin
    if(inst[31:30] == 2'b01)begin
        alu_op = `ALU_ADD;
        if(inst[29 : 26] == `BR_B || inst[29 : 26] == `BR_BL)
            imm = {{4{inst[9]}}, inst[9:0], inst[25:10], {2{1'b0}}};
        else imm = {{14{inst[25]}}, inst[25:10], {2{1'b0}}};
        case(inst[29 : 26])
        `BR_BEQ,`BR_BNE,`BR_BLT,`BR_BGE,`BR_BLTU,`BR_BGEU, `BR_B:begin
            alu_src0_sel = sel_pc;
            alu_src1_sel = sel_imm;
            rf_we = 1'b0;
            rf_wd_sel = rf_sel_alu_res;
        end
        `BR_BL:begin
            alu_src0_sel = sel_pc;
            alu_src1_sel = sel_imm;
            rf_we = 1'b1;
            rf_wd_sel = rf_sel_pc_add4;
        end
        `BR_JIRL:begin
            alu_src0_sel = sel_rd0;
            alu_src1_sel = sel_imm;
            rf_we = 1'b1;
            rf_wd_sel = rf_sel_pc_add4;
        end
        default:begin
            alu_src0_sel = sel_rd0;
            alu_src1_sel = sel_rd1;
            rf_we = 1'b0;
            rf_wd_sel = rf_sel_alu_res;
        end
        endcase
    end else begin
        if(inst[31 : 26] == 6'b001010)begin
            alu_op = `ALU_ADD;
            imm = {{20{inst[21]}}, inst[21:10]};
            alu_src0_sel = sel_rd0;
            alu_src1_sel = sel_imm;
            case(inst[25 : 22])
                `SD_STB, `SD_STH, `SD_STW:begin
                    rf_we = 1'b0;
                    rf_wd_sel = rf_sel_alu_res;
                end
                default:begin
                    rf_we = 1'b1;
                    rf_wd_sel = rf_sel_dmem_rdata;
                end
            endcase
        end else begin
            case(inst[31:25])
                LU12I_W:begin
                    alu_op = `ALU_ADD;
                    imm = {inst[24 : 5], {12{1'b0}}};
                    rf_we = 1'b1;
                    alu_src0_sel = sel_rd0;
                    alu_src1_sel = sel_imm;
                    rf_wd_sel = rf_sel_alu_res;
                end
                PCADDU12I:begin
                    alu_op = `ALU_ADD;
                    imm = {inst[24 : 5], {12{1'b0}}};
                    rf_we = 1'b1;
                    alu_src0_sel = sel_pc;
                    alu_src1_sel = sel_imm;
                    rf_wd_sel = rf_sel_alu_res;
                end
                default:begin
                    case(inst[31:22])
                        SLTI:begin
                            alu_op = `ALU_SLT;
                            imm = {{20{inst[21]}}, inst[21:10]};
                            rf_we = 1'b1;
                            alu_src0_sel = sel_rd0;
                            alu_src1_sel = sel_imm;
                            rf_wd_sel = rf_sel_alu_res;
                        end
                        SLTUI:begin
                            alu_op = `ALU_SLTU;
                            imm = {{20{inst[21]}}, inst[21:10]};
                            rf_we = 1'b1;
                            alu_src0_sel = sel_rd0;
                            alu_src1_sel = sel_imm;
                            rf_wd_sel = rf_sel_alu_res;
                        end
                        ADDI_W:begin
                            alu_op = `ALU_ADD;
                            imm = {{20{inst[21]}}, inst[21:10]};
                            rf_we = 1'b1;
                            alu_src0_sel = sel_rd0;
                            alu_src1_sel = sel_imm;
                            rf_wd_sel = rf_sel_alu_res;
                        end
                        ANDI:begin
                            alu_op = `ALU_AND;
                            imm = {{20{1'b0}}, inst[21:10]};
                            rf_we = 1'b1;
                            alu_src0_sel = sel_rd0;
                            alu_src1_sel = sel_imm;
                            rf_wd_sel = rf_sel_alu_res;
                        end
                        ORI:begin
                            alu_op = `ALU_OR;
                            imm = {{20{1'b0}}, inst[21:10]};
                            rf_we = 1'b1;
                            alu_src0_sel = sel_rd0;
                            alu_src1_sel = sel_imm;
                            rf_wd_sel = rf_sel_alu_res;
                        end
                        XORI:begin
                            alu_op = `ALU_XOR;
                            imm = {{20{1'b0}}, inst[21:10]};
                            rf_we = 1'b1;
                            alu_src0_sel = sel_rd0;
                            alu_src1_sel = sel_imm;
                            rf_wd_sel = rf_sel_alu_res;
                        end
                        default:begin
                            case(inst[31:15])
                                ADD_W:begin
                                    alu_op = `ALU_ADD;
                                    imm = {32{1'b0}};
                                    rf_we = 1'b1;
                                    alu_src0_sel = sel_rd0;
                                    alu_src1_sel = sel_rd1;
                                    rf_wd_sel = rf_sel_alu_res;
                                end
                                SUB_W:begin
                                    alu_op = `ALU_SUB;
                                    imm = {32{1'b0}};
                                    rf_we = 1'b1;
                                    alu_src0_sel = sel_rd0;
                                    alu_src1_sel = sel_rd1;
                                    rf_wd_sel = rf_sel_alu_res;
                                end
                                SLT:begin
                                    alu_op = `ALU_SLT;
                                    imm = {32{1'b0}};
                                    rf_we = 1'b1;
                                    alu_src0_sel = sel_rd0;
                                    alu_src1_sel = sel_rd1;
                                    rf_wd_sel = rf_sel_alu_res;
                                end
                                SLTU:begin
                                    alu_op = `ALU_SLTU;
                                    imm = {32{1'b0}};
                                    rf_we = 1'b1;
                                    alu_src0_sel = sel_rd0;
                                    alu_src1_sel = sel_rd1;
                                    rf_wd_sel = rf_sel_alu_res;
                                end
                                AND:begin
                                    alu_op = `ALU_AND;
                                    imm = {32{1'b0}};
                                    rf_we = 1'b1;
                                    alu_src0_sel = sel_rd0;
                                    alu_src1_sel = sel_rd1;
                                    rf_wd_sel = rf_sel_alu_res;
                                end
                                OR:begin
                                    alu_op = `ALU_OR;
                                    imm = {32{1'b0}};
                                    rf_we = 1'b1;
                                    alu_src0_sel = sel_rd0;
                                    alu_src1_sel = sel_rd1;
                                    rf_wd_sel = rf_sel_alu_res;
                                end
                                XOR:begin
                                    alu_op = `ALU_XOR;
                                    imm = {32{1'b0}};
                                    rf_we = 1'b1;
                                    alu_src0_sel = sel_rd0;
                                    alu_src1_sel = sel_rd1;
                                    rf_wd_sel = rf_sel_alu_res;
                                end
                                SLL_W:begin
                                    alu_op = `ALU_SLL;
                                    imm = {32{1'b0}};
                                    rf_we = 1'b1;
                                    alu_src0_sel = sel_rd0;
                                    alu_src1_sel = sel_rd1;
                                    rf_wd_sel = rf_sel_alu_res;
                                end
                                SRL_W:begin
                                    alu_op = `ALU_SRL;
                                    imm = {32{1'b0}};
                                    rf_we = 1'b1;
                                    alu_src0_sel = sel_rd0;
                                    alu_src1_sel = sel_rd1;
                                    rf_wd_sel = rf_sel_alu_res;
                                end
                                SRA_W:begin
                                    alu_op = `ALU_SRA;
                                    imm = {32{1'b0}};
                                    rf_we = 1'b1;
                                    alu_src0_sel = sel_rd0;
                                    alu_src1_sel = sel_rd1;
                                    rf_wd_sel = rf_sel_alu_res;
                                end
                                SLLI_W:begin
                                    alu_op = `ALU_SLL;
                                    imm = {{27{1'b0}}, inst[14:10]};
                                    rf_we = 1'b1;
                                    alu_src0_sel = sel_rd0;
                                    alu_src1_sel = sel_imm;
                                    rf_wd_sel = rf_sel_alu_res;
                                end
                                SRLI_W:begin
                                    alu_op = `ALU_SRL;
                                    imm = {{27{1'b0}}, inst[14:10]};
                                    rf_we = 1'b1;
                                    alu_src0_sel = sel_rd0;
                                    alu_src1_sel = sel_imm;
                                    rf_wd_sel = rf_sel_alu_res;
                                end
                                SRAI_W:begin
                                    alu_op = `ALU_SRA;
                                    imm = {{27{1'b0}}, inst[14:10]};
                                    rf_we = 1'b1;
                                    alu_src0_sel = sel_rd0;
                                    alu_src1_sel = sel_imm;
                                    rf_wd_sel = rf_sel_alu_res;
                                end
                                default:begin//attention
                                    alu_op = 0;
                                    imm = 0;
                                    rf_we = 1'b0;
                                    alu_src0_sel = sel_rd0;
                                    alu_src1_sel = sel_imm;
                                    rf_wd_sel = rf_sel_alu_res;
                                end
                            endcase
                        end
                    endcase
                end
            endcase
        end
    end
end

always @(*) begin
    if(inst[31:30] == 2'b01)
        br_type = inst[29 : 26];
    else br_type = 4'b0000;
end

endmodule