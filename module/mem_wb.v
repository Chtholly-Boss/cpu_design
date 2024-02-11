`include "define.v"

module mem_wb (input wire rst,
               input wire clk,
               input wire [`RegAddrBus] mem_wd,
               input wire mem_wreg,
               input wire [`RegBus] mem_wdata,
               output reg [`RegAddrBus] wb_wd,
               output reg wb_wreg,
               output reg [`RegBus] wb_wdata);
    
    always @(posedge clk) begin
        if (rst == `RstEnable) begin
            wb_wd    <= `NOPRegAddr;
            wb_wdata <= `ZeroWord;
            wb_wreg  <= `WriteDisable;
            end else begin
            wb_wd    <= mem_wd;
            wb_wdata <= mem_wdata;
            wb_wreg  <= mem_wreg;
        end
    end
    
endmodule //mem_wb
