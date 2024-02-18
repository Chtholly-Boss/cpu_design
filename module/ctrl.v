`include "./define.v"
module ctrl (input wire rst,
             input wire stallreq_from_id,
             input wire stallreq_from_ex,
             output reg [5:0] stall,
             
             input  wire [31:0] excepttype_i,
             input  wire [31:0] cp0_epc_i,
             
             output reg [31:0] new_pc,
             output reg flush);
    /* 0-pc, 1-fetch, 2-decode, 3-execute, 4-memory access, 5-write back */
    always @(*) begin
        if (rst == `RstEnable) begin
            stall <= 6'h0;
            flush <= 1'b0;
            new_pc <= `ZeroWord;
        end else if(excepttype_i != `ZeroWord) begin
            flush <= 1'b1;
            stall <= 6'b00_0000;
            case (excepttype_i)
                32'h0000_0001: new_pc <= 32'h0000_0020;
                32'h0000_0008: new_pc <= 32'h0000_0040;
                32'h0000_000a: new_pc <= 32'h0000_0040;
                32'h0000_000d: new_pc <= 32'h0000_0040;
                32'h0000_000c: new_pc <= 32'h0000_0040;
                32'h0000_000e: new_pc <= cp0_epc_i;
                default:begin
                end
            endcase
        end else if (stallreq_from_ex == `Stop) begin
            stall <= 6'b001111;
            flush <= 1'b0;
        end else if (stallreq_from_id == `Stop) begin
            stall <= 6'b000111;
            flush <= 1'b0;
        end else begin
            stall <= 6'b000000;
            flush <= 1'b0;
            new_pc <= `ZeroWord;
        end
    end
    
endmodule //ctrl
