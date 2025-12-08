`timescale 1ns / 1ps

module sr04_controller(
    input clk,
    input rst,
    input start,
    input echo,

    output trig,
    // output [8:0] dist,
    output [3:0] fnd_com,
    output [7:0] fnd_data
    );

    wire w_tick;
    wire [8:0] w_dist;

    sr04_control_unit U_SR04_CU(
        .clk(clk),
        .rst(rst),
        .start(start),
        .i_tick(w_tick),
        .i_echo(echo),
        .o_trig(trig),
        .o_dist(w_dist) // for 400cm
    );

    tick_gen_1uhz U_TICK_GEN(
        .clk(clk),
        .rst(rst),
        .tick_1uhz(w_tick)
        );

    fnd_controller U_FND(
        .clk(clk),
        .rst(rst),
        .cnt(w_dist),
        .fnd_com(fnd_com),
        .fnd_data(fnd_data)
    );

endmodule

module tick_gen_1uhz(
    clk,
    rst,
    tick_1uhz
    );

    input clk;
    input rst;

    output tick_1uhz;

    parameter COUNT = 100 - 1;
    localparam WIDTH = $clog2(COUNT);

    reg [WIDTH-1:0] cnt;
    reg r_tick;

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            cnt <= 0;
            r_tick <= 0;
        end
        else begin
            if(cnt == COUNT) begin
                cnt <= 0;
                r_tick <= 1;
            end
            else begin
                cnt <= cnt + 1;
                r_tick <= 0;
            end
        end
    end

    assign tick_1uhz = r_tick;

endmodule