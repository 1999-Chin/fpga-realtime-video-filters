`timescale 1ns / 1ps

module vga (
    input wire clk_25mhz,
    input wire [11:0] bram_data,

    output reg [16:0] bram_addr,
    output reg hsync,
    output reg vsync,
    output reg [3:0] vga_r,
    output reg [3:0] vga_g,
    output reg [3:0] vga_b
);

    // VGA Timing Constants (640x480 @ 60Hz)
    parameter H_DISPLAY       = 640;
    parameter H_FRONT_PORCH   = 16;
    parameter H_SYNC_PULSE    = 96;
    parameter H_BACK_PORCH    = 48;
    parameter H_TOTAL         = 800;

    parameter V_DISPLAY       = 480;
    parameter V_FRONT_PORCH   = 10;
    parameter V_SYNC_PULSE    = 2;
    parameter V_BACK_PORCH    = 33;
    parameter V_TOTAL         = 525;

    reg [9:0] h_count;
    reg [9:0] v_count;

    wire active_video;
    reg active_video_delay;
    reg hsync_delay;
    reg vsync_delay;

    wire [8:0] x_qvga;
    wire [8:0] y_qvga;

    wire hsync_next = ~((h_count >= H_DISPLAY + H_FRONT_PORCH) &&
                        (h_count < H_DISPLAY + H_FRONT_PORCH + H_SYNC_PULSE));

    wire vsync_next = ~((v_count >= V_DISPLAY + V_FRONT_PORCH) &&
                        (v_count < V_DISPLAY + V_FRONT_PORCH + V_SYNC_PULSE));

    assign active_video = (h_count < H_DISPLAY) && (v_count < V_DISPLAY);

    // We drop the lowest bit (divide by 2) to scale 320x240 up to 640x480
    assign x_qvga = h_count >> 1;
    assign y_qvga = v_count >> 1;

    // Address = (Y * 320) + X
    // (Y * 320) = (Y * 256) + (Y * 64) = (Y << 8) + (Y << 6)
    always @(*) begin
        if (active_video) begin
            bram_addr = (y_qvga << 8) + (y_qvga << 6) + x_qvga;
        end else begin
            bram_addr = 17'd0;
        end
    end

    // BRAM takes 1 clock cycle to output data after receiving an address.
    // We must delay the active video and sync signals by 1 clock cycle
    // so the monitor gets the color perfectly aligned with the syncs.
    always @(posedge clk_25mhz) begin
        if (h_count == H_TOTAL - 1) begin
            h_count <= 0;
            if (v_count == V_TOTAL - 1)
                v_count <= 0;
            else
                v_count <= v_count + 1;
        end else begin
            h_count <= h_count + 1;
        end
        active_video_delay <= active_video;
        hsync_delay        <= hsync_next;
        vsync_delay        <= vsync_next;

        // Output syncs
        hsync <= hsync_delay;
        vsync <= vsync_delay;

        // Output colors: Only draw when in the active region
        if (active_video_delay) begin
            vga_r <= bram_data[11:8];
            vga_g <= bram_data[7:4];
            vga_b <= bram_data[3:0];
        end else begin
            // Output black during front porch, sync pulse, and back porch
            vga_r <= 4'd0;
            vga_g <= 4'd0;
            vga_b <= 4'd0;
        end
    end

endmodule
