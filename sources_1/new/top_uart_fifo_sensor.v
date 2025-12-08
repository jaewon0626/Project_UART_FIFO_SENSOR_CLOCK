`timescale 1ns / 1ps

module top_uart_fifo_sensor(
        input clk,
        input rst,
        input btn_start,

        output tx,
        
        inout dht11_io
    );

    wire w_push;
    wire [7:0] w_ascii;
    wire [7:0] w_tx_data;
    wire w_tx_start;
    wire w_btn_db;
    wire w_tx_busy;

    uart U_UART(
        .clk(clk),
        .rst(rst),
        .tx_start(!w_tx_start), // btn_U
        .rx(),
        .tx_data(w_tx_data),

        .tx(tx),
        .tx_busy(w_tx_busy),
        .rx_data(),
        .rx_busy(),
        .rx_done()
    );

    fifo U_TX_FIFO(
        .clk(clk),
        .rst(rst),
        .w_data(w_ascii),
        .push(w_push), // we
        .pop(!w_tx_busy), // rd

        .r_data(w_tx_data),
        .full(),
        .empty(w_tx_start)
    );

    /*
    fifo U_RX_FIFO(
        .clk(clk),
        .rst(rst),
        .w_data(w_ascii),
        .push(w_push), // we
        .pop(!tx_busy), // rd

        .r_data(w_tx_data),
        .full(),
        .empty(!w_tx_start)
    );
    */

    top_dht11 U_DHT11(
        .clk(clk),
        .rst(rst),
        .btnU(w_btn_db),

        .dht11_data(),
        .go_ascii(w_push),
        .ascii(w_ascii),

        .dht11_io(dht11_io)
    );

    btn_debounce U_BTN_DB_DHT11(
        .clk(clk),
        .rst(rst),
        .i_btn(btn_start),
        .o_btn(w_btn_db)
        );


endmodule
