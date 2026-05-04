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

`define NPC_SEL_ADD4            2'b00
`define NPC_SEL_OFFSET          2'b01
`define NPC_SEL_J               2'b10

`define BR_JIRL                 4'b0011
`define BR_B                    4'b0100
`define BR_BL                   4'b0101
`define BR_BEQ                  4'b0110
`define BR_BNE                  4'b0111
`define BR_BLT                  4'b1000
`define BR_BGE                  4'b1001
`define BR_BLTU                 4'b1010
`define BR_BGEU                 4'b1011  

`define SD_LDB                  4'b0000
`define SD_LDH                  4'b0001
`define SD_LDW                  4'b0010
`define SD_STB                  4'b0100
`define SD_STH                  4'b0101
`define SD_STW                  4'b0110
`define SD_LDBU                 4'b1000
`define SD_LDHU                 4'b1001