`include "./define.v"
module openmips_min_sopc (input wire clk,
                          input wire rst);
    /*** Connection Between processor and inst_rom ***/
    wire [`InstAddrBus] inst_addr;
    wire [`InstBus] inst;
    wire rom_ce;
    /*** Connection Between processor and data_ram ***/
    wire [`RegBus] ram_addr_o;
    wire [`RegBus] ram_data_o;
    wire [3:0] ram_sel_o;
    wire ram_we_o;
    wire ram_ce_o;
    wire [`RegBus] ram_data_i;
    
    openmips  u_openmips (
    .rst                     (rst),
    .clk                     (clk),
    .rom_data_i              (inst),
    
    .rom_addr_o              (inst_addr),
    .rom_ce_o                (rom_ce),

    .ram_data_i(ram_data_i),
    .ram_addr_o(ram_addr_o),
    .ram_data_o(ram_data_o),
    .ram_sel_o(ram_sel_o),
    .ram_we_o(ram_we_o),
    .ram_ce_o(ram_ce_o)
    );
    inst_rom  u_inst_rom (
    .ce                      (rom_ce),
    .addr                    (inst_addr),
    .inst                    (inst)
    );
    data_ram  u_data_ram (
    .clk                     (clk),
    .ce                      (ram_ce_o),
    .we                      (ram_we_o),
    .addr                    (ram_addr_o),
    .sel                     (ram_sel_o),
    .data_i                  (ram_data_o),
    
    .data_o                  (ram_data_i)
    );
endmodule //openmips_min_sopc
