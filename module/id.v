`include "define.v"
module id (input wire rst,
           input wire [`InstAddrBus] pc_i,
           input wire [`InstBus] inst_i,
           input wire [`RegBus] reg1_data_i,
           input wire [`RegBus] reg2_data_i,
           output reg reg1_re_o,
           output reg [`RegAddrBus] reg1_addr_o,
           output reg reg2_re_o,
           output reg [`RegAddrBus] reg2_addr_o,
           output reg [`AluOpBus] aluop_o,
           output reg [`AluSelBus] alusel_o,
           output reg [`RegBus] reg1_o,
           output reg [`RegBus] reg2_o,
           output reg [`RegAddrBus] wd_o,
           output reg wreg_o,
           input wire ex_wreg_i,
           input wire [`RegAddrBus] ex_wd_i,
           input wire [`RegBus] ex_wdata_i,
           input wire mem_wreg_i,
           input wire [`RegAddrBus] mem_wd_i,
           input wire [`RegBus] mem_wdata_i);
    /*** Definition***/
    wire [5:0] op_1 = inst_i[31:26];
    wire [4:0] op_2 = inst_i[10:6];
    wire [5:0] op_3 = inst_i[5:0];
    wire [4:0] op_4 = inst_i[20:16];
    
    reg[`RegBus] imm; // instant value
    reg instvalid;
    /*** Decode ***/
    always @(*) begin
        if (rst == `RstEnable) begin
            aluop_o     <= `EXE_NOP_OP;
            alusel_o    <= `EXE_RES_NOP;
            wd_o        <= `NOPRegAddr;
            wreg_o      <= `WriteDisable;
            instvalid   <= `InstValid;
            reg1_re_o   <= `ReadDisable;
            reg2_re_o   <= `ReadDisable;
            reg1_addr_o <= `NOPRegAddr;
            reg2_addr_o <= `NOPRegAddr;
            imm         <= `ZeroWord;
            end else begin
            /*** Initialize ***/
            aluop_o  <= `EXE_NOP_OP;
            alusel_o <= `EXE_RES_NOP;
            
            wd_o   <= inst_i[15:11];
            wreg_o <= `WriteDisable;
            
            instvalid <= `InstInvalid;
            
            reg1_re_o   <= `ReadDisable;
            reg2_re_o   <= `ReadDisable;
            reg1_addr_o <= inst_i[25:21];
            reg2_addr_o <= inst_i[20:16];
            
            imm <= `ZeroWord;
            /*** operation check ***/
            case (op_1)
                `EXE_SPECIAL_INST:begin
                    case (op_2)
                        5'b00000: begin
                            case (op_3)
                                /*** Move Instructions***/
                                `EXE_MFHI:begin
                                    wreg_o    <= `WriteDisable;
                                    aluop_o   <= `EXE_MFHI_OP;
                                    alusel_o  <= `EXE_RES_MOVE;
                                    reg1_re_o <= `ReadDisable;
                                    reg2_re_o <= `ReadDisable;
                                    instvalid <= `InstValid;
                                end
                                
                                `EXE_MFLO:begin
                                    wreg_o    <= `WriteDisable;
                                    aluop_o   <= `EXE_MFLO_OP;
                                    alusel_o  <= `EXE_RES_MOVE;
                                    reg1_re_o <= `ReadDisable;
                                    reg2_re_o <= `ReadDisable;
                                    instvalid <= `InstValid;
                                end
                                
                                `EXE_MTHI:begin
                                    wreg_o    <= `WriteDisable;
                                    aluop_o   <= `EXE_MTHI_OP;
                                    reg1_re_o <= `ReadEnable;
                                    reg2_re_o <= `ReadDisable;
                                    instvalid <= `InstValid;
                                end
                                
                                `EXE_MTLO:begin
                                    wreg_o    <= `WriteDisable;
                                    aluop_o   <= `EXE_MTLO_OP;
                                    reg1_re_o <= `ReadEnable;
                                    reg2_re_o <= `ReadDisable;
                                    instvalid <= `InstValid;
                                end
                                
                                `EXE_MOVN:begin
                                    aluop_o   <= `EXE_MOVN_OP;
                                    alusel_o  <= `EXE_RES_MOVE;
                                    reg1_re_o <= `ReadEnable;
                                    reg2_re_o <= `ReadEnable;
                                    instvalid <= `InstValid;
                                    
                                    if (reg2_o != `ZeroWord) begin
                                        wreg_o <= `WriteEnable;
                                        end else begin
                                            wreg_o <= `WriteDisable;
                                        end
                                    end
                                    
                                    `EXE_MOVZ:begin
                                        aluop_o   <= `EXE_MOVZ_OP;
                                        alusel_o  <= `EXE_RES_MOVE;
                                        reg1_re_o <= `ReadEnable;
                                        reg2_re_o <= `ReadEnable;
                                        instvalid <= `InstValid;
                                        
                                        if (reg2_o == `ZeroWord) begin
                                            wreg_o <= `WriteEnable;
                                            end else begin
                                                wreg_o <= `WriteDisable;
                                            end
                                        end
                                        /*** Logic Instructions ***/
                                        `EXE_OR: begin
                                            wreg_o    <= `WriteEnable;
                                            aluop_o   <= `EXE_OR_OP;
                                            alusel_o  <= `EXE_RES_LOGIC;
                                            reg1_re_o <= `ReadEnable;
                                            reg2_re_o <= `ReadEnable;
                                            instvalid <= `InstValid;
                                        end
                                        
                                        `EXE_AND: begin
                                            wreg_o    <= `WriteEnable;
                                            aluop_o   <= `EXE_AND_OP;
                                            alusel_o  <= `EXE_RES_LOGIC;
                                            reg1_re_o <= `ReadEnable;
                                            reg2_re_o <= `ReadEnable;
                                            instvalid <= `InstValid;
                                        end
                                        
                                        `EXE_XOR: begin
                                            wreg_o    <= `WriteEnable;
                                            aluop_o   <= `EXE_XOR_OP;
                                            alusel_o  <= `EXE_RES_LOGIC;
                                            reg1_re_o <= `ReadEnable;
                                            reg2_re_o <= `ReadEnable;
                                            instvalid <= `InstValid;
                                        end
                                        
                                        `EXE_NOR: begin
                                            wreg_o    <= `WriteEnable;
                                            aluop_o   <= `EXE_NOR_OP;
                                            alusel_o  <= `EXE_RES_LOGIC;
                                            reg1_re_o <= `ReadEnable;
                                            reg2_re_o <= `ReadEnable;
                                            instvalid <= `InstValid;
                                        end
                                        
                                        `EXE_SLLV: begin
                                            wreg_o    <= `WriteEnable;
                                            aluop_o   <= `EXE_SLLV_OP;
                                            alusel_o  <= `EXE_RES_SHIFT;
                                            reg1_re_o <= `ReadEnable;
                                            reg2_re_o <= `ReadEnable;
                                            instvalid <= `InstValid;
                                        end
                                        
                                        `EXE_SRLV: begin
                                            wreg_o    <= `WriteEnable;
                                            aluop_o   <= `EXE_SRLV_OP;
                                            alusel_o  <= `EXE_RES_SHIFT;
                                            reg1_re_o <= `ReadEnable;
                                            reg2_re_o <= `ReadEnable;
                                            instvalid <= `InstValid;
                                        end
                                        
                                        `EXE_SRAV: begin
                                            wreg_o    <= `WriteEnable;
                                            aluop_o   <= `EXE_SRAV_OP;
                                            alusel_o  <= `EXE_RES_SHIFT;
                                            reg1_re_o <= `ReadEnable;
                                            reg2_re_o <= `ReadEnable;
                                            instvalid <= `InstValid;
                                        end
                                        
                                        `EXE_SYNC: begin
                                            wreg_o    <= `WriteDisable;
                                            aluop_o   <= `EXE_NOP_OP;
                                            alusel_o  <= `EXE_RES_NOP;
                                            reg1_re_o <= `ReadEnable;
                                            reg2_re_o <= `ReadEnable;
                                            instvalid <= `InstValid;
                                        end
                                        /*** Arithmetic Instructions ***/
                                        `EXE_SLT:begin
                                            wreg_o    <= `WriteEnable;
                                            aluop_o   <= `EXE_SLT_OP;
                                            alusel_o  <= `EXE_RES_ARITHMETIC;
                                            reg1_re_o <= `ReadEnable;
                                            reg2_re_o <= `ReadEnable;
                                            instvalid <= `InstValid;
                                        end
                                        
                                        `EXE_SLTU:begin
                                            wreg_o    <= `WriteEnable;
                                            aluop_o   <= `EXE_SLTU_OP;
                                            alusel_o  <= `EXE_RES_ARITHMETIC;
                                            reg1_re_o <= `ReadEnable;
                                            reg2_re_o <= `ReadEnable;
                                            instvalid <= `InstValid;
                                        end
                                        
                                        `EXE_ADD:begin
                                            wreg_o    <= `WriteEnable;
                                            aluop_o   <= `EXE_ADD_OP;
                                            alusel_o  <= `EXE_RES_ARITHMETIC;
                                            reg1_re_o <= `ReadEnable;
                                            reg2_re_o <= `ReadEnable;
                                            instvalid <= `InstValid;
                                        end
                                        
                                        `EXE_ADDU:begin
                                            wreg_o    <= `WriteEnable;
                                            aluop_o   <= `EXE_ADDU_OP;
                                            alusel_o  <= `EXE_RES_ARITHMETIC;
                                            reg1_re_o <= `ReadEnable;
                                            reg2_re_o <= `ReadEnable;
                                            instvalid <= `InstValid;
                                        end
                                        
                                        `EXE_SUB:begin
                                            wreg_o    <= `WriteEnable;
                                            aluop_o   <= `EXE_SUB_OP;
                                            alusel_o  <= `EXE_RES_ARITHMETIC;
                                            reg1_re_o <= `ReadEnable;
                                            reg2_re_o <= `ReadEnable;
                                            instvalid <= `InstValid;
                                        end
                                        
                                        `EXE_SUBU:begin
                                            wreg_o    <= `WriteEnable;
                                            aluop_o   <= `EXE_SUBU_OP;
                                            alusel_o  <= `EXE_RES_ARITHMETIC;
                                            reg1_re_o <= `ReadEnable;
                                            reg2_re_o <= `ReadEnable;
                                            instvalid <= `InstValid;
                                        end
                                        
                                        `EXE_MULT:begin
                                            wreg_o    <= `WriteDisable;
                                            aluop_o   <= `EXE_MULT_OP;
                                            reg1_re_o <= `ReadEnable;
                                            reg2_re_o <= `ReadEnable;
                                            instvalid <= `InstValid;
                                        end
                                        
                                        `EXE_MULTU:begin
                                            wreg_o    <= `WriteDisable;
                                            aluop_o   <= `EXE_MULTU_OP;
                                            reg1_re_o <= `ReadEnable;
                                            reg2_re_o <= `ReadEnable;
                                            instvalid <= `InstValid;
                                        end
                                        
                                        default:begin
                                            
                                        end
                            endcase
                        end
                        default:begin
                            
                        end
                    endcase
                end
                `EXE_SPECIAL2_INST:begin
                    case (op_3)
                        `EXE_CLZ:begin
                            wreg_o    <= `WriteEnable;
                            aluop_o   <= `EXE_CLZ_OP;
                            alusel_o  <= `EXE_RES_ARITHMETIC;
                            reg1_re_o <= `ReadEnable;
                            reg2_re_o <= `ReadDisable;
                            instvalid <= `InstValid;
                        end
                        
                        `EXE_CLO:begin
                            wreg_o    <= `WriteEnable;
                            aluop_o   <= `EXE_CLO_OP;
                            alusel_o  <= `EXE_RES_ARITHMETIC;
                            reg1_re_o <= `ReadEnable;
                            reg2_re_o <= `ReadDisable;
                            instvalid <= `InstValid;
                        end
                        
                        `EXE_MUL:begin
                            wreg_o    <= `WriteEnable;
                            aluop_o   <= `EXE_MUL_OP;
                            alusel_o  <= `EXE_RES_MUL;
                            reg1_re_o <= `ReadEnable;
                            reg2_re_o <= `ReadEnable;
                            instvalid <= `InstValid;
                        end
                        default:
                    endcase
                end
                /*** Logic Instruction ***/
                `EXE_ORI:begin
                    wreg_o    <= `WriteEnable;
                    wd_o      <= inst_i[20:16];
                    aluop_o   <= `EXE_ORI_OP;
                    alusel_o  <= `EXE_RES_LOGIC;
                    reg1_re_o <= `ReadEnable;
                    reg2_re_o <= `ReadDisable;
                    imm       <= {16'h0,inst_i[15:0]};
                    instvalid <= `InstValid;
                end
                
                `EXE_ANDI:begin
                    wreg_o    <= `WriteEnable;
                    wd_o      <= inst_i[20:16];
                    aluop_o   <= `EXE_ANDI_OP;
                    alusel_o  <= `EXE_RES_LOGIC;
                    reg1_re_o <= `ReadEnable;
                    reg2_re_o <= `ReadDisable;
                    imm       <= {16'h0,inst_i[15:0]};
                    instvalid <= `InstValid;
                end
                
                `EXE_XORI:begin
                    wreg_o    <= `WriteEnable;
                    wd_o      <= inst_i[20:16];
                    aluop_o   <= `EXE_XORI_OP;
                    alusel_o  <= `EXE_RES_LOGIC;
                    reg1_re_o <= `ReadEnable;
                    reg2_re_o <= `ReadDisable;
                    imm       <= {16'h0,inst_i[15:0]};
                    instvalid <= `InstValid;
                end
                
                `EXE_LUI:begin
                    wreg_o    <= `WriteEnable;
                    wd_o      <= inst_i[20:16];
                    aluop_o   <= `EXE_ORI_OP;
                    alusel_o  <= `EXE_RES_LOGIC;
                    reg1_re_o <= `ReadEnable;
                    reg2_re_o <= `ReadDisable;
                    imm       <= {inst_i[15:0],16'h0};
                    instvalid <= `InstValid;
                end
                
                `EXE_PREF:begin
                    wreg_o    <= `WriteDisable;
                    aluop_o   <= `EXE_NOP_OP;
                    alusel_o  <= `EXE_RES_NOP;
                    reg1_re_o <= `ReadDisable;
                    reg2_re_o <= `ReadDisable;
                    instvalid <= `InstValid;
                end
                /*** Arithmetic Instruction ***/
                `EXE_SLTI:begin
                    wreg_o    <= `WriteEnable;
                    aluop_o   <= `EXE_SLTI_OP;
                    alusel_o  <= `EXE_RES_ARITHMETIC;
                    reg1_re_o <= `ReadEnable;
                    reg2_re_o <= `ReadDisable;
                    imm       <= {{16{inst_i[15]}},inst_i[15:0]};
                    wd_o      <= inst_i[20:16];
                    instvalid <= `InstValid;
                end
                
                `EXE_SLTIU:begin
                    wreg_o    <= `WriteEnable;
                    aluop_o   <= `EXE_SLTIU_OP;
                    alusel_o  <= `EXE_RES_ARITHMETIC;
                    reg1_re_o <= `ReadEnable;
                    reg2_re_o <= `ReadDisable;
                    imm       <= {{16{inst_i[15]}},inst_i[15:0]};
                    wd_o      <= inst_i[20:16];
                    instvalid <= `InstValid;
                end
                
                `EXE_ADDI:begin
                    wreg_o    <= `WriteEnable;
                    aluop_o   <= `EXE_ADDI_OP;
                    alusel_o  <= `EXE_RES_ARITHMETIC;
                    reg1_re_o <= `ReadEnable;
                    reg2_re_o <= `ReadDisable;
                    imm       <= {{16{inst_i[15]}},inst_i[15:0]};
                    wd_o      <= inst_i[20:16];
                    instvalid <= `InstValid;
                end
                
                `EXE_ADDIU:begin
                    wreg_o    <= `WriteEnable;
                    aluop_o   <= `EXE_ADDIU_OP;
                    alusel_o  <= `EXE_RES_ARITHMETIC;
                    reg1_re_o <= `ReadEnable;
                    reg2_re_o <= `ReadDisable;
                    imm       <= {{16{inst_i[15]}},inst_i[15:0]};
                    wd_o      <= inst_i[20:16];
                    instvalid <= `InstValid;
                end
                /*** default ***/
                default :begin
                end
            endcase
            if (inst_i[31:21] == 11'h0) begin
                case (op_3)
                    /*** Logic Instruction ***/
                    `EXE_SLL:begin
                        wreg_o    <= `WriteEnable;
                        aluop_o   <= `EXE_SLL_OP;
                        alusel_o  <= `EXE_RES_SHIFT;
                        reg1_re_o <= `ReadDisable;
                        reg2_re_o <= `ReadEnable;
                        imm[4:0]  <= inst_i[10:6];
                        wd_o      <= inst_i[15:11];
                        instvalid <= `InstValid;
                    end
                    
                    `EXE_SRL:begin
                        wreg_o    <= `WriteEnable;
                        aluop_o   <= `EXE_SRL_OP;
                        alusel_o  <= `EXE_RES_SHIFT;
                        reg1_re_o <= `ReadDisable;
                        reg2_re_o <= `ReadEnable;
                        imm[4:0]  <= inst_i[10:6];
                        wd_o      <= inst_i[15:11];
                        instvalid <= `InstValid;
                    end
                    
                    `EXE_SRA:begin
                        wreg_o    <= `WriteEnable;
                        aluop_o   <= `EXE_SRA_OP;
                        alusel_o  <= `EXE_RES_SHIFT;
                        reg1_re_o <= `ReadDisable;
                        reg2_re_o <= `ReadEnable;
                        imm[4:0]  <= inst_i[10:6];
                        wd_o      <= inst_i[15:11];
                        instvalid <= `InstValid;
                    end
                endcase
            end
        end
    end
    /*** Determine operands based on Signals ***/
    always @(*) begin
        if (rst == `RstEnable) begin
            reg1_o <= `ZeroWord;
            end else if (reg1_re_o == `ReadEnable && ex_wreg_i == `WriteEnable
            && reg1_addr_o == ex_wd_i) begin
            /*** RAW between Decode and Execute ***/
            reg1_o <= ex_wdata_i;
            end else if (reg1_re_o == `ReadEnable && mem_wreg_i == `WriteEnable
            && reg1_addr_o == mem_wd_i) begin
            /*** RAW between Decode and Memory Access ***/
            reg1_o <= mem_wdata_i;
            end else if (reg1_re_o == `ReadEnable) begin
            reg1_o <= reg1_data_i;
            end else if (reg1_re_o == `ReadDisable) begin
            reg1_o <= imm;
            end else begin
            reg1_o <= `ZeroWord;
        end
    end
    
    /*** Determine operands based on Signals ***/
    always @(*) begin
        if (rst == `RstEnable) begin
            reg2_o <= `ZeroWord;
            end else if (reg2_re_o == `ReadEnable && ex_wreg_i == `WriteEnable
            && reg2_addr_o == ex_wd_i) begin
            reg2_o <= ex_wdata_i;
            end else if (reg2_re_o == `ReadEnable && mem_wreg_i == `WriteEnable
            && reg2_addr_o == mem_wd_i) begin
            reg2_o <= mem_wdata_i;
            end else if (reg2_re_o == `ReadEnable) begin
            reg2_o <= reg2_data_i;
            end else if (reg2_re_o == `ReadDisable) begin
            reg2_o <= imm;
            end else begin
            reg2_o <= `ZeroWord;
        end
    end
endmodule //id
