`timescale 1ns / 1ps

module uart_tx (  // uart FSM
    input        clk,
    input        rst,
    input        start,
    input        b_tick,
    input  [7:0] tx_data,
    output       tx_busy,
    output       tx
);

    // define state parameter
    parameter [2:0] IDLE = 0, WAIT = 1, START = 2, DATA = 3, STOP = 4;

    // define state
    reg [7:0] c_data, n_data;
    reg [3:0] c_tick_cnt, n_tick_cnt;
    reg [2:0] c_s, n_s, c_bit_cnt, n_bit_cnt;
    reg c_tx, n_tx;
    reg c_tx_busy, n_tx_busy;

    // assign output
    assign tx = c_tx;
    assign tx_busy = c_tx_busy;

    // state register
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_s        <= IDLE;
            c_tx       <= 1'b1;
            c_tx_busy  <= 1'b0;
            c_bit_cnt  <= 0;
            c_tick_cnt <= 4'h0;
            c_data     <= 8'h0;
        end else begin
            c_s        <= n_s;
            c_tx       <= n_tx;
            c_tx_busy  <= n_tx_busy;
            c_bit_cnt  <= n_bit_cnt;
            c_tick_cnt <= n_tick_cnt;
            c_data     <= n_data;
        end
    end

    // next state combinational logic + output combinational logic
    always @(*) begin
        n_s        = c_s;
        n_tx       = c_tx;
        n_tx_busy  = c_tx_busy;
        n_bit_cnt  = c_bit_cnt;
        n_tick_cnt = c_tick_cnt;
        n_data     = c_data;
        case (c_s)
            IDLE: begin
                n_tx       = 1'b1;
                n_tx_busy  = 1'b0;  // moore machine
                n_tick_cnt = 0;
                if (start) begin
                    //n_tx_busy = 1'b1;
                    n_data = tx_data;
                    n_s = WAIT;  // if write tx_busy at here => mealy machine
                end
            end
            WAIT: begin
                n_tx_busy = 1'b1;
                if (b_tick) begin
                    n_s = START;
                end
            end
            START: begin
                n_tx      = 1'b0;
                n_bit_cnt = 0;
                if (b_tick) begin
                    if (c_tick_cnt == 15) begin
                        n_s = DATA;
                        n_tick_cnt = 0;
                    end else begin
                        n_tick_cnt = c_tick_cnt + 1;
                    end
                end
            end
            DATA: begin
                n_tx = c_data[0];  // LSB out // tx_data[c_bit_cnt] <= mux
                if (b_tick) begin
                    if (c_tick_cnt == 15) begin
                        n_data = c_data >> 1;  // shift register
                        n_tick_cnt = 0;
                        if (c_bit_cnt == 7) begin
                            n_s = STOP;
                        end else begin
                            n_bit_cnt = c_bit_cnt + 1;
                            n_s       = DATA;
                        end
                    end else begin
                        n_tick_cnt = c_tick_cnt + 1;
                    end
                end
            end
            STOP: begin
                n_tx = 1'b1;
                if (b_tick) begin
                    if (c_tick_cnt == 15) begin
                        n_s = IDLE;
                    end else begin
                        n_tick_cnt = c_tick_cnt + 1;
                    end
                end
            end
            default: n_s = c_s;
        endcase
    end

endmodule