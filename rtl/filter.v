`timescale 1ns / 1ps

module filter(
    input clk_25m,
    input [4:0] sw,
    input [3:0] r_raw, g_raw, b_raw,
    output reg [3:0] r_filtered, g_filtered, b_filtered
);

    wire [3:0] gray;

    assign gray = (r_raw * 5 + g_raw * 9 + b_raw * 2) >> 4;

    always @(posedge clk_25m) begin
        case (sw[4:0])
            5'b00000: begin //No filter
                r_filtered <= r_raw;
                g_filtered <= g_raw;
                b_filtered <= b_raw;
            end
            5'b00001: begin //Red color isolation filter
                if ((r_raw > g_raw + 2) && (r_raw > b_raw + 2)) begin
                    r_filtered <= r_raw;
                    g_filtered <= g_raw;
                    b_filtered <= b_raw;
                end else begin
                    r_filtered <= gray;
                    g_filtered <= gray;
                    b_filtered <= gray;
                end
            end
            5'b00010: begin //Green color isolation filter
                if ((g_raw > r_raw + 2) && (g_raw > b_raw + 2)) begin
                    r_filtered <= r_raw;
                    g_filtered <= g_raw;
                    b_filtered <= b_raw;
                end else begin
                    r_filtered <= gray;
                    g_filtered <= gray;
                    b_filtered <= gray;
                end
            end
            5'b00100: begin //Blue color isolation filter
                if ((b_raw > r_raw) && (b_raw > g_raw - 1)) begin
                    r_filtered <= r_raw;
                    g_filtered <= g_raw;
                    b_filtered <= b_raw;
                end else begin
                    r_filtered <= gray;
                    g_filtered <= gray;
                    b_filtered <= gray;
                end
            end
            5'b01000: begin //Grayscale filter
                r_filtered <= gray;
                g_filtered <= gray;
                b_filtered <= gray;
            end
            5'b10000: begin //Thresholding filter
                if (gray > 4'd8) begin
                    r_filtered <= 4'hF;
                    g_filtered <= 4'hF;
                    b_filtered <= 4'hF;
                end
                else begin
                    r_filtered <= 4'h0;
                    g_filtered <= 4'h0;
                    b_filtered <= 4'h0;
                end
            end
            default: begin //Black screen when turning more than one switch on
                r_filtered <= 4'h0;
                g_filtered <= 4'h0;
                b_filtered <= 4'h0;
            end
        endcase
    end
endmodule
