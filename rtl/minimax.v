
module minimax (
`ifdef USE_POWER_PINS
    inout vdd,	// User area 1 1.8V supply
    inout vss,	// User area 1 digital ground
`endif
   input  clk,
   input  reset,
   input  [15:0] inst,
   input  [31:0] rdata,
   output [PC_BITS-1:0] inst_addr,
   output reg inst_regce,
   output [31:0] addr,
   output [31:0] wdata,
   output [3:0] wmask,
   output rreq);

  // Parameters are currently unimplemented
  parameter PC_BITS = 12;
  parameter [31:0] UC_BASE = 32'h00000000;
  parameter TRACE = 0;

  wire [31:0] uc_base;
  assign uc_base = UC_BASE;

  // Register file address ports
  wire [5:0] addrS, addrD;
  wire [4:0] addrD_port, addrS_port;
  wire bD_banksel, bS_banksel;
  wire [31:0] regS, regD, aluA, aluB, aluS, aluX;

  // Program counter
  reg [PC_BITS-1:1] pc_fetch = {(PC_BITS-2){1'b0}};
  reg [PC_BITS-1:1] pc_fetch_dly = {(PC_BITS-2){1'b0}};
  reg [PC_BITS-1:1] pc_execute = {(PC_BITS-2){1'b0}};

  // PC ALU output
  wire [PC_BITS-1:1] aguX, aguA, aguB;

  // Track bubbles and execution inhibits through the pipeline.
  wire bubble;
  reg bubble1 = 1'b1, bubble2 = 1'b1;
  wire branch_taken;
  reg microcode = 1'b0;
  wire trap, op16_trap, op32_trap;

  // Writeback and deferred writeback strobes
  wire wb;
  reg [4:0] dra = 5'b0;

  // Opcode masks for 16-bit instructions
  wire [15:0] inst_type_masked;
  wire [15:0] inst_type_masked_i16;
  wire [15:0] inst_type_masked_sr;
  wire [15:0] inst_type_masked_and;
  wire [15:0] inst_type_masked_op;
  wire [15:0] inst_type_masked_j;
  wire [15:0] inst_type_masked_mj;

  // Strobes for 16-bit instructions
  wire op16;
  wire op16_addi4spn;
  wire op16_lw;
  reg dly16_lw = 1'b0;
  wire op16_sw;

  wire op16_addi;
  wire op16_jal;
  wire op16_li;
  wire op16_addi16sp;
  wire op16_lui;

  wire op16_srli;
  wire op16_srai;
  wire op16_andi;
  wire op16_sub;
  wire op16_xor;
  wire op16_or;
  wire op16_and;
  wire op16_j;
  wire op16_beqz;
  wire op16_bnez;

  wire op16_slli;
  wire op16_lwsp;
  reg dly16_lwsp = 1'b0;
  wire op16_jr;
  wire op16_mv;

  wire op16_ebreak;
  wire op16_jalr;
  wire op16_add;
  wire op16_swsp;

  wire op16_slli_setrd;
  reg dly16_slli_setrd = 1'b0;
  wire op16_slli_setrs;
  reg dly16_slli_setrs = 1'b0;
  wire op16_slli_thunk;

  // Strobes for 32-bit instructions
  wire op32;

  assign inst_type_masked     = inst & 16'b111_0_00000_00000_11;
  assign inst_type_masked_i16 = inst & 16'b111_0_11111_00000_11;
  assign inst_type_masked_sr  = inst & 16'b111_1_11000_11111_11;
  assign inst_type_masked_and = inst & 16'b111_0_11000_00000_11;
  assign inst_type_masked_op  = inst & 16'b111_0_11000_11000_11;
  assign inst_type_masked_j   = inst & 16'b111_1_00000_11111_11;
  assign inst_type_masked_mj  = inst & 16'b111_1_00000_00000_11;

  // From 16.8 (RVC Instruction Set Listings)
  assign op16_addi4spn   = (inst_type_masked     == 16'b000_0_00000_00000_00) & ~bubble;
  assign op16_lw         = (inst_type_masked     == 16'b010_0_00000_00000_00) & ~bubble;
  assign op16_sw         = (inst_type_masked     == 16'b110_0_00000_00000_00) & ~bubble;
  
  assign op16_addi       = (inst_type_masked     == 16'b000_0_00000_00000_01) & ~bubble;
  assign op16_jal        = (inst_type_masked     == 16'b001_0_00000_00000_01) & ~bubble;
  assign op16_li         = (inst_type_masked     == 16'b010_0_00000_00000_01) & ~bubble;
  assign op16_addi16sp   = (inst_type_masked_i16 == 16'b011_0_00010_00000_01) & ~bubble;
  assign op16_lui        = (inst_type_masked     == 16'b011_0_00000_00000_01) & ~bubble & ~op16_addi16sp;
      
  assign op16_srli       = (inst_type_masked_sr  == 16'b100_0_00000_00001_01) & ~bubble;
  assign op16_srai       = (inst_type_masked_sr  == 16'b100_0_01000_00001_01) & ~bubble;
  assign op16_andi       = (inst_type_masked_and == 16'b100_0_10000_00000_01) & ~bubble;
  assign op16_sub        = (inst_type_masked_op  == 16'b100_0_11000_00000_01) & ~bubble;
  assign op16_xor        = (inst_type_masked_op  == 16'b100_0_11000_01000_01) & ~bubble;
  assign op16_or         = (inst_type_masked_op  == 16'b100_0_11000_10000_01) & ~bubble;
  assign op16_and        = (inst_type_masked_op  == 16'b100_0_11000_11000_01) & ~bubble;
  assign op16_j          = (inst_type_masked     == 16'b101_0_00000_00000_01) & ~bubble;
  assign op16_beqz       = (inst_type_masked     == 16'b110_0_00000_00000_01) & ~bubble;
  assign op16_bnez       = (inst_type_masked     == 16'b111_0_00000_00000_01) & ~bubble;
  
  assign op16_slli       = (inst_type_masked_j   == 16'b000_0_00000_00001_10) & ~bubble;
  assign op16_lwsp       = (inst_type_masked     == 16'b010_0_00000_00000_10) & ~bubble;
  assign op16_jr         = (inst_type_masked_j   == 16'b100_0_00000_00000_10) & ~bubble;
  assign op16_mv         = (inst_type_masked_mj  == 16'b100_0_00000_00000_10) & ~bubble & ~op16_jr;
  assign op16_ebreak     = (inst                 == 16'b100_1_00000_00000_10) & ~bubble;
  assign op16_jalr       = (inst_type_masked_j   == 16'b100_1_00000_00000_10) & ~bubble & ~op16_ebreak;
  assign op16_add        = (inst_type_masked_mj  == 16'b100_1_00000_00000_10) & ~bubble & ~op16_jalr & ~ op16_ebreak;
  assign op16_swsp       = (inst_type_masked     == 16'b110_0_00000_00000_10) & ~bubble;

    // Non-standard extensions to support microcode are permitted in these opcode gaps
  assign op16_slli_setrd = (inst_type_masked_j   == 16'b000_1_00000_00001_10) & ~bubble;
  assign op16_slli_setrs = (inst_type_masked_j   == 16'b000_1_00000_00010_10) & ~bubble;
  assign op16_slli_thunk = (inst_type_masked_j   == 16'b000_1_00000_00100_10) & ~bubble;

  // Blanket matches for RVC and RV32I instructions
  assign op32 =  &(inst[1:0]) & ~bubble;
  assign op16 = ~&(inst[1:0]) & ~bubble;

  // Trap on unimplemented instructions
  assign op32_trap = op32;

  assign op16_trap = op16 & ~(
      op16_addi4spn | op16_lw | op16_sw |
      op16_addi | op16_jal | op16_li | op16_addi16sp | op16_lui |
      op16_srli | op16_srai | op16_andi | op16_sub| op16_xor| op16_or| op16_and| op16_j| op16_beqz| op16_bnez |
      op16_slli | op16_lwsp | op16_jr | op16_mv | op16_ebreak | op16_jalr | op16_add | op16_swsp |
      op16_slli_setrd | op16_slli_setrs | op16_slli_thunk);

  assign trap = op16_trap | op32_trap;

  // Data bus outputs tap directly off register/ALU path.
  assign wdata = regD;
  assign addr = aluS;
  assign rreq = op16_lwsp | op16_lw
`ifdef BUBBLE_STORES
   | op16_sw | op16_swsp
`endif
  ;
  assign wmask = 4'b1111 & {4{op16_swsp | op16_sw}};

  // Instruction bus outputs do too
  assign inst_addr = {pc_fetch, 1'b0};

  // PC logic
  assign bubble = bubble1 | bubble2;

  assign branch_taken = (op16_beqz & (~|regS)
                | (op16_bnez & (|regS)))
                | op16_j | op16_jal | op16_jr | op16_jalr
                | op16_slli_thunk;

  // Fetch Process
  always @(posedge clk) begin
    // Update fetch instruction unless we're hung up on a multi-cycle instruction word
    pc_fetch <= aguX & {(PC_BITS){~reset}};

    // Fetch misses create a 2-cycle penalty
    bubble2 <= reset | branch_taken | trap;

    // Multi-cycle instructions must correctly pause the fetch/execution pipeline
    bubble1 <= reset | bubble2 | rreq;

    if (rreq) begin
      inst_regce <= 1'b0;
    end else begin
      pc_fetch_dly <= pc_fetch;
      pc_execute <= pc_fetch_dly;
      inst_regce <= 1'b1;
    end

    microcode <= (microcode | trap) & ~(reset | op16_slli_thunk);

`ifdef ENABLE_ASSERTS
    if (microcode & trap) begin
      $display("Double trap!");
      $stop;
    end

    // Check to make sure the microcode doesn't exceed the program counter size
    if (UC_BASE[31:PC_BITS] != 0) begin
      $display("Microcode at 0x%0h cannot be reached with a %d-bit program counter!", UC_BASE, PC_BITS);
      $stop;
    end
`endif

  end

  // Datapath Process
  always @(posedge clk) begin
    dly16_lw <= op16_lw;
    dly16_lwsp <= op16_lwsp;
    dly16_slli_setrs <= op16_slli_setrs;
    dly16_slli_setrd <= op16_slli_setrd;

    // Load and setrs/setrd instructions complete a cycle after they are
    // initiated, so we need to keep some state.
    dra <= (regD[4:0] & ({5{op16_slli_setrd | op16_slli_setrs}}))
           | ({2'b01, inst[4:2]} & {5{op16_lw}})
           | (inst[11:7] & {5{op16_lwsp | op32}});
  end

  // READ/WRITE register file port
  assign addrD_port = (dra & {5{dly16_slli_setrd | dly16_lw | dly16_lwsp}})
    | (5'b00001 & {5{op16_jal | op16_jalr | trap}}) // write return address into ra
    | ({2'b01, inst[4:2]} & {5{op16_addi4spn | op16_sw}}) // data
    | (inst[6:2] & {5{op16_swsp}})
    | (inst[11:7] & ({5{op16_addi | op16_add
        | (op16_mv & ~dly16_slli_setrd)
        | op16_addi16sp
        | op16_slli_setrd | op16_slli_setrs
        | op16_li | op16_lui
        | op16_slli}}))
    | ({2'b01, inst[9:7]} & {5{op16_sub
        | op16_xor | op16_or | op16_and | op16_andi
        | op16_srli | op16_srai}});

  // READ-ONLY register file port
  assign addrS_port = (dra & {5{dly16_slli_setrs}})
      | (5'b00010 & {5{op16_addi4spn | op16_lwsp | op16_swsp}})
      | (inst[11:7] & {5{op16_jr | op16_jalr | op16_slli_thunk | op16_slli}}) // jump destination
      | ({2'b01, inst[9:7]} & {5{op16_sw | op16_lw | op16_beqz | op16_bnez}})
      | ({2'b01, inst[4:2]} & {5{op16_and | op16_or | op16_xor | op16_sub}})
      | (inst[6:2] & {5{(op16_mv & ~dly16_slli_setrs) | op16_add}});

  // Select between "normal" and "microcode" register banks.
  assign bD_banksel = (microcode ^ dly16_slli_setrd) | trap;
  assign bS_banksel = (microcode ^ dly16_slli_setrs) | trap;

  (*blackbox*)
  minimax_rf regfile (
`ifdef USE_POWER_PINS
    .vdd(vdd),	// User area 1 1.8V supply
    .vss(vss),	// User area 1 digital ground
`endif
    .clk(clk),
    .addrS(addrS_port),
    .addrD(addrD_port),
    .new_value(aluX),
    .we(wb),
    .rS_microcode(bS_banksel),
    .rD_microcode(bD_banksel),
    .rS(regS),
    .rD(regD)
  );

  assign aluA = (regD & {32{op16_add | op16_addi | op16_sub
                    | op16_and | op16_andi
                    | op16_or | op16_xor
                    | op16_addi16sp
                    | op16_slli | op16_srli | op16_srai}})
          | ({22'b0, inst[10:7], inst[12:11], inst[5], inst[6], 2'b0} & {32{op16_addi4spn}})
          | ({24'b0, inst[8:7], inst[12:9], 2'b0} & {32{op16_swsp}})
          | ({24'b0, inst[3:2], inst[12], inst[6:4], 2'b0} & {32{op16_lwsp}})
          | ({25'b0, inst[5], inst[12:10], inst[6], 2'b0} & {32{op16_lw | op16_sw}});

  assign aluB = regS
          | ({{27{inst[12]}}, inst[6:2]} & {32{op16_addi | op16_andi | op16_li}})
          | ({{15{inst[12]}}, inst[6:2], 12'b0} & {32{op16_lui}})
          | ({{23{inst[12]}}, inst[4:3], inst[5], inst[2], inst[6], 4'b0} & {32{op16_addi16sp}});

  // This synthesizes into 4 CARRY8s - no need for manual xor/cin heroics
  assign aluS = op16_sub ? (aluA - aluB) : (aluA + aluB);

  assign aluX = (aluS & (
                    {32{op16_add | op16_sub | op16_addi
                      | op16_li | op16_lui
                      | op16_addi4spn | op16_addi16sp
                      | op16_slli}})) |
          ({op16_srai & aluA[31], aluA[31:1]} & {32{op16_srai | op16_srli}}) |
          ((aluA & aluB) & {32{op16_andi | op16_and}}) |
          ((aluA ^ aluB) & {32{op16_xor}}) |
          ((aluA | aluB) & {32{op16_or | op16_mv}}) |
          (rdata & {32{dly16_lw | dly16_lwsp}}) |
          ({{(32-1-PC_BITS-1){1'b0}}, pc_fetch_dly[PC_BITS-1:1], 1'b0} & {32{op16_jal | op16_jalr | trap}}); //  instruction following the jump (hence _dly)

  // Address Generation Unit (AGU)
  assign aguA = (pc_fetch & ~{(PC_BITS-1){trap | branch_taken}})
        | (pc_execute & {(PC_BITS-1){branch_taken}} & ~{(PC_BITS-1){op16_jr | op16_jalr | op16_slli_thunk}});

  assign aguB = (regS[PC_BITS-1:1] & {(PC_BITS-1){op16_jr | op16_jalr | op16_slli_thunk}})
        | ({{(PC_BITS-11){inst[12]}}, inst[8], inst[10:9], inst[6], inst[7], inst[2], inst[11], inst[5:3]}
              & {(PC_BITS-1){branch_taken & (op16_j | op16_jal)}})
        | ({{(PC_BITS-8){inst[12]}}, inst[6:5], inst[2], inst[11:10], inst[4:3]}
              & {(PC_BITS-1){branch_taken & (op16_bnez | op16_beqz)}})
        | (uc_base[PC_BITS-1:1] & {(PC_BITS-1){trap}});

  assign aguX = (aguA + aguB) + {{(PC_BITS-2){1'b0}}, ~(branch_taken | rreq | trap)};

  assign wb = trap |                  // writes microcode x1/ra
             dly16_lw | dly16_lwsp |  // writes data
             op16_jal | op16_jalr |   // writes x1/ra
             op16_li | op16_lui |
             op16_addi | op16_addi4spn | op16_addi16sp |
             op16_andi | op16_mv | op16_add |
             op16_and | op16_or | op16_xor | op16_sub |
             op16_slli | op16_srli | op16_srai;

  // Tracing
`ifdef ENABLE_TRACE
  initial begin
`ifdef COMPATIBLE_TRACE
      $display("FETCH1\t",
        "FETCH2\t",
        "EXECUTE\t",
        "aguA\t",
        "aguB\t",
        "aguX\t",
        "INST\t",
        "OPCODE\t",
        "addrD\t",
        "addrS\t",
        "regD\t\t",
        "regS\t\t",
        "aluA\t\t",
        "aluB\t\t",
        "aluS\t\t",
        "aluX");
`else
      $display(
          "  FETCH1"
        , "   FETCH2"
        , "  EXECUTE"
        , "     aguA"
        , "     aguB"
        , "     aguX"
        , "     INST"
        , " OPCODE  "
        , " addrD"
        , " addrS"
        , "     regD"
        , "     regS"
        , "     aluA"
        , "     aluB"
        , "     aluS"
        , "     aluX"
        , " FLAGS");
`endif
  end

  // This register can be viewed in the resulting VCD file by setting
  // the display type to "ASCII".
  reg [9*8:0] opcode;

  always @(posedge clk) begin
`ifdef COMPATIBLE_TRACE
      $write("%H\t", {pc_fetch, 1'b0});
      $write("%H\t", {pc_fetch_dly, 1'b0});
      $write("%H\t", {pc_execute, 1'b0});
      $write("%H\t", {aguA, 1'b0});
      $write("%H\t", {aguB, 1'b0});
      $write("%H\t", {aguX, 1'b0});
      $write("%H\t", inst);

      if(op16_addi4spn)        begin $write("ADI4SPN"); opcode = "ADI4SPN"; end
      else if(op16_lw)         begin $write("LW"); opcode = "LW"; end
      else if(op16_sw)         begin $write("SW"); opcode = "SW"; end
      else if(op16_addi)       begin $write("ADDI"); opcode = "ADDI"; end
      else if(op16_jal)        begin $write("JAL"); opcode = "JAL"; end
      else if(op16_li)         begin $write("LI"); opcode = "LI"; end
      else if(op16_addi16sp)   begin $write("ADI16SP"); opcode = "ADI16SP"; end
      else if(op16_lui)        begin $write("LUI"); opcode = "LUI"; end
      else if(op16_srli)       begin $write("SRLI"); opcode = "SRLI"; end
      else if(op16_srai)       begin $write("SRAI"); opcode = "SRAI"; end
      else if(op16_andi)       begin $write("ANDI"); opcode = "ANDI"; end
      else if(op16_sub)        begin $write("SUB"); opcode = "SUB"; end
      else if(op16_xor)        begin $write("XOR"); opcode = "XOR"; end
      else if(op16_or)         begin $write("OR"); opcode = "OR"; end
      else if(op16_and)        begin $write("AND"); opcode = "AND"; end
      else if(op16_j)          begin $write("J"); opcode = "J"; end
      else if(op16_beqz)       begin $write("BEQZ"); opcode = "BEQZ"; end
      else if(op16_bnez)       begin $write("BNEZ"); opcode = "BNEZ"; end
      else if(op16_slli)       begin $write("SLLI"); opcode = "SLLI"; end
      else if(op16_lwsp)       begin $write("LWSP"); opcode = "LWSP"; end
      else if(op16_jr)         begin $write("JR"); opcode = "JR"; end
      else if(op16_mv)         begin $write("MV"); opcode = "MV"; end
      else if(op16_ebreak)     begin $write("EBREAK"); opcode = "EBREAK"; end
      else if(op16_jalr)       begin $write("JALR"); opcode = "JALR"; end
      else if(op16_add)        begin $write("ADD"); opcode = "ADD"; end
      else if(op16_swsp)       begin $write("SWSP"); opcode = "SWSP"; end
      else if(op16_slli_thunk) begin $write("THUNK"); opcode = "THUNK"; end
      else if(op16_slli_setrd) begin $write("SETRD"); opcode = "SETRD"; end
      else if(op16_slli_setrs) begin $write("SETRS"); opcode = "SETRS"; end
      else if(op32)            begin $write("RV32I"); opcode = "RV32I"; end
      else if(bubble)          begin $write("BUBBL"); opcode = "BUBBLE"; end
      else                     begin $write("NOP?"); opcode = "NOP?"; end

      $write("\t%H", addrD);
      $write("\t%H", addrS);

      $write("\t%H", regD);
      $write("\t%H", regS);

      $write("\t%H", aluA);
      $write("\t%H", aluB);
      $write("\t%H", aluS);
      $write("\t%H", aluX);

      if(trap) begin
        $write("\tTRAP");
      end
      if(branch_taken) begin
        $write("\tTAKEN");
      end
      if(bubble) begin
        $write("\tBUBBLE");
      end
      if(wb) begin
        $write("\tWB");
      end
      if(reset) begin
        $write("\tRESET");
      end
      if(microcode) begin
        $write("\tMCODE");
      end
      if(| wmask) begin
        $write("\tWMASK=%H", wmask);
        $write("\tADDR=%H", addr);
        $write("\tWDATA=%H", wdata);
      end
      if(rreq) begin
        $write("\tRREQ");
        $write("\tADDR=%H", addr);
      end
      if(| dra) begin
        $write("\t@DRA=%H", dra);
      end
      $display("");
`else // `ifdef COMPATIBLE_TRACE
      $write("%8H ", {pc_fetch, 1'b0});
      $write("%8H ", {pc_fetch_dly, 1'b0});
      $write("%8H ", {pc_execute, 1'b0});
      $write("%8H ", {aguA, 1'b0});
      $write("%8H ", {aguB, 1'b0});
      $write("%8H ", {aguX, 1'b0});
      $write("%8H ", inst);

      if(op16_addi4spn)        begin $write("ADDI4SPN"); opcode = "ADDI4SPN"; end
      else if(op16_lw)         begin $write("LW      "); opcode = "LW      "; end
      else if(op16_sw)         begin $write("SW      "); opcode = "SW      "; end
      else if(op16_addi)       begin $write("ADDI    "); opcode = "ADDI    "; end
      else if(op16_jal)        begin $write("JAL     "); opcode = "JAL     "; end
      else if(op16_li)         begin $write("LI      "); opcode = "LI      "; end
      else if(op16_addi16sp)   begin $write("ADDI16SP"); opcode = "ADDI16SP"; end
      else if(op16_lui)        begin $write("LUI     "); opcode = "LUI     "; end
      else if(op16_srli)       begin $write("SRLI    "); opcode = "SRLI    "; end
      else if(op16_srai)       begin $write("SRAI    "); opcode = "SRAI    "; end
      else if(op16_andi)       begin $write("ANDI    "); opcode = "ANDI    "; end
      else if(op16_sub)        begin $write("SUB     "); opcode = "SUB     "; end
      else if(op16_xor)        begin $write("XOR     "); opcode = "XOR     "; end
      else if(op16_or)         begin $write("OR      "); opcode = "OR      "; end
      else if(op16_and)        begin $write("AND     "); opcode = "AND     "; end
      else if(op16_j)          begin $write("J       "); opcode = "J       "; end
      else if(op16_beqz)       begin $write("BEQZ    "); opcode = "BEQZ    "; end
      else if(op16_bnez)       begin $write("BNEZ    "); opcode = "BNEZ    "; end
      else if(op16_slli)       begin $write("SLLI    "); opcode = "SLLI    "; end
      else if(op16_lwsp)       begin $write("LWSP    "); opcode = "LWSP    "; end
      else if(op16_jr)         begin $write("JR      "); opcode = "JR      "; end
      else if(op16_mv)         begin $write("MV      "); opcode = "MV      "; end
      else if(op16_ebreak)     begin $write("EBREAK  "); opcode = "EBREAK  "; end
      else if(op16_jalr)       begin $write("JALR    "); opcode = "JALR    "; end
      else if(op16_add)        begin $write("ADD     "); opcode = "ADD     "; end
      else if(op16_swsp)       begin $write("SWSP    "); opcode = "SWSP    "; end
      else if(op16_slli_thunk) begin $write("THUNK   "); opcode = "THUNK   "; end
      else if(op16_slli_setrd) begin $write("SETRD   "); opcode = "SETRD   "; end
      else if(op16_slli_setrs) begin $write("SETRS   "); opcode = "SETRS   "; end
      else if(op32)            begin $write("RV32I   "); opcode = "RV32I   "; end
      else if(bubble)          begin $write("BUBBLE  "); opcode = "BUBBLE  "; end
      else                     begin $write("NOP?    "); opcode = "NOP?    "; end
      
      $write("  %1b.%2H", addrD[5], addrD[4:0]);
      $write("  %1b.%2H", addrS[5], addrS[4:0]);

      $write(" %8H", regD);
      $write(" %8H", regS);

      $write(" %8H", aluA);
      $write(" %8H", aluB);
      $write(" %8H", aluS);
      $write(" %8H", aluX);

      if(trap) begin
        $write(" TRAP");
      end
      if(branch_taken) begin
        $write(" TAKEN");
      end
      if(bubble) begin
        $write(" BUBBLE");
      end
      if(wb) begin
        $write(" WB");
      end
      if(reset) begin
        $write(" RESET");
      end
      if(microcode) begin
        $write(" MCODE");
      end
      if(| wmask) begin
        $write(" WMASK=%0h", wmask);
        $write(" ADDR=%0h", addr);
        $write(" WDATA=%0h", wdata);
      end
      if(rreq) begin
        $write(" RREQ");
        $write(" ADDR=%0h", addr);
      end
      if(| dra) begin
        $write(" @DRA=%0h", dra);
      end
      $display("");
`endif // `ifdef COMPATIBLE_TRACE
    end
`endif // `ifdef ENABLE_TRACE

endmodule
