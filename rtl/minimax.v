module minimax (
  input  clk,
   input  reset,
   input  [15:0] inst,
   input  [31:0] rdata,
   output [11:0] inst_addr,
   output reg inst_regce,
   output [31:0] addr,
   output [31:0] wdata,
   output [3:0] wmask,
   output rreq);
  wire [5:0] addrS;
  wire [5:0] addrD;
  wire [31:0] regS;
  wire [31:0] regD;
  wire [31:0] aluA;
  wire [31:0] aluB;
  wire [31:0] aluS;
  wire [31:0] aluX;
  reg [10:0] pc_fetch;
  reg [10:0] pc_fetch_dly;
  reg [10:0] pc_execute;
  reg [10:0] agux;
  reg [10:0] agua;
  reg [10:0] agub;
  reg bubble;
  reg bubble1;
  reg bubble2;
  reg branch_taken;
  reg microcode;
  reg trap;
  reg op16_trap;
  reg op32_trap;
  reg wb;
  reg [4:0] dra;
  reg op16;
  reg op16_addi4spn;
  reg op16_lw;
  reg dly16_lw;
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
  reg op16_lwsp;
  reg dly16_lwsp;
  reg op16_jr;
  reg op16_mv;
  reg op16_ebreak;
  reg op16_jalr;
  reg op16_add;
  reg op16_swsp;
  reg op16_slli_setrd;
  reg dly16_slli_setrd;
  reg op16_slli_setrs;
  reg dly16_slli_setrs;
  reg op16_slli_thunk;
  reg op32;
  wire [15:0] inst_type_masked;
  wire [15:0] inst_type_masked_i16;
  wire [15:0] inst_type_masked_sr;
  wire [15:0] inst_type_masked_and;
  wire [15:0] inst_type_masked_op;
  wire [15:0] inst_type_masked_j;
  wire [15:0] inst_type_masked_mj;

  wire rd_banksel;
  wire rs_banksel;

  wire n288_o;
  wire [3:0] n290_o;
  wire [3:0] n291_o;
  wire [11:0] n293_o;
  wire n295_o;
  wire n296_o;
  wire n297_o;
  wire n298_o;
  wire n299_o;
  wire n300_o;
  wire n301_o;
  wire n302_o;
  wire n303_o;
  wire n304_o;
  wire n305_o;
  wire n324_o;
  wire n325_o;
  wire n327_o;
  wire n328_o;
  reg n343_q;
  wire [4:0] addrd_port;
  wire [4:0] addrs_port;
  wire [31:0] n645_o;
  wire [31:0] n646_o;
  wire [31:0] n647_o;
  wire n648_o;
  wire n649_o;
  wire n650_o;
  wire n651_o;
  wire n652_o;
  wire n653_o;
  wire n654_o;
  wire [31:0] n655_o;
  wire [31:0] n656_o;
  wire n657_o;
  wire n658_o;
  wire [30:0] n659_o;
  wire [31:0] n660_o;
  wire n661_o;
  wire [31:0] n662_o;
  wire [31:0] n663_o;
  wire [31:0] n664_o;
  wire [31:0] n665_o;
  wire n666_o;
  wire [31:0] n667_o;
  wire [31:0] n668_o;
  wire [31:0] n669_o;
  wire [31:0] n670_o;
  wire [31:0] n671_o;
  wire [31:0] n672_o;
  wire [31:0] n673_o;
  wire [31:0] n674_o;
  wire n675_o;
  wire [31:0] n676_o;
  wire [31:0] n677_o;
  wire [31:0] n678_o;
  wire n679_o;
  wire [31:0] n680_o;
  wire [31:0] n681_o;
  wire [31:0] n682_o;
  wire [11:0] n684_o;
  wire [31:0] n685_o;
  wire n686_o;
  wire n687_o;
  wire [31:0] n688_o;
  wire [31:0] n689_o;
  wire [31:0] n690_o;
  wire n691_o;
  wire n692_o;
  wire [10:0] n693_o;
  wire [10:0] n694_o;
  wire [10:0] n695_o;
  wire [10:0] n696_o;
  wire n697_o;
  wire n698_o;
  wire n699_o;
  wire [10:0] n700_o;
  wire [10:0] n701_o;
  wire [10:0] n702_o;
  wire [10:0] n703_o;
  wire n704_o;
  wire n705_o;
  wire [10:0] n706_o;
  wire [10:0] n707_o;
  wire n708_o;
  wire n709_o;
  wire [1:0] n710_o;
  wire [1:0] n711_o;
  wire [3:0] n712_o;
  wire n713_o;
  wire [4:0] n714_o;
  wire n715_o;
  wire [5:0] n716_o;
  wire n717_o;
  wire [6:0] n718_o;
  wire n719_o;
  wire [7:0] n720_o;
  wire [2:0] n721_o;
  wire [10:0] n722_o;
  wire [10:0] n723_o;
  wire [10:0] n724_o;
  wire n725_o;
  wire [10:0] n726_o;
  wire [10:0] n727_o;
  wire [10:0] n728_o;
  wire n729_o;
  wire n730_o;
  wire n731_o;
  wire n732_o;
  wire [3:0] n733_o;
  wire [1:0] n734_o;
  wire [5:0] n735_o;
  wire n736_o;
  wire [6:0] n737_o;
  wire [1:0] n738_o;
  wire [8:0] n739_o;
  wire [1:0] n740_o;
  wire [10:0] n741_o;
  wire [10:0] n742_o;
  wire [10:0] n743_o;
  wire n744_o;
  wire [10:0] n745_o;
  wire [10:0] n746_o;
  wire [10:0] n747_o;
  wire [10:0] n749_o;
  wire [10:0] n750_o;
  wire [10:0] n751_o;
  wire [10:0] n752_o;
  wire n753_o;
  wire n754_o;
  wire n755_o;
  wire [10:0] n756_o;
  wire [10:0] n757_o;
  wire n758_o;
  wire n759_o;
  wire n760_o;
  wire n761_o;
  wire n762_o;
  wire n763_o;
  wire n764_o;
  wire n765_o;
  wire n766_o;
  wire n767_o;
  wire n768_o;
  wire n769_o;
  wire n770_o;
  wire n771_o;
  wire n772_o;
  wire n773_o;
  wire n774_o;
  wire n775_o;
  wire n776_o;
  wire [4:0] n779_o;
  wire n780_o;
  wire n781_o;
  wire [31:0] n807_data; // mem_rd
  wire [31:0] n808_data; // mem_rd
  assign inst_addr = n293_o;
  assign addr = aluS;
  assign wdata = regD;
  assign wmask = n291_o;
  /* .\minimax.vhd:58:16  */
  assign regS = n807_data; // (signal)
  /* .\minimax.vhd:58:22  */
  assign regD = n808_data; // (signal)
  /* .\minimax.vhd:58:34  */
  /* .\minimax.vhd:174:21  */
  assign aluS = n646_o; // (signal)
  /* .\minimax.vhd:58:46  */
  assign aluX = n690_o; // (signal)
  /* .\minimax.vhd:64:16  */
  always @*
    agux = n757_o; // (isignal)
  initial
    agux = 11'b00000000000;
  /* .\minimax.vhd:64:22  */
  always @*
    agua = n702_o; // (isignal)
  initial
    agua = 11'b00000000000;
  /* .\minimax.vhd:64:28  */
  always @*
    agub = n751_o; // (isignal)
  initial
    agub = 11'b00000000000;
  /* .\minimax.vhd:68:16  */
  always @*
    branch_taken = n305_o; // (isignal)
  initial
    branch_taken = 1'b0;
  /* .\minimax.vhd:72:16  */
  always @*
    wb = n776_o; // (isignal)
  initial
    wb = 1'b0;

  always @* begin
    op16_addi4spn   = (inst_type_masked     == 16'b0000000000000000) & ~bubble;
    op16_lw         = (inst_type_masked     == 16'b0100000000000000) & ~bubble;
    op16_sw         = (inst_type_masked     == 16'b1100000000000000) & ~bubble;
  
    op16_addi       = (inst_type_masked     == 16'b0000000000000001) & ~bubble;
    op16_jal        = (inst_type_masked     == 16'b0010000000000001) & ~bubble;
    op16_li         = (inst_type_masked     == 16'b0100000000000001) & ~bubble;
    op16_addi16sp   = (inst_type_masked_i16 == 16'b0110000100000001) & ~bubble;
    op16_lui        = (inst_type_masked     == 16'b0110000000000001) & ~bubble & ~op16_addi16sp;
      
    op16_srli       = (inst_type_masked_sr  == 16'b1000000000000101) & ~bubble;
    op16_srai       = (inst_type_masked_sr  == 16'b1000010000000101) & ~bubble;
    op16_andi       = (inst_type_masked_and == 16'b1000100000000001) & ~bubble;
    op16_sub        = (inst_type_masked_op  == 16'b1000110000000001) & ~bubble;
    op16_xor        = (inst_type_masked_op  == 16'b1000110000100001) & ~bubble;
    op16_or         = (inst_type_masked_op  == 16'b1000110001000001) & ~bubble;
    op16_and        = (inst_type_masked_op  == 16'b1000110001100001) & ~bubble;
    op16_j          = (inst_type_masked     == 16'b1010000000000001) & ~bubble;
    op16_beqz       = (inst_type_masked     == 16'b1100000000000001) & ~bubble;
    op16_bnez       = (inst_type_masked     == 16'b1110000000000001) & ~bubble;
  
    op16_slli       = (inst_type_masked_j   == 16'b0000000000000110) & ~bubble;
    op16_lwsp       = (inst_type_masked     == 16'b0100000000000010) & ~bubble;
    op16_jr         = (inst_type_masked_j   == 16'b1000000000000010) & ~bubble;
    op16_mv         = (inst_type_masked_mj  == 16'b1000000000000010) & ~bubble & ~op16_jr;
    op16_ebreak     = (inst                 == 16'b1001000000000010) & ~bubble;
    op16_jalr       = (inst_type_masked_j   == 16'b1001000000000010) & ~bubble & ~op16_ebreak;
    op16_add        = (inst_type_masked_mj  == 16'b1001000000000010) & ~bubble & ~op16_jalr & ~ op16_ebreak;
    op16_swsp       = (inst_type_masked     == 16'b1100000000000010) & ~bubble;

    // Non-standard extensions to support microcode are permitted in these opcode gaps
    op16_slli_setrd = (inst_type_masked_j   == 16'b0001000000000110) & ~bubble;
    op16_slli_setrs = (inst_type_masked_j   == 16'b0001000000001010) & ~bubble;
    op16_slli_thunk = (inst_type_masked_j   == 16'b0001000000010010) & ~bubble;

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

    bubble = bubble1 | bubble2;

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
  assign inst_type_masked = inst & 16'b1110000000000011;
  assign inst_type_masked_i16 = inst & 16'b1110111110000011;
  assign inst_type_masked_sr = inst & 16'b1111110001111111;
  assign inst_type_masked_and = inst & 16'b1110110000000011;
  assign inst_type_masked_op = inst & 16'b1110110001100011;
  assign inst_type_masked_j = inst & 16'b1111000001111111;
  assign inst_type_masked_mj = inst & 16'b1111000000000011;

  /* .\minimax.vhd:175:27  */
  assign rreq = op16_lwsp | op16_lw;
  /* .\minimax.vhd:176:38  */
  assign n288_o = op16_swsp | op16_sw;
  /* .\minimax.vhd:176:23  */
  assign n290_o = {{3{n288_o}}, n288_o}; // sext
  /* .\minimax.vhd:176:23  */
  assign n291_o = 4'b1111 & n290_o;
  /* .\minimax.vhd:179:48  */
  assign n293_o = {pc_fetch, 1'b0};
  /* .\minimax.vhd:184:41  */
  assign n295_o = |(regS);
  /* .\minimax.vhd:184:41  */
  assign n296_o = ~n295_o;
  /* .\minimax.vhd:184:36  */
  assign n297_o = op16_beqz & n296_o;
  /* .\minimax.vhd:185:36  */
  assign n298_o = |(regS);
  /* .\minimax.vhd:185:31  */
  assign n299_o = op16_bnez & n298_o;
  /* .\minimax.vhd:185:17  */
  assign n300_o = n297_o | n299_o;
  /* .\minimax.vhd:186:17  */
  assign n301_o = n300_o | op16_j;
  /* .\minimax.vhd:186:27  */
  assign n302_o = n301_o | op16_jal;
  /* .\minimax.vhd:186:39  */
  assign n303_o = n302_o | op16_jr;
  /* .\minimax.vhd:186:50  */
  assign n304_o = n303_o | op16_jalr;
  /* .\minimax.vhd:187:17  */
  assign n305_o = n304_o | op16_slli_thunk;
  /* .\minimax.vhd:211:47  */
  assign n324_o = microcode & trap;
  /* .\minimax.vhd:211:32  */
  assign n325_o = ~n324_o;
  /* .\minimax.vhd:211:25  */
  assign n327_o = ~1'b1;
  /* .\minimax.vhd:211:25  */
  assign n328_o = n327_o | n325_o;
  // /* .\minimax.vhd:211:25  */
  // always @*
  //   if (!n343_q)
  //     $fatal(1, "assertion failure n329");
  /* .\minimax.vhd:189:9  */
  always @(posedge clk)
    n343_q <= n328_o;
  initial
    n343_q = 1'b1;
  /* .\minimax.vhd:280:47  */
  assign n645_o = aluA - aluB;
  /* .\minimax.vhd:280:63  */
  assign n646_o = op16_sub ? n645_o : n647_o;
  /* .\minimax.vhd:281:52  */
  assign n647_o = aluA + aluB;
  /* .\minimax.vhd:284:34  */
  assign n648_o = op16_add | op16_sub;
  /* .\minimax.vhd:284:46  */
  assign n649_o = n648_o | op16_addi;
  /* .\minimax.vhd:285:25  */
  assign n650_o = n649_o | op16_li;
  /* .\minimax.vhd:285:36  */
  assign n651_o = n650_o | op16_lui;
  /* .\minimax.vhd:286:25  */
  assign n652_o = n651_o | op16_addi4spn;
  /* .\minimax.vhd:286:42  */
  assign n653_o = n652_o | op16_addi16sp;
  /* .\minimax.vhd:287:25  */
  assign n654_o = n653_o | op16_slli;
  /* .\minimax.vhd:283:23  */
  assign n655_o = {{31{n654_o}}, n654_o}; // sext
  /* .\minimax.vhd:283:23  */
  assign n656_o = aluS & n655_o;
  /* .\minimax.vhd:288:38  */
  assign n657_o = aluA[31];
  /* .\minimax.vhd:288:30  */
  assign n658_o = op16_srai & n657_o;
  /* .\minimax.vhd:288:50  */
  assign n659_o = aluA[31:1];
  /* .\minimax.vhd:288:44  */
  assign n660_o = {n658_o, n659_o};
  /* .\minimax.vhd:288:80  */
  assign n661_o = op16_srai | op16_srli;
  /* .\minimax.vhd:288:65  */
  assign n662_o = {{31{n661_o}}, n661_o}; // sext
  /* .\minimax.vhd:288:65  */
  assign n663_o = n660_o & n662_o;
  /* .\minimax.vhd:287:40  */
  assign n664_o = n656_o | n663_o;
  /* .\minimax.vhd:289:24  */
  assign n665_o = aluA & aluB;
  /* .\minimax.vhd:289:49  */
  assign n666_o = op16_andi | op16_and;
  /* .\minimax.vhd:289:34  */
  assign n667_o = {{31{n666_o}}, n666_o}; // sext
  /* .\minimax.vhd:289:34  */
  assign n668_o = n665_o & n667_o;
  /* .\minimax.vhd:288:95  */
  assign n669_o = n664_o | n668_o;
  /* .\minimax.vhd:290:24  */
  assign n670_o = aluA ^ aluB;
  /* .\minimax.vhd:290:34  */
  assign n671_o = {{31{op16_xor}}, op16_xor}; // sext
  /* .\minimax.vhd:290:34  */
  assign n672_o = n670_o & n671_o;
  /* .\minimax.vhd:289:63  */
  assign n673_o = n669_o | n672_o;
  /* .\minimax.vhd:291:24  */
  assign n674_o = aluA | aluB;
  /* .\minimax.vhd:291:46  */
  assign n675_o = op16_or | op16_mv;
  /* .\minimax.vhd:291:33  */
  assign n676_o = {{31{n675_o}}, n675_o}; // sext
  /* .\minimax.vhd:291:33  */
  assign n677_o = n674_o & n676_o;
  /* .\minimax.vhd:290:50  */
  assign n678_o = n673_o | n677_o;
  /* .\minimax.vhd:292:38  */
  assign n679_o = dly16_lw | dly16_lwsp;
  /* .\minimax.vhd:292:24  */
  assign n680_o = {{31{n679_o}}, n679_o}; // sext
  /* .\minimax.vhd:292:24  */
  assign n681_o = rdata & n680_o;
  /* .\minimax.vhd:291:59  */
  assign n682_o = n678_o | n681_o;
  /* .\minimax.vhd:293:55  */
  assign n684_o = {pc_fetch_dly, 1'b0};
  /* .\minimax.vhd:293:35  */
  assign n685_o = {20'b0, n684_o};  //  uext
  /* .\minimax.vhd:293:80  */
  assign n686_o = op16_jal | op16_jalr;
  /* .\minimax.vhd:293:93  */
  assign n687_o = n686_o | trap;
  /* .\minimax.vhd:293:66  */
  assign n688_o = {{31{n687_o}}, n687_o}; // sext
  /* .\minimax.vhd:293:66  */
  assign n689_o = n685_o & n688_o;
  /* .\minimax.vhd:292:54  */
  assign n690_o = n682_o | n689_o;
  /* .\minimax.vhd:296:41  */
  assign n691_o = trap | branch_taken;
  /* .\minimax.vhd:296:31  */
  assign n692_o = ~n691_o;
  /* .\minimax.vhd:296:27  */
  assign n693_o = {{10{n692_o}}, n692_o}; // sext
  /* .\minimax.vhd:296:27  */
  assign n694_o = pc_fetch & n693_o;
  /* .\minimax.vhd:297:32  */
  assign n695_o = {{10{branch_taken}}, branch_taken}; // sext
  /* .\minimax.vhd:297:32  */
  assign n696_o = pc_execute & n695_o;
  /* .\minimax.vhd:297:66  */
  assign n697_o = op16_jr | op16_jalr;
  /* .\minimax.vhd:297:79  */
  assign n698_o = n697_o | op16_slli_thunk;
  /* .\minimax.vhd:297:53  */
  assign n699_o = ~n698_o;
  /* .\minimax.vhd:297:49  */
  assign n700_o = {{10{n699_o}}, n699_o}; // sext
  /* .\minimax.vhd:297:49  */
  assign n701_o = n696_o & n700_o;
  /* .\minimax.vhd:297:17  */
  assign n702_o = n694_o | n701_o;
  /* .\minimax.vhd:299:31  */
  assign n703_o = regS[11:1];
  /* .\minimax.vhd:299:58  */
  assign n704_o = op16_jr | op16_jalr;
  /* .\minimax.vhd:299:71  */
  assign n705_o = n704_o | op16_slli_thunk;
  /* .\minimax.vhd:299:45  */
  assign n706_o = {{10{n705_o}}, n705_o}; // sext
  /* .\minimax.vhd:299:45  */
  assign n707_o = n703_o & n706_o;
  /* .\minimax.vhd:300:75  */
  assign n708_o = inst[12];
  /* .\minimax.vhd:300:87  */
  assign n709_o = inst[8];
  /* .\minimax.vhd:300:81  */
  assign n710_o = {n708_o, n709_o};
  /* .\minimax.vhd:300:97  */
  assign n711_o = inst[10:9];
  /* .\minimax.vhd:300:91  */
  assign n712_o = {n710_o, n711_o};
  /* .\minimax.vhd:300:117  */
  assign n713_o = inst[6];
  /* .\minimax.vhd:300:111  */
  assign n714_o = {n712_o, n713_o};
  /* .\minimax.vhd:300:127  */
  assign n715_o = inst[7];
  /* .\minimax.vhd:300:121  */
  assign n716_o = {n714_o, n715_o};
  /* .\minimax.vhd:300:137  */
  assign n717_o = inst[2];
  /* .\minimax.vhd:300:131  */
  assign n718_o = {n716_o, n717_o};
  /* .\minimax.vhd:300:147  */
  assign n719_o = inst[11];
  /* .\minimax.vhd:300:141  */
  assign n720_o = {n718_o, n719_o};
  /* .\minimax.vhd:300:158  */
  assign n721_o = inst[5:3];
  /* .\minimax.vhd:300:152  */
  assign n722_o = {n720_o, n721_o};
  /* .\minimax.vhd:301:25  */
  assign n723_o = {{10{branch_taken}}, branch_taken}; // sext
  /* .\minimax.vhd:301:25  */
  assign n724_o = n722_o & n723_o;
  /* .\minimax.vhd:301:54  */
  assign n725_o = op16_j | op16_jal;
  /* .\minimax.vhd:301:42  */
  assign n726_o = {{10{n725_o}}, n725_o}; // sext
  /* .\minimax.vhd:301:42  */
  assign n727_o = n724_o & n726_o;
  /* .\minimax.vhd:300:17  */
  assign n728_o = n707_o | n727_o;
  /* .\minimax.vhd:302:74  */
  assign n729_o = inst[12];
  /* .\minimax.vhd:302:74  */
  assign n730_o = inst[12];
  /* .\minimax.vhd:302:74  */
  assign n731_o = inst[12];
  /* .\minimax.vhd:302:74  */
  assign n732_o = inst[12];
  assign n733_o = {n729_o, n730_o, n731_o, n732_o};
  /* .\minimax.vhd:302:86  */
  assign n734_o = inst[6:5];
  /* .\minimax.vhd:302:80  */
  assign n735_o = {n733_o, n734_o};
  /* .\minimax.vhd:302:105  */
  assign n736_o = inst[2];
  /* .\minimax.vhd:302:99  */
  assign n737_o = {n735_o, n736_o};
  /* .\minimax.vhd:302:115  */
  assign n738_o = inst[11:10];
  /* .\minimax.vhd:302:109  */
  assign n739_o = {n737_o, n738_o};
  /* .\minimax.vhd:302:136  */
  assign n740_o = inst[4:3];
  /* .\minimax.vhd:302:130  */
  assign n741_o = {n739_o, n740_o};
  /* .\minimax.vhd:303:25  */
  assign n742_o = {{10{branch_taken}}, branch_taken}; // sext
  /* .\minimax.vhd:303:25  */
  assign n743_o = n741_o & n742_o;
  /* .\minimax.vhd:303:57  */
  assign n744_o = op16_bnez | op16_beqz;
  /* .\minimax.vhd:303:42  */
  assign n745_o = {{10{n744_o}}, n744_o}; // sext
  /* .\minimax.vhd:303:42  */
  assign n746_o = n743_o & n745_o;
  /* .\minimax.vhd:302:17  */
  assign n747_o = n728_o | n746_o;
  /* .\minimax.vhd:304:55  */
  assign n749_o = {{10{trap}}, trap}; // sext
  /* .\minimax.vhd:304:55  */
  assign n750_o = 11'b00000000000 & n749_o;
  /* .\minimax.vhd:304:17  */
  assign n751_o = n747_o | n750_o;
  /* .\minimax.vhd:306:23  */
  assign n752_o = agua + agub;
  /* .\minimax.vhd:306:51  */
  assign n753_o = branch_taken | rreq;
  /* .\minimax.vhd:306:59  */
  assign n754_o = n753_o | trap;
  /* .\minimax.vhd:306:33  */
  assign n755_o = ~n754_o;
  /* .\minimax.vhd:306:31  */
  assign n756_o = {10'b0, n755_o};  //  uext
  /* .\minimax.vhd:306:31  */
  assign n757_o = n752_o + n756_o;
  /* .\minimax.vhd:308:20  */
  assign n758_o = trap | dly16_lw;
  /* .\minimax.vhd:309:26  */
  assign n759_o = n758_o | dly16_lwsp;
  /* .\minimax.vhd:309:40  */
  assign n760_o = n759_o | op16_jal;
  /* .\minimax.vhd:310:26  */
  assign n761_o = n760_o | op16_jalr;
  /* .\minimax.vhd:310:39  */
  assign n762_o = n761_o | op16_li;
  /* .\minimax.vhd:311:25  */
  assign n763_o = n762_o | op16_lui;
  /* .\minimax.vhd:311:37  */
  assign n764_o = n763_o | op16_addi;
  /* .\minimax.vhd:312:27  */
  assign n765_o = n764_o | op16_addi4spn;
  /* .\minimax.vhd:312:44  */
  assign n766_o = n765_o | op16_addi16sp;
  /* .\minimax.vhd:312:61  */
  assign n767_o = n766_o | op16_andi;
  /* .\minimax.vhd:313:27  */
  assign n768_o = n767_o | op16_mv;
  /* .\minimax.vhd:313:38  */
  assign n769_o = n768_o | op16_add;
  /* .\minimax.vhd:313:50  */
  assign n770_o = n769_o | op16_and;
  /* .\minimax.vhd:314:26  */
  assign n771_o = n770_o | op16_or;
  /* .\minimax.vhd:314:37  */
  assign n772_o = n771_o | op16_xor;
  /* .\minimax.vhd:314:49  */
  assign n773_o = n772_o | op16_sub;
  /* .\minimax.vhd:314:61  */
  assign n774_o = n773_o | op16_slli;
  /* .\minimax.vhd:315:27  */
  assign n775_o = n774_o | op16_srli;
  /* .\minimax.vhd:315:40  */
  assign n776_o = n775_o | op16_srai;
  /* .\minimax.vhd:321:37  */
  assign n779_o = addrD[4:0];
  /* .\minimax.vhd:321:29  */
  assign n780_o = |(n779_o);
  /* .\minimax.vhd:321:51  */
  assign n781_o = n780_o & wb;

  // READ/WRITE register file port
  assign addrd_port = (dra & {5{dly16_slli_setrd | dly16_lw | dly16_lwsp}})
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
  assign addrs_port = (dra & {5{dly16_slli_setrs}})
      | (5'b00010 & {5{op16_addi4spn | op16_lwsp | op16_swsp}})
      | (inst[11:7] & {5{op16_jr | op16_jalr | op16_slli_thunk | op16_slli}})
      | ({2'b01, inst[9:7]} & {5{op16_sw | op16_lw | op16_beqz | op16_bnez}})
      | ({2'b01, inst[4:2]} & {5{op16_and | op16_or | op16_xor | op16_sub}})
      | (inst[6:2] & {5{op16_mv & ~dly16_slli_setrs | op16_add}});

  // Select between "normal" and "microcode" register banks.
  assign rs_banksel = (microcode ^ dly16_slli_setrs) | trap;
  assign rd_banksel = (microcode ^ dly16_slli_setrd) | trap;

  assign addrD = {rd_banksel, addrd_port};
  assign addrS = {rs_banksel, addrs_port};

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

  // Fetch Process
  always @(posedge clk) begin
    // Update fetch instruction unless we're hung up on a multi-cycle instruction word
    pc_fetch <= agux & {11{~reset}};

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

  /* .\minimax.vhd:261:31  */
  reg [31:0] register_file[63:0] ; // memory
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
  assign n807_data = register_file[addrS];
  assign n808_data = register_file[addrD];
  always @(posedge clk)
    if (n781_o)
      register_file[addrD] <= aluX;
  /* .\minimax.vhd:262:31  */
  /* .\minimax.vhd:261:31  */
  /* .\minimax.vhd:322:47  */
endmodule
