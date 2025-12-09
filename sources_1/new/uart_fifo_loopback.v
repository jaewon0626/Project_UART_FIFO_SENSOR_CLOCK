`timescale 1ns / 1ps

module uart_fifo_loopback (
    input        clk,
    input        rst,
    input        rx,
    input        push_dht11,
    input        push_sr04,
    input        push_key,
    input        push_time,
    input  [7:0] ascii_dht11,
    input  [7:0] ascii_sr04,
    input  [7:0] ascii_key,
    input  [7:0] ascii_time,
    output       rx_done,
    output       tx,
    output       w_lp_push,
    output [7:0] w_lp_data
);

    wire [7:0] w_rx_data, w_tx_data;
    wire w_tx_busy, w_tx_start; // w_lp_push can use signal to catch button

    wire [7:0] w_ascii = (push_dht11) ? ascii_dht11 : 
                         (push_sr04)  ? ascii_sr04  : 
                         (push_key)   ? ascii_key   : 
                         (push_time)  ? ascii_time  : 0;

    uart U_UART (  // top module
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .tx_start(!w_tx_start),
        .tx_data(w_tx_data),
        .tx(tx),
        .tx_busy(w_tx_busy),
        //.rx_busy(),
        .rx_done(rx_done),
        .rx_data(w_rx_data)
    );

    fifo U_FIFO_RX (
        .clk(clk),
        .rst(rst),
        .w_data(w_rx_data),
        .push(rx_done),
        .pop(1'b1),
        .r_data(w_lp_data),
        //.full(),
        .empty(w_lp_push)
    );

    fifo U_FIFO_TX (
        .clk(clk),
        .rst(rst),
        .w_data(w_ascii),
        .push((push_dht11||push_sr04||push_key||push_time)),
        .pop(!w_tx_busy),
        .r_data(w_tx_data),
        .full(),
        .empty(w_tx_start)
    );

endmodule
