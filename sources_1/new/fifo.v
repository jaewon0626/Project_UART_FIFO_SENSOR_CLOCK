`timescale 1ns / 1ps

module fifo(
    input clk,
    input rst,
    input [7:0] w_data,
    input push, // we
    input pop, // rd

    output [7:0] r_data,
    output full,
    output empty
    );

    wire [3:0] w_addr;
    wire [3:0] r_addr;

    register_file U_RF(
        .clk(clk),
        .w_data(w_data),
        .w_addr(w_addr),
        .r_addr(r_addr),
        .we((~full & push)),
        .r_data(r_data)
    );

    fifo_control_unit U_FIFO_CU(
        .clk(clk),
        .rst(rst),
        .push(push),
        .pop(pop),
        .w_addr(w_addr),
        .r_addr(r_addr),
        .full(full),
        .empty(empty)
    );

endmodule
