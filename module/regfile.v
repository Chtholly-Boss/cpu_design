`include "define.v"
module regfile (input wire clk,
                input wire rst,
                input wire [`RegAddrBus] waddr,
                input wire [`RegBus] wdata,
                input wire we,
                input wire re_1,
                input wire [`RegAddrBus] raddr_1,
                output reg [`RegBus] rdata_1,
                input wire re_2,
                input wire [`RegAddrBus] raddr_2,
                output reg [`RegBus] rdata_2);
    /*** Definition ***/
    reg [`RegBus] regs[0: `RegNum - 1];
    /*** Write logic ***/
    always @(posedge clk) begin
        if (rst == `RstDisable) begin
            if ((we == `WriteEnable) && (waddr != `RegNumLog2'h0)) begin
                regs[waddr] <= wdata;
            end
        end
    end
    
    /*** Read logic ***/
    always @(posedge clk) begin
        if (rst == `RstEnable) begin
            rdata_1 <= `ZeroWord;
            end else if (raddr_1 == `RegNumLog2'h0) begin
            rdata_1 <= `ZeroWord;
            end else if ((raddr_1 == waddr) && (we == `WriteEnable) && (re_1 == `ReadEnable)) begin
            /* transmit */
            rdata_1 <= wdata;
            end else if (re_1 == `ReadEnable) begin
            rdata_1 <= regs[raddr_1];
            end else
            rdata_1 <= `ZeroWord;
        end
        
        always @(posedge clk) begin
            if (rst == `RstEnable) begin
                rdata_2 <= `ZeroWord;
                end else if (raddr_2 == `RegNumLog2'h0) begin
                rdata_2 <= `ZeroWord;
                end else if ((raddr_2 == waddr) && (we == `WriteEnable) && (re_2 == `ReadEnable)) begin
                /* transmit */
                rdata_2 <= wdata;
                end else if (re_2 == `ReadEnable) begin
                rdata_2 <= regs[raddr_2];
                end else
                rdata_2 <= `ZeroWord;
            end
            
            
            endmodule //regfile
