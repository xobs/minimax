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

module minimax_tb;
parameter MAXTICKS = 100000;
parameter PC_BITS = 14;
parameter UC_BASE = 32'h0000800;

// 	generic (
// 		ROM_FILENAME : string := "/dev/null";
// 		MAXTICKS : integer := -1;
// 		TRACE : boolean := TRUE);

// architecture behav of minimax_tb is
	reg clk;
	reg reset;

	reg [31:0] ticks;
	reg [15:0] rom_array [0:8191];

	// Run clock at 10 ns
	always #10 clk <= (clk === 1'b0);

	initial begin
		clk = 0;
	end

	initial begin
		$dumpfile("minimax_tb.vcd");
    	$dumpvars(0, minimax_tb);

		$readmemh("../asm/blink.mem", rom_array);
		$readmemh("../asm/microcode.mem", rom_array, UC_BASE);

		$display("Running clock...");
		repeat (MAXTICKS) begin
			@(posedge clk);
		end
		$display("Finished test");
		$finish;
	end

	wire [31:0] rom_window;
	wire [15:0] inst_lat;
	reg [15:0] inst_reg;
	wire inst_regce;

	wire [PC_BITS-1:0] inst_addr;
	wire [31:0] addr, wdata;
	reg [31:0] rdata;
	wire [3:0] wmask;
	wire rreq;
	reg [31:0] i32;

	reg cpu_reset;

	assign rom_window = rom_array[ticks];

	assign inst_lat = inst_addr[1] ? i32[31:16] : i32[15:0];
	always @(posedge clk) begin
		cpu_reset <= reset;

		rdata <= {rom_array[{addr[PC_BITS-1:2], 1'b0}], rom_array[{addr[PC_BITS-1:2], 1'b1}]};
		i32 <= {rom_array[{inst_addr[PC_BITS-1:2], 1'b0}], rom_array[{inst_addr[PC_BITS-1:2], 1'b1}]};

		if (inst_regce) begin
			inst_reg <= inst_lat;
		end

		if (wmask == 4'hf) begin
			rom_array[addr[PC_BITS-1:1]] <= wdata[31:16];
			rom_array[addr[PC_BITS-1:1]+1] <= wdata[15:0];
		end

	end

	minimax #(
		.TRACE(1'b0),
		.PC_BITS(PC_BITS),
		.UC_BASE(UC_BASE)
	) dut (
		.clk(clk),
		.reset(cpu_reset),
		.inst_addr(inst_addr),
		.inst(inst_reg),
		.inst_regce(inst_regce),
		.addr(addr),
		.wdata(wdata),
		.rdata(rdata),
		.wmask(wmask),
		.rreq(rreq)
	);

	initial begin
		reset <= 1'b1;
		#96;
		reset <= 1'b0;
	end

	initial begin
		ticks <= 0;
	end

	// Capture test exit conditions - timeout or quit
	always @(posedge clk)
	begin
		// Track ticks counter and bail if we took too long
		ticks <= ticks + 1;
		if (ticks >= MAXTICKS) begin
			$display("FAIL: Exceeded MAXTICKS");
			$finish;
		end

		// // Capture writes to address 0xfffffffc and use these as "quit" values
		// if(wmask=x"f" and addr=x"fffffffc") begin
		// 	if nor wdata then
		// 		write(buf, string'("SUCCESS: returned 0."));
		// 	else
		// 		write(buf, "FAIL: returned " & integer'image(to_integer(signed(wdata))));
		// 	end if;
		// 	writeline(output, buf);
		// 	finish(to_integer(signed(wdata)));
		// end
	end

endmodule
