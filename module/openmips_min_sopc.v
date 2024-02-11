`include "./define.v"
module openmips_min_sopc (input wire clk,
                          input wire rst);
    /*** Connection Between processor and inst_rom ***/
    wire [`InstAddrBus] inst_addr;
    wire [`InstBus] inst;
    wire rom_ce;
    
    openmips  u_openmips (
    .rst                     (rst),
    .clk                     (clk),
    .rom_data_i              (inst),
    
    .rom_addr_o              (inst_addr),
    .rom_ce_o                (rom_ce)
    );
    inst_rom  u_inst_rom (
    .ce                      (rom_ce),
    .addr                    (inst_addr),
    .inst                    (inst)
    );
endmodule //openmips_min_sopc
