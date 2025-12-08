`timescale 1ns / 1ps

module sr04_control_unit(
    input clk,
    input rst,
    input start,
    input i_tick,
    input i_echo,

    output o_trig,
    output [8:0] o_dist // for 400cm
    );

localparam IDLE = 0;    
localparam START = 1;
localparam WAIT = 2;
localparam DETECT = 3;
localparam CAL = 4;

reg [2:0] c_state, n_state;
reg c_trig, n_trig;
reg [($clog2(400*58))-1:0] c_tick_cnt, n_tick_cnt;
reg [8:0] c_dist, n_dist;

always @(posedge clk, posedge rst) begin
    if(rst) begin
        c_state <= 3'b0;
        c_trig <= 1'b0;
        c_tick_cnt <= 0;
        c_dist <= 9'b0;
    end
    else begin
        c_state <= n_state;
        c_trig <= n_trig;
        c_tick_cnt <= n_tick_cnt;
        c_dist <= n_dist;
    end
end

always @(*) begin
    n_state = c_state;
    n_trig = c_trig;
    n_tick_cnt = c_tick_cnt;
    n_dist = c_dist;
    case(c_state) 
        IDLE : begin
            n_trig = 0;
            n_dist = 0;
            if(start) begin
                n_trig = 1;
                n_tick_cnt = 0;
                n_state = START;
            end
        end
        START : begin
            if(i_tick) begin
                if(c_tick_cnt == 10) begin
                    n_trig = 0;
                    n_tick_cnt = 0;
                    n_state = WAIT;
                end
                else begin
                    n_tick_cnt = c_tick_cnt + 1;
                end
            end
        end
        WAIT : begin
            if(i_echo) begin
                n_state = DETECT;
            end
        end
        DETECT : begin
            if((i_echo) && (i_tick)) begin
                n_tick_cnt = c_tick_cnt + 1;
            end
            else begin
                if(!i_echo) begin
                    n_dist = c_tick_cnt / 58;
                    n_state = CAL;
                end
            end
        end
        CAL : begin
            if (start) begin
                n_trig = 1;
                n_tick_cnt = 0;
                n_state = START;
            end
            else if(i_tick) begin
                if (c_tick_cnt >= 40000) begin // 400*58 = 23,200 이상 설정
                    n_state = IDLE;
                end 
                else begin
                    n_tick_cnt = c_tick_cnt + 1;
                end
            end
        end
    endcase
end

assign o_trig = c_trig;
assign o_dist = c_dist;

endmodule
