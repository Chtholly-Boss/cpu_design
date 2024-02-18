module cp0_reg (
    input  wire clk,
    input  wire rst,

    input  wire we_i,
    input  wire [4:0] waddr_i,
    input  wire [4:0] raddr_i,
    input  wire [31:0] data_i,

    input  wire [5:0] int_i,

    output reg [31:0] data_o,
    output reg [31:0] count_o,
    output reg [31:0] compare_o,
    output reg [31:0] status_o,
    output reg [31:0] cause_o,
    output reg [31:0] epc_o,
    output reg [31:0] config_o,
    output reg [31:0] prid_o,

    output reg  timer_int_o,

    input  wire [31:0] excepttype_i,
    input  wire [31:0] current_inst_addr_i,
    input  wire is_in_delayslot_i
);

/*** Write to CP0 ***/
    always @(posedge clk) begin
        if (rst == `RstEnable) begin
            count_o <= 0;
            compare_o <= 0;
            status_o <= 32'h10000000;
            cause_o <= `ZeroWord;
            epc_o <= `ZeroWord;
            config_o <= 32'h00800000;
            prid_o <= 32'b00000000010011000000000100000010;
            timer_int_o <= `InterruptNotAssert;
        end else begin
            count_o <= count_o + 32'h1;
            cause_o[15:10] <= int_i; // External Interupt

            if (compare_o != `ZeroWord && count_o == compare_o) begin
                timer_int_o <= `InterruptAssert;
            end

            if (we_i == `WriteEnable) begin
                case (waddr_i)
                    `CP0_REG_COUNT:begin
                        count_o <= data_i;
                    end
                    `CP0_REG_COMPARE:begin
                        compare_o <= data_i;
                        timer_int_o <= `InterruptNotAssert;
                    end
                    `CP0_REG_STATUS:begin
                        status_o <= data_i;
                    end
                    `CP0_REG_EPC:begin
                        epc_o <= data_i;
                    end
                    `CP0_REG_CAUSE:begin
                        cause_o[9:8] <= data_i[9:8];
                        cause_o[23] <= data_i[23];
                        cause_o[22] <= data_i[22];
                    end
                endcase
            end
        end
    end

    /*** Read from CP0 ***/
    always @( *) begin
        if (rst == `RstEnable) begin
            data_o <= `ZeroWord;
        end else begin
            case (raddr_i)
                `CP0_REG_COUNT:begin
                    data_o <= count_o;
                end
                `CP0_REG_COMPARE:begin
                    data_o <= compare_o;
                end
                `CP0_REG_STATUS:begin
                    data_o <= status_o;
                end
                `CP0_REG_CAUSE:begin
                    data_o <= cause_o;
                end
                `CP0_REG_EPC:begin
                    data_o <= epc_o;
                end
                `CP0_REG_PrId:begin
                    data_o <= prid_o;
                end
                `CP0_REG_CONFIG:begin
                    data_o <= config_o;
                end
                default begin
                end
            endcase
        end
    end

    /*** Exception Control ***/
    always @(posedge clk) begin
        if (rst == `RstEnable) begin
            count_o <= 0;
            compare_o <= 0;
            status_o <= 32'h10000000;
            cause_o <= `ZeroWord;
            epc_o <= `ZeroWord;
            config_o <= 32'h00800000;
            prid_o <= 32'b00000000010011000000000100000010;
            timer_int_o <= `InterruptNotAssert;
        end else begin
            case (excepttype_i)
            /*** External Interupt ***/
                32'h0000_0001:begin
                    if (is_in_delayslot_i == `InDelaySlot) begin
                        epc_o <= current_inst_addr_i - 4;
                        cause_o[31] <= 1'b1;
                    end else begin
                        epc_o <= current_inst_addr_i;
                        cause_o <= 1'b0;
                    end
                    status_o[1] <= 1'b1;
                    cause_o[6:2] = 5'b00000;
                end
            /*** Syscall ***/
                32'h0000_0008:begin
                    if (status_o[1] == 1'b0) begin
                        if (is_in_delayslot_i == `InDelaySlot) begin
                        epc_o <= current_inst_addr_i - 4;
                        cause_o[31] <= 1'b1;
                        end else begin
                            epc_o <= current_inst_addr_i;
                            cause_o <= 1'b0;
                        end
                    end
                    status_o[1] <= 1'b1;
                    cause_o[6:2] = 5'b01000;
                end
            /*** Instruction Invalid ***/
                32'h0000_000a:begin
                    if (status_o[1] == 1'b0) begin
                        if (is_in_delayslot_i == `InDelaySlot) begin
                        epc_o <= current_inst_addr_i - 4;
                        cause_o[31] <= 1'b1;
                        end else begin
                            epc_o <= current_inst_addr_i;
                            cause_o <= 1'b0;
                        end
                    end
                    status_o[1] <= 1'b1;
                    cause_o[6:2] = 5'b01010;
                end
            /*** Self Caused ***/
                32'h0000_000d:begin
                    if (status_o[1] == 1'b0) begin
                        if (is_in_delayslot_i == `InDelaySlot) begin
                        epc_o <= current_inst_addr_i - 4;
                        cause_o[31] <= 1'b1;
                        end else begin
                            epc_o <= current_inst_addr_i;
                            cause_o <= 1'b0;
                        end
                    end
                    status_o[1] <= 1'b1;
                    cause_o[6:2] = 5'b01101;
                end
            /*** Overflow ***/
                32'h0000_000c:begin
                    if (status_o[1] == 1'b0) begin
                        if (is_in_delayslot_i == `InDelaySlot) begin
                        epc_o <= current_inst_addr_i - 4;
                        cause_o[31] <= 1'b1;
                        end else begin
                            epc_o <= current_inst_addr_i;
                            cause_o <= 1'b0;
                        end
                    end
                    status_o[1] <= 1'b1;
                    cause_o[6:2] = 5'b01100;
                end
            /*** Eret ***/
                32'h0000_000e:begin
                    status_o[1] <= 1'b0;
                end
                default:begin
                end
            endcase
        end
    end

endmodule //cp0_reg