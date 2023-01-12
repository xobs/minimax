//
// Minimax: microcoded RISC-V
//
// (c) 2022 Three-Speed Logic, Inc., all rights reserved.
//
// This testbench contains:
//
// * A minimax core,
// * A 4kB dual-port RAM connected to both instruction and data buses, and
// * Enough "peripheral" to halt the simulation on completion.
//

`timescale 1 ns / 1 ps

// Use defines here rather than parameters, because iverilog's `-P` argument
// doesn't seem to work properly.
`ifndef ROM_FILENAME
`define ROM_FILENAME "../asm/blink.mem"
`endif

`ifndef MICROCODE_FILENAME
`define MICROCODE_FILENAME "../asm/microcode.mem"
`endif

`ifndef VCD_FILENAME
`define VCD_FILENAME "minimax_tb.vcd"
`endif

`ifndef MAXTICKS
`define MAXTICKS 100000
`endif

`ifdef ENABLE_TRACE
`define TRACE 1'b1
`else
`define TRACE 1'b0
`endif

module minimax_tb;
    parameter MAXTICKS = `MAXTICKS;
    parameter PC_BITS = 13;
    parameter UC_BASE = 32'h0000800;
    parameter ROM_FILENAME = `ROM_FILENAME;
    parameter MICROCODE_FILENAME = `MICROCODE_FILENAME;
    parameter TRACE = `TRACE;

    reg clk_2x;
    wire cpu_clk;
    wire mem_clk;
    reg cpu_reset, mem_reset;

    reg [31:0] ticks;
    reg [15:0] rom_array [0:8191];

    // Run clock at 10 ns
    always #5 clk_2x <= (clk_2x === 1'b0);
    assign cpu_clk = ticks[1];
    // assign cpu_clk = ticks[1] & ticks[0];
    assign mem_clk = ~ticks[1] & ticks[0];

    initial begin
        clk_2x = 0;
    end

    integer i;
    initial begin
        $dumpfile(`VCD_FILENAME);
        $dumpvars(0, minimax_tb);

        for (i = 0; i < 8192; i = i + 1) rom_array[i] = 16'b0;

        $readmemh(ROM_FILENAME, rom_array);
        `ifndef SKIP_MICROCODE
        $readmemh(MICROCODE_FILENAME, rom_array, UC_BASE);
        `endif

        for (i = 0; i < 512; i = i + 1) begin
            bank0.ram0.mem[i] = rom_array[i * 2] >> 0;
            bank0.ram1.mem[i] = rom_array[i * 2] >> 8;
            bank0.ram2.mem[i] = rom_array[i * 2 + 1] >> 0;
            bank0.ram3.mem[i] = rom_array[i * 2 + 1] >> 8;
        end

        for (i = 0; i < 512; i = i + 1) begin
            bank1.ram0.mem[i] = rom_array[1024 + i * 2] >> 0;
            bank1.ram1.mem[i] = rom_array[1024 + i * 2] >> 8;
            bank1.ram2.mem[i] = rom_array[1024 + i * 2 + 1] >> 0;
            bank1.ram3.mem[i] = rom_array[1024 + i * 2 + 1] >> 8;
        end

        for (i = 0; i < 512; i = i + 1) begin
            bank2.ram0.mem[i] = rom_array[2*1024 + i * 2] >> 0;
            bank2.ram1.mem[i] = rom_array[2*1024 + i * 2] >> 8;
            bank2.ram2.mem[i] = rom_array[2*1024 + i * 2 + 1] >> 0;
            bank2.ram3.mem[i] = rom_array[2*1024 + i * 2 + 1] >> 8;
        end

        for (i = 0; i < 512; i = i + 1) begin
            bank3.ram0.mem[i] = rom_array[3*1024 + i * 2] >> 0;
            bank3.ram1.mem[i] = rom_array[3*1024 + i * 2] >> 8;
            bank3.ram2.mem[i] = rom_array[3*1024 + i * 2 + 1] >> 0;
            bank3.ram3.mem[i] = rom_array[3*1024 + i * 2 + 1] >> 8;
        end

        forever begin
            @(posedge clk_2x);
        end
    end

    reg [15:0] inst_lat;
    reg [15:0] inst_reg, inst_reg_ram;
    wire inst_regce;

    wire [PC_BITS-1:0] inst_addr;
    wire [31:0] addr, wdata;
    reg [31:0] rdata;
    wire [3:0] wmask;
    wire rreq;

    // reg [31:0] ram_addr;
    wire [31:0] ram_addr;
    // assign ram_addr = (rreq ? addr : inst_addr);
    wire [31:0] rdata_ram;

    reg [15:0] inst_lat_ram;
    always @(posedge cpu_clk) begin
        inst_lat_ram <= ~inst_addr[1] ? rdata_ram[15:0] : rdata_ram[31:16];
    end

    reg [31:0] rom_window;
    reg [31:0] ram_window;
    always @(posedge cpu_clk) begin
        ram_window <= rdata_ram;
        rom_window <= {rom_array[ticks * 2 + 1], rom_array[ticks * 2]};
    end

    assign ram_addr = cpu_reset ? 32'b0 : (({32{(|rreq)}} & addr)
                                        | ({32{(~|rreq)}} & inst_addr));

    always @(posedge cpu_clk) begin

        // Only support one access to memory at a time:
        //
        //   * Write data to RAM
        //   * Read data from RAM
        //   * Read an instruction
        //
        // Minimax will stall its pipeline any time it needs to read data
        // from memory. If it is compiled with BUBBLE_STORES defined, then
        // it will also delay for one cycle when storing data.
        //
        // This is necessary due to the GF180 memories being single-ported.
        if (wmask == 4'hf) begin
            rom_array[addr[PC_BITS-1:1]+1] <= wdata[31:16];
            rom_array[addr[PC_BITS-1:1]] <= wdata[15:0];
            inst_lat <= 16'b0;
            rdata <= 1'b0;
        end else if (rreq) begin
            inst_lat <= 16'b0;
            rdata <= {rom_array[{addr[PC_BITS-1:2], 1'b1}], rom_array[{addr[PC_BITS-1:2], 1'b0}]};
            // rdata <= ram_window;
        end else begin
            rdata <= 32'b0;
            if (inst_addr[1])
                inst_lat <= rom_array[{inst_addr[PC_BITS-1:2], 1'b1}];
            else
                inst_lat <= rom_array[{inst_addr[PC_BITS-1:2], 1'b0}];
        end

        if (inst_regce) begin
            // inst_reg <= inst_lat;
            inst_reg <= inst_lat_ram;
            inst_reg_ram <= inst_lat_ram;
        end
    end

    minimax #(
        .TRACE(TRACE),
        .PC_BITS(PC_BITS),
        .UC_BASE(UC_BASE)
    ) dut (
        .clk(cpu_clk),
        .reset(cpu_reset),
        .inst_addr(inst_addr),
        .inst(inst_reg),
        .inst_regce(inst_regce),
        .addr(addr),
        .wdata(wdata),
        .rdata(ram_window),
        .wmask(wmask),
        .rreq(rreq)
    );

    assign rdata_ram = 
          (rdata_bank0 & {32{(ram_addr[12:11] == 2'h0)}})
        | (rdata_bank1 & {32{(ram_addr[12:11] == 2'h1)}})
        | (rdata_bank2 & {32{(ram_addr[12:11] == 2'h2)}})
        | (rdata_bank3 & {32{(ram_addr[12:11] == 2'h3)}});

    // Bytes 0-2047
    wire bank_clk;
    assign bank_clk = clk_2x;
    wire [31:0] rdata_bank0;
    gf180mcu_sram_512x32 bank0 (
        .clk(bank_clk),
        .reset(mem_reset),
        .en(ram_addr[12:11] == 2'h0),
        .addr(ram_addr[10:2]),
        .rdata(rdata_bank0),
        .wdata(wdata),
        .wen(wmask == 4'hf)
    );

    // Bytes 2048-4097
    wire [31:0] rdata_bank1;
    gf180mcu_sram_512x32 bank1 (
        .clk(bank_clk),
        .reset(mem_reset),
        .en(ram_addr[12:11] == 2'h1),
        .addr(ram_addr[10:2]),
        .rdata(rdata_bank1),
        .wdata(wdata),
        .wen(wmask == 4'hf)
    );

    // Bytes 4098-6143
    wire [31:0] rdata_bank2;
    gf180mcu_sram_512x32 bank2 (
        .clk(bank_clk),
        .reset(mem_reset),
        .en(ram_addr[12:11] == 2'h2),
        .addr(ram_addr[10:2]),
        .rdata(rdata_bank2),
        .wdata(wdata),
        .wen(wmask == 4'hf)
    );

    // Bytes 6144-8191
    wire [31:0] rdata_bank3;
    gf180mcu_sram_512x32 bank3 (
        .clk(bank_clk),
        .reset(mem_reset),
        .en(ram_addr[12:11] == 2'h3),
        .addr(ram_addr[10:2]),
        .rdata(rdata_bank3),
        .wdata(wdata),
        .wen(wmask == 4'hf)
    );

    initial begin
        cpu_reset <= 1'b1;
        mem_reset <= 1'b1;
        #40
        mem_reset <= 1'b0;
        #36;
        cpu_reset <= 1'b0;
    end

    initial begin
        ticks <= 0;
    end

    always @(posedge clk_2x) begin
        if (cpu_reset) ticks <= 0; else ticks <= ticks + 1;
    end

    // Capture test exit conditions - timeout or quit
    always @(posedge clk_2x)
    begin
        // Track ticks counter and bail if we took too long
        if (MAXTICKS != -1 && ticks >= (MAXTICKS * 4)) begin
            $display("FAIL: Exceeded MAXTICKS of %0d", MAXTICKS);
            $finish_and_return(1);
        end

        // Capture writes to address 0xfffffffc and use these as "quit" values
        if (wmask == 4'b1111 && addr == 32'hfffffffc) begin
            if (~|wdata) begin
                $display("SUCCESS: returned 0.");
                $finish_and_return(0);
            end else begin
                $display("FAIL: returned %0d", wdata);
                $finish_and_return(1);
            end
        end
    end

endmodule
