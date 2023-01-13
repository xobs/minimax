module minimax_rf (
    input clk,
    input [4:0] addrS,
    input [4:0] addrD,
    input [31:0] new_value,
    input we,
    output [31:0] rS,
    output [31:0] rD
);

  reg [31:0] register_file[31:1];

  // Look up register file contents combinatorially
  assign rS = (|addrS) ? register_file[addrS] : 32'b0;
  assign rD = (|addrD) ? register_file[addrD] : 32'b0;

  always @(posedge clk) begin
    // writeback
    if ((|addrD) & we) begin
      register_file[addrD] <= new_value;
    end
  end

  initial begin
    register_file[31] = 32'b00000000000000000000000000000000;
    register_file[30] = 32'b00000000000000000000000000000000;
    register_file[29] = 32'b00000000000000000000000000000000;
    register_file[28] = 32'b00000000000000000000000000000000;
    register_file[27] = 32'b00000000000000000000000000000000;
    register_file[26] = 32'b00000000000000000000000000000000;
    register_file[25] = 32'b00000000000000000000000000000000;
    register_file[24] = 32'b00000000000000000000000000000000;
    register_file[23] = 32'b00000000000000000000000000000000;
    register_file[22] = 32'b00000000000000000000000000000000;
    register_file[21] = 32'b00000000000000000000000000000000;
    register_file[20] = 32'b00000000000000000000000000000000;
    register_file[19] = 32'b00000000000000000000000000000000;
    register_file[18] = 32'b00000000000000000000000000000000;
    register_file[17] = 32'b00000000000000000000000000000000;
    register_file[16] = 32'b00000000000000000000000000000000;
    register_file[15] = 32'b00000000000000000000000000000000;
    register_file[14] = 32'b00000000000000000000000000000000;
    register_file[13] = 32'b00000000000000000000000000000000;
    register_file[12] = 32'b00000000000000000000000000000000;
    register_file[11] = 32'b00000000000000000000000000000000;
    register_file[10] = 32'b00000000000000000000000000000000;
    register_file[9] = 32'b00000000000000000000000000000000;
    register_file[8] = 32'b00000000000000000000000000000000;
    register_file[7] = 32'b00000000000000000000000000000000;
    register_file[6] = 32'b00000000000000000000000000000000;
    register_file[5] = 32'b00000000000000000000000000000000;
    register_file[4] = 32'b00000000000000000000000000000000;
    register_file[3] = 32'b00000000000000000000000000000000;
    register_file[2] = 32'b00000000000000000000000000000000;
    register_file[1] = 32'b00000000000000000000000000000000;
  end

`ifdef ENABLE_REGISTER_INSPECTION
  // Wires that make it easier to inspect the register file during simulation
  wire [31:0] x0;
  wire [31:0] x1;
  wire [31:0] x2;
  wire [31:0] x3;
  wire [31:0] x4;
  wire [31:0] x5;
  wire [31:0] x6;
  wire [31:0] x7;
  wire [31:0] x8;
  wire [31:0] x9;
  wire [31:0] x10;
  wire [31:0] x11;
  wire [31:0] x12;
  wire [31:0] x13;
  wire [31:0] x14;
  wire [31:0] x15;
  wire [31:0] x16;
  wire [31:0] x17;
  wire [31:0] x18;
  wire [31:0] x19;
  wire [31:0] x20;
  wire [31:0] x21;
  wire [31:0] x22;
  wire [31:0] x23;
  wire [31:0] x24;
  wire [31:0] x25;
  wire [31:0] x26;
  wire [31:0] x27;
  wire [31:0] x28;
  wire [31:0] x29;
  wire [31:0] x30;
  wire [31:0] x31;

  assign cpu_x0 =  32'b0;
  assign cpu_x1 =  register_file[1];
  assign cpu_x2 =  register_file[2];
  assign cpu_x3 =  register_file[3];
  assign cpu_x4 =  register_file[4];
  assign cpu_x5 =  register_file[5];
  assign cpu_x6 =  register_file[6];
  assign cpu_x7 =  register_file[7];
  assign cpu_x8 =  register_file[8];
  assign cpu_x9 =  register_file[9];
  assign cpu_x10 = register_file[10];
  assign cpu_x11 = register_file[11];
  assign cpu_x12 = register_file[12];
  assign cpu_x13 = register_file[13];
  assign cpu_x14 = register_file[14];
  assign cpu_x15 = register_file[15];
  assign cpu_x16 = register_file[16];
  assign cpu_x17 = register_file[17];
  assign cpu_x18 = register_file[18];
  assign cpu_x19 = register_file[19];
  assign cpu_x20 = register_file[20];
  assign cpu_x21 = register_file[21];
  assign cpu_x22 = register_file[22];
  assign cpu_x23 = register_file[23];
  assign cpu_x24 = register_file[24];
  assign cpu_x25 = register_file[25];
  assign cpu_x26 = register_file[26];
  assign cpu_x27 = register_file[27];
  assign cpu_x28 = register_file[28];
  assign cpu_x29 = register_file[29];
  assign cpu_x30 = register_file[30];
  assign cpu_x31 = register_file[31];

`endif // `ifdef ENABLE_REGISTER_INSPECTION

endmodule
