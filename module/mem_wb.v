`include "define.v"

module mem_wb (input wire rst,
               input wire clk,
               input wire [`RegAddrBus] mem_wd,
               input wire mem_wreg,
               input wire [`RegBus] mem_wdata,
               output reg [`RegAddrBus] wb_wd,
               output reg wb_wreg,
               output reg [`RegBus] wb_wdata,
               input  wire mem_whilo,
               input  wire [`RegBus] mem_hi,
               input  wire [`RegBus] mem_lo,
               
               output reg wb_whilo,
               output reg [`RegBus] wb_hi,
               output reg [`RegBus] wb_lo,
               input  wire [5:0] stall,
               
               input  wire mem_LLbit_we,
               input  wire mem_LLbit_value,
               output reg wb_LLbit_we,
               output reg wb_LLbit_value);
    
    always @(posedge clk) begin
        if (rst == `RstEnable) begin
            wb_wd    <= `NOPRegAddr;
            wb_wdata <= `ZeroWord;
            wb_wreg  <= `WriteDisable;
            wb_hi <= `ZeroWord;
            wb_lo <= `ZeroWord;
            wb_whilo <= `WriteDisable;
            wb_LLbit_value <= 1'b0;
            wb_LLbit_we <= 1'b0;
        end else if(stall[4] == `Stop && stall[5] == `NoStop) begin
            wb_wd    <= `NOPRegAddr;
            wb_wdata <= `ZeroWord;
            wb_wreg  <= `WriteDisable;
            wb_hi <= `ZeroWord;
            wb_lo <= `ZeroWord;
            wb_whilo <= `WriteDisable;
            wb_LLbit_value <= 1'b0;
            wb_LLbit_we <= 1'b0;
        end else if(stall[4] == `NoStop) begin
            wb_wd    <= mem_wd;
            wb_wdata <= mem_wdata;
            wb_wreg  <= mem_wreg;
            wb_hi <= mem_hi;
            wb_lo <= mem_lo;
            wb_whilo <= mem_whilo;
            wb_LLbit_value <= mem_LLbit_value;
            wb_LLbit_we <= mem_LLbit_we;
        end
    end
    
endmodule //mem_wb
