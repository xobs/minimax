module RAM32_1RW1R  #(parameter    USE_LATCH=1,
                                    WSIZE=1 ) 
(
`ifdef USE_POWER_PINS
    input                           VDD,
    input                           VSS,
`endif
    input   wire                    CLK,
    input   wire [WSIZE-1:0]        WE0,
    input                           EN0,
    input                           EN1,
    input   wire [4:0]              A0,
    input   wire [4:0]              A1,
    input   wire [(WSIZE*8-1):0]    Di0,
    output  wire [(WSIZE*8-1):0]    Do0,
    output  wire [(WSIZE*8-1):0]    Do1
);

    reg [31:0] backing[(WSIZE*8-1):0];

    assign Do0 = backing[A0];
    assign Do1 = backing[A1];

    generate
    genvar c;
    for (c=0; c < WSIZE; c = c+1) begin
        always @(negedge CLK) begin
            if (WE0[c]) begin
                backing[A0][c*8+7:c*8] <= Di0[c*8+7:c*8];
            end
        end
    end
    endgenerate

  initial begin
    backing[31] = 32'b00000000000000000000000000000000;
    backing[30] = 32'b00000000000000000000000000000000;
    backing[29] = 32'b00000000000000000000000000000000;
    backing[28] = 32'b00000000000000000000000000000000;
    backing[27] = 32'b00000000000000000000000000000000;
    backing[26] = 32'b00000000000000000000000000000000;
    backing[25] = 32'b00000000000000000000000000000000;
    backing[24] = 32'b00000000000000000000000000000000;
    backing[23] = 32'b00000000000000000000000000000000;
    backing[22] = 32'b00000000000000000000000000000000;
    backing[21] = 32'b00000000000000000000000000000000;
    backing[20] = 32'b00000000000000000000000000000000;
    backing[19] = 32'b00000000000000000000000000000000;
    backing[18] = 32'b00000000000000000000000000000000;
    backing[17] = 32'b00000000000000000000000000000000;
    backing[16] = 32'b00000000000000000000000000000000;
    backing[15] = 32'b00000000000000000000000000000000;
    backing[14] = 32'b00000000000000000000000000000000;
    backing[13] = 32'b00000000000000000000000000000000;
    backing[12] = 32'b00000000000000000000000000000000;
    backing[11] = 32'b00000000000000000000000000000000;
    backing[10] = 32'b00000000000000000000000000000000;
    backing[9] = 32'b00000000000000000000000000000000;
    backing[8] = 32'b00000000000000000000000000000000;
    backing[7] = 32'b00000000000000000000000000000000;
    backing[6] = 32'b00000000000000000000000000000000;
    backing[5] = 32'b00000000000000000000000000000000;
    backing[4] = 32'b00000000000000000000000000000000;
    backing[3] = 32'b00000000000000000000000000000000;
    backing[2] = 32'b00000000000000000000000000000000;
    backing[1] = 32'b00000000000000000000000000000000;
  end

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

  assign x0 =  32'b0;
  assign x1 =  backing[1];
  assign x2 =  backing[2];
  assign x3 =  backing[3];
  assign x4 =  backing[4];
  assign x5 =  backing[5];
  assign x6 =  backing[6];
  assign x7 =  backing[7];
  assign x8 =  backing[8];
  assign x9 =  backing[9];
  assign x10 = backing[10];
  assign x11 = backing[11];
  assign x12 = backing[12];
  assign x13 = backing[13];
  assign x14 = backing[14];
  assign x15 = backing[15];
  assign x16 = backing[16];
  assign x17 = backing[17];
  assign x18 = backing[18];
  assign x19 = backing[19];
  assign x20 = backing[20];
  assign x21 = backing[21];
  assign x22 = backing[22];
  assign x23 = backing[23];
  assign x24 = backing[24];
  assign x25 = backing[25];
  assign x26 = backing[26];
  assign x27 = backing[27];
  assign x28 = backing[28];
  assign x29 = backing[29];
  assign x30 = backing[30];
  assign x31 = backing[31];
  
  endmodule
