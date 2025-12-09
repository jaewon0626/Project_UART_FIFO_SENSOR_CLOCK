`timescale 1ns / 1ps

module tick_gen_1us_1Mhz (
    input clk,
    input reset,
    output tick_gen_1us
);
    reg [$clog2(100) - 1 : 0] counter;
    reg tick_gen_1us_reg;

    assign tick_gen_1us = tick_gen_1us_reg;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter          <= 0;
            tick_gen_1us_reg <= 0;
        end else begin
            if (counter == 100 - 1) begin
                counter          <= 0;
                tick_gen_1us_reg <= 1;
            end else begin
                counter         <= counter + 1;
                tick_gen_1us_reg <= 0;
            end                
        end
    end

endmodule