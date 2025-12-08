`timescale 1ns / 1ps

    module uart(
    input clk,
    input rst,
    input tx_start, // btn_U
    input rx,
    input [7:0] tx_data,

    output tx,
    output tx_busy,
    output [7:0] rx_data,
    output rx_busy,
    output rx_done
    );

    wire w_b_tick;

    // wire w_btn_db;
    // wire w_send;
    // wire [7:0] w_tx_data;

    uart_tx U_UART_TX(
        .clk(clk),
        .rst(rst),
        .start(tx_start),
        .b_tick(w_b_tick),
        .tx_data(tx_data),
        .tx_busy(tx_busy),
        .tx(tx)
        );
    
    /*
    uart_rx U_UART_RX(
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .b_tick(w_b_tick),
        .rx_data(rx_data),
        .rx_busy(rx_busy),
        .rx_done(rx_done)
        );
    */
    
    baud_tick_gen U_BAUD_TICK_GEN(
        .clk(clk),
        .rst(rst),
        .b_tick(w_b_tick)
        );

    /*
    ascii_sender U_ASCII_sender(
        .clk(clk),
        .rst(rst),
        .start(w_btn_db),
        .tx_busy(w_tx_busy),
    
        .send_start(w_send),
        .ascii_data(w_data)
        );
        */

endmodule