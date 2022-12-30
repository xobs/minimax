module minimax #(
  // Parameters are currently unimplemented
  parameter PC_BITS = 12,
  parameter UC_BASE = 32'h00000000,
  parameter TRACE = 0
) (
  input  clk,
   input  reset,
   input  [15:0] inst,
   input  [31:0] rdata,
   output reg [11:0] inst_addr,
   output reg inst_regce,
   output reg [31:0] addr,
   output reg [31:0] wdata,
   output reg [3:0] wmask,
   output reg rreq);

  // Register file
  (* ram_style = "distributed" *) reg [31:0] register_file[63:0] ;

  // Register file address ports
  wire [5:0] addrS, addrD;
  wire [4:0] addrD_port, addrS_port;
  wire bD_banksel, bS_banksel;
  wire [31:0] regS, regD, aluA, aluB, aluS, aluX;

  // Program counter
  reg [10:0] pc_fetch, pc_fetch_dly, pc_execute;

  // PC ALU output
  wire [10:0] aguA, aguB, aguX;

  // Track bubbles and execution inhibits through the pipeline.
  reg bubble, bubble1, bubble2;
  reg branch_taken, microcode;
  reg trap, op16_trap, op32_trap;

  // Writeback and deferred writeback strobes
  wire wb;
  reg [4:0] dra;

  // Opcode masks for 16-bit instructions
  wire [15:0] inst_type_masked;
  wire [15:0] inst_type_masked_i16;
  wire [15:0] inst_type_masked_sr;
  wire [15:0] inst_type_masked_and;
  wire [15:0] inst_type_masked_op;
  wire [15:0] inst_type_masked_j;
  wire [15:0] inst_type_masked_mj;

  // Strobes for 16-bit instructions
  reg op16;
  reg op16_addi4spn;
  reg op16_lw, dly16_lw;
  reg op16_sw;

  reg op16_addi;
  reg op16_jal;
  reg op16_li;
  reg op16_addi16sp;
  reg op16_lui;

  reg op16_srli;
  reg op16_srai;
  reg op16_andi;
  reg op16_sub;
  reg op16_xor;
  reg op16_or;
  reg op16_and;
  reg op16_j;
  reg op16_beqz;
  reg op16_bnez;

  reg op16_slli;
  reg op16_lwsp, dly16_lwsp;
  reg op16_jr;
  reg op16_mv;

  reg op16_ebreak;
  reg op16_jalr;
  reg op16_add;
  reg op16_swsp;

  reg op16_slli_setrd, dly16_slli_setrd;
  reg op16_slli_setrs, dly16_slli_setrs;
  reg op16_slli_thunk;

  // Strobes for 32-bit instructions
  reg op32;

  assign inst_type_masked     = inst & 16'b111_0_00000_00000_11;
  assign inst_type_masked_i16 = inst & 16'b111_0_11111_00000_11;
  assign inst_type_masked_sr  = inst & 16'b111_1_11000_11111_11;
  assign inst_type_masked_and = inst & 16'b111_0_11000_00000_11;
  assign inst_type_masked_op  = inst & 16'b111_0_11000_11000_11;
  assign inst_type_masked_j   = inst & 16'b111_1_00000_11111_11;
  assign inst_type_masked_mj  = inst & 16'b111_1_00000_00000_11;

  always @* begin
    op16_addi4spn   = (inst_type_masked     == 16'b000_0_00000_00000_00) & ~bubble;
    op16_lw         = (inst_type_masked     == 16'b010_0_00000_00000_00) & ~bubble;
    op16_sw         = (inst_type_masked     == 16'b110_0_00000_00000_00) & ~bubble;
  
    op16_addi       = (inst_type_masked     == 16'b000_0_00000_00000_01) & ~bubble;
    op16_jal        = (inst_type_masked     == 16'b001_0_00000_00000_01) & ~bubble;
    op16_li         = (inst_type_masked     == 16'b010_0_00000_00000_01) & ~bubble;
    op16_addi16sp   = (inst_type_masked_i16 == 16'b011_0_00010_00000_01) & ~bubble;
    op16_lui        = (inst_type_masked     == 16'b011_0_00000_00000_01) & ~bubble & ~op16_addi16sp;
      
    op16_srli       = (inst_type_masked_sr  == 16'b100_0_00000_00001_01) & ~bubble;
    op16_srai       = (inst_type_masked_sr  == 16'b100_0_01000_00001_01) & ~bubble;
    op16_andi       = (inst_type_masked_and == 16'b100_0_10000_00000_01) & ~bubble;
    op16_sub        = (inst_type_masked_op  == 16'b100_0_11000_00000_01) & ~bubble;
    op16_xor        = (inst_type_masked_op  == 16'b100_0_11000_01000_01) & ~bubble;
    op16_or         = (inst_type_masked_op  == 16'b100_0_11000_10000_01) & ~bubble;
    op16_and        = (inst_type_masked_op  == 16'b100_0_11000_11000_01) & ~bubble;
    op16_j          = (inst_type_masked     == 16'b101_0_00000_00000_01) & ~bubble;
    op16_beqz       = (inst_type_masked     == 16'b110_0_00000_00000_01) & ~bubble;
    op16_bnez       = (inst_type_masked     == 16'b111_0_00000_00000_01) & ~bubble;
  
    op16_slli       = (inst_type_masked_j   == 16'b000_0_00000_00001_10) & ~bubble;
    op16_lwsp       = (inst_type_masked     == 16'b010_0_00000_00000_10) & ~bubble;
    op16_jr         = (inst_type_masked_j   == 16'b100_0_00000_00000_10) & ~bubble;
    op16_mv         = (inst_type_masked_mj  == 16'b100_0_00000_00000_10) & ~bubble & ~op16_jr;
    op16_ebreak     = (inst                 == 16'b100_1_00000_00000_10) & ~bubble;
    op16_jalr       = (inst_type_masked_j   == 16'b100_1_00000_00000_10) & ~bubble & ~op16_ebreak;
    op16_add        = (inst_type_masked_mj  == 16'b100_1_00000_00000_10) & ~bubble & ~op16_jalr & ~ op16_ebreak;
    op16_swsp       = (inst_type_masked     == 16'b110_0_00000_00000_10) & ~bubble;

    // Non-standard extensions to support microcode are permitted in these opcode gaps
    op16_slli_setrd = (inst_type_masked_j   == 16'b000_1_00000_00001_10) & ~bubble;
    op16_slli_setrs = (inst_type_masked_j   == 16'b000_1_00000_00010_10) & ~bubble;
    op16_slli_thunk = (inst_type_masked_j   == 16'b000_1_00000_00100_10) & ~bubble;

    // Blanket matches for RVC and RV32I instructions
    op32 = &(inst[1:0]) & ~bubble;
    op16 = ~&(inst[1:0]) & ~bubble;

    // Trap on unimplemented instructions
    op32_trap = op32;
    op16_trap = op16 & ~(
        op16_addi4spn | op16_lw | op16_sw |
        op16_addi | op16_jal | op16_li | op16_addi16sp | op16_lui |
        op16_srli | op16_srai | op16_andi | op16_sub| op16_xor| op16_or| op16_and| op16_j| op16_beqz| op16_bnez |
        op16_slli | op16_lwsp | op16_jr | op16_mv | op16_ebreak | op16_jalr | op16_add | op16_swsp |
        op16_slli_setrd | op16_slli_setrs | op16_slli_thunk);

    trap = op16_trap | op32_trap;

    // Data bus outputs tap directly off register/ALU path.
    wdata = regD;
    addr = aluS;
    rreq = op16_lwsp | op16_lw;
    wmask = 4'b1111 & {4{op16_swsp | op16_sw}};

    // Instruction bus outputs do too
    inst_addr = {pc_fetch, 1'b0};

    // PC logic
    bubble = bubble1 | bubble2;

    branch_taken = (op16_beqz & ~(|(regS)) | op16_bnez & (|(regS))) | op16_j | op16_jal | op16_jr | op16_jalr | op16_slli_thunk;

  end initial begin
    op16_addi4spn = 1'b0;
    op16_lw = 1'b0;
    op16_sw = 1'b0;

    op16_addi = 1'b0;
    op16_jal = 1'b0;
    op16_li = 1'b0;
    op16_addi16sp = 1'b0;
    op16_lui = 1'b0;

    op16_srli = 1'b0;
    op16_srai = 1'b0;
    op16_andi = 1'b0;
    op16_sub = 1'b0;
    op16_xor = 1'b0;
    op16_or = 1'b0;
    op16_and = 1'b0;
    op16_j = 1'b0;
    op16_beqz = 1'b0;
    op16_bnez = 1'b0;

    op16_slli = 1'b0;
    op16_lwsp = 1'b0;
    op16_jr = 1'b0;
    op16_mv = 1'b0;
    op16_ebreak = 1'b0;
    op16_jalr = 1'b0;
    op16_add = 1'b0;
    op16_swsp = 1'b0;

    op16_slli_setrd = 1'b0;
    op16_slli_setrs = 1'b0;
    op16_slli_thunk = 1'b0;

    op32 = 1'b0;
    op16 = 1'b0;

    op32_trap = 1'b0;
    op16_trap = 1'b0;

    trap = 1'b0;

    bubble = 1'b1;
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
      | (inst[11:7] & {5{op16_jr | op16_jalr | op16_slli_thunk | op16_slli}})
      | ({2'b01, inst[9:7]} & {5{op16_sw | op16_lw | op16_beqz | op16_bnez}})
      | ({2'b01, inst[4:2]} & {5{op16_and | op16_or | op16_xor | op16_sub}})
      | (inst[6:2] & {5{op16_mv & ~dly16_slli_setrs | op16_add}});

  // Select between "normal" and "microcode" register banks.
  assign bS_banksel = (microcode ^ dly16_slli_setrs) | trap;
  assign bD_banksel = (microcode ^ dly16_slli_setrd) | trap;

  assign addrD = {bD_banksel, addrD_port};
  assign addrS = {bS_banksel, addrS_port};

  assign aluA = (regD & {32{op16_add | op16_addi | op16_sub
                    | op16_and | op16_andi
                    | op16_or | op16_xor
                    | op16_addi16sp
                    | op16_slli | op16_srli | op16_srai}})
          | ({22'b0000000000000000000000, inst[10:7], inst[12:11], inst[5], inst[6], 2'b00} & {32{op16_addi4spn}})
          | ({24'b000000000000000000000000, inst[8:7], inst[12:9], 2'b00} & {32{op16_swsp}})
          | ({24'b000000000000000000000000, inst[3:2], inst[12], inst[6:4], 2'b00} & {32{op16_lwsp}})
          | ({25'b0000000000000000000000000, inst[5], inst[12:10], inst[6], 2'b00} & {32{op16_lw | op16_sw}});

  assign aluB = regS
          | ({{27{inst[12]}}, inst[6:2]} & {32{op16_addi | op16_andi | op16_li}})
          | ({{15{inst[12]}}, inst[6:2], 12'b000000000000} & {32{op16_lui}})
          | ({{23{inst[12]}}, inst[4:3], inst[5], inst[2], inst[6], 4'b0000} & {32{op16_addi16sp}});

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
          ({20'b0, pc_fetch_dly, 1'b0} & {32{op16_jal | op16_jalr | trap}});

  // Address Generation Unit (AGU)
  assign aguA = (pc_fetch & {11{~(trap | branch_taken)}})
        | ((pc_execute & {11{branch_taken}}) & {11{~(op16_jr | op16_jalr | op16_slli_thunk)}});

  assign aguB = (regS[11:1] & {11{op16_jr | op16_jalr | op16_slli_thunk}})
        | ({inst[12], inst[8], inst[10:9], inst[6], inst[7], inst[2], inst[11], inst[5:3]} & {11{branch_taken}} & {11{op16_j | op16_jal}})
        | ({{12{inst[12]}}, inst[6:5], inst[2], inst[11:10], inst[4:3]} & {11{branch_taken}} & {11{op16_bnez | op16_beqz}})
        | (11'b00000000000 & {11{trap}});

  assign aguX = (aguA + aguB) + {10'b0, ~(branch_taken | rreq | trap)};

  assign wb = trap |                  // writes microcode x1/ra
             dly16_lw | dly16_lwsp |  // writes data
             op16_jal | op16_jalr |   // writes x1/ra
             op16_li | op16_lui |
             op16_addi | op16_addi4spn | op16_addi16sp |
             op16_andi | op16_mv | op16_add |
             op16_and | op16_or | op16_xor | op16_sub |
             op16_slli | op16_srli | op16_srai;

  // Fetch Process
  always @(posedge clk) begin
    // Update fetch instruction unless we're hung up on a multi-cycle instruction word
    pc_fetch <= aguX & {11{~reset}};

    // Fetch misses create a 2-cycle penalty
    bubble2 <= reset | branch_taken | trap;

    // Multi-cycle instructions must correctly pause the fetch/execution pipeline
    bubble1 <= reset | bubble2 | rreq;

    if (rreq) begin
      pc_fetch_dly <= pc_fetch_dly;
      pc_execute <= pc_execute;
      inst_regce <= 1'b0;
    end else begin
      pc_fetch_dly <= pc_fetch;
      pc_execute <= pc_fetch_dly;
      inst_regce <= 1'b1;
    end

    microcode <= (microcode | trap) & ~(reset | op16_slli_thunk);

    // if (~(microcode | trap)) begin
    //   $display("Double trap!");
    //   $finish;
    // end

  end initial begin
    pc_fetch = 11'b00000000000;

    bubble2 = 1'b1;
    bubble1 = 1'b1;

    pc_fetch_dly = 11'b00000000000;
    pc_execute = 11'b00000000000;
    inst_regce = 1'b0;

    microcode = 1'b0;
  end

  // Datapath Process
  always @(posedge clk) begin
    dly16_lw <= op16_lw;
    dly16_lwsp <= op16_lwsp;
    dly16_slli_setrd <= op16_slli_setrd;
    dly16_slli_setrs <= op16_slli_setrs;

    // Load and setrs/setrd instructions complete a cycle after they are
    // initiated, so we need to keep some state.
    dra <= (regD[4:0] & ({5{op16_slli_setrd | op16_slli_setrs}})) |
           (({2'b01, inst[4:2]}) & ({5{op16_lw}})) |
           inst[11:7] & {5{op16_lwsp | op32}};

  end initial begin
    dly16_lw = 1'b0;
    dly16_lwsp = 1'b0;
    dly16_slli_setrd = 1'b0;
    dly16_slli_setrs = 1'b0;

    dra = 5'b00000;
  end

  initial begin
    register_file[63] = 32'b00000000000000000000000000000000;
    register_file[62] = 32'b00000000000000000000000000000000;
    register_file[61] = 32'b00000000000000000000000000000000;
    register_file[60] = 32'b00000000000000000000000000000000;
    register_file[59] = 32'b00000000000000000000000000000000;
    register_file[58] = 32'b00000000000000000000000000000000;
    register_file[57] = 32'b00000000000000000000000000000000;
    register_file[56] = 32'b00000000000000000000000000000000;
    register_file[55] = 32'b00000000000000000000000000000000;
    register_file[54] = 32'b00000000000000000000000000000000;
    register_file[53] = 32'b00000000000000000000000000000000;
    register_file[52] = 32'b00000000000000000000000000000000;
    register_file[51] = 32'b00000000000000000000000000000000;
    register_file[50] = 32'b00000000000000000000000000000000;
    register_file[49] = 32'b00000000000000000000000000000000;
    register_file[48] = 32'b00000000000000000000000000000000;
    register_file[47] = 32'b00000000000000000000000000000000;
    register_file[46] = 32'b00000000000000000000000000000000;
    register_file[45] = 32'b00000000000000000000000000000000;
    register_file[44] = 32'b00000000000000000000000000000000;
    register_file[43] = 32'b00000000000000000000000000000000;
    register_file[42] = 32'b00000000000000000000000000000000;
    register_file[41] = 32'b00000000000000000000000000000000;
    register_file[40] = 32'b00000000000000000000000000000000;
    register_file[39] = 32'b00000000000000000000000000000000;
    register_file[38] = 32'b00000000000000000000000000000000;
    register_file[37] = 32'b00000000000000000000000000000000;
    register_file[36] = 32'b00000000000000000000000000000000;
    register_file[35] = 32'b00000000000000000000000000000000;
    register_file[34] = 32'b00000000000000000000000000000000;
    register_file[33] = 32'b00000000000000000000000000000000;
    register_file[32] = 32'b00000000000000000000000000000000;
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
    register_file[0] = 32'b00000000000000000000000000000000;
  end
  assign regS = register_file[addrS];
  assign regD = register_file[addrD];

  // Regs proc
  always @(posedge clk) begin
    if (|(addrD[4:0]) & wb) begin
      register_file[addrD] <= aluX;
    end
  end
endmodule
