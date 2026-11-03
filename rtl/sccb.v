`timescale 1ns / 1ps

module sccb(
    input  wire clk,     // 25MHz Master Clock
    output wire sioc,    // SCCB Clock
    inout  wire siod     // SCCB Data
);

    // Clock Divider
    // Generate ~390kHz internal SCCB timing clock
    reg [7:0] clk_div = 0;
    reg i2c_clk = 0;

    always @(posedge clk) begin
        if (clk_div == 8'd31) begin
            clk_div <= 0;
            i2c_clk <= ~i2c_clk;
        end
        else begin
            clk_div <= clk_div + 1'b1;
        end
    end

    // Camera Register ROM
    reg [7:0] reg_idx = 0;
    reg [15:0] reg_data;

    wire [7:0] TOTAL_REGS = 8;
    wire [7:0] ID_ADDR    = 8'h42;

    always @(*) begin
        case(reg_idx)

            0: reg_data = 16'h1280; // COM7 : RESET
            1: reg_data = 16'h1101; // CLKRC
            2: reg_data = 16'h6B4A; // PLL
            3: reg_data = 16'h1204; // RGB mode
            4: reg_data = 16'h8C00; // Disable RGB444
            5: reg_data = 16'h40D0; // RGB565
            6: reg_data = 16'h3A04; // TSLB
            7: reg_data = 16'hB084; // Magic register

            default: reg_data = 16'hFFFF;

        endcase
    end

    // SCCB Internal Signals
    reg [3:0] state = 0;
    reg [1:0] phase = 0;

    reg [5:0]  bit_cnt = 0;
    reg [23:0] shift_reg = 0;

    reg sioc_reg = 1;
    reg siod_reg = 1;
    reg siod_out_en = 1;

    reg [9:0] delay_cnt = 0;

    assign sioc = sioc_reg;

    // Open-drain behavior
    assign siod = (siod_out_en && (siod_reg == 1'b0))
                ? 1'b0
                : 1'bz;

    // State Definitions
    localparam ST_IDLE  = 4'd0;
    localparam ST_START = 4'd1;
    localparam ST_BIT   = 4'd2;
    localparam ST_ACK   = 4'd3;
    localparam ST_NEXT  = 4'd4;
    localparam ST_STOP  = 4'd5;

    // SCCB Main FSM
    always @(posedge i2c_clk) begin

        case(state)

        // IDLE
        ST_IDLE: begin

            if (reg_idx < TOTAL_REGS) begin

                // Delay after reset command
                if (reg_idx == 1 && delay_cnt < 10'd400) begin
                    delay_cnt <= delay_cnt + 1'b1;
                end
                else begin

                    shift_reg <= {
                        ID_ADDR,
                        reg_data[15:8],
                        reg_data[7:0]
                    };

                    sioc_reg <= 1'b1;
                    siod_reg <= 1'b1;
                    siod_out_en <= 1'b1;

                    phase <= 0;
                    state <= ST_START;

                end
            end
        end

        // START CONDITION
        ST_START: begin

            // SDA falls while SCL stays HIGH
            siod_reg <= 1'b0;

            bit_cnt <= 6'd23;

            phase <= 0;
            state <= ST_BIT;

        end

        // SEND DATA BIT (4-Phase)
        ST_BIT: begin

            case(phase)

            // Phase 0 : Pull clock LOW
            2'd0: begin
                sioc_reg <= 1'b0;
                phase <= 2'd1;
            end

            // Phase 1 : Put data on SDA
            2'd1: begin

                siod_out_en <= 1'b1;
                siod_reg <= shift_reg[bit_cnt];

                phase <= 2'd2;
            end

            // Phase 2 : Clock HIGH
            2'd2: begin
                sioc_reg <= 1'b1;
                phase <= 2'd3;
            end

            // Phase 3 : Hold
            2'd3: begin

                if (bit_cnt == 16 ||
                    bit_cnt == 8  ||
                    bit_cnt == 0) begin

                    phase <= 0;
                    state <= ST_ACK;

                end
                else begin

                    bit_cnt <= bit_cnt - 1'b1;
                    phase <= 0;

                end
            end

            endcase
        end

        // ACK / DON'T CARE BIT
        ST_ACK: begin

            case(phase)

            // Phase 0 : Clock LOW
            2'd0: begin
                sioc_reg <= 1'b0;
                phase <= 2'd1;
            end

            // Phase 1 : Release SDA
            2'd1: begin
                siod_out_en <= 1'b0;
                phase <= 2'd2;
            end

            // Phase 2 : Clock HIGH
            2'd2: begin
                sioc_reg <= 1'b1;
                phase <= 2'd3;
            end

            // Phase 3 : Hold
            2'd3: begin

                if (bit_cnt == 0) begin

                    phase <= 0;
                    state <= ST_STOP;

                end
                else begin

                    bit_cnt <= bit_cnt - 1'b1;

                    phase <= 0;
                    state <= ST_NEXT;

                end
            end

            endcase
        end

        // Resume transmission after ACK
        ST_NEXT: begin

            sioc_reg <= 1'b0;
            siod_out_en <= 1'b1;

            state <= ST_BIT;

        end

        // STOP CONDITION
        ST_STOP: begin

            case(phase)

            // Phase 0 : Pull LOW
            2'd0: begin

                sioc_reg <= 1'b0;

                siod_out_en <= 1'b1;
                siod_reg <= 1'b0;

                phase <= 2'd1;

            end

            // Phase 1 : Clock HIGH
            2'd1: begin

                sioc_reg <= 1'b1;

                phase <= 2'd2;

            end

            // Phase 2 : SDA HIGH => STOP
            2'd2: begin

                siod_reg <= 1'b1;

                phase <= 2'd3;

            end

            // Phase 3 : Finish register
            2'd3: begin

                reg_idx <= reg_idx + 1'b1;

                phase <= 0;
                state <= ST_IDLE;

            end

            endcase
        end

        // Default
        default: begin
            state <= ST_IDLE;
        end

        endcase
    end

endmodule
