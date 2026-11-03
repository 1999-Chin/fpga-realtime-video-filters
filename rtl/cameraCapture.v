`timescale 1ns / 1ps

module cameraCapture(
    input pclk,
    input href,
    input vsync,
    input [7:0] d,
    output reg [16:0] addr,
    output reg [11:0] data_out,
    output reg we
);

    reg [9:0] x = 0;
    reg [9:0] y = 0;
    reg [7:0] fb;
    reg byte_state = 0;
    reg pre_href = 0;

    wire [3:0] red, green, blue;

    assign red = fb[7:4];
    assign green = {fb[2:0], d[7]};
    assign blue = d[4:1];

    always @(posedge pclk) begin
        if (vsync) begin
            addr <= 0;
            y <= 0;
            x <= 0;
            byte_state <= 0;
            we <= 0;
        end else if (!href) begin
            we <= 0;
            x <= 0;
            byte_state <= 0;
            if (pre_href == 1) begin
                y <= y + 1;
            end
        end else begin
            if (byte_state == 0) begin
                fb <= d;
                we <= 0;
                byte_state <= 1;
            end else begin
                if (y[0] == 0 && x[0] == 0 && addr < 76800) begin
                    data_out <= {red, green, blue};
                    we <= 1;
                    addr <= addr + 1;
                end else begin
                    we <= 0;
                end
                x <= x + 1;
                byte_state <= 0;
            end
        end
        pre_href <= href;
    end
endmodule
