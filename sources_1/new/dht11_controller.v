`timescale 1ns / 1ps

module dht11_controller (
    input clk,
    input rst,
    input start,

    output [7:0] rh_data,
    output [7:0] t_data,
    output dht11_done,
    output dth11_valid,
    output [2:0] state_led,

    inout dht11_io
);

    localparam IDLE = 0, START = 1, WAIT = 2, SYNCL = 3;
    localparam SYNCH = 4, DATA_SYNC = 5, DATA_DETECT = 6, STOP = 7;

    wire w_tick;

    reg [2:0] c_state, n_state;
    reg [$clog2(2000) - 1:0] t_cnt_reg, t_cnt_next;
    reg dht11_reg, dht11_next;
    reg o_en_reg, o_en_next;
    reg [39:0] data_reg, data_next;
    reg [$clog2(40) - 1:0] d_cnt_reg, d_cnt_next;
    reg valid_reg, valid_next;
    reg done_reg, done_next;

    wire [7:0] rh_data_d, t_data_d, check_sum;

    assign dht11_io  = (o_en_reg) ? dht11_reg : 1'bz;
    assign state_led = c_state;
    assign dth11_valid = valid_reg;
    assign dht11_done = done_reg;
    

    assign rh_data = data_reg[39:32];
    assign rh_data_d = data_reg[31:24];
    assign t_data = data_reg[23:16];
    assign t_data_d = data_reg[15:8];
    assign check_sum = data_reg[7:0];

    // 엣지 검출용 레지스터 & 와이어
    reg dht11_io_d, dht11_io_dd;
    wire dht11_posedge, dht11_negedge;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dht11_io_d  <= 1'b0;
            dht11_io_dd <= 1'b0;
        end else begin
            dht11_io_d  <= dht11_io;    // 1 클럭 지연
            dht11_io_dd <= dht11_io_d;  // 2 클럭 지연
        end
    end

    assign dht11_posedge =  dht11_io_d & ~dht11_io_dd;
    assign dht11_negedge = ~dht11_io_d & dht11_io_dd;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state   <= 0;
            t_cnt_reg <= 0;
            dht11_reg <= 1'b1;  // 초기값 항상 high.
            o_en_reg  <= 1'b1;  // IDLE에서 항상 출력 모드로 동작.
            data_reg  <= 0;
            d_cnt_reg <= 0;
            valid_reg <= 0;
            done_reg <= 0;
        end else begin
            c_state   <= n_state;
            t_cnt_reg <= t_cnt_next;
            dht11_reg <= dht11_next;
            o_en_reg  <= o_en_next;
            data_reg  <= data_next;
            d_cnt_reg <= d_cnt_next;
            valid_reg <= valid_next;
            done_reg <= done_next;
        end
    end

    always @(*) begin
        n_state = c_state;
        t_cnt_next = t_cnt_reg;
        dht11_next = dht11_reg;
        o_en_next = o_en_reg;
        data_next = data_reg;
        d_cnt_next = d_cnt_reg;
        valid_next = valid_reg;
        done_next = done_reg;
        case (c_state)
            IDLE: begin
                done_next = 1'b0;
                dht11_next = 1'b1;
                o_en_next = 1'b1;
                d_cnt_next = 0;
                t_cnt_next = 0;
                if (start) begin
                    n_state = START;
                end
            end
            START: begin
                valid_next = 1'b0;
                if (w_tick) begin
                    dht11_next = 1'b0;
                    if (t_cnt_reg == 1800) begin
                        n_state = WAIT;
                        t_cnt_next = 0;
                    end
                    else begin
                        t_cnt_next = t_cnt_reg + 1;
                    end
                end
            end
            WAIT: begin
                // output to high
                dht11_next = 1'b1;
                if (w_tick) begin
                    if (t_cnt_reg == 2) begin
                        n_state = SYNCL;
                        t_cnt_next = 0;
                        // 출력을 입력으로 전환
                        o_en_next = 0;
                    end else begin
                        t_cnt_next = t_cnt_reg + 1;
                    end
                end
            end
            SYNCL: begin
                if (dht11_posedge) begin // edge detect로 바꾸는 게 더 좋을 것 같음.
                    n_state = SYNCH;
                end
            end
            SYNCH: begin
                if (dht11_negedge) begin
                    n_state = DATA_SYNC;
                end
            end
            DATA_SYNC: begin
                if (w_tick) begin
                    if (dht11_io == 1) begin
                        n_state = DATA_DETECT;
                    end
                end
            end
            DATA_DETECT: begin
                if (w_tick) begin
                    if (dht11_io == 0) begin
                        data_next[39 - d_cnt_reg] = (t_cnt_next >= 5)? 1 : 0;
                        d_cnt_next = d_cnt_reg + 1;
                        n_state = (d_cnt_reg == 39)? STOP : DATA_SYNC;
                        t_cnt_next = 0;
                    end
                    else begin
                        t_cnt_next = t_cnt_reg + 1;
                    end
                end
            end
            STOP: begin
                if (check_sum == (rh_data + rh_data_d + t_data + t_data_d)) begin
                    valid_next = 1'b1;
                end
                if (w_tick) begin
                    if (t_cnt_reg == 4) begin
                        n_state = IDLE;
                        t_cnt_next = 0;
                        done_next = 1'b1;
                    end
                    t_cnt_next = t_cnt_reg + 1;
                end
            end
        endcase
    end

    tick_gen U_TICK_10us (
            .clk(clk),
            .rst(rst),
            .o_tick(w_tick)
        );

endmodule
