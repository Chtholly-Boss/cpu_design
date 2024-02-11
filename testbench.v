`timescale 1ns/1ps
`include "./define.v"
module testbench ();
    reg     CLOCK_50;
    reg     rst;
    
    initial begin
        CLOCK_50             = 1'b0;
        forever #10 CLOCK_50 = ~CLOCK_50;
    end
    
    initial begin
        rst      = `RstEnable;
        #195 rst = `RstDisable;
        #1000 $stop;
    end
    
    openmips_min_sopc openmips_min_sopc0(
    .clk(CLOCK_50),
    .rst(rst)
    );
    /*iverilog */
    initial
    begin
        $dumpfile("wave.vcd");
        $dumpvars(0,testbench);
    end
    
endmodule
