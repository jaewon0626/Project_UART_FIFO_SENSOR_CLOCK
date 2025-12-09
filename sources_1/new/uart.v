`timescale 1ns / 1ps

module uart (  // top module
    input        clk,
    input        rst,
    input        tx_start,
    input        rx,
    input  [7:0] tx_data,
    output       tx,
    output       tx_busy,
    output       rx_busy,
    output       rx_done,
    output [7:0] rx_data
);

    wire w_b_tick;

    baud_tick_gen U_BAUD_TICK (
        // input
        .clk(clk),
        .rst(rst),
        // output
        .b_tick(w_b_tick)
    );

    uart_rx U_UART_RX (
        // input
        .clk(clk),
        .rst(rst),
        .b_tick(w_b_tick),
        .rx(rx),
        // output
        .rx_data(rx_data),
        .rx_busy(rx_busy),
        .rx_done(rx_done)
    );

    uart_tx U_UART_TX (
        // input
        .clk(clk),
        .rst(rst),
        .start(tx_start),
        .b_tick(w_b_tick),
        .tx_data(tx_data),
        // output
        .tx_busy(tx_busy),
        .tx(tx)
    );

endmodule

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

module baud_tick_gen #(  // system clock frequency/frequency = tick count
    parameter SYSTEM_FREQ = 100_000_000,
    parameter TICK_FREQ   = (9600*16)
) (
    input  clk,
    input  rst,
    output b_tick
);

    // tick bps : 9600
    localparam MAX_COUNT = SYSTEM_FREQ / TICK_FREQ;
    localparam WIDTH = $clog2(SYSTEM_FREQ / TICK_FREQ);

    reg [WIDTH-1:0] tick_counter;
    reg r_tick;

    // assign tick
    assign b_tick = r_tick;

    // generate tick
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            tick_counter <= 0;
            r_tick       <= 1'b0;
        end else begin
            if (tick_counter == MAX_COUNT - 1) begin
                tick_counter <= 0;
                r_tick       <= 1'b1;
            end else begin
                tick_counter <= tick_counter + 1;
                r_tick       <= 1'b0;
            end
        end
    end

endmodule

module uart_rx (
    input        clk,
    input        rst,
    input        b_tick,
    input        rx,
    output [7:0] rx_data,
    output       rx_busy,
    output       rx_done
);

    // parameter
    localparam [1:0] IDLE = 0, START = 1, DATA = 2, STOP = 3;

    reg c_rx_busy, n_rx_busy;
    reg c_rx_done, n_rx_done;
    reg [1:0] c_state, n_state;
    reg [2:0] c_bit_cnt, n_bit_cnt;
    reg [3:0] c_b_tick_cnt, n_b_tick_cnt;
    reg [7:0] c_rx_data, n_rx_data;

    // output
    assign rx_data = c_rx_data;
    assign rx_busy = c_rx_busy;
    assign rx_done = c_rx_done;

    // state register
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state      <= IDLE;
            c_b_tick_cnt <= 0;
            c_rx_data    <= 0;
            c_bit_cnt    <= 0;
            c_rx_busy    <= 1'b0;
            c_rx_done    <= 1'b0;
        end else begin
            c_state      <= n_state;
            c_b_tick_cnt <= n_b_tick_cnt;
            c_rx_data    <= n_rx_data;
            c_bit_cnt    <= n_bit_cnt;
            c_rx_busy    <= n_rx_busy;
            c_rx_done    <= n_rx_done;
        end
    end

    // next combinational logic
    always @(*) begin
        n_state      = c_state;
        n_b_tick_cnt = c_b_tick_cnt;
        n_rx_data    = c_rx_data;
        n_bit_cnt    = c_bit_cnt;
        n_rx_busy    = c_rx_busy;
        n_rx_done    = c_rx_done;
        case (c_state)
            IDLE: begin
                n_rx_done = 1'b0;
                if (~rx) begin  // rx == 0, receive start
                    n_b_tick_cnt = 0;
                    n_bit_cnt = 0;
                    n_rx_busy = 1'b1;
                    n_state = START;
                end
            end
            START: begin
                if (b_tick) begin
                    if (c_b_tick_cnt == 7) begin // catch middle
                        n_b_tick_cnt = 0;
                        n_state = DATA;
                    end else begin
                        n_b_tick_cnt = c_b_tick_cnt + 1;
                    end
                end
            end
            DATA: begin
                if (b_tick) begin
                    if (c_b_tick_cnt == 15) begin
                        n_b_tick_cnt = 0;
                        n_rx_data = {rx, c_rx_data[7:1]};
                        if (c_bit_cnt == 7) begin
                            n_bit_cnt = 0;
                            n_state   = STOP;
                        end else begin
                            n_bit_cnt = c_bit_cnt + 1;
                        end
                    end else begin
                        n_b_tick_cnt = c_b_tick_cnt + 1;
                    end
                end
            end
            STOP: begin
                if (b_tick) begin
                    if (c_b_tick_cnt == 15) begin
                        n_b_tick_cnt = 0;
                        n_rx_busy = 1'b0;
                        n_rx_done = 1'b1;
                        n_state = IDLE;
                    end else begin
                        n_b_tick_cnt = c_b_tick_cnt + 1;
                    end
                end
            end
        endcase
    end

endmodule
