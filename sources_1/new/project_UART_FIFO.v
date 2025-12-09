`timescale 1ns / 1ps

module project_UART_FIFO (  // project top module
    input         clk,
    input         rst,
    input         rx,
    input  [15:0] sw,
    input         btn_L,
    input         btn_R,
    input         btn_U,
    input         btn_D,
    input         echo,

    output        trigger,
    output [ 8:0] led,
    output        tx,
    output [ 3:0] fnd_com,
    output [ 7:0] fnd_data,

    inout dth11_io
);

    wire key_signal, w_key_sel;
    wire w_rx_done;
    wire w_key_L, w_key_R, w_key_U, w_key_D, w_key_q, w_key_z; // btn
    wire w_key_w, w_key_W, w_key_d, w_key_m, w_key_S, w_key_M, w_key_H, w_key_f, w_key_F; // switch
    wire [8:0] key_sw, w_key_sw_sel;
    wire [7:0] w_key;
    wire [7:0] w_ascii_dht11, w_ascii_sr04, w_ascii_key, w_ascii_time;
    wire w_push_dht11, w_push_sr04, w_push_key, w_push_time;

    uart_fifo_loopback U_UART_FIFO_LP (
        // input
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .push_dht11(w_push_dht11),
        .push_sr04(w_push_sr04),
        .push_key(!key_signal),
        .push_time(w_push_time),
        .ascii_dht11(w_ascii_dht11),
        .ascii_sr04(w_ascii_sr04),
        .ascii_key(w_key),
        .ascii_time(w_ascii_time),
        // output
        .tx(tx),
        .rx_done(w_rx_done),
        .w_lp_push(key_signal),
        .w_lp_data(w_key)
    );

    key_decoder U_KEY_DEC (
        // input
        .clk(clk),
        .rst(rst),
        .i_key(w_key),
        .key_signal(key_signal),  // key_signal
        // output
        .o_key_L(w_key_L),
        .o_key_R(w_key_R),
        .o_key_U(w_key_U),
        .o_key_D(w_key_D),
        .o_key_w(w_key_w),
        .o_key_W(w_key_W),
        .o_key_d(w_key_d),
        .o_key_m(w_key_m),
        .o_key_S(w_key_S),
        .o_key_M(w_key_M),
        .o_key_H(w_key_H),
        .o_key_q(w_key_q),
        .o_key_f(w_key_f),
        .o_key_F(w_key_F),
        .o_key_z(w_key_z),
        .key_sel(w_key_sel)
    );

    project3_Clock_with_Sensor_top U_WATCH_TOP (
        // input
        .clk(clk),
        .reset(rst),
        .sw(sw), //sw4 = DISTANCE, sw3 = TEM,HUM, sw0 = Time
        .btn_L(btn_L),  //clear
        .btn_R(btn_R),  //run_stop
        .btn_U(btn_U),  //up
        .btn_D(btn_D),
        .key_L(w_key_L),
        .key_R(w_key_R),
        .key_U(w_key_U),
        .key_D(w_key_D),
        .key_q(w_key_q),
        .key_z(w_key_z),
        .key_sel(w_key_sel),  // w_key_sel
        .key_sw(key_sw),
        .key_sw_sel(w_key_sw_sel),
        .echo(echo),
        // output
        .trigger(trigger),
        .led(led),
        .fnd_com(fnd_com),
        .fnd_data(fnd_data),
        .ascii_dht11(w_ascii_dht11),
        .ascii_sr04(w_ascii_sr04),
        .ascii_time(w_ascii_time),
        .push_dht11(w_push_dht11),
        .push_sr04(w_push_sr04),
        .push_time(w_push_time),
        //inout
        .dth11_io(dth11_io)
    );

    key_switch U_KEY_SW (
        // input
        .clk(clk),
        .rst(rst),
        .key_w(w_key_w),
        .key_W(w_key_W),
        .key_d(w_key_d),
        .key_m(w_key_m),
        .key_S(w_key_S),
        .key_M(w_key_M),
        .key_H(w_key_H),
        .key_f(w_key_f),
        .key_F(w_key_F),
        // output
        .key_sw(key_sw), // 0: digit_sel, 1: mode_sw_w, 2: timer, 3: msec, 4: sec, 5: min, 6: hour
        .o_key_sel(w_key_sw_sel)
    );


endmodule

module key_decoder (
    input clk,
    input rst,
    input [7:0] i_key,
    input key_signal,
    output o_key_L,
    output o_key_R,
    output o_key_U,
    output o_key_D,
    output o_key_w,
    output o_key_W,
    output o_key_d,
    output o_key_m,
    output o_key_S,
    output o_key_M,
    output o_key_H,
    output o_key_q,
    output o_key_f,
    output o_key_F,
    output o_key_z,
    output key_sel
);

    reg c_key_L, n_key_L;
    reg c_key_R, n_key_R;
    reg c_key_U, n_key_U;
    reg c_key_D, n_key_D;
    reg c_key_w, n_key_w;
    reg c_key_W, n_key_W;
    reg c_key_d, n_key_d;
    reg c_key_m, n_key_m;
    reg c_key_S, n_key_S;
    reg c_key_M, n_key_M;
    reg c_key_H, n_key_H;
    reg c_key_q, n_key_q;
    reg c_key_f, n_key_f;
    reg c_key_F, n_key_F;
    reg c_key_z, n_key_z;
    reg c_key_sel, n_key_sel;

    localparam r = 8'h72;  // run
    localparam s = 8'h73;  // stop
    localparam c = 8'h63;  // clear
    localparam w = 8'h77;  // mode (watch <-> stopwatch)
    localparam W = 8'h57;  // mode (Timer)
    localparam D = 8'h44;  // digit select "o_key_d"
    localparam u = 8'h75;  // up 
    localparam d = 8'h64;  // down "o_key_D"
    localparam m = 8'h6d;  // MSEC
    localparam S = 8'h53;  // SEC
    localparam M = 8'h4d;  // MIN
    localparam H = 8'h48;  // HOUR
    localparam q = 8'h71;  // sensing
    localparam f = 8'h66;  // SR04
    localparam F = 8'h46;  // DHT11
    localparam z = 8'h7A;  // display time

    assign o_key_L = c_key_L;
    assign o_key_R = c_key_R;
    assign o_key_U = c_key_U;
    assign o_key_D = c_key_D;
    assign o_key_w = c_key_w;
    assign o_key_W = c_key_W;
    assign o_key_d = c_key_d;
    assign o_key_m = c_key_m;
    assign o_key_S = c_key_S;
    assign o_key_M = c_key_M;
    assign o_key_H = c_key_H;
    assign o_key_q = c_key_q;
    assign o_key_f = c_key_f;
    assign o_key_F = c_key_F;
    assign o_key_z = c_key_z;
    assign key_sel = c_key_sel;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_key_L   <= 0;
            c_key_R   <= 0;
            c_key_U   <= 0;
            c_key_D   <= 0;
            c_key_w   <= 0;
            c_key_W   <= 0;
            c_key_d   <= 0;
            c_key_m   <= 0;
            c_key_S   <= 0;
            c_key_M   <= 0;
            c_key_H   <= 0;
            c_key_q   <= 0;
            c_key_f   <= 0;
            c_key_F   <= 0;
            c_key_z   <= 0;
            c_key_sel <= 0;
        end else begin
            if (!key_signal) begin
                c_key_L   <= n_key_L;
                c_key_R   <= n_key_R;
                c_key_U   <= n_key_U;
                c_key_D   <= n_key_D;
                c_key_w   <= n_key_w;
                c_key_W   <= n_key_W;
                c_key_d   <= n_key_d;
                c_key_m   <= n_key_m;
                c_key_S   <= n_key_S;
                c_key_M   <= n_key_M;
                c_key_H   <= n_key_H;
                c_key_q   <= n_key_q;
                c_key_f   <= n_key_f;
                c_key_F   <= n_key_F;
                c_key_z   <= n_key_z;
                c_key_sel <= 1;
            end else begin
                c_key_L   <= 0;
                c_key_R   <= 0;
                c_key_U   <= 0;
                c_key_D   <= 0;
                c_key_w   <= 0;
                c_key_W   <= 0;
                c_key_d   <= 0;
                c_key_m   <= 0;
                c_key_S   <= 0;
                c_key_M   <= 0;
                c_key_H   <= 0;
                c_key_q   <= 0;
                c_key_f   <= 0;
                c_key_F   <= 0;
                c_key_z   <= 0;
                c_key_sel <= 0;
            end
        end
    end

    always @(*) begin
        n_key_L = c_key_L;
        n_key_R = c_key_R;
        n_key_U = c_key_U;
        n_key_D = c_key_D;
        n_key_w = c_key_w;
        n_key_W = c_key_W;
        n_key_d = c_key_d;
        n_key_m = c_key_m;
        n_key_S = c_key_S;
        n_key_M = c_key_M;
        n_key_H = c_key_H;
        n_key_q = c_key_q;
        n_key_f = c_key_f;
        n_key_F = c_key_F;
        n_key_z = c_key_z;
        case (i_key)
            r: n_key_R = 1;
            s: n_key_R = 1;
            c: n_key_L = 1;
            w: n_key_w = 1;
            W: n_key_W = 1;
            D: n_key_d = 1;
            u: n_key_U = 1;
            d: n_key_D = 1;
            m: n_key_m = 1;
            S: n_key_S = 1;
            M: n_key_M = 1;
            H: n_key_H = 1;
            q: n_key_q = 1;
            f: n_key_f = 1;
            F: n_key_F = 1;
            z: n_key_z = 1;
            default: ;
        endcase
    end

endmodule

module key_switch (
    input        clk,
    input        rst,
    input        key_w,
    input        key_W,
    input        key_d,
    input        key_m,
    input        key_S,
    input        key_M,
    input        key_H,
    input        key_f,
    input        key_F,
    output [8:0] key_sw, // 0: digit_sel, 1: mode_sw_w, 2: timer, 3: msec, 4: sec, 5: min, 6: hour, 7: SR04, 8: DHT11
    output [8:0] o_key_sel
);

    reg [8:0] r_sw, r_key_sel;

    assign key_sw = r_sw;
    assign o_key_sel = r_key_sel;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            r_sw <= 7'b0;
            r_key_sel <= 7'b0;
        end else begin
            // mode stopwatch watch
            if (key_w) begin 
                r_sw[1] <= ~r_sw[1];
                r_key_sel[1] <= ~r_key_sel[1];
            end else begin
                r_sw[1] <= r_sw[1];
                r_key_sel[1] <= r_key_sel[1];
            end
            // mode timer
            if (key_W) begin 
                r_sw[2] <= ~r_sw[2];
                r_key_sel[2] <= ~r_key_sel[2];
            end else begin
                r_sw[2] <= r_sw[2];
                r_key_sel[2] <= r_key_sel[2];
            end
            // digit select
            if (key_d) begin 
                r_sw[0] <= ~r_sw[0];
                r_key_sel[0] <= ~r_key_sel[0];
            end else begin
                r_sw[0] <= r_sw[0];
                r_key_sel[0] <= r_key_sel[0];
            end
            // msec
            if (key_m) begin 
                r_sw[3] <= ~r_sw[3];
                r_key_sel[3] <= ~r_key_sel[3];
            end else begin
                r_sw[3] <= r_sw[3];
                r_key_sel[3] <= r_key_sel[3];
            end
            // sec
            if (key_S) begin 
                r_sw[4] <= ~r_sw[4];
                r_key_sel[4] <= ~r_key_sel[4];
            end else begin
                r_sw[4] <= r_sw[4];
                r_key_sel[4] <= r_key_sel[4];
            end
            // min
            if (key_M) begin 
                r_sw[5] <= ~r_sw[5];
                r_key_sel[5] <= ~r_key_sel[5];
            end else begin
                r_sw[5] <= r_sw[5];
                r_key_sel[5] <= r_key_sel[5];
            end
            // hour
            if (key_H) begin 
                r_sw[6] <= ~r_sw[6];
                r_key_sel[6] <= ~r_key_sel[6];
            end else begin
                r_sw[6] <= r_sw[6];
                r_key_sel[6] <= r_key_sel[6];
            end
            // SR04
            if (key_f) begin
                r_sw[7] <= ~r_sw[7];
                r_key_sel[7] <= ~r_key_sel[7];
            end else begin
                r_sw[7] <= r_sw[7];
                r_key_sel[7] <= r_key_sel[7];
            end
            // DHT11
            if (key_F) begin
                r_sw[8] <= ~r_sw[8];
                r_key_sel[8] <= ~r_key_sel[8];
            end else begin
                r_sw[8] <= r_sw[8];
                r_key_sel[8] <= r_key_sel[8];
            end
        end
    end

endmodule
