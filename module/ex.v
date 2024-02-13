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
           output reg [`RegBus] wdata_o,
           
           input  wire [`RegBus] hi_i,
           input  wire [`RegBus] lo_i,
 
           input  wire [`RegBus] mem_hi_i,
           input  wire [`RegBus] mem_lo_i,
           input  wire mem_whilo_i,

           input  wire [`RegBus] wb_hi_i,
           input  wire [`RegBus] wb_lo_i,
           input  wire wb_whilo_i,

           output  reg [`RegBus] hi_o,
           output reg [`RegBus] lo_o,
           output reg whilo_o
           );
    /*** Definition ***/
    reg[`RegBus] logicout;
    reg[`RegBus] shiftRes;
    reg[`RegBus] moveres;
    reg[`RegBus] HI;
    reg[`RegBus] LO;
    /*** Check if Memory Access and Write Back would change HI/LO ***/
    always @( *) begin
        if (rst == `RstEnable) begin
            {HI,LO} <= {`ZeroWord,`ZeroWord};
        end else if(mem_whilo_i == `WriteEnable) begin
            {HI,LO} <= {mem_hi_i,mem_lo_i};
        end else if(wb_whilo_i == `WriteEnable) begin
            {HI,LO} <= {wb_hi_i,wb_lo_i};
        end else begin
            {HI,LO} <= {hi_i,lo_i};
        end
    end

    /*** Compute Move result Based on aluop_i ***/
    always @( *) begin
        if (rst == `RstEnable) begin
            moveres <= `ZeroWord;
        end else begin
            moveres <= `ZeroWord;
            case (aluop_i)
                `EXE_MFHI_OP: begin
                    moveres <= HI;
                end
                
                `EXE_MFLO_OP:begin
                    moveres <= LO;
                end

                `EXE_MOVN_OP:begin
                    moveres <= reg1_i;
                end

                `EXE_MOVZ_OP:begin
                    moveres <= reg1_i;
                end

                default :begin
                    
                end
            endcase
        end
    end
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
            `EXE_RES_MOVE:begin
                wdata_o <= moveres;
            end
            default: begin
                wdata_o <= `ZeroWord;
            end
        endcase
    end
    /*** Write HILO ***/
    always @( *) begin
        if (rst == `RstEnable) begin
            whilo_o <= `WriteDisable;
            {hi_o,lo_o} <= {`ZeroWord,`ZeroWord};
        end else if(aluop_i == `EXE_MTHI_OP) begin
            whilo_o <= `WriteEnable;
            {hi_o,lo_o} <= {reg1_i,LO};
        end else if (aluop_i == `EXE_MTLO_OP) begin
            whilo_o <= `WriteEnable;
            {hi_o,lo_o} <= {HI,reg1_i};
        end else begin
            whilo_o <= `WriteDisable;
            {hi_o,lo_o} <= {`ZeroWord,`ZeroWord};
        end
    end
endmodule //ex
