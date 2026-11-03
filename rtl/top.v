`timescale 1ns / 1ps

module top(
    input clk_100mhz,
    input reset,
    inout ov7670_siod,
    input ov7670_pclk,
    input ov7670_vsync,
    input ov7670_href,
    input [7:0] ov7670_data,
    input [4:0] sw,
    output ov7670_sioc,
    output ov7670_xclk,
    output ov7670_pwdn,
    output ov7670_rst,
    output [3:0] vga_r, vga_g, vga_b,
    output vga_hsync,
    output vga_vsync
);

    wire clk_25m;
    wire clk_24m;

    wire [11:0] capture_data;

    wire [16:0] addra;
    wire [16:0] addrb;
    wire [11:0] pixel_from_bram;
    wire we;

    wire [3:0] r_raw, g_raw, b_raw;

    clk_wiz_0 clock_gen (
        .clk_in1(clk_100mhz),
        .clk_out1(clk_25m),
        .clk_out2(clk_24m)
    );

    sccb config_inst (
        .clk(clk_25m),
        .sioc(ov7670_sioc),
        .siod(ov7670_siod)
    );

    cameraCapture capture_inst (
        .pclk(ov7670_pclk),
        .href(ov7670_href),
        .vsync(ov7670_vsync),
        .d(ov7670_data),
        .addr(addra),
        .data_out(capture_data),
        .we(we)
    );

    blk_mem_gen_0 ram_inst (
        .addra(addra),
        .clka(ov7670_pclk),
        .dina(capture_data),
        .wea(we),
        .addrb(addrb),
        .clkb(clk_25m),
        .doutb(pixel_from_bram)
    );

    vga vga_inst (
        .clk_25mhz(clk_25m),
        .bram_data(pixel_from_bram),
        .bram_addr(addrb),
        .hsync(vga_hsync),
        .vsync(vga_vsync),
        .vga_r(r_raw),
        .vga_g(g_raw),
        .vga_b(b_raw)
    );

    filter filter_inst (
        .clk_25m(clk_25m),
        .sw(sw),
        .r_raw(r_raw),
        .g_raw(g_raw),
        .b_raw(b_raw),
        .r_filtered(vga_r),
        .g_filtered(vga_g),
        .b_filtered(vga_b)
    );

    assign ov7670_xclk = clk_24m;
    assign ov7670_pwdn = 1'b0;
    assign ov7670_rst  = 1'b1;

endmodule
