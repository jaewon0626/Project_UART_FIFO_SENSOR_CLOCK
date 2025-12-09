`timescale 1ns / 1ps

module project3_Clock_with_Sensor_top(
    input        clk,
    input        reset,
    input [15:0] sw, // sw[0] = screen select, sw[1] = mode select, sw[2] = timer, sw[12] = digit select msec, sw[13] = digit select sec, sw[14] digit select min, sw[15] digit select hour
                     // sw[3] = DHT11, sw[4] = SR04
    input        btn_L, // clear
    input        btn_R, // run_stop
    input        btn_U, // up
    input        btn_D, // down

    input        key_L,
    input        key_R,
    input        key_U,
    input        key_D,
    input        key_q,
    input        key_z,

    input        key_sel,
    input [8:0]  key_sw,
    input [8:0]  key_sw_sel,
    input        echo,

    output reg [8:0] led,
    output [3:0] fnd_com,
    output [7:0] fnd_data,

    output       trigger,

    output [7:0] ascii_dht11,
    output [7:0] ascii_sr04,
    output [7:0] ascii_time,
    output push_dht11,
    output push_sr04,
    output push_time,

    inout dth11_io
    );

    wire [6:0] w_msec_stopwatch;
    wire [5:0] w_sec_stopwatch;
    wire [5:0] w_min_stopwatch;
    wire [4:0] w_hour_stopwatch;

    wire [6:0] w_msec_watch;
    wire [5:0] w_sec_watch;
    wire [5:0] w_min_watch;
    wire [4:0] w_hour_watch;

    wire [6:0] w_msec_timer;
    wire [5:0] w_sec_timer;
    wire [5:0] w_min_timer;
    wire [4:0] w_hour_timer;

    wire [6:0] w_msec_result;
    wire [5:0] w_sec_result;
    wire [5:0] w_min_result;
    wire [4:0] w_hour_result;

    wire [15:0] w_sw;

    wire [39:0] w_dth11_data;
    wire [8:0]  w_distance;

    wire [23:0] w_time_data;

    wire [6:0]  w_dth11_LED;

    wire o_run_stop, o_clear;
    wire w_run_StopWatch, w_run_Watch, w_run_Timer, w_clear_StopWatch, w_clear_Watch, w_clear_Timer, w_up_StopWatch, w_up_Watch, w_up_Timer, w_down_StopWatch, w_down_Watch, w_down_Timer;
    wire i_up_StopWatch_msec, i_up_Watch_msfec, i_up_StopWatch_sec, i_up_Watch_sec, i_up_StopWatch_min, i_up_Watch_min, i_up_StopWatch_hour, i_up_Watch_hour;
    wire i_up_Timer_msec, i_up_Timer_sec, i_up_Timer_min, i_up_Timer_hour;
    wire i_down_StopWatch_msec, i_down_Watch_msec, i_down_StopWatch_sec, i_down_Watch_sec, i_down_StopWatch_min, i_down_Watch_min, i_down_StopWatch_hour, i_down_Watch_hour;
    wire i_down_Timer_msec, i_down_Timer_sec, i_down_Timer_min, i_down_Timer_hour;

    wire w_clock_R, w_dth11_R, w_sr04_R;
    wire w_btn_dht11, w_btn_sr04;
    wire w_o_btn_dht11, w_o_btn_sr04;

    wire w_dht11_done, w_sr04_done, w_time_done;

    wire w_led_7, w_led_6;

    assign i_up_StopWatch_msec = (w_sw[12]) ? w_up_StopWatch : 1'b0;
    assign i_up_Watch_msec = (w_sw[12]) ? w_up_Watch : 1'b0;
    assign i_up_Timer_msec = (w_sw[12]) ? w_up_Timer : 1'b0;

    assign i_up_StopWatch_sec = (w_sw[13]) ? w_up_StopWatch : 1'b0;
    assign i_up_Watch_sec = (w_sw[13]) ? w_up_Watch : 1'b0;
    assign i_up_Timer_sec = (w_sw[13]) ? w_up_Timer : 1'b0;

    assign i_up_StopWatch_min = (w_sw[14]) ? w_up_StopWatch : 1'b0;
    assign i_up_Watch_min = (w_sw[14]) ? w_up_Watch : 1'b0;
    assign i_up_Timer_min = (w_sw[14]) ? w_up_Timer : 1'b0;

    assign i_up_StopWatch_hour = (w_sw[15]) ? w_up_StopWatch : 1'b0;
    assign i_up_Watch_hour = (w_sw[15]) ? w_up_Watch : 1'b0;
    assign i_up_Timer_hour = (w_sw[15]) ? w_up_Timer : 1'b0;

    assign i_down_StopWatch_msec = (w_sw[12]) ? w_down_StopWatch : 1'b0;
    assign i_down_Watch_msec = (w_sw[12]) ? w_down_Watch : 1'b0;
    assign i_down_Timer_msec = (w_sw[12]) ? w_down_Timer : 1'b0;

    assign i_down_StopWatch_sec = (w_sw[13]) ? w_down_StopWatch : 1'b0;
    assign i_down_Watch_sec = (w_sw[13]) ? w_down_Watch : 1'b0;
    assign i_down_Timer_sec = (w_sw[13]) ? w_down_Timer : 1'b0;

    assign i_down_StopWatch_min = (w_sw[14]) ? w_down_StopWatch : 1'b0;
    assign i_down_Watch_min = (w_sw[14]) ? w_down_Watch : 1'b0;
    assign i_down_Timer_min = (w_sw[14]) ? w_down_Timer : 1'b0;

    assign i_down_StopWatch_hour = (w_sw[15]) ? w_down_StopWatch : 1'b0;
    assign i_down_Watch_hour = (w_sw[15]) ? w_down_Watch : 1'b0;
    assign i_down_Timer_hour = (w_sw[15]) ? w_down_Timer : 1'b0;

        time_split U_TIME_SP (
            .clk(clk),
            .rst(rst),
            .key_z(key_z),
            .hourminsec({w_hour_watch, w_min_watch, w_sec_watch}), //16:11 hour, 10:5 min, 4:0 sec
            .time_data(w_time_data),
            .time_done(w_time_done)
        );

        trans_ascii_time U_TRANS_TIME (
            .clk(clk),
            .rst(rst),
            .time_data(w_time_data),  // distance 
            .time_done(w_time_done),  // 측정 완료 펄스
            .ascii(ascii_time),
            .go_ascii(push_time)
        );


        mux_1x3_switch U_btn_R (
            //input
            .sel({w_sw[4], w_sw[3]}), //{sw[4],sw[3]}
            .btn_R(btn_R),
            //output
            .clock_R (w_clock_R),
            .dth11_R (w_dth11_R),
            .sr04_R  (w_sr04_R),
            .led_7   (w_led_7),
            .led_6   (w_led_6)
        );

        sw_select U_SW_SEL (
            .i_key_sw(key_sw),
            .sw(sw),
            .key_sw_sel(key_sw_sel),
            .o_key_sw(w_sw)
        );

        fnd_controller_pj3 U_dnc_cntl_pj3(
        
            //input [1:0] digit_sel, //for button in middle of the board
            .clk(clk),
            .reset(reset),
            .sw({w_sw[4], w_sw[3], w_sw[0]}),
                //CLOCK
            .msec(w_msec_result),
            .sec(w_sec_result),
            .min(w_min_result),
            .hour(w_hour_result),
                //DTH11
            .dth11_data({w_dth11_data[39:32], w_dth11_data[23:16]}),
                //SR04
            .dist(w_distance),

            .fnd_com(fnd_com),
            .fnd_data(fnd_data)
        );

        mux_12to4 U_MUX8x4(
            //input
            .mode({w_sw[2], w_sw[1]}),
            .SW_msec(w_msec_stopwatch),
            .SW_sec(w_sec_stopwatch),
            .SW_min(w_min_stopwatch),
            .SW_hour(w_hour_stopwatch),
            .W_msec(w_msec_watch),
            .W_sec(w_sec_watch),
            .W_min(w_min_watch),
            .W_hour(w_hour_watch),
            .T_msec(w_msec_timer),
            .T_sec(w_sec_timer),
            .T_min(w_min_timer),
            .T_hour(w_hour_timer),
            //output
            .o_msec(w_msec_result),
            .o_sec(w_sec_result),
            .o_min(w_min_result),
            .o_hour(w_hour_result)
        );

        SR04_without_fnd U_SR04_cntl(
            //input
            .clk(clk),
            .reset(reset),
            .btn_start(w_o_btn_sr04),
            .echo(echo),
            //output
            .done(w_sr04_done),
            .trigger(trigger),
            .distance(w_distance)
        );

        trans_ascii_sr04 U_TRANS_SR04 (
            .clk(clk),
            .rst(rst),
            .dist_data(w_distance),  // distance 
            .sr04_done(w_sr04_done), // 측정 완료 펄스
            .ascii(ascii_sr04),
            .go_ascii(push_sr04)
        );

        DHT11_without_fnd U_DTH11_cntl(
            //input
            .clk(clk),
            .reset(reset),
            .btn_start(w_o_btn_dht11),     

            .led(w_dth11_LED),    //state, valid
            //.valid(),
            .done(w_dht11_done), 
            .dth11_data(w_dth11_data),

            .dth11_io(dth11_io)
        );

        trans_ascii_dht11 U_TRANS_DHT11 (
            .clk(clk),
            .rst(rst),
            .rh_data(w_dth11_data[39:32]),    // 
            .t_data(w_dth11_data[23:16]),     // 
            .dht11_done(w_dht11_done), // 
            .ascii(ascii_dht11),
            .go_ascii(push_dht11)
        );

        CLOCK_M U_STOPWATCH_M(
            //input
            .clk(clk),
            .reset(reset),
            .btn_L(w_clear_StopWatch),
            .btn_R(w_run_StopWatch),
            .inc_msec(i_up_StopWatch_msec),
            .dec_msec(i_down_StopWatch_msec),
            .inc_sec(i_up_StopWatch_sec),
            .dec_sec(i_down_StopWatch_sec),
            .inc_min(i_up_StopWatch_min),
            .dec_min(i_down_StopWatch_min),
            .inc_hour(i_up_StopWatch_hour),
            .dec_hour(i_down_StopWatch_hour),
            //output
            .msec(w_msec_stopwatch),
            .sec(w_sec_stopwatch),
            .min(w_min_stopwatch),
            .hour(w_hour_stopwatch)
        );

        CLOCK_M_WATCH U_WATCH_M(
            //input
            .clk(clk),
            .reset(reset),
            .btn_L(w_clear_Watch),
            .btn_R(w_run_Watch),
            .inc_msec(i_up_Watch_msec),
            .dec_msec(i_down_Watch_msec),
            .inc_sec(i_up_Watch_sec),
            .dec_sec(i_down_Watch_sec),
            .inc_min(i_up_Watch_min),
            .dec_min(i_down_Watch_min),
            .inc_hour(i_up_Watch_hour),
            .dec_hour(i_down_Watch_hour),
            //output
            .msec(w_msec_watch),
            .sec(w_sec_watch),
            .min(w_min_watch),
            .hour(w_hour_watch)
        );

        CLOCK_M_TIMER U_TIMER_M(
            //input
            .clk(clk),
            .reset(reset),
            .btn_L(w_clear_Timer),
            .btn_R(w_run_Timer),
            .inc_msec(i_up_Timer_msec),
            .dec_msec(i_down_Timer_msec),
            .inc_sec(i_up_Timer_sec),
            .dec_sec(i_down_Timer_sec),
            .inc_min(i_up_Timer_min),
            .dec_min(i_down_Timer_min),
            .inc_hour(i_up_Timer_hour),
            .dec_hour(i_down_Timer_hour),
            //output
            .done_led(done_led),
            .msec(w_msec_timer),
            .sec(w_sec_timer),
            .min(w_min_timer),
            .hour(w_hour_timer)
        );

        btn_select #(.DEFAULT(1'b0)) U_RUN_select
        (
            .mode({w_sw[2], w_sw[1]}),
            .i_btn(o_run_stop),
            .i_key(key_R),
            .key_sel(key_sel),
            //output
            .o_btn_SW(w_run_StopWatch),
            .o_btn_W(w_run_Watch),
            .o_btn_T(w_run_Timer)
        );

        btn_select #(.DEFAULT(1'b0)) U_CLEAR_select(
            .mode({w_sw[2], w_sw[1]}),
            .i_btn(o_clear),
            .i_key(key_L),
            .key_sel(key_sel),
            //output
            .o_btn_SW(w_clear_StopWatch),
            .o_btn_W(w_clear_Watch),
            .o_btn_T(w_clear_Timer)
        );

        btn_select #(.DEFAULT(1'b0)) U_UP_select
        (
            .mode({w_sw[2], w_sw[1]}),
            .i_btn(o_up),
            .i_key(key_U),
            .key_sel(key_sel),
            //output
            .o_btn_SW(w_up_StopWatch),
            .o_btn_W(w_up_Watch),
            .o_btn_T(w_up_Timer)
        );

        btn_select #(.DEFAULT(1'b0)) U_DOWN_select
        (
            .mode({w_sw[2], w_sw[1]}),
            .i_btn(o_down),
            .i_key(key_D),
            .key_sel(key_sel),
            //output
            .o_btn_SW(w_down_StopWatch),
            .o_btn_W(w_down_Watch),
            .o_btn_T(w_down_Timer)
        );

        btn_select_sensor U_btn_SENSEOR (
            .mode({w_sw[4],w_sw[3]}), //{sw[4],sw[3]}
            .i_btn((w_btn_sr04|w_btn_dht11)),
            .i_key(key_q),
            .key_sel(key_sel),
            .o_btn_sr04(w_o_btn_sr04),
            .o_btn_dht11(w_o_btn_dht11)
        );

        btn_debounce U_CLEAR_DB(
            //input
            .clk(clk),
            .reset(reset),
            .i_btn(btn_L),
            //output
            .o_btn(o_clear)
        );

        btn_debounce U_RUN_STOP_DB(
            //input
            .clk(clk),
            .reset(reset),
            .i_btn(w_clock_R),
            //output
            .o_btn(o_run_stop)
        );

        btn_debounce U_UP_DB(
            //input
            .clk(clk),
            .reset(reset),
            .i_btn(btn_U),
            //output
            .o_btn(o_up)
        );

        btn_debounce U_DOWN_DB(
            //input
            .clk(clk),
            .reset(reset),
            .i_btn(btn_D),
            //output
            .o_btn(o_down)
        );

        btn_debounce U_btn_sr04 (
            .clk(clk),
            .reset(reset),
            .i_btn(w_sr04_R),
            .o_btn(w_btn_sr04)
        );

        btn_debounce U_btn_dht11 (
            .clk(clk),
            .reset(reset),
            .i_btn(w_dth11_R),
            .o_btn(w_btn_dht11)
        );

        always @(*) begin
                case (w_sw[2:0])
                    3'b000: led[5:0] = 6'b000001;
                    3'b001: led[5:0] = 6'b000010;
                    3'b010: led[5:0] = 6'b000100;
                    3'b011: led[5:0] = 6'b001000;
                    3'b100: led[5:0] = 6'b010000;
                    3'b101: led[5:0] = 6'b100000;
                    3'b110: led[5:0] = 6'b010000;
                    3'b111: led[5:0] = 6'b100000;
                    default:led[5:0] = 6'b000000;
                endcase
                led[6] = w_led_6;
                led[7] = w_led_7;
                led[8] = w_dth11_LED[6];
        end

endmodule

module time_split (
    input clk,
    input rst,
    input key_z,
    input [16:0] hourminsec, //16:12 hour, 11:6 min, 5:0 sec
    output [23:0] time_data,
    output time_done
);
    
    parameter IDLE__ = 0, SPLIT = 1;

    reg [1:0] c_state, n_state;
    reg [23:0] c_time_data, n_time_data;
    reg c_time_done, n_time_done;

    assign time_data = c_time_data;
    assign time_done = c_time_done;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state <= IDLE__;
            c_time_data <= 0;
            c_time_done <= 0;
        end else begin
            c_state <= n_state;
            c_time_data <= n_time_data;
            c_time_done <= n_time_done;
        end
    end

    always @(*) begin
        n_state = c_state;
        n_time_data = c_time_data;
        n_time_done = c_time_done;
        case (c_state)
            IDLE__: begin
                n_time_done = 0;
                if (key_z) begin
                    n_state = SPLIT;
                end
            end
            SPLIT: begin
                n_time_data[23:20] = hourminsec[16:12] / 10 % 10;
                n_time_data[19:16] = hourminsec[16:12] % 10;
                n_time_data[15:12] = hourminsec[11:6] / 10 % 10;
                n_time_data[11:8] = hourminsec[11:6] % 10;
                n_time_data[7:4] = hourminsec[5:0] / 10 % 10;
                n_time_data[3:0] = hourminsec[5:0] % 10;
                n_time_done = 1;
                n_state = IDLE__;
            end
        endcase
    end


endmodule

module mux_1x3_switch (
    input      [1:0]    sel, //{sw[4],sw[3]}
    input               btn_R,
    output reg          clock_R,
    output reg          dth11_R,
    output reg          sr04_R,
    output reg          led_7,
    output reg          led_6
);

    always @(*) begin

        clock_R = 1'b0;
        dth11_R = 1'b0;
        sr04_R  = 1'b0;
        led_7   = 1'b0;
        led_6   = 1'b0;

        case (sel)
            2'b00: clock_R = btn_R;
            2'b01: dth11_R = btn_R;
            2'b10: sr04_R  = btn_R;
            2'b11: clock_R = btn_R;
        endcase

        if (sel == 2'b10) begin
            led_7 = 1'b1;
            led_6 = 1'b0;
        end else if (sel == 2'b01) begin
            led_7 = 1'b0;
            led_6 = 1'b1;
        end
    end

endmodule

module sw_select (
    input [8:0] i_key_sw,
    input [8:0] key_sw_sel,
    input [15:0] sw,
    output [15:0] o_key_sw
);
    
    assign o_key_sw[0] = (key_sw_sel[0]) ? i_key_sw[0] : sw[0];
    assign o_key_sw[1] = (key_sw_sel[1]) ? i_key_sw[1] : sw[1];
    assign o_key_sw[2] = (key_sw_sel[2]) ? i_key_sw[2] : sw[2];
    assign o_key_sw[3] = (key_sw_sel[8]) ? i_key_sw[8] : sw[3];
    assign o_key_sw[4] = (key_sw_sel[7]) ? i_key_sw[7] : sw[4];
    assign o_key_sw[12] = (key_sw_sel[3]) ? i_key_sw[3] : sw[12];
    assign o_key_sw[13] = (key_sw_sel[4]) ? i_key_sw[4] : sw[13];
    assign o_key_sw[14] = (key_sw_sel[5]) ? i_key_sw[5] : sw[14];
    assign o_key_sw[15] = (key_sw_sel[6]) ? i_key_sw[6] : sw[15];

endmodule

module btn_select_sensor #(
    parameter DEFAULT = 1'b0
    )(
    input [1:0] mode, //{sw[4],sw[3]}
    input i_btn,
    input i_key,
    input key_sel,
    output o_btn_sr04,
    output o_btn_dht11
);
    

    reg r_btn_sr04, r_btn_dht11;
    reg r_key_sr04, r_key_dht11;

    assign o_btn_sr04 = (key_sel) ? r_key_sr04 : r_btn_sr04;
    assign o_btn_dht11 = (key_sel) ? r_key_dht11 : r_btn_dht11;

    always @(*) begin
        case (mode)
            2'b01: begin
                r_btn_dht11 = i_btn;
                r_btn_sr04 = DEFAULT;
                r_key_dht11 = i_key;
                r_key_sr04 = DEFAULT;
            end
            2'b10: begin
                r_btn_dht11 = DEFAULT;
                r_btn_sr04 = i_btn;
                r_key_dht11 = DEFAULT;
                r_key_sr04 = i_key;
            end
            default: begin
                r_btn_dht11 = DEFAULT;
                r_btn_sr04 = DEFAULT;
                r_key_dht11 = DEFAULT;
                r_key_sr04 = DEFAULT;
            end
        endcase
    end

endmodule

module btn_select #(parameter DEFAULT = 1'b1) (
    input [1:0] mode,
    input i_btn,
    input i_key,
    input key_sel,
    output o_btn_SW,
    output o_btn_W,
    output o_btn_T
);
    
    localparam SW = 0, W = 1, T = 2;

    reg r_btn_SW, r_btn_W, r_btn_T;
    reg r_key_SW, r_key_W, r_key_T;

    assign o_btn_SW = (key_sel) ? r_key_SW : r_btn_SW;
    assign o_btn_W = (key_sel) ? r_key_W : r_btn_W;
    assign o_btn_T = (key_sel) ? r_key_T : r_btn_T;

    always @(*) begin
        case (mode)
            SW: begin
                r_btn_SW = i_btn;
                r_btn_W = DEFAULT;
                r_btn_T = DEFAULT;
                r_key_SW = i_key;
                r_key_W = DEFAULT;
                r_key_T = DEFAULT;
            end 

            W: begin
                r_btn_SW = DEFAULT;
                r_btn_W = i_btn;
                r_btn_T = DEFAULT;
                r_key_SW = DEFAULT;
                r_key_W = i_key;
                r_key_T = DEFAULT;
            end

            T: begin
                r_btn_SW = DEFAULT;
                r_btn_W = DEFAULT;
                r_btn_T = i_btn;
                r_key_SW = DEFAULT;
                r_key_W = DEFAULT;
                r_key_T = i_key;
            end
            default: begin
                r_btn_SW = DEFAULT;
                r_btn_W = DEFAULT;
                r_btn_T = i_btn;
                r_key_SW = DEFAULT;
                r_key_W = DEFAULT;
                r_key_T = i_key;
            end
        endcase
    end

endmodule

module mux_12to4(
    input [3:0]mode,
    //SW
    input [6:0] SW_msec,
    input [5:0] SW_sec,
    input [5:0] SW_min,
    input [4:0] SW_hour,
    //W
    input [6:0] W_msec,
    input [5:0] W_sec,
    input [5:0] W_min,
    input [4:0] W_hour,
    //T
    input [6:0] T_msec,
    input [5:0] T_sec,
    input [5:0] T_min,
    input [4:0] T_hour,
    //DTH11
    input [39:0] dth11_data,
    //SR04
    input [8:0] dist,
    output [6:0] o_msec,
    output [5:0] o_sec,
    output [5:0] o_min,
    output [4:0] o_hour
);

    localparam SW = 0, W = 1, T = 2;

    reg [6:0] r_msec;
    reg [5:0] r_sec, r_min;
    reg [4:0] r_hour;

    assign o_msec = r_msec;
    assign o_sec = r_sec;
    assign o_min = r_min;
    assign o_hour = r_hour;

    always @(*) begin
        case (mode)
            SW: begin
                r_msec = SW_msec;
                r_sec = SW_sec;
                r_min = SW_min;
                r_hour = SW_hour;
            end
            W: begin
                r_msec = W_msec;
                r_sec = W_sec;
                r_min = W_min;
                r_hour = W_hour;
            end
            T: begin
                r_msec = T_msec;
                r_sec = T_sec;
                r_min = T_min;
                r_hour = T_hour;
            end
            default: begin
                r_msec = T_msec;
                r_sec = T_sec;
                r_min = T_min;
                r_hour = T_hour;
            end
        endcase
    end

endmodule


module stopwatch_dp (
    input        clk,
    input        reset,
    input        clear,
    input        run_stop,
    input        inc_msec,
    input        dec_msec,
    input        inc_sec,
    input        dec_sec,
    input        inc_min,
    input        dec_min,
    input        inc_hour,
    input        dec_hour,
    output [6:0] msec,
    output [5:0] sec,
    output [5:0] min,
    output [4:0] hour
);

    wire w_tick_100hz;
    wire w_tick_msec, w_tick_sec, w_tick_min;

    //generate 100hz tick
    tick_gen_100hz U_tick_gen_100hz(
        //input
        .clk(clk),
        .reset(reset),
        .run_stop(run_stop),
        //output
        .o_tick(w_tick_100hz)
    );

    //count msec tic
    tick_counter #(.TICK_COUNT(100), .WIDTH(7)) U_msec (
        //input
        .clk(clk),
        .reset(reset),
        .i_tick(w_tick_100hz),
        //.run_stop(run_stop),
        .clear(clear),
        .inc(inc_msec),
        .dec(dec_msec),
        //output
        .o_tick(w_tick_msec),
        .o_time(msec)
    ); 

    //count sec
    tick_counter #(.TICK_COUNT(60), .WIDTH(6)) U_sec (
        //input
        .clk(clk),
        .reset(reset),
        .i_tick(w_tick_msec),
        //.run_stop(run_stop),
        .clear(clear),
        .inc(inc_sec),
        .dec(dec_sec),
        //output
        .o_tick(w_tick_sec),
        .o_time(sec)
    ); 

    //count min
    tick_counter #(.TICK_COUNT(60), .WIDTH(6)) U_min (
        //input
        .clk(clk),
        .reset(reset),
        .i_tick(w_tick_sec),
        //.run_stop(run_stop),
        .clear(clear),
        .inc(inc_min),
        .dec(dec_min),
        //output
        .o_tick(w_tick_min),
        .o_time(min)
    ); 

    //count min
    tick_counter #(.TICK_COUNT(24), .WIDTH(5)) U_hour (
        //input
        .clk(clk),
        .reset(reset),
        .i_tick(w_tick_min),
        //.run_stop(run_stop),
        .clear(clear),
        .inc(inc_hour),
        .dec(dec_hour),
        //output
        .o_tick(),
        .o_time(hour)
    ); 

endmodule

module stopwatch_dp_WATCH (
    input        clk,
    input        reset,
    input        clear,
    input        run_stop,
    input        inc_msec,
    input        dec_msec,
    input        inc_sec,
    input        dec_sec,
    input        inc_min,
    input        dec_min,
    input        inc_hour,
    input        dec_hour,
    output [6:0] msec,
    output [5:0] sec,
    output [5:0] min,
    output [4:0] hour
);

    wire w_tick_100hz;
    wire w_tick_msec, w_tick_sec, w_tick_min;

    //generate 100hz tick
    tick_gen_100hz U_tick_gen_100hz(
        //input
        .clk(clk),
        .reset(reset),
        .run_stop(run_stop),
        //output
        .o_tick(w_tick_100hz)
    );

    //count msec tic
    tick_counter #(.TICK_COUNT(100), .WIDTH(7)) U_msec (
        //input
        .clk(clk),
        .reset(reset),
        .i_tick(w_tick_100hz),
        //.run_stop(run_stop),
        .clear(clear),
        .inc(inc_msec),
        .dec(dec_msec),
        //output
        .o_tick(w_tick_msec),
        .o_time(msec)
    ); 

    //count sec
    tick_counter #(.TICK_COUNT(60), .WIDTH(6)) U_sec (
        //input
        .clk(clk),
        .reset(reset),
        .i_tick(w_tick_msec),
        //.run_stop(run_stop),
        .clear(clear),
        .inc(inc_sec),
        .dec(dec_sec),
        //output
        .o_tick(w_tick_sec),
        .o_time(sec)
    ); 

    //count min
    tick_counter #(.TICK_COUNT(60), .WIDTH(6)) U_min (
        //input
        .clk(clk),
        .reset(reset),
        .i_tick(w_tick_sec),
        //.run_stop(run_stop),
        .clear(clear),
        .inc(inc_min),
        .dec(dec_min),
        //output
        .o_tick(w_tick_min),
        .o_time(min)
    ); 

    //count hour
    tick_counter #(.TICK_COUNT(24), .WIDTH(5), .DEFAULT_(12)) U_hour (
        //input
        .clk(clk),
        .reset(reset),
        .i_tick(w_tick_min),
        //.run_stop(run_stop),
        .clear(clear),
        .inc(inc_hour),
        .dec(dec_hour),
        //output
        .o_tick(),
        .o_time(hour)
    ); 

endmodule

module stopwatch_dp_TIMER (
    input        clk,
    input        reset,
    input        clear,
    input        run_stop,
    input        inc_msec,
    input        dec_msec,
    input        inc_sec,
    input        dec_sec,
    input        inc_min,
    input        dec_min,
    input        inc_hour,
    input        dec_hour,
    output       done,
    output [6:0] msec,
    output [5:0] sec,
    output [5:0] min,
    output [4:0] hour
);

    wire w_tick_100hz;
    wire w_tick_msec, w_tick_sec, w_tick_min;

    assign done = (msec == 0 && sec == 0 && min == 0 && hour == 0 && run_stop) ? 1'b1 : 0;

    //generate 100hz tick
    tick_gen_100hz U_tick_gen_100hz(
        //input
        .clk(clk),
        .reset(reset),
        .run_stop(run_stop),
        //output
        .o_tick(w_tick_100hz)
    );

    //count msec tic
    tick_counter_timer #(.TICK_COUNT(100), .WIDTH(7)) U_msec (
        //input
        .clk(clk),
        .reset(reset),
        .i_tick(w_tick_100hz),
        //.run_stop(run_stop),
        .clear(clear),
        .inc(inc_msec),
        .dec(dec_msec),
        //output
        .o_tick(w_tick_msec),
        .o_time(msec)
    ); 

    //count sec
    tick_counter_timer #(.TICK_COUNT(60), .WIDTH(6)/*, .DEFAULT_(5)*/) U_sec (
        //input
        .clk(clk),
        .reset(reset),
        .i_tick(w_tick_msec),
        //.run_stop(run_stop),
        .clear(clear),
        .inc(inc_sec),
        .dec(dec_sec),
        //output
        .o_tick(w_tick_sec),
        .o_time(sec)
    ); 

    //count min
    tick_counter_timer #(.TICK_COUNT(60), .WIDTH(6), .DEFAULT_(1)) U_min ( // timer default is 5min
        //input
        .clk(clk),
        .reset(reset),
        .i_tick(w_tick_sec),
        //.run_stop(run_stop),
        .clear(clear),
        .inc(inc_min),
        .dec(dec_min),
        //output
        .o_tick(w_tick_min),
        .o_time(min)
    ); 

    //count hour
    tick_counter_timer #(.TICK_COUNT(24), .WIDTH(5)) U_hour (
        //input
        .clk(clk),
        .reset(reset),
        .i_tick(w_tick_min),
        //.run_stop(run_stop),
        .clear(clear),
        .inc(inc_hour),
        .dec(dec_hour),
        //output
        .o_tick(),
        .o_time(hour)
    ); 

endmodule

module tick_counter #(parameter TICK_COUNT = 100, WIDTH = 7, DEFAULT_ = 0) (
    input               clk,
    input               reset,
    input               i_tick,
    //input               run_stop,
    input               clear,
    input               inc,
    input               dec,
    output              o_tick,
    output [WIDTH-1:0]  o_time
);
    
    reg [$clog2(TICK_COUNT)-1 : 0] counter_reg, counter_next;
    reg tick_reg, tick_next;

    assign o_time = counter_reg;
    assign o_tick = tick_reg;
    
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_reg <= DEFAULT_;
            tick_reg <= 1'b0;
        end else begin
            counter_reg <= counter_next;
            tick_reg <= tick_next;
        end
    end

    always @(*) begin
        counter_next = counter_reg;
        tick_next = 1'b0;
        //tick 이 1일 경우만 counter inc
        if (i_tick) begin
            if (counter_reg == TICK_COUNT - 1) begin
                counter_next = 0;
                tick_next = 1'b1;
            end else begin
                counter_next = counter_reg + 1;
                tick_next = 1'b0; 
            end 
        end
        //교수님이 만드신 clear
        if (clear) counter_next = DEFAULT_;
        else if(inc) begin
            if(counter_reg == TICK_COUNT - 1) begin
                counter_next = 0;
            end
            else begin
                counter_next = counter_reg + 1;
            end
        end
        else if(dec) begin
            if(counter_reg == 0) begin
                counter_next = TICK_COUNT - 1;
            end
            else begin
                counter_next = counter_reg - 1;
            end
        end
    end

endmodule

module tick_counter_timer #(parameter TICK_COUNT = 100, WIDTH = 7, DEFAULT_ = 0) (
    input               clk,
    input               reset,
    input               i_tick,
    //input               run_stop,
    input               clear,
    input               inc,
    input               dec,
    output              o_tick,
    output [WIDTH-1:0]  o_time
);
    
    reg [$clog2(TICK_COUNT)-1 : 0] counter_reg, counter_next;
    reg tick_reg, tick_next;

    assign o_time = counter_reg;
    assign o_tick = tick_reg;
    
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_reg <= DEFAULT_;
            tick_reg <= 1'b0;
        end else begin
            counter_reg <= counter_next;
            tick_reg <= tick_next;
        end
    end

    always @(*) begin
        counter_next = counter_reg;
        tick_next = 1'b0;
        //tick 이 1일 경우만 counter inc
        if (i_tick) begin
            if (counter_reg == 0) begin
                counter_next = TICK_COUNT - 1;
                tick_next = 1'b1;
            end else begin
                counter_next = counter_reg - 1;
                tick_next = 1'b0; 
            end 
        end
        //교수님이 만드신 clear
        if (clear) counter_next = DEFAULT_;
        else if(inc) begin
            if(counter_reg == TICK_COUNT - 1) begin
                counter_next = 0;
            end
            else begin
                counter_next = counter_reg + 1;
            end
        end
        else if(dec) begin
            if(counter_reg == 0) begin
                counter_next = TICK_COUNT - 1;
            end
            else begin
                counter_next = counter_reg - 1;
            end
        end
    end

endmodule

module tick_gen_100hz (
    input clk,
    input reset,
    input run_stop,
    output o_tick
);
    parameter  FCOUNT = 1_000_000 ;
    reg [$clog2(FCOUNT)-1:0] counter;
    reg r_tick;
    assign o_tick = r_tick;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter <= 0;
            r_tick <= 0;
        end else begin
            if(run_stop) begin
                if (counter == FCOUNT-1) begin
                    counter <= 0;
                    r_tick <= 1'b1;
                end else begin
                    counter <= counter + 1;
                    r_tick <= 1'b0;
                end
            end
        end
    end

endmodule

module btn_debounce(
    input clk,
    input reset,
    input i_btn,
    output o_btn
    );

    wire debounce;
    reg [3:0] q_reg, q_next;
    reg edge_reg;

    //clk divider 1Mhz
    reg [$clog2(100)-1:0] counter;
    reg r_db_clk;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter <= 0;
            r_db_clk <= 0;
        end else begin
            if (counter == (100-1)) begin
                counter <= 0;
                r_db_clk <= 1'b1;
            end else begin
                counter <= counter +1;
                r_db_clk <= 1'b0;
            end
        end
    end

    //shift register
    always @(posedge r_db_clk, posedge reset) begin
        if (reset) begin
            q_reg <= 0;
        end else begin
            q_reg <= q_next;
        end
    end

    //shift register
    always @(*) begin
        q_next = {i_btn, q_reg[3:1]};
    end

    //4 input AND logic
    assign debounce = &q_reg;

    //
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            edge_reg <= 0;
        end else begin
            edge_reg <= debounce;
        end
    end

    assign o_btn = ~edge_reg & debounce;

endmodule

module CLOCK_M( 
    input clk,
    input reset,
    input btn_L,
    input btn_R,
    input inc_msec,
    input dec_msec,
    input inc_sec,
    input dec_sec,
    input inc_min,
    input dec_min,
    input inc_hour,
    input dec_hour,
    output [6:0] msec,
    output [5:0] sec,
    output [5:0] min,
    output [4:0] hour
);

    wire w_run_stop, w_clear;

        stopwatch_w U_stopwatch_w(
            //input
            .clk(clk),
            .reset(reset),
            .btn_L(btn_L),
            .btn_R(btn_R),
            //output
            .run_stop(w_run_stop),
            .clear(w_clear)
        );

        stopwatch_dp U_SW_DP(
            //input
            .clk(clk),
            .reset(reset),
            .clear(w_clear),
            .run_stop(w_run_stop),
            .inc_msec(inc_msec),
            .dec_msec(dec_msec),
            .inc_sec(inc_sec),
            .dec_sec(dec_sec),
            .inc_min(inc_min),
            .dec_min(dec_min),
            .inc_hour(inc_hour),
            .dec_hour(dec_hour),
            //output
            .msec(msec),
            .sec(sec),
            .min(min),
            .hour(hour)
        );

endmodule

module CLOCK_M_WATCH( 
    input clk,
    input reset,
    input btn_L,
    input btn_R,
    input inc_msec,
    input dec_msec,
    input inc_sec,
    input dec_sec,
    input inc_min,
    input dec_min,
    input inc_hour,
    input dec_hour,
    output [6:0] msec,
    output [5:0] sec,
    output [5:0] min,
    output [4:0] hour
);

    wire w_run_stop, w_clear;

        stopwatch_w U_stopwatch_w(
            //input
            .clk(clk),
            .reset(reset),
            .btn_L(btn_L),
            .btn_R(btn_R),
            //output
            .run_stop(w_run_stop),
            .clear(w_clear)
        );

        stopwatch_dp_WATCH U_SW_DP(
            //input
            .clk(clk),
            .reset(reset),
            .clear(w_clear),
            .run_stop(w_run_stop),
            .inc_msec(inc_msec),
            .dec_msec(dec_msec),
            .inc_sec(inc_sec),
            .dec_sec(dec_sec),
            .inc_min(inc_min),
            .dec_min(dec_min),
            .inc_hour(inc_hour),
            .dec_hour(dec_hour),
            //output
            .msec(msec),
            .sec(sec),
            .min(min),
            .hour(hour)
        );

endmodule

module CLOCK_M_TIMER( 
    input clk,
    input reset,
    input btn_L,
    input btn_R,
    input inc_msec,
    input dec_msec,
    input inc_sec,
    input dec_sec,
    input inc_min,
    input dec_min,
    input inc_hour,
    input dec_hour,
    output done_led,
    output [6:0] msec,
    output [5:0] sec,
    output [5:0] min,
    output [4:0] hour
);

    assign done_led = done;

    wire w_run_stop, w_clear;

        stopwatch_dp_TIMER U_SW_DP(
            //input
            .clk(clk),
            .reset(reset),
            .clear(w_clear),
            .run_stop(w_run_stop),
            .inc_msec(inc_msec),
            .dec_msec(dec_msec),
            .inc_sec(inc_sec),
            .dec_sec(dec_sec),
            .inc_min(inc_min),
            .dec_min(dec_min),
            .inc_hour(inc_hour),
            .dec_hour(dec_hour),
            //output
            .msec(msec),
            .sec(sec),
            .min(min),
            .hour(hour),
            .done(done)
        );

        timer_w U_timer_w (
            .clk(clk),
            .reset(reset),
            .btn_L(btn_L),
            .btn_R(btn_R),
            .done(done),
            .run(w_run_stop),
            .clear(w_clear)
        );

endmodule

module timer_w(
    input clk,
    input reset,
    input btn_L,
    input btn_R,
    input done,
    output reg run,
    output reg clear
);

    parameter STOP = 2'b00;
    parameter RUNN = 2'b01;
    parameter DONE = 2'b10;

    reg [1:0] current_state, next_state;

    always @(posedge clk or posedge reset) begin
        if (reset)
            current_state <= STOP;
        else
            current_state <= next_state;
    end

    always @(*) begin
        next_state = current_state;
        run = 0;
        clear = 0;
        case (current_state)
            STOP: begin
                if (btn_R) begin
                    next_state = RUNN;
                    run = 1;
                end
                if (btn_L) clear = 1;
            end
            RUNN: begin
                run = 1;
                if (done)
                    next_state = DONE;
                else if (btn_R)
                    next_state = STOP;
            end
            DONE: begin
                clear = 1;
                next_state = STOP;
            end
        endcase
    end

endmodule

module stopwatch_w( //controller
    
    input clk,
    input reset,
    input btn_L,
    input btn_R,

    output run_stop,
    output clear

);

    //fsm
    //parameter state define
    parameter STOP = 3'b000;
    parameter RUN = 3'b001;
    parameter CLEAR = 3'b010;

    reg [2:0] c_state, n_state;
    reg c_clear;
    reg n_clear;

    //state register SL
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            c_state <= STOP;
            c_clear <= 1'b0;
        end else begin
            c_state <= n_state;
            c_clear <= n_clear;
        end
    end

    //next CL
    always @(*) begin
        n_state = c_state; //latch 방지
        n_clear = c_clear; //latch 방지
        case (c_state)
            STOP: begin
                n_clear = 1'b0;
                if(btn_R == 1'b1) begin
                    n_state = RUN;
                end else if (btn_L == 1'b1) begin
                    n_state = CLEAR;
                end else n_state = c_state;
            end

            RUN: begin
                if(btn_R == 1'b1) begin
                    n_state = STOP;
                end else n_state = c_state;
            end

            CLEAR: begin
                n_state = STOP;
                n_clear = 1'b1;
            end
        endcase
    end

    assign run_stop = (c_state == RUN) ? 1'b1 : 1'b0;
    assign clear = c_clear;

endmodule

