`include "const_var.v"

module SLU (
    input                   [31 : 0]                addr,
    input                   [ 3 : 0]                dmem_access,

    input                   [31 : 0]                rd_in,
    input                   [31 : 0]                wd_in,

    output      reg         [31 : 0]                rd_out,
    output      reg         [31 : 0]                wd_out
);

wire [4:0] offset = addr [1:0] << 3;

always @(*) begin
    case(dmem_access)
        `SD_LDB:begin
            rd_out = {{24{rd_in[offset + 7]}}, rd_in[offset +: 8]};
            wd_out = wd_in;
        end
        `SD_LDH:begin
            case(offset[4:3])
                2'b00:rd_out = {{16{rd_in[15]}}, rd_in[15:0]};
                2'b10:rd_out = {{16{rd_in[31]}}, rd_in[31:16]};
                default:rd_out = rd_in;
            endcase
            wd_out = wd_in;
        end
        `SD_LDW:begin
            rd_out = rd_in;
            wd_out = wd_in;
        end
        `SD_STB:begin
            rd_out = rd_in;
            case(offset[4:3])
                2'b00:wd_out = {rd_in[31:8], wd_in[7:0]};
                2'b01:wd_out = {rd_in[31:16], wd_in[7:0], rd_in[7:0]};
                2'b10:wd_out = {rd_in[31:24], wd_in[7:0], rd_in[15:0]};
                2'b11:wd_out = {wd_in[7:0], rd_in[23:0]};
                default:wd_out = wd_in;
            endcase
        end
        `SD_STH:begin
            rd_out = rd_in;
            case(offset[4:3])
                2'b00:wd_out = {rd_in[31:16], wd_in[15:0]};
                2'b10:wd_out = {wd_in[15:0], rd_in[15:0]};
                default:wd_out = wd_in;
            endcase
        end
        `SD_STW:begin
            rd_out = rd_in;
            wd_out = wd_in;
        end
        `SD_LDBU:begin
            wd_out = wd_in;
            rd_out = {{24{1'b0}}, rd_in[offset +:8]};
        end
        `SD_LDHU:begin
            case(offset[4:3])
                2'b00:rd_out = {{16{1'b0}}, rd_in[15:0]};
                2'b10:rd_out = {{16{1'b0}}, rd_in[31:16]};
                default:rd_out = rd_in;
            endcase
            wd_out = wd_in;
        end
        default:begin
            rd_out = rd_in;
            wd_out = wd_in;
        end
    endcase
end

endmodule