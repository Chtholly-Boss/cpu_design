`include "./define.v"
module ctrl (input wire rst,
             input wire stallreq_from_id,
             input wire stallreq_from_ex,
             output reg [5:0] stall);
    /* 0-pc, 1-fetch, 2-decode, 3-execute, 4-memory access, 5-write back */
    always @(*) begin
        if (rst == `RstEnable) begin
            stall <= 6'h0;
            end else if (stallreq_from_ex == `Stop) begin
            stall <= 6'b001111;
            end else if (stallreq_from_id == `Stop) begin
            stall <= 6'b000111;
            end else begin
            stall <= 6'b000000;
        end
    end
    
endmodule //ctrl
