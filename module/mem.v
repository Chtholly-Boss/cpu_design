`include "./define.v"

module mem (input wire rst,
            input wire [`RegAddrBus] wd_i,
            input wire wreg_i,
            input wire [`RegBus] wdata_i,
            output reg [`RegAddrBus] wd_o,
            output reg wreg_o,
            output reg [`RegBus] wdata_o);
    always @(*) begin
        if (rst == `RstEnable) begin
            wd_o    <= `NOPRegAddr;
            wdata_o <= `ZeroWord;
            wreg_o  <= `WriteDisable;
            end else begin
            wd_o    <= wd_i;
            wdata_o <= wdata_i;
            wreg_o  <= wreg_i;
        end
    end
    
endmodule //mem
