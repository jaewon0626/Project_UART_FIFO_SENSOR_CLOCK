`timescale 1ns / 1ps

module DHT11_without_fnd(

    //input
    input        clk,
    input        reset,
    input        btn_start,      

    output [6:0]  led,    //state, valid
    output        valid,
    output        done,
    output [39:0] dth11_data,

    inout dth11_io
);


    wire w_tick_10us;

    tick_gen_10us_100khz U_tick_gen_10us(
        //input
        .clk(clk),
        .reset(reset),
        //ouput
        .tick_gen_10us(w_tick_10us)
    );

    DHT11_control_unit U_DTH11_cnt_unit(
        //input
        .clk(clk), 
        .reset(reset),
        .start(btn_start),
        .tick_10us(w_tick_10us),
        //output
        .valid(valid),  //?
        .done(done),   //?
        .led(led),    //state, valid
        .dth11_data(dth11_data),//?

        //inout
        .dth11_io(dth11_io) // tx, rx
    );

endmodule
