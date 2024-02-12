`include "./define.v"
module ex (input wire rst,
           input wire [`AluOpBus] aluop_i,
           input wire [`AluSelBus] alusel_i,
           input wire [`RegBus] reg1_i,
           input wire [`RegBus] reg2_i,
           input wire [`RegAddrBus] wd_i,
           input wire wreg_i,
           output reg [`RegAddrBus] wd_o,
           output reg wreg_o,
           output reg [`RegBus] wdata_o);
    /*** Definition ***/
    reg[`RegBus] logicout;
    reg[`RegBus] shiftRes;
    /*** Compute logicout Based on aluop_i ***/
    always @(*) begin
        if (rst == `RstEnable) begin
            logicout <= `ZeroWord;
            end else begin
            case (aluop_i)
                `EXE_OR_OP,`EXE_ORI_OP: begin
                    logicout <= reg1_i | reg2_i;
                end
                `EXE_AND_OP,`EXE_ANDI_OP:begin
                    logicout <= reg1_i & reg2_i;
                end
                `EXE_XOR_OP,`EXE_XORI_OP:begin
                    logicout <= reg1_i ^ reg2_i;
                end
                `EXE_NOR_OP:begin
                    logicout <= ~(reg1_i | reg2_i);
                end
                default: begin
                    logicout <= `ZeroWord;
                end
            endcase
        end
    end
    /*** Compute Shift result Based on aluop_i ***/
    always @( *) begin
        if (rst == `RstEnable) begin
            shiftRes <= `ZeroWord;
        end else begin
            case (aluop_i)
                `EXE_SLL_OP,`EXE_SLLV_OP:begin
                    shiftRes <= reg2_i << reg1_i[4:0];
                end
                `EXE_SRL_OP,`EXE_SRLV_OP:begin
                    shiftRes <= reg2_i >> reg1_i[4:0];
                end
                `EXE_SRA_OP,`EXE_SRAV_OP:begin
                    shiftRes <= ({32{reg2_i[31]}} << (6'd32 - {1'b0,reg1_i[4:0]})) | (reg2_i >> reg1_i[4:0]);
                end
            endcase
        end
    end
    /*** Determine the Final Result ***/
    always @(*) begin
        wd_o   <= wd_i;
        wreg_o <= wreg_i;
        case (alusel_i)
            `EXE_RES_LOGIC: begin
                wdata_o <= logicout;
            end
            `EXE_RES_SHIFT:begin
                wdata_o <= shiftRes;
            end
            default: begin
                wdata_o <= `ZeroWord;
            end
        endcase
    end
endmodule //ex
