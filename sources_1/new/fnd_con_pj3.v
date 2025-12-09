`timescale 1ns / 1ps

module fnd_controller_pj3(

    //input [1:0] digit_sel, //for button in middle of the board
    input           clk,
    input           reset,
    input   [2:0]   sw,
        //CLOCK
    input   [6:0]   msec,
    input   [5:0]   sec,
    input   [5:0]   min,
    input   [4:0]   hour,
        //DTH11
    input   [15:0]  dth11_data,
        //SR04
    input   [8:0]   dist,

    output  [3:0]   fnd_com,
    output  [7:0]   fnd_data
);

    wire [3:0] w_digit_msec_1, w_digit_msec_10, w_digit_sec_1, w_digit_sec_10; //A
    wire [3:0] w_digit_min_1, w_digit_min_10, w_digit_hour_1, w_digit_hour_10; //B
    wire [3:0] HUM_1, HUM_10, TEM_1, TEM_10; //C
    wire [3:0] w_dist_1, w_dist_10, w_dist_100, w_dist_1000;//D

    wire [3:0] w_bcd_A, w_bcd_B; //A&B
    wire [3:0] w_dth11; //C
    wire [3:0] w_sr04; //D
    wire [3:0] W_select_AorBorCorD;
    wire w_dot_onoff;
    wire [2:0] w_digit_sel;
    wire w_1khz;

    clk_div U_CLK_DIV(
        .clk(clk),
        .reset(reset),
        .o_1khz(w_1khz)
    );

    //spliters//(msec)(sec)(min)(hour)/////////////////////////////////////////////////////////////////////////
    digit_spliter #(.DS_WIDTH(7)) U_MSEC_DS (
        .i_data(msec),
        .digit_1(w_digit_msec_1),
        .digit_10(w_digit_msec_10)
    );

    digit_spliter #(.DS_WIDTH(6)) U_SEC_DS (
        .i_data(sec),
        .digit_1(w_digit_sec_1),
        .digit_10(w_digit_sec_10)
    );

    digit_spliter #(.DS_WIDTH(6)) U_MIN_DS (
        .i_data(min),
        .digit_1(w_digit_min_1),
        .digit_10(w_digit_min_10)
    );

    digit_spliter #(.DS_WIDTH(5)) U_HOUR_DS (
        .i_data(hour),
        .digit_1(w_digit_hour_1),
        .digit_10(w_digit_hour_10)
    );

    digit_spliter_TEM U_TEM_DS (
        .i_data(dth11_data[7:0]),
        .TEM_1(TEM_1),
        .TEM_10(TEM_10)
    );

    digit_spliter_HUM U_HUM_DS (
        .i_data(dth11_data[15:8]),
        .HUM_1(HUM_1),
        .HUM_10(HUM_10)
    );

    digit_spliter_DIS U_DIS(
        .dist(dist),

        .dist_1(w_dist_1),
        .dist_10(w_dist_10),
        .dist_100(w_dist_100),
        .dist_1000(w_dist_1000)
    );

    //spliters//(msec)(sec)(min)(hour)/////////////////////////////////////////////////////////////////////////

    dot_comp U_dot_comp(
        .msec(msec),
        .dot_onoff(w_dot_onoff)
    );

    //MUX??????????????????????????????????????????????????????????????????????????????????????????????????????
    mux_8x1 U_8x1_MSEC_SEC_A(
        .sel(w_digit_sel),
        .digit_1(w_digit_msec_1),
        .digit_10(w_digit_msec_10),
        .digit_100(w_digit_sec_1),
        .digit_1000(w_digit_sec_10),
        .digit_off_1(4'he),
        .digit_off_10(4'he),
        .digit_dot({3'b111, w_dot_onoff}),
        .digit_off_1000(4'he),
        .bcd_data(w_bcd_A)
    );

    mux_8x1 U_8x1_MIN_HOUR_B(
        .sel(w_digit_sel),
        .digit_1(w_digit_min_1),
        .digit_10(w_digit_min_10),
        .digit_100(w_digit_hour_1),
        .digit_1000(w_digit_hour_10),
        .digit_off_1(4'he),
        .digit_off_10(4'he),
        .digit_dot({3'b111, w_dot_onoff}),
        .digit_off_1000(4'he),
        .bcd_data(w_bcd_B)
    );

    mux_8x1 U_8x1_TEM_HUM_C(
        .sel(w_digit_sel),
        .digit_1(TEM_1),
        .digit_10(TEM_10),
        .digit_100(HUM_1),
        .digit_1000(HUM_10),
        .digit_off_1(4'he),
        .digit_off_10(4'he),
        .digit_dot(4'hf),
        .digit_off_1000(4'he),
        .bcd_data(w_dth11)
    );

    mux_8x1 U_8x1_DIST_D(
        .sel(w_digit_sel),
        .digit_1(w_dist_1),
        .digit_10(w_dist_10),
        .digit_100(w_dist_100),
        .digit_1000(w_dist_1000),
        .digit_off_1(4'hf),
        .digit_off_10(4'he),
        .digit_dot(4'he),
        .digit_off_1000(4'he),
        .bcd_data(w_sr04)
    );

    mux_2x1 U_MUX_2x1(
        .sel(sw),
        .A(w_bcd_A),
        .B(w_bcd_B),
        .C(w_dth11),
        .D(w_sr04),
        .select(W_select_AorBorCorD)
    );
    //MUX??????????????????????????????????????????????????????????????????????????????????????????????????????

    decoder_2x4 U_decoder_fnd_com (
        .sel(w_digit_sel[1:0]),
        .fnd_com(fnd_com)
    );

    counter_8 U_counter_8(
        .clk(w_1khz),
        .reset(reset),
        .digit_sel(w_digit_sel) 
    );

    bcd_decoder U_BCD (
        .bcd(W_select_AorBorCorD),
        .fnd_data(fnd_data)
    );


endmodule


module digit_spliter #(parameter DS_WIDTH = 7) (
    input [DS_WIDTH-1:0] i_data,
    output [3:0] digit_1,
    output [3:0] digit_10
);

    assign digit_1 = i_data % 10;
    assign digit_10 = (i_data/10) %10;

endmodule

module digit_spliter_TEM (
    input [7:0] i_data,
    output [3:0] TEM_1,
    output [3:0] TEM_10
);

    assign TEM_1 = i_data % 10;
    assign TEM_10 = (i_data/10) %10;

endmodule

module digit_spliter_HUM (
    input [7:0] i_data,
    output [3:0] HUM_1,
    output [3:0] HUM_10
);

    assign HUM_1 = i_data % 10;
    assign HUM_10 = (i_data/10) %10;

endmodule

module digit_spliter_DIS (
    input  [8:0] dist,
    output [3:0] dist_1,
    output [3:0] dist_10,
    output [3:0] dist_100,
    output [3:0] dist_1000
);

    assign dist_1 = dist % 10;
    assign dist_10 = (dist / 10) % 10;
    assign dist_100 = (dist / 100) % 10;
    assign dist_1000 = (dist / 1000) % 10;

endmodule

module bcd_decoder (
    input      [3:0]bcd,
    output reg [7:0]fnd_data
);   

    always @(bcd) begin
        case (bcd)
            4'h0: fnd_data = 8'hc0;
            4'h1: fnd_data = 8'hf9;
            4'h2: fnd_data = 8'ha4;
            4'h3: fnd_data = 8'hb0;
            4'h4: fnd_data = 8'h99;
            4'h5: fnd_data = 8'h92;
            4'h6: fnd_data = 8'h82;
            4'h7: fnd_data = 8'hf8; //1111 1000
            4'h8: fnd_data = 8'h80;
            4'h9: fnd_data = 8'h90;
            4'he: fnd_data = 8'hff;
            4'hf: fnd_data = 8'h7f;

            default: fnd_data = 8'hff;
        endcase
    end

endmodule

module mux_8x1 (
    input      [2:0]sel,
    input      [3:0]digit_1,
    input      [3:0]digit_10,
    input      [3:0]digit_100,
    input      [3:0]digit_1000,
    input      [3:0]digit_off_1,
    input      [3:0]digit_off_10,
    input      [3:0]digit_dot,
    input      [3:0]digit_off_1000,
    output reg [3:0]bcd_data
);
    
    always @(*) begin //@=event, * = every input
        case (sel)
            3'b000: bcd_data = digit_1;
            3'b001: bcd_data = digit_10;
            3'b010: bcd_data = digit_100; 
            3'b011: bcd_data = digit_1000;
            3'b100: bcd_data = digit_off_1;
            3'b101: bcd_data = digit_off_10;
            3'b110: bcd_data = digit_dot; 
            3'b111: bcd_data = digit_off_1000;
            default: bcd_data = digit_1;
        endcase
    end

endmodule

module mux_2x1 (
    input      [2:0]    sel,
    input      [3:0]    A,
    input      [3:0]    B,
    input      [3:0]    C,
    input      [3:0]    D,
    output reg [3:0]    select
);
    
    always @(*) begin
        case (sel)
            3'b000: select = A;
            3'b001: select = B;
            3'b010: select = C;
            3'b011: select = C;
            3'b100: select = D;
            3'b101: select = D;
            default: select = A;
        endcase
    end

endmodule

module decoder_2x4 (
    input [1:0] sel,
    output reg [3:0] fnd_com
);
    
    always @(*) begin
        case (sel)
            2'b00: fnd_com = 4'b1110;
            2'b01: fnd_com = 4'b1101;
            2'b10: fnd_com = 4'b1011;
            2'b11: fnd_com = 4'b0111;
            default: fnd_com = 4'b1110;
        endcase
    end

endmodule

module counter_8 (
    input clk,
    input reset,
    output [2:0] digit_sel 
);
    
    reg [2:0] r_counter; 
    assign digit_sel = r_counter;

    always @(posedge clk, posedge reset) begin //posedge = positive edge, negedge = negative edge// when occure positive edge, 'begin' start
        if (reset) begin
            //initialization
            r_counter <= 0;
        end else begin
            //operation
            r_counter <= r_counter + 1;
        end
    end

endmodule

module clk_div (
    input clk,
    input reset,
    output reg o_1khz
);

    reg [16:0] r_counter;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter <= 0;
            o_1khz <= 1'b0;
        end else begin
            if (r_counter == 100_000 - 1) begin
                r_counter <= 0;
                o_1khz <= 1'b1;
            end else begin
                r_counter <= r_counter + 1; //increse 1, each clk
                o_1khz <= 1'b0;
            end
        end
    end
    
endmodule 

module dot_comp (
    input [6:0] msec,
    output dot_onoff
);
    
    assign dot_onoff = (msec >= 50)? 1'b1 : 1'b0;

endmodule