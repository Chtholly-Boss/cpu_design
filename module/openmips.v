`include "./define.v"

module openmips (input wire rst,
                 input wire clk,
                 input wire [`RegBus] rom_data_i,
                 output wire [`RegBus] rom_addr_o,
                 output wire rom_ce_o,
                 input wire [31:0] ram_data_i,
                 output wire [31:0] ram_addr_o,
                 output wire [31:0] ram_data_o,
                 output wire ram_we_o,
                 output wire [3:0] ram_sel_o,
                 output wire ram_ce_o,
                 input  wire [5:0] int_i,
                 output wire [31:0] timer_int_o);
    /*** Pipeline Control Signal ***/
    wire [5:0] stall;
    wire stallreq_from_id;
    wire stallreq_from_ex;
    
    /*** Connection between IF/ID and ID ***/
    wire [`InstAddrBus] pc;
    wire [`InstAddrBus] id_pc_i;
    wire [`InstBus] id_inst_i;
    
    /*** Connection between ID and ID/EX ***/
    wire [`AluOpBus] id_aluop_o;
    wire [`AluSelBus] id_alusel_o;
    wire [`RegBus] id_reg1_o;
    wire [`RegBus] id_reg2_o;
    wire id_wreg_o;
    wire [`RegAddrBus] id_wd_o;
    
    wire id_is_in_delayslot_i;
    wire id_branch_flag_o;
    wire [`RegBus] id_branch_target_address_o;
    wire id_is_in_delayslot_o;
    wire [`RegBus] id_link_addr_o;
    wire id_next_inst_in_delayslot_o;
    
    wire [`RegBus] id_inst_o;
    /*** Connection between ID/EX and EX ***/
    wire [`AluOpBus] ex_aluop_i;
    wire [`AluSelBus] ex_alusel_i;
    wire [`RegBus] ex_reg1_i;
    wire [`RegBus] ex_reg2_i;
    wire ex_wreg_i;
    wire [`RegAddrBus] ex_wd_i;
    wire [`RegBus] ex_link_address_i;
    wire ex_is_in_delayslot_i;
    wire [`RegBus] ex_inst_i;
    
    /*** Connection between EX and EX/MEM ***/
    wire ex_wreg_o;
    wire [`RegAddrBus] ex_wd_o;
    wire [`RegBus] ex_wdata_o;
    wire [`RegBus] ex_hi_o;
    wire [`RegBus] ex_lo_o;
    wire ex_whilo_o;
    wire [`DoubleRegBus] ex_hilo_temp_o;
    wire [1:0] ex_cnt_o;
    wire [`DoubleRegBus] ex_hilo_temp_i;
    wire [1:0] ex_cnt_i;
    wire [`AluOpBus] ex_aluop_o;
    wire [`RegBus] ex_mem_addr_o;
    wire [`RegBus] ex_reg2_o;
    wire ex_cp0_reg_we_o;
    wire [4:0] ex_cp0_reg_waddr_o;
    wire [31:0] ex_cp0_reg_wdata_o;
    
    wire [4:0] ex_cp0_reg_raddr_o;
    
    /*** Connection between EX/MEM and MEM ***/
    wire mem_wreg_i;
    wire [`RegAddrBus] mem_wd_i;
    wire [`RegBus] mem_wdata_i;
    wire [`RegBus] mem_hi_i;
    wire [`RegBus] mem_lo_i;
    wire mem_whilo_i;
    
    wire [`AluOpBus] mem_aluop_i;
    wire [`RegBus] mem_mem_addr_i;
    wire [`RegBus] mem_reg2_i;
    wire [`RegBus] mem_mem_data_i;
    
    wire mem_cp0_reg_we_i;
    wire [4:0] mem_cp0_reg_waddr_i;
    wire [31:0] mem_cp0_reg_wdata_i;
    /*** Connection between MEM and MEM/WB ***/
    wire mem_wreg_o;
    wire [`RegAddrBus] mem_wd_o;
    wire [`RegBus] mem_wdata_o;
    wire [`RegBus] mem_hi_o;
    wire [`RegBus] mem_lo_o;
    wire mem_whilo_o;
    wire mem_LLbit_we_o;
    wire mem_LLbit_value_o;
    wire mem_cp0_reg_we_o;
    wire [4:0] mem_cp0_reg_waddr_o;
    wire [31:0] mem_cp0_reg_wdata_o;
    
    /*** Connection between MEM/WB and Regfile***/
    wire wb_wreg_i;
    wire [`RegAddrBus] wb_wd_i;
    wire [`RegBus] wb_wdata_i;
    wire [`RegBus] wb_hi_i;
    wire [`RegBus] wb_lo_i;
    wire wb_whilo_i;

    wire wb_cp0_reg_we;
    wire [31:0] wb_cp0_reg_wdata;
    wire [4:0] wb_cp0_reg_waddr;
    /*** Connection between ID and Regfile ***/
    wire reg1_read;
    wire reg2_read;
    wire [`RegAddrBus] reg1_addr;
    wire [`RegAddrBus] reg2_addr;
    wire [`RegBus] reg1_data;
    wire [`RegBus] reg2_data;
    assign rom_addr_o = pc;
    
    /*** Connection between EX and DIV ***/
    wire signed_div_i;
    wire [31:0] opdata_1_i;
    wire [31:0] opdata_2_i;
    wire start_i;
    wire annul_i;
    wire [63:0] result_o;
    wire ready_o;
    
    /*** Connection with HILO ***/
    wire [`RegBus] hi_o;
    wire [`RegBus] lo_o;
    
    /*** Connection with LLbit reg ***/
    wire mem_LLbit_value_i;
    wire mem_LLbit_we_i;
    wire wb_LLbit_we_i;
    wire wb_LLbit_value_i;
    /*** Instantiate the modules ***/
    /*** Instruction Fetch ***/
    pc_reg  u_pc_reg (
    .clk           (clk),
    .rst           (rst),
    
    .pc            (pc),
    .ce            (rom_ce_o),
    
    .stall(stall),
    .branch_flag_i(id_branch_flag_o),
    .branch_target_address_i(id_branch_target_address_o)
    );
    
    if_id  u_if_id (
    .clk           (clk),
    .rst           (rst),
    .if_pc         (pc),
    .if_inst       (rom_data_i),
    
    .id_pc         (id_pc_i),
    .id_inst       (id_inst_i),
    
    .stall(stall)
    );
    /*** Instruction Decode ***/
    id u_id (
    .rst        (rst),
    .pc_i       (id_pc_i),
    .inst_i     (id_inst_i),
    
    .reg1_data_i(reg1_data),
    .reg2_data_i(reg2_data),
    
    .reg1_re_o  (reg1_read),
    .reg2_re_o  (reg2_read),
    .reg1_addr_o(reg1_addr),
    .reg2_addr_o(reg2_addr),
    
    .aluop_o    (id_aluop_o),
    .alusel_o   (id_alusel_o),
    .reg1_o     (id_reg1_o),
    .reg2_o     (id_reg2_o),
    .wd_o       (id_wd_o),
    .wreg_o     (id_wreg_o),
    
    .ex_wd_i    (ex_wd_o),
    .ex_wreg_i  (ex_wreg_o),
    .ex_wdata_i (ex_wdata_o),
    .ex_aluop_i (ex_aluop_o),
    
    .mem_wd_i   (mem_wd_o),
    .mem_wreg_i (mem_wreg_o),
    .mem_wdata_i(mem_wdata_o),
    
    .stallreq_from_id(stallreq_from_id),
    
    .branch_flag_o             (id_branch_flag_o),
    .branch_target_address_o   (id_branch_target_address_o),
    .is_in_delayslot_i         (id_is_in_delayslot_i),
    .is_in_delayslot_o         (id_is_in_delayslot_o),
    .link_addr_o               (id_link_addr_o),
    .next_inst_in_delayslot_o  (id_next_inst_in_delayslot_o),
    
    .inst_o(id_inst_o)
    );
    id_ex  u_id_ex (
    .clk                     (clk),
    .rst                     (rst),
    .id_aluop                (id_aluop_o),
    .id_alusel               (id_alusel_o),
    .id_reg1                 (id_reg1_o),
    .id_reg2                 (id_reg2_o),
    .id_wd                   (id_wd_o),
    .id_wreg                 (id_wreg_o),
    
    .ex_aluop                    (ex_aluop_i),
    .ex_alusel                   (ex_alusel_i),
    .ex_reg1                     (ex_reg1_i),
    .ex_reg2                     (ex_reg2_i),
    .ex_wd                       (ex_wd_i),
    .ex_wreg                     (ex_wreg_i),
    
    .stall(stall),
    
    .id_link_address           (id_link_addr_o),
    .id_is_in_delayslot        (id_is_in_delayslot_o),
    .next_inst_in_delayslot_i  (id_next_inst_in_delayslot_o),
    .ex_link_address           (ex_link_address_i),
    .ex_is_in_delayslot        (ex_is_in_delayslot_i),
    .is_in_delayslot_o         (id_is_in_delayslot_i),
    
    .id_inst(id_inst_o),
    .ex_inst(ex_inst_i)
    );
    /*** Execute ***/
    ex  u_ex (
    .rst                     (rst),
    . aluop_i                (ex_aluop_i),
    . alusel_i               (ex_alusel_i),
    .reg1_i                  (ex_reg1_i),
    .reg2_i                  (ex_reg2_i),
    .wd_i                    (ex_wd_i),
    .wreg_i                  (ex_wreg_i),
    
    .wd_o                    (ex_wd_o),
    .wreg_o                  (ex_wreg_o),
    .wdata_o                 (ex_wdata_o),
    
    .hi_i(hi_o),
    .lo_i(lo_o),
    
    .mem_hi_i(mem_hi_o),
    .mem_lo_i(mem_lo_o),
    .mem_whilo_i(mem_whilo_o),
    
    .wb_hi_i(wb_hi_i),
    .wb_lo_i(wb_lo_i),
    .wb_whilo_i(wb_whilo_i),
    
    .whilo_o(ex_whilo_o),
    .hi_o(ex_hi_o),
    .lo_o(ex_lo_o),
    
    .stallreq_from_ex(stallreq_from_ex),
    .hilo_temp_o(ex_hilo_temp_o),
    .hilo_temp_i(ex_hilo_temp_i),
    .cnt_o(ex_cnt_o),
    .cnt_i(ex_cnt_i),
    
    .div_result_i(result_o),
    .div_ready_i(ready_o),
    .div_opdata1_o(opdata_1_i),
    .div_opdata2_o(opdata_2_i),
    .div_start_o(start_i),
    .signed_div_o(signed_div_i),
    
    .link_address_i(ex_link_address_i),
    .is_in_delayslot_i(ex_is_in_delayslot_i),
    
    .inst_i(ex_inst_i),
    .aluop_o(ex_aluop_o),
    .mem_addr_o(ex_mem_addr_o),
    .reg2_o(ex_reg2_o),
    
    .mem_wd_i   (mem_wd_o),
    .mem_wreg_i (mem_wreg_o),
    .mem_wdata_i(mem_wdata_o),
    
    .cp0_reg_wdata_o(ex_cp0_reg_wdata_o),
    .cp0_reg_we_o(ex_cp0_reg_we_o),
    .cp0_reg_waddr_o(ex_cp0_reg_waddr_o),
    .mem_cp0_reg_waddr(mem_cp0_reg_waddr_o),
    .mem_cp0_reg_wdata(mem_cp0_reg_wdata_o),
    .mem_cp0_reg_we(mem_cp0_reg_we_o),
    .wb_cp0_reg_waddr(wb_cp0_reg_waddr),
    .wb_cp0_reg_wdata(wb_cp0_reg_wdata),
    .wb_cp0_reg_we(wb_cp0_reg_we),

    .cp0_reg_data_i(data_o)
    );
    ex_mem  u_ex_mem (
    .rst                     (rst),
    .clk                     (clk),
    .ex_wd                   (ex_wd_o),
    .ex_wreg                 (ex_wreg_o),
    .ex_wdata                (ex_wdata_o),
    
    .mem_wd                  (mem_wd_i),
    .mem_wreg                (mem_wreg_i),
    .mem_wdata               (mem_wdata_i),
    
    .ex_hi(ex_hi_o),
    .ex_lo(ex_lo_o),
    .ex_whilo(ex_whilo_o),
    .mem_hi(mem_hi_i),
    .mem_lo(mem_lo_i),
    .mem_whilo(mem_whilo_i),
    
    .stall(stall),
    .hilo_i(ex_hilo_temp_o),
    .hilo_o(ex_hilo_temp_i),
    .cnt_i(ex_cnt_o),
    .cnt_o(ex_cnt_i),
    
    .ex_aluop(ex_aluop_o),
    .ex_mem_addr(ex_mem_addr_o),
    .ex_reg2(ex_reg2_o),
    
    .mem_aluop(mem_aluop_i),
    .mem_mem_addr(mem_mem_addr_i),
    .mem_reg2(mem_reg2_i),
    
    .ex_cp0_reg_waddr(ex_cp0_reg_waddr_o),
    .ex_cp0_reg_wdata(ex_cp0_reg_wdata_o),
    .ex_cp0_reg_we(ex_cp0_reg_we_o),
    .mem_cp0_reg_waddr(mem_cp0_reg_waddr_i),
    .mem_cp0_reg_wdata(mem_cp0_reg_wdata_i),
    .mem_cp0_reg_we(mem_cp0_reg_we_i)
    );
    /*** Memory Access ***/
    mem  u_mem (
    .rst                     (rst),
    .wd_i                    (mem_wd_i),
    .wreg_i                  (mem_wreg_i),
    .wdata_i                 (mem_wdata_i),
    
    .wd_o                    (mem_wd_o),
    .wreg_o                  (mem_wreg_o),
    .wdata_o                 (mem_wdata_o),
    
    .hi_i(mem_hi_i),
    .lo_i(mem_lo_i),
    .whilo_i(mem_whilo_i),
    .hi_o(mem_hi_o),
    .lo_o(mem_lo_o),
    .whilo_o(mem_whilo_o),
    
    .reg2_i(mem_reg2_i),
    .aluop_i(mem_aluop_i),
    .mem_addr_i(mem_mem_addr_i),
    .mem_data_i(ram_data_i),
    .mem_addr_o(ram_addr_o),
    .mem_we_o(ram_we_o),
    .mem_sel_o(ram_sel_o),
    .mem_data_o(ram_data_o),
    .mem_ce_o(ram_ce_o),
    
    .LLbit_value_o(mem_LLbit_value_o),
    .LLbit_we_o(mem_LLbit_we_o),
    .LLbit_i(mem_LLbit_value_i),
    .wb_LLbit_value_i(wb_LLbit_value_i),
    .wb_LLbit_we_i(wb_LLbit_we_i),
    
    .cp0_reg_wdata_i(mem_cp0_reg_wdata_i),
    .cp0_reg_we_i(mem_cp0_reg_we_i),
    .cp0_reg_waddr_i(mem_cp0_reg_waddr_i),
    .cp0_reg_wdata_o(mem_cp0_reg_wdata_o),
    .cp0_reg_we_o(mem_cp0_reg_we_o),
    .cp0_reg_waddr_o(mem_cp0_reg_waddr_o)
    );
    mem_wb  u_mem_wb (
    .rst                     (rst),
    .clk                     (clk),
    .mem_wd                  (mem_wd_o),
    .mem_wreg                (mem_wreg_o),
    .mem_wdata               (mem_wdata_o),
    
    .wb_wd                   (wb_wd_i),
    .wb_wreg                 (wb_wreg_i),
    .wb_wdata                (wb_wdata_i),
    
    .mem_hi(mem_hi_o),
    .mem_lo(mem_lo_o),
    .mem_whilo(mem_whilo_o),
    .wb_hi(wb_hi_i),
    .wb_lo(wb_lo_i),
    .wb_whilo(wb_whilo_i),
    
    .stall(stall),
    .mem_LLbit_value(mem_LLbit_value_o),
    .mem_LLbit_we(mem_LLbit_we_o),
    .wb_LLbit_value(wb_LLbit_value_i),
    .wb_LLbit_we(wb_LLbit_we_i),
    
    .mem_cp0_reg_waddr(mem_cp0_reg_waddr_o),
    .mem_cp0_reg_wdata(mem_cp0_reg_wdata_o),
    .mem_cp0_reg_we(mem_cp0_reg_we_o),
    .wb_cp0_reg_waddr(wb_cp0_reg_waddr),
    .wb_cp0_reg_wdata(wb_cp0_reg_wdata),
    .wb_cp0_reg_we(wb_cp0_reg_we)
    );
    /*** Register File ***/
    regfile u_regfile(
    .clk    (clk),
    .rst    (rst),
    .waddr  (wb_wd_i),
    .wdata  (wb_wdata_i),
    .we     (wb_wreg_i),
    .re_1   (reg1_read),
    .raddr_1(reg1_addr),
    .rdata_1(reg1_data),
    .re_2   (reg2_read),
    .raddr_2(reg2_addr),
    .rdata_2(reg2_data)
    );
    /*** HILO ***/
    hilo_reg  u_hilo_reg (
    .rst                     (rst),
    .clk                     (clk),
    .we                      (wb_whilo_i),
    .hi_i                    (wb_hi_i),
    .lo_i                    (wb_lo_i),
    
    .hi_o                    (hi_o),
    .lo_o                    (lo_o)
    );
    /*** Stall Control ***/
    ctrl  u_ctrl (
    .rst                     (rst),
    .stallreq_from_id        (stallreq_from_id),
    .stallreq_from_ex        (stallreq_from_ex),
    
    .stall                   (stall)
    );
    /*** Division Module ***/
    div  u_div (
    .clk                     (clk),
    .rst                     (rst),
    .signed_div_i            (signed_div_i),
    .opdata_1_i              (opdata_1_i),
    .opdata_2_i              (opdata_2_i),
    .start_i                 (start_i),
    .annul_i                 (1'b0),
    
    .result_o                (result_o),
    .ready_o                 (ready_o)
    );
    /*** LLbit reg ***/
    wire flush;
    assign flush = 1'b0;
    LLbit_reg  u_LLbit_reg (
    .clk                     (clk),
    .rst                     (rst),
    .flush                   (flush),
    .LLbit_i                 (wb_LLbit_value_i),
    .we                      (wb_LLbit_we_i),
    
    .LLbit_o                 (mem_LLbit_value_i)
    );
    /*** Connection with CP0 ***/
    wire  [31:0]  data_o;
    wire  [31:0]  count_o;
    wire  [31:0]  compare_o;
    wire  [31:0]  status_o;
    wire  [31:0]  cause_o;
    wire  [31:0]  epc_o;
    wire  [31:0]  config_o;
    wire  [31:0]  prid_o;
    /*** CP0 ***/
    cp0_reg  u_cp0_reg (
    .clk                     (clk),
    .rst                     (rst),
    .we_i                    (wb_cp0_reg_we),
    .waddr_i                 (wb_cp0_reg_waddr),
    .raddr_i                 (ex_cp0_reg_raddr_o),
    .data_i                  (wb_cp0_reg_wdata),
    .int_i                   (int_i),
    
    .data_o                  (data_o),
    .count_o                 (count_o),
    .compare_o               (compare_o),
    .status_o                (status_o),
    .cause_o                 (cause_o),
    .epc_o                   (epc_o),
    .config_o                (config_o),
    .prid_o                  (prid_o),
    .timer_int_o             (timer_int_o)
    );
endmodule //openmips
