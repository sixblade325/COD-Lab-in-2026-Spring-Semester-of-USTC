`include "const_var.v"

module NewSLU (
    input                   [31 : 0]                addr,
    input                   [ 3 : 0]                dmem_access,

    input                   [31 : 0]                rd_in,
    input                   [31 : 0]                wd_in,

    output      reg         [31 : 0]                rd_out,
    output      reg         [31 : 0]                wd_out,
    output      reg         [3  : 0]                mask
);

wire [4:0] offset = addr [1:0] << 3;

always @(*) begin
    mask = 4'b1111;
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
            wd_out = wd_in << addr[1 : 0];
            mask = 4'b0000;
            mask[addr [1 : 0]] = 1'b1;
        end
        `SD_STH:begin
            rd_out = rd_in;
            wd_out = wd_in << addr[1 : 0];
            mask = 4'b0000;
            mask[addr [1 : 0]] = 1'b1;
            mask[addr [1 : 0] ^ 1] = 1'b1;
        end
        `SD_STW:begin
            rd_out = rd_in;
            wd_out = wd_in;
            mask = 4'b1111;
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