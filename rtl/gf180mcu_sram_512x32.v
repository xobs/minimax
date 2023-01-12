// Tie 
module gf180mcu_sram_512x32(
    input  clk,
    input  reset,
    input  en,
    input  [8:0] addr,
    output [31:0] rdata,
    input  [31:0] wdata,
    input  wen);

    wire [7:0] wen_mask;
    reg was_reset;

    assign wen_mask = {8{~wen}};

    reg was_en;
    wire cen;

    // want: If `en` is 1, then when clk is high we should transition
    // high->low then low->high

    assign cen = ~(en & ~was_en | clk);
    always @(posedge clk) begin
        if (reset)
            was_en <= 1'b0;
        else
            was_en <= ~cen;
    end

    gf180mcu_fd_ip_sram__sram512x8m8wm1 ram0 (
        .CLK(clk),
        .CEN(cen),
        .GWEN(~wen),
        .WEN(wen_mask),
        .A(addr),
        .D(wdata[7:0]),
        .Q(rdata[7:0])
    );

    gf180mcu_fd_ip_sram__sram512x8m8wm1 ram1 (
        .CLK(clk),
        .CEN(cen),
        .GWEN(~wen),
        .WEN(wen_mask),
        .A(addr),
        .D(wdata[15:8]),
        .Q(rdata[15:8])
    );

    gf180mcu_fd_ip_sram__sram512x8m8wm1 ram2 (
        .CLK(clk),
        .CEN(cen),
        .GWEN(~wen),
        .WEN(wen_mask),
        .A(addr),
        .D(wdata[23:16]),
        .Q(rdata[23:16])
    );

    gf180mcu_fd_ip_sram__sram512x8m8wm1 ram3 (
        .CLK(clk),
        .CEN(cen),
        .GWEN(~wen),
        .WEN(wen_mask),
        .A(addr),
        .D(wdata[31:24]),
        .Q(rdata[31:24])
    );
endmodule
