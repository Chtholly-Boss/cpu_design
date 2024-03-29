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
           input wire [`RegBus] hi_i,
           input wire [`RegBus] lo_i,
           input wire [`RegBus] mem_hi_i,
           input wire [`RegBus] mem_lo_i,
           input wire mem_whilo_i,
           input wire [`RegBus] wb_hi_i,
           input wire [`RegBus] wb_lo_i,
           input wire wb_whilo_i,
           output reg [`RegBus] hi_o,
           output reg [`RegBus] lo_o,
           output reg whilo_o,

           output reg stallreq_from_ex,
           
           input  wire [`DoubleRegBus] hilo_temp_i,
           input  wire [1:0] cnt_i,
           output reg [`DoubleRegBus] hilo_temp_o,
           output reg [1:0] cnt_o,
           
           input  wire [`DoubleRegBus] div_result_i,
           input  wire div_ready_i,
           
           output reg [`RegBus] div_opdata1_o,
           output reg [`RegBus] div_opdata2_o,
           output reg div_start_o,
           output reg signed_div_o,
           
           input  wire is_in_delayslot_i,
           input  wire [31:0] link_address_i,
           
           input  wire [31:0] inst_i,
           output wire [`AluOpBus] aluop_o,
           output wire [`RegBus] mem_addr_o,
           output wire [`RegBus] reg2_o,
           
           input wire mem_wreg_i,
           input wire [`RegAddrBus] mem_wd_i,
           input wire [`RegBus] mem_wdata_i,
           
           input  wire mem_cp0_reg_we,
           input  wire [4:0] mem_cp0_reg_waddr,
           input  wire [31:0] mem_cp0_reg_wdata,
           
           input  wire wb_cp0_reg_we,
           input  wire [4:0] wb_cp0_reg_waddr,
           input  wire [31:0] wb_cp0_reg_wdata,
           
           input  wire [31:0] cp0_reg_data_i,
           output reg [4:0] cp0_reg_raddr_o,
           
           output reg cp0_reg_we_o,
           output reg [4:0] cp0_reg_waddr_o,
           output reg [31:0] cp0_reg_wdata_o,
           
           input  wire [31:0] excepttype_i,
           input  wire [31:0] current_inst_addr_i,
           
           output wire [31:0] excepttype_o,
           output wire is_in_delayslot_o,
           output wire [31:0] current_inst_addr_o);
    /*** Definition ***/
    reg[`RegBus] HI;
    reg[`RegBus] LO;
    
    assign aluop_o = aluop_i;

    reg trapassert;
    reg ovassert;

    assign excepttype_o = {excepttype_i[31:12],ovassert,trapassert,excepttype_i[9:8],8'h00};
    assign is_in_delayslot_o = is_in_delayslot_i;
    assign current_inst_addr_o = current_inst_addr_i;
    /*** Check if Memory Access and Write Back would change HI/LO ***/
    always @(*) begin
        if (rst == `RstEnable) begin
            {HI,LO} <= {`ZeroWord,`ZeroWord};
            end else if (mem_whilo_i == `WriteEnable) begin
            {HI,LO} <= {mem_hi_i,mem_lo_i};
            end else if (wb_whilo_i == `WriteEnable) begin
            {HI,LO} <= {wb_hi_i,wb_lo_i};
            end else begin
            {HI,LO} <= {hi_i,lo_i};
        end
    end
    
    /*** Compute Move result Based on aluop_i ***/
    reg[`RegBus] moveres;
    always @(*) begin
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
                
                `EXE_MFC0_OP:begin
                    cp0_reg_raddr_o <= inst_i[15:11];
                    moveres <= cp0_reg_data_i;
                    if (mem_cp0_reg_we == `WriteEnable
                    && mem_cp0_reg_waddr == inst_i[15:11]) begin
                        moveres <= mem_cp0_reg_wdata;
                    end else if(wb_cp0_reg_we == `WriteEnable
                    && wb_cp0_reg_waddr == inst_i[15:11]) begin
                        moveres <= wb_cp0_reg_wdata;
                    end
                end
                default :begin
                    
                end
            endcase
        end
    end
    /*** Compute logicout Based on aluop_i ***/
    reg[`RegBus] logicout;
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
    reg[`RegBus] shiftRes;
    always @(*) begin
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
    
    reg [`RegBus] arithmeticres;
    wire          ov_sum;
    
    wire          reg1_eq_reg2;
    wire          reg1_lt_reg2;
    wire[`RegBus] reg2_i_mux;
    wire[`RegBus] reg1_i_not;
    wire[`RegBus] result_sum;
    
    assign reg2_i_mux = ((aluop_i == `EXE_SUB_OP) ||
    (aluop_i == `EXE_SUBU_OP) ||
    (aluop_i == `EXE_SLT_OP) ||
    (aluop_i == `EXE_SLTI_OP) ||
    (aluop_i == `EXE_TLT_OP) ||
    (aluop_i == `EXE_TLTI_OP) ||
    (aluop_i == `EXE_TGE_OP) ||
    (aluop_i == `EXE_TGEI_OP)) ?
    (~reg2_i) + 1 : reg2_i;
    
    assign result_sum = reg1_i + reg2_i_mux;
    
    assign ov_sum = (
    (~reg1_i[31] & ~reg2_i_mux[31] & result_sum[31]) ||
    (reg1_i[31] & reg2_i[31] & ~result_sum[31])
    );
    
    assign reg1_lt_reg2 = (
    (aluop_i == `EXE_SLT_OP) ||
    (aluop_i == `EXE_SLTI_OP) ||
    (aluop_i == `EXE_TLT_OP) ||
    (aluop_i == `EXE_TLTI_OP) ||
    (aluop_i == `EXE_TGE_OP) ||
    (aluop_i == `EXE_TGEI_OP)
    ) ? (
    (reg1_i[31] & ~reg2_i[31]) ||
    (reg1_i[31] & reg2_i[31] & result_sum[31]) ||
    (~reg1_i[31] & ~reg2_i[31] & result_sum[31])) : (reg1_i < reg2_i);
    
    assign reg1_i_not = ~reg1_i;
    /*** Exception Judgement ***/
    always @( *) begin
        if (rst == `RstEnable) begin
            trapassert <= `TrapAssert;
        end else begin
            trapassert <= `TrapNotAssert;
            case (aluop_i)
                `EXE_TEQ_OP,`EXE_TEQI_OP:begin
                    if (reg1_i == reg2_i) begin
                        trapassert = `TrapAssert;
                    end
                end
                `EXE_TGE_OP,`EXE_TGEI_OP,`EXE_TGEU_OP,`EXE_TGEIU_OP:begin
                    if (~reg1_lt_reg2) begin
                        trapassert = `TrapAssert;
                    end
                end
                `EXE_TLT_OP,`EXE_TLTI_OP,`EXE_TLTU_OP,`EXE_TLTIU_OP:begin
                    if (reg1_lt_reg2) begin
                        trapassert = `TrapAssert;
                    end
                end
                `EXE_TNE_OP,`EXE_TNEI_OP:begin
                    if (reg1_i != reg2_i) begin
                        trapassert = `TrapAssert;
                    end
                end
                default begin
                   trapassert <= `TrapNotAssert; 
                end
            endcase
        end
    end

    always @( *) begin
        if (((aluop_i == `EXE_ADD_OP) ||
        (aluop_i == `EXE_ADDI_OP) ||
        (aluop_i == `EXE_SUB_OP)) &&
        (ov_sum == 1'b1)) begin
            wreg_o <= `WriteDisable;
            ovassert <= 1'b1;
        end else begin
            wreg_o <= wreg_i;
            ovassert <= 1'b0;
        end
    end
    /*** Compute Arithmetic Results Based on aluop ***/
    always @(*) begin
        if (rst == `RstEnable) begin
            arithmeticres <= `ZeroWord;
            end else begin
            case (aluop_i)
                `EXE_SLT_OP,`EXE_SLTI_OP:begin
                    arithmeticres <= reg1_lt_reg2;
                end
                
                `EXE_SLTU_OP,`EXE_SLTIU_OP:begin
                    arithmeticres <= reg1_lt_reg2;
                end
                
                `EXE_ADD_OP,`EXE_ADDI_OP:begin
                    arithmeticres <= result_sum;
                end
                
                `EXE_ADDU_OP,`EXE_ADDIU_OP:begin
                    arithmeticres <= result_sum;
                end
                
                `EXE_SUB_OP:begin
                    arithmeticres <= result_sum;
                end
                
                `EXE_SUBU_OP:begin
                    arithmeticres <= result_sum;
                end
                
                `EXE_CLZ_OP  :begin
                    arithmeticres <= reg1_i[31]  ? 0  : reg1_i[30] ? 1 :
                    reg1_i[29] ? 2  : reg1_i[28] ? 3 :
                    reg1_i[27] ? 4  : reg1_i[26] ? 5 :
                    reg1_i[25] ? 6  : reg1_i[24] ? 7 :
                    reg1_i[23] ? 8  : reg1_i[22] ? 9 :
                    reg1_i[21] ? 10 : reg1_i[20] ? 11 :
                    reg1_i[19] ? 12 : reg1_i[18] ? 13 :
                    reg1_i[17] ? 14 : reg1_i[16] ? 15 :
                    reg1_i[15] ? 16 : reg1_i[14] ? 17 :
                    reg1_i[13] ? 18 : reg1_i[12] ? 19 :
                    reg1_i[11] ? 20 : reg1_i[10] ? 21 :
                    reg1_i[9]  ? 22 : reg1_i[8]  ? 23 :
                    reg1_i[7]  ? 24 : reg1_i[6]  ? 25 :
                    reg1_i[5]  ? 26 : reg1_i[4]  ? 27 :
                    reg1_i[3]  ? 28 : reg1_i[2]  ? 29 :
                    reg1_i[1]  ? 30 : reg1_i[0]  ? 31 : 32;
                end
                
                `EXE_CLO_OP                           :begin
                    arithmeticres <= reg1_i_not[31]  ? 0  : reg1_i_not[30] ? 1 :
                    reg1_i_not[29] ? 2  : reg1_i_not[28] ? 3 :
                    reg1_i_not[27] ? 4  : reg1_i_not[26] ? 5 :
                    reg1_i_not[25] ? 6  : reg1_i_not[24] ? 7 :
                    reg1_i_not[23] ? 8  : reg1_i_not[22] ? 9 :
                    reg1_i_not[21] ? 10 : reg1_i_not[20] ? 11 :
                    reg1_i_not[19] ? 12 : reg1_i_not[18] ? 13 :
                    reg1_i_not[17] ? 14 : reg1_i_not[16] ? 15 :
                    reg1_i_not[15] ? 16 : reg1_i_not[14] ? 17 :
                    reg1_i_not[13] ? 18 : reg1_i_not[12] ? 19 :
                    reg1_i_not[11] ? 20 : reg1_i_not[10] ? 21 :
                    reg1_i_not[9]  ? 22 : reg1_i_not[8]  ? 23 :
                    reg1_i_not[7]  ? 24 : reg1_i_not[6]  ? 25 :
                    reg1_i_not[5]  ? 26 : reg1_i_not[4]  ? 27 :
                    reg1_i_not[3]  ? 28 : reg1_i_not[2]  ? 29 :
                    reg1_i_not[1]  ? 30 : reg1_i_not[0]  ? 31 : 32;
                end
                default:begin
                    arithmeticres <= `ZeroWord;
                end
            endcase
        end
    end
    
    /*** Multiplication ***/
    wire[`RegBus] opdata1_mult;
    wire[`RegBus] opdata2_mult;
    wire[`DoubleRegBus] hilo_temp;
    reg [`DoubleRegBus] hilo_temp_for_madd_msub;
    reg[`DoubleRegBus] mulres;
    reg stallreq_for_madd_msub;
    
    assign opdata1_mult = (((aluop_i == `EXE_MUL_OP) ||
    (aluop_i == `EXE_MULT_OP) ||
    (aluop_i == `EXE_MADD_OP) ||
    (aluop_i == `EXE_MSUB_OP)) &&
    (reg1_i[31] == 1'b1)) ? (~reg1_i + 1) : reg1_i;
    
    assign opdata2_mult = (((aluop_i == `EXE_MUL_OP) ||
    (aluop_i == `EXE_MULT_OP) ||
    (aluop_i == `EXE_MADD_OP) ||
    (aluop_i == `EXE_MSUB_OP)) &&
    (reg2_i[31] == 1'b1)) ? (~reg2_i + 1) : reg2_i;
    
    assign hilo_temp = opdata1_mult * opdata2_mult;
    
    always @(*) begin
        if (rst == `RstEnable) begin
            mulres <= {`ZeroWord,`ZeroWord};
            end else if ((aluop_i == `EXE_MUL_OP) ||
            (aluop_i == `EXE_MULT_OP) ||
            (aluop_i == `EXE_MADD_OP) ||
            (aluop_i == `EXE_MSUB_OP)) begin
            if ((reg1_i[31] ^ reg2_i[31]) == 1'b1) begin
                mulres <= ~hilo_temp + 1;
                end else begin
                mulres <= hilo_temp;
            end
            end else begin
            mulres <= hilo_temp;
        end
    end

    /*** MADD and MSUB ***/
    always @( *) begin
        if (rst == `RstEnable) begin
            hilo_temp_o <= {`ZeroWord,`ZeroWord};
            cnt_o <= 2'b00;
            stallreq_for_madd_msub <= `NoStop;
        end else begin
            case (aluop_i)
                `EXE_MADD_OP,`EXE_MADDU_OP:begin
                    if (cnt_i == 2'b00) begin
                        hilo_temp_o <= mulres;
                        cnt_o <= 2'b01;
                        stallreq_for_madd_msub <= `Stop;
                        hilo_temp_for_madd_msub <= {`ZeroWord,`ZeroWord};
                    end else if(cnt_i == 2'b01) begin
                        hilo_temp_o <= {`ZeroWord,`ZeroWord};
                        cnt_o <= 2'b10;
                        hilo_temp_for_madd_msub <= hilo_temp_i + {HI,LO};
                        stallreq_for_madd_msub <= `NoStop;
                    end
                end 

                `EXE_MSUB_OP,`EXE_MSUBU_OP:begin
                    if (cnt_i == 2'b00) begin
                        hilo_temp_o <= ~mulres + 1;
                        cnt_o <= 2'b01;
                        stallreq_for_madd_msub <= `Stop;
                    end else if(cnt_i == 2'b01) begin
                        hilo_temp_o <= {`ZeroWord,`ZeroWord};
                        cnt_o <= 2'b10;
                        hilo_temp_for_madd_msub <= hilo_temp_i + {HI,LO};
                        stallreq_for_madd_msub <= `NoStop;
                    end
                end
                default:begin
                    hilo_temp_o <= {`ZeroWord,`ZeroWord};
                    cnt_o <= 2'b00;
                    stallreq_for_madd_msub <= `NoStop;
                end 
            endcase
        end
    end

    /*** Division ***/
    reg stallreq_for_div;
    always @( *) begin
        if (rst == `RstEnable) begin
            stallreq_for_div <= `NoStop;
            div_opdata1_o <= `ZeroWord;
            div_opdata2_o <= `ZeroWord;
            div_start_o <= `DivStop;
            signed_div_o <= 1'b0;
        end else begin
            stallreq_for_div <= `NoStop;
            div_opdata1_o <= `ZeroWord;
            div_opdata2_o <= `ZeroWord;
            div_start_o <= `DivStop;
            signed_div_o <= 1'b0;
            case (aluop_i)
                `EXE_DIV_OP:begin
                    if (div_ready_i == `DivResultNotReady) begin
                        div_opdata1_o <= reg1_i;
                        div_opdata2_o <= reg2_i;
                        div_start_o <= `DivStart;
                        signed_div_o <= 1'b1;
                        stallreq_for_div <= `Stop;
                    end else if(div_ready_i == `DivResultReady) begin
                        div_opdata1_o <= reg1_i;
                        div_opdata2_o <= reg2_i;
                        div_start_o <= `DivStop;
                        signed_div_o <= 1'b1;
                        stallreq_for_div <= `NoStop;
                    end 
                end 
                `EXE_DIVU_OP:begin
                    if (div_ready_i == `DivResultNotReady) begin
                        div_opdata1_o <= reg1_i;
                        div_opdata2_o <= reg2_i;
                        div_start_o <= `DivStart;
                        signed_div_o <= 1'b0;
                        stallreq_for_div <= `Stop;
                    end else if(div_ready_i == `DivResultReady) begin
                        div_opdata1_o <= reg1_i;
                        div_opdata2_o <= reg2_i;
                        div_start_o <= `DivStop;
                        signed_div_o <= 1'b0;
                        stallreq_for_div <= `NoStop;
                    end
                end
                default: begin
                end
            endcase
        end
    end

    /*** mtc0 ***/
    always @( *) begin
        if (rst == `RstEnable) begin
            cp0_reg_waddr_o <= 5'b00000;
            cp0_reg_we_o <= `WriteDisable;
            cp0_reg_wdata_o <= `ZeroWord;
        end else if(aluop_i == `EXE_MTC0_OP) begin
            cp0_reg_waddr_o <= inst_i[15:11];
            cp0_reg_we_o <= `WriteEnable;
            cp0_reg_wdata_o <= reg1_i;
        end else begin
            cp0_reg_waddr_o <= 5'b00000;
            cp0_reg_we_o <= `WriteDisable;
            cp0_reg_wdata_o <= `ZeroWord;
        end
    end
    /*** Determine the Final Result ***/
    always @(*) begin
        wd_o <= wd_i;
        if (((aluop_i == `EXE_ADD_OP)  ||
            (aluop_i == `EXE_ADDI_OP) ||
            (aluop_i == `EXE_SUB_OP))  &&
            (ov_sum == 1'b1)) begin
            wreg_o <= `WriteDisable;
            end else begin
            wreg_o <= wreg_i;
            end
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
                `EXE_RES_ARITHMETIC:begin
                    wdata_o <= arithmeticres;
                end
                `EXE_RES_MUL:begin
                    wdata_o <= mulres[31:0];
                end
                `EXE_RES_JUMP_BRANCH:begin
                    wdata_o <= link_address_i;
                end
                default: begin
                    wdata_o <= `ZeroWord;
                end
            endcase
            end
    /*** Write HILO ***/
    always @(*) begin
        if (rst == `RstEnable) begin
            whilo_o     <= `WriteDisable;
            {hi_o,lo_o} <= {`ZeroWord,`ZeroWord};
            end else if ((aluop_i == `EXE_MULT_OP) ||
            (aluop_i == `EXE_MULTU_OP)) begin
            whilo_o <= `WriteEnable;
            {hi_o,lo_o} <= mulres;
            end else if (aluop_i == `EXE_MTHI_OP) begin
            whilo_o     <= `WriteEnable;
            {hi_o,lo_o} <= {reg1_i,LO};
            end else if (aluop_i == `EXE_MTLO_OP) begin
            whilo_o     <= `WriteEnable;
            {hi_o,lo_o} <= {HI,reg1_i};
            end else begin
            whilo_o     <= `WriteDisable;
            {hi_o,lo_o} <= {`ZeroWord,`ZeroWord};
        end
    end
    /*** Write HILO for MADD and MSUB and Division***/
    always @( *) begin
        if (rst == `RstEnable) begin
            whilo_o <= `WriteDisable;
            {hi_o,lo_o} <= {`ZeroWord,`ZeroWord};
        end else if((aluop_i == `EXE_MADD_OP) ||
        (aluop_i == `EXE_MADDU_OP) ||
        (aluop_i == `EXE_MSUB_OP) ||
        (aluop_i == `EXE_MSUBU_OP)) begin
            whilo_o <= `WriteEnable;
            {hi_o,lo_o} <= hilo_temp_for_madd_msub;
        end else if((aluop_i == `EXE_DIV_OP) ||
        (aluop_i == `EXE_DIVU_OP)) begin
            whilo_o <= `WriteEnable;
            {hi_o,lo_o} <= div_result_i;
        end
    end
    /*** Memory Instruction ***/
    assign aluop_o = aluop_i;
    assign mem_addr_o = reg1_i + {{16{inst_i[15]}},inst_i[15:0]};
    assign reg2_o = (mem_wreg_i == `WriteEnable && mem_wd_i == wd_o) ? mem_wdata_i:reg2_i;
    /*** Stall Control ***/
    always @(*) begin
        stallreq_from_ex <= stallreq_for_madd_msub || stallreq_for_div;
    end

endmodule //ex
