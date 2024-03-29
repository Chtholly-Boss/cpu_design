`include "./define.v"
module if_id (input wire clk,
              input wire rst,
              input wire [`InstAddrBus] if_pc,
              input wire [`InstBus] if_inst,
              output reg [`InstAddrBus] id_pc,
              output reg [`InstBus] id_inst,
              input  wire [5:0] stall,
              input wire flush);
    always @(posedge clk) begin
        if (rst == `RstEnable) begin
            id_pc   <= 32'h00000000;
            id_inst <= 32'h00000000;
        end else if(flush == 1'b1) begin
            id_pc <= `ZeroWord;
            id_inst <= `ZeroWord;
        end else if(stall[1] == `Stop && stall[2] == `NoStop) begin
            id_pc <= `ZeroWord;
            id_inst <= `ZeroWord;
        end else if(stall[1] == `NoStop) begin
            id_pc   <= if_pc;
            id_inst <= if_inst;
        end
    end
    
endmodule //if_id
