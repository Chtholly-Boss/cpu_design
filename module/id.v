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
           input wire [`RegBus] mem_wdata_i,
           output wire stallreq_from_id,
           
           output reg branch_flag_o,
           output reg [31:0] branch_target_address_o,
           output reg is_in_delayslot_o,
           output reg [31:0] link_addr_o,
           output reg next_inst_in_delayslot_o,
           input  wire is_in_delayslot_i );

    /*** Definition***/
    wire [5:0] op_1 = inst_i[31:26];
    wire [4:0] op_2 = inst_i[10:6];
    wire [5:0] op_3 = inst_i[5:0];
    wire [4:0] op_4 = inst_i[20:16];
    
    reg[`RegBus] imm; // instant value
    reg instvalid;

    wire [`RegBus] pc_plus_8;
    wire [`RegBus] pc_plus_4;

    wire [`RegBus] imm_sll2_signedext;

    assign pc_plus_8 = pc_i + 8;
    assign pc_plus_4 = pc_i + 4;

    assign imm_sll2_signedext = {{14{inst_i[15]}},inst_i[15:0],2'b00};

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
            link_addr_o <= `ZeroWord;
            branch_flag_o <= `NotBranch;
            branch_target_address_o <= `ZeroWord;
            next_inst_in_delayslot_o <= `NotInDelaySlot;
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
            link_addr_o <= `ZeroWord;
            branch_flag_o <= `NotBranch;
            branch_target_address_o <= `ZeroWord;
            next_inst_in_delayslot_o <= `NotInDelaySlot;
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
                                /*** Multiplication ***/
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
                                /*** Division ***/
                                `EXE_DIV:begin
                                    wreg_o    <= `WriteDisable;
                                    aluop_o   <= `EXE_DIV_OP;
                                    reg1_re_o <= `ReadEnable;
                                    reg2_re_o <= `ReadEnable;
                                    instvalid <= `InstValid;
                                end

                                `EXE_DIVU:begin
                                    wreg_o    <= `WriteDisable;
                                    aluop_o   <= `EXE_DIVU_OP;
                                    reg1_re_o <= `ReadEnable;
                                    reg2_re_o <= `ReadEnable;
                                    instvalid <= `InstValid;
                                end
                                /*** JUMP Instruction ***/
                                `EXE_JR:begin
                                    wreg_o <= `WriteDisable;
                                    aluop_o <= `EXE_JR_OP;
                                    alusel_o <= `EXE_RES_JUMP_BRANCH;
                                    reg1_re_o <= `ReadEnable;
                                    reg2_re_o <= `ReadDisable;
                                    link_addr_o <= `ZeroWord;
                                    branch_target_address_o <= reg1_o;
                                    branch_flag_o <= `Branch;
                                    next_inst_in_delayslot_o <= `InDelaySlot;
                                    instvalid <= `InstValid;
                                end

                                `EXE_JALR:begin
                                    wreg_o <= `WriteEnable;
                                    aluop_o <= `EXE_JALR_OP;
                                    alusel_o <= `EXE_RES_JUMP_BRANCH;
                                    reg1_re_o <= `ReadEnable;
                                    reg2_re_o <= `ReadDisable;
                                    wd_o <= inst_i[15:11];
                                    link_addr_o <= pc_plus_8;
                                    branch_target_address_o <= reg1_o;
                                    branch_flag_o <= `Branch;
                                    next_inst_in_delayslot_o <= `InDelaySlot;
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

                        `EXE_MADD:begin
                            wreg_o <= `WriteDisable;
                            aluop_o <= `EXE_MADD_OP;
                            alusel_o <= `EXE_RES_MUL;
                            reg1_re_o <= `ReadEnable;
                            reg2_re_o <= `ReadEnable;
                            instvalid <= `InstValid;
                        end

                        `EXE_MADDU:begin
                            wreg_o <= `WriteDisable;
                            aluop_o <= `EXE_MADDU_OP;
                            alusel_o <= `EXE_RES_MUL;
                            reg1_re_o <= `ReadEnable;
                            reg2_re_o <= `ReadEnable;
                            instvalid <= `InstValid;
                        end

                        `EXE_MSUB:begin
                            wreg_o <= `WriteDisable;
                            aluop_o <= `EXE_MSUB_OP;
                            alusel_o <= `EXE_RES_MUL;
                            reg1_re_o <= `ReadEnable;
                            reg2_re_o <= `ReadEnable;
                            instvalid <= `InstValid;
                        end

                        `EXE_MSUBU:begin
                            wreg_o <= `WriteDisable;
                            aluop_o <= `EXE_MSUBU_OP;
                            alusel_o <= `EXE_RES_MUL;
                            reg1_re_o <= `ReadEnable;
                            reg2_re_o <= `ReadEnable;
                            instvalid <= `InstValid;
                        end
                        default:begin
                            
                        end
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
                /*** JUMP Instruction ***/
                `EXE_J:begin
                    wreg_o <= `WriteDisable;
                    aluop_o <= `EXE_J_OP;
                    alusel_o <= `EXE_RES_JUMP_BRANCH;
                    reg1_re_o <= `ReadDisable;
                    reg2_re_o <= `ReadDisable;
                    link_addr_o <= `ZeroWord;
                    branch_target_address_o <= {pc_plus_4[31:28],inst_i[25:0],2'b00};
                    branch_flag_o <= `Branch;
                    next_inst_in_delayslot_o <= `InDelaySlot;
                    instvalid <= `InstValid;
                end

                `EXE_JAL:begin
                    wreg_o <= `WriteEnable;
                    aluop_o <= `EXE_JAL_OP;
                    alusel_o <= `EXE_RES_JUMP_BRANCH;
                    reg1_re_o <= `ReadDisable;
                    reg2_re_o <= `ReadDisable;
                    wd_o <= 5'b11111;
                    link_addr_o <= pc_plus_8;
                    branch_target_address_o <= {pc_plus_4[31:28],inst_i[25:0],2'b00};
                    branch_flag_o <= `Branch;
                    next_inst_in_delayslot_o <= `InDelaySlot;
                    instvalid <= `InstValid;
                end

                `EXE_BEQ:begin
                    wreg_o <= `WriteDisable;
                    aluop_o <= `EXE_BEQ_OP;
                    alusel_o <= `EXE_RES_JUMP_BRANCH;
                    reg1_re_o <= `ReadEnable;
                    reg2_re_o <= `ReadEnable;
                    instvalid <= `InstValid;
                    if (reg1_o == reg2_o) begin
                        branch_flag_o <= `Branch;
                        next_inst_in_delayslot_o <= `InDelaySlot;
                        branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
                    end
                end

                `EXE_BGTZ:begin
                    wreg_o <= `WriteDisable;
                    aluop_o <= `EXE_BGTZ_OP;
                    alusel_o <= `EXE_RES_JUMP_BRANCH;
                    reg1_re_o <= `ReadEnable;
                    reg2_re_o <= `ReadDisable;
                    instvalid <= `InstValid;
                    if ((reg1_o[31] == 1'b0) && (reg1_o != `ZeroWord)) begin
                        branch_flag_o <= `Branch;
                        next_inst_in_delayslot_o <= `InDelaySlot;
                        branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
                    end
                end

                `EXE_BLEZ:begin
                    wreg_o <= `WriteDisable;
                    aluop_o <= `EXE_BLEZ_OP;
                    alusel_o <= `EXE_RES_JUMP_BRANCH;
                    reg1_re_o <= `ReadEnable;
                    reg2_re_o <= `ReadDisable;
                    instvalid <= `InstValid;
                    if ((reg1_o[31] == 1'b1) || (reg1_o != `ZeroWord)) begin
                        branch_flag_o <= `Branch;
                        next_inst_in_delayslot_o <= `InDelaySlot;
                        branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
                    end
                end

                `EXE_BNE:begin
                    wreg_o <= `WriteDisable;
                    aluop_o <= `EXE_BNE_OP;
                    alusel_o <= `EXE_RES_JUMP_BRANCH;
                    reg1_re_o <= `ReadEnable;
                    reg2_re_o <= `ReadEnable;
                    instvalid <= `InstValid;
                    if (reg1_o != reg2_o) begin
                        branch_flag_o <= `Branch;
                        next_inst_in_delayslot_o <= `InDelaySlot;
                        branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
                    end
                end

                `EXE_REGIMM_INST:begin
                    case (op_4)
                        `EXE_BGEZ:begin
                            wreg_o <= `WriteDisable;
                            aluop_o <= `EXE_BGEZ_OP;
                            alusel_o <= `EXE_RES_JUMP_BRANCH;
                            reg1_re_o <= `ReadEnable;
                            reg2_re_o <= `ReadDisable;
                            instvalid <= `InstValid;
                            if (reg1_o[31] == 1'b0) begin
                                branch_flag_o <= `Branch;
                                next_inst_in_delayslot_o <= `InDelaySlot;
                                branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
                            end
                        end

                        `EXE_BGEZAL:begin
                            wreg_o <= `WriteEnable;
                            aluop_o <= `EXE_BGEZAL_OP;
                            alusel_o <= `EXE_RES_JUMP_BRANCH;
                            reg1_re_o <= `ReadEnable;
                            reg2_re_o <= `ReadDisable;
                            link_addr_o <= pc_plus_8;
                            wd_o <= 5'b11111;
                            instvalid <= `InstValid;
                            if (reg1_o[31] == 1'b0) begin
                                branch_flag_o <= `Branch;
                                next_inst_in_delayslot_o <= `InDelaySlot;
                                branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
                            end
                        end

                        `EXE_BLTZ:begin
                            wreg_o <= `WriteDisable;
                            aluop_o <= `EXE_BLTZ_OP;
                            alusel_o <= `EXE_RES_JUMP_BRANCH;
                            reg1_re_o <= `ReadEnable;
                            reg2_re_o <= `ReadDisable;
                            instvalid <= `InstValid;
                            if (reg1_o[31] == 1'b1) begin
                                branch_flag_o <= `Branch;
                                next_inst_in_delayslot_o <= `InDelaySlot;
                                branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
                            end
                        end

                        `EXE_BLTZAL:begin
                            wreg_o <= `WriteEnable;
                            aluop_o <= `EXE_BLTZAL_OP;
                            alusel_o <= `EXE_RES_JUMP_BRANCH;
                            reg1_re_o <= `ReadEnable;
                            reg2_re_o <= `ReadDisable;
                            link_addr_o <= pc_plus_8;
                            wd_o <= 5'b11111;
                            instvalid <= `InstValid;
                            if (reg1_o[31] == 1'b1) begin
                                branch_flag_o <= `Branch;
                                next_inst_in_delayslot_o <= `InDelaySlot;
                                branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
                            end
                        end
                    endcase
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
    /*** delayslot check ***/
    always @( *) begin
        if (rst == `RstEnable) begin
            is_in_delayslot_o <= `NotInDelaySlot;
        end else begin
            is_in_delayslot_o <= is_in_delayslot_i;
        end
    end
    assign stallreq_from_id = `NoStop;
endmodule //id
