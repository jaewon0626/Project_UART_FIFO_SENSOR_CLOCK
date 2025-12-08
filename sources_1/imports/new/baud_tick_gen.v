`timescale 1ns / 1ps

module baud_tick_gen(
    input clk,
    input rst,

    output b_tick
    );

    // tick bps : 9600 
    // --> 100_000_000 / 9600 = 10416
    parameter BAUD_COUNT = 100_000_000/(9600*16);
    localparam WIDTH = $clog2(BAUD_COUNT);

    reg [WIDTH-1:0] tick_cnt;
    reg r_tick;

    always @(posedge clk, posedge rst) begin
        if(rst) begin
            tick_cnt <= 0;
            r_tick <= 0;
        end
        else begin
            if(tick_cnt == BAUD_COUNT) begin
                tick_cnt <= 0;
                r_tick <= 1'b1;
            end
            else begin
                tick_cnt <= tick_cnt + 1;
                r_tick <= 1'b0;
            end
            end
        end     
        
        assign b_tick = r_tick;

endmodule
