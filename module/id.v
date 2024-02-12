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
                /*** ori instruction ***/
                `EXE_ORI:begin
                    wreg_o    <= `WriteEnable;
                    wd_o      <= inst_i[20:16];
                    aluop_o   <= `EXE_OR_OP;
                    alusel_o  <= `EXE_RES_LOGIC;
                    reg1_re_o <= `ReadEnable;
                    reg2_re_o <= `ReadDisable;
                    imm       <= {16'h0,inst_i[15:0]};
                    instvalid <= `InstValid;
                end
                /*** default ***/
                default :begin
                end
            endcase
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
            && reg2_addr_o == ex_wreg_i) begin
            reg2_o <= ex_wdata_i;
            end else if (reg2_re_o == `ReadEnable && mem_wreg_i == `WriteEnable
            && reg2_addr_o == mem_wreg_i) begin
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
