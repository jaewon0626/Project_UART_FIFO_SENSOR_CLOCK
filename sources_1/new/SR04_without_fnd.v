`timescale 1ns / 1ps

module SR04_without_fnd (
    //input
    input        clk,
    input        reset,
    input        btn_start,
    input        echo,
    //output
    output       done,
    output       trigger,
    output [8:0] distance
);

    wire w_tick_gen_1us;

    tick_gen_1us_1Mhz U_tick_gen_1us (
      .clk(clk),
      .reset(reset),
      .tick_gen_1us(w_tick_gen_1us)
  );

    sr04_cnt_unit U_SR04_cnt_unit (
      //input
      .clk(clk),
      .reset(reset),
      .start(btn_start),
      .tick_1us(w_tick_gen_1us),
      .echo(echo),
      //output
      .done(done),
      .trigger(trigger),
      .distance(distance)  // for 400cm
    );


endmodule
