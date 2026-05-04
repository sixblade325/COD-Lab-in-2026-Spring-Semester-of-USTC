`define ALU_ADD                 5'B00000    
`define ALU_SUB                 5'B00010   
`define ALU_SLT                 5'B00100
`define ALU_SLTU                5'B00101
`define ALU_AND                 5'B01001
`define ALU_OR                  5'B01010
`define ALU_XOR                 5'B01011
`define ALU_SLL                 5'B01110   
`define ALU_SRL                 5'B01111    
`define ALU_SRA                 5'B10000  
`define ALU_SRC0                5'B10001
`define ALU_SRC1                5'B10010

module DECODE (
    input                   [31 : 0]            inst,

    output reg              [ 4 : 0]            alu_op,
    output reg              [31 : 0]            imm,

    output                  [ 4 : 0]            rf_ra0,
    output                  [ 4 : 0]            rf_ra1,
    output                  [ 4 : 0]            rf_wa,
    output reg              [ 0 : 0]            rf_we,

    output reg              [ 0 : 0]            alu_src0_sel,
    output reg              [ 0 : 0]            alu_src1_sel
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
localparam sel_rd0      =       1'b0;
localparam sel_pc       =       1'b1;
localparam sel_rd1      =       1'b0;
localparam sel_imm      =       1'b1;

assign    rf_ra0 = inst[31:25] == LU12I_W ? 5'b00000 : inst [ 9 : 5];
assign    rf_ra1 = inst [14 : 10];
assign    rf_wa  = inst [ 4 : 0];

always @(*) begin
    case(inst[31:25])
        LU12I_W:begin
            alu_op = `ALU_ADD;
            imm = {inst[24 : 5], {12{1'b0}}};
            rf_we = 1'b1;
            alu_src0_sel = sel_rd0;
            alu_src1_sel = sel_imm;
        end
        PCADDU12I:begin
            alu_op = `ALU_ADD;
            imm = {inst[24 : 5], {12{1'b0}}};
            rf_we = 1'b1;
            alu_src0_sel = sel_pc;
            alu_src1_sel = sel_imm;
        end
        default:begin
            case(inst[31:22])
                SLTI:begin
                    alu_op = `ALU_SLT;
                    imm = {{20{inst[21]}}, inst[21:10]};
                    rf_we = 1'b1;
                    alu_src0_sel = sel_rd0;
                    alu_src1_sel = sel_imm;
                end
                SLTUI:begin
                    alu_op = `ALU_SLTU;
                    imm = {{20{inst[21]}}, inst[21:10]};
                    rf_we = 1'b1;
                    alu_src0_sel = sel_rd0;
                    alu_src1_sel = sel_imm;
                end
                ADDI_W:begin
                    alu_op = `ALU_ADD;
                    imm = {{20{inst[21]}}, inst[21:10]};
                    rf_we = 1'b1;
                    alu_src0_sel = sel_rd0;
                    alu_src1_sel = sel_imm;
                end
                ANDI:begin
                    alu_op = `ALU_AND;
                    imm = {{20{1'b0}}, inst[21:10]};
                    rf_we = 1'b1;
                    alu_src0_sel = sel_rd0;
                    alu_src1_sel = sel_imm;
                end
                ORI:begin
                    alu_op = `ALU_OR;
                    imm = {{20{1'b0}}, inst[21:10]};
                    rf_we = 1'b1;
                    alu_src0_sel = sel_rd0;
                    alu_src1_sel = sel_imm;
                end
                XORI:begin
                    alu_op = `ALU_XOR;
                    imm = {{20{1'b0}}, inst[21:10]};
                    rf_we = 1'b1;
                    alu_src0_sel = sel_rd0;
                    alu_src1_sel = sel_imm;
                end
                default:begin
                    case(inst[31:15])
                        ADD_W:begin
                            alu_op = `ALU_ADD;
                            imm = {32{1'b0}};
                            rf_we = 1'b1;
                            alu_src0_sel = sel_rd0;
                            alu_src1_sel = sel_rd1;
                        end
                        SUB_W:begin
                            alu_op = `ALU_SUB;
                            imm = {32{1'b0}};
                            rf_we = 1'b1;
                            alu_src0_sel = sel_rd0;
                            alu_src1_sel = sel_rd1;
                        end
                        SLT:begin
                            alu_op = `ALU_SLT;
                            imm = {32{1'b0}};
                            rf_we = 1'b1;
                            alu_src0_sel = sel_rd0;
                            alu_src1_sel = sel_rd1;
                        end
                        SLTU:begin
                            alu_op = `ALU_SLTU;
                            imm = {32{1'b0}};
                            rf_we = 1'b1;
                            alu_src0_sel = sel_rd0;
                            alu_src1_sel = sel_rd1;
                        end
                        AND:begin
                            alu_op = `ALU_AND;
                            imm = {32{1'b0}};
                            rf_we = 1'b1;
                            alu_src0_sel = sel_rd0;
                            alu_src1_sel = sel_rd1;
                        end
                        OR:begin
                            alu_op = `ALU_OR;
                            imm = {32{1'b0}};
                            rf_we = 1'b1;
                            alu_src0_sel = sel_rd0;
                            alu_src1_sel = sel_rd1;
                        end
                        XOR:begin
                            alu_op = `ALU_XOR;
                            imm = {32{1'b0}};
                            rf_we = 1'b1;
                            alu_src0_sel = sel_rd0;
                            alu_src1_sel = sel_rd1;
                        end
                        SLL_W:begin
                            alu_op = `ALU_SLL;
                            imm = {32{1'b0}};
                            rf_we = 1'b1;
                            alu_src0_sel = sel_rd0;
                            alu_src1_sel = sel_rd1;
                        end
                        SRL_W:begin
                            alu_op = `ALU_SRL;
                            imm = {32{1'b0}};
                            rf_we = 1'b1;
                            alu_src0_sel = sel_rd0;
                            alu_src1_sel = sel_rd1;
                        end
                        SRA_W:begin
                            alu_op = `ALU_SRA;
                            imm = {32{1'b0}};
                            rf_we = 1'b1;
                            alu_src0_sel = sel_rd0;
                            alu_src1_sel = sel_rd1;
                        end
                        SLLI_W:begin
                            alu_op = `ALU_SLL;
                            imm = {{27{1'b0}}, inst[14:10]};
                            rf_we = 1'b1;
                            alu_src0_sel = sel_rd0;
                            alu_src1_sel = sel_imm;
                        end
                        SRLI_W:begin
                            alu_op = `ALU_SRL;
                            imm = {{27{1'b0}}, inst[14:10]};
                            rf_we = 1'b1;
                            alu_src0_sel = sel_rd0;
                            alu_src1_sel = sel_imm;
                        end
                        SRAI_W:begin
                            alu_op = `ALU_SRA;
                            imm = {{27{1'b0}}, inst[14:10]};
                            rf_we = 1'b1;
                            alu_src0_sel = sel_rd0;
                            alu_src1_sel = sel_imm;
                        end
                        default:begin//attention
                            alu_op = 0;
                            imm = 0;
                            rf_we = 1'b0;
                            alu_src0_sel = sel_rd0;
                            alu_src1_sel = sel_imm;
                        end
                    endcase
                end
            endcase
        end
    endcase
end

endmodule