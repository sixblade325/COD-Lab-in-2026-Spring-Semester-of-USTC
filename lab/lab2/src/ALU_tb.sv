module ALU_tb();
    //...
reg[31:0]   src0, src1;
reg[4:0]   sel;
wire[31:0]  res;
reg [4:0] options [11:0];

initial begin
    options[0] = 5'B00000;
    options[1] = 5'B00010;
    options[2] = 5'B00100;
    options[3] = 5'B00101;
    options[4] = 5'B01001;
    options[5] = 5'B01010;
    options[6] = 5'B01011;
    options[7] = 5'B01110;  
    options[8] = 5'B01111;   
    options[9] = 5'B10000; 
    options[10] = 5'B10001;
    options[11] = 5'B10010;
end

ALU alu(src0, src1, sel, res);
integer i;

    initial begin
        src0=32'hffff; src1=32'hffff; sel=12'h001;
        for(i = 0; i < 12; i = i + 1) begin
            #30 sel = options[i];
        end
        #30;
        src0=32'hffff_ffff; src1=32'h1; sel=12'h001;
        for(i = 0; i < 12; i = i + 1) begin
            #30 sel = options[i];
        end
        #30;
        src0=32'h1; src1=32'h0; sel=12'h001;
        for(i = 0; i < 12; i = i + 1) begin
            #30 sel = options[i];
        end
        #30;
        src0=32'hffff_ffff; src1=32'hffff_fffe; sel=12'h001;
        for(i = 0; i < 12; i = i + 1) begin
            #30 sel = options[i];
        end
        #30;
        src0=32'h0; src1=32'hffff_ffff; sel=12'h001;
        for(i = 0; i < 12; i = i + 1) begin
            #30 sel = options[i];
        end
        #30;
    end
    //...
endmodule