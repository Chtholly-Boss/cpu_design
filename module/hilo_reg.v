module hilo_reg (
    input  wire rst,
    input  wire clk,

    input  wire we,
    input  wire [31:0] hi_i,
    input  wire [31:0] lo_i,

    output reg [31:0] hi_o,
    output reg [31:0] lo_o
);
always @(posedge clk) begin
    if (rst == `RstEnable) begin
        hi_o <= `ZeroWord;
        lo_o <= `ZeroWord;
    end else if(we == `WriteEnable) begin
        hi_o <= hi_i;
        lo_o <= lo_i;
    end
end
endmodule //hilo_reg