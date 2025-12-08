`timescale 1ns / 1ps

module fnd_controller(
    clk,
    rst,
    cnt,
    fnd_com,
    fnd_data
    );

    input clk;
    input rst;
    input [13:0] cnt;

    output [3:0] fnd_com;
    output [7:0] fnd_data;

    wire [3:0] w_digit_1;
    wire [3:0] w_digit_10;
    wire [3:0] w_digit_100;
    wire [3:0] w_digit_1000;

    wire [3:0] w_bcd;
    wire [1:0] w_digit_sel;
    wire w_1khz;

    bcd_decoder u_bcd(
        .bcd(w_bcd),
        .fnd_data(fnd_data)
        );
    
    digital_spliter u_ds(
        .cnt_data(cnt),
        .digit_1(w_digit_1),
        .digit_10(w_digit_10),
        .digit_100(w_digit_100),
        .digit_1000(w_digit_1000)
        );

    mux_4x1 u_mux4x1(
        .sel(w_digit_sel),
        .digit_1(w_digit_1),
        .digit_10(w_digit_10),
        .digit_100(w_digit_100),
        .digit_1000(w_digit_1000),
        .bcd_data(w_bcd)
        );

    mux_2x4 u_mux2x4(
        .sel(w_digit_sel),
        .fnd_com(fnd_com)
        );

    counter_4 u_cnt_4(
        .clk(w_1khz),
        .rst(rst),
        .digit_sel(w_digit_sel)
        );

    clk_div_1khz u_clk_div(
        .clk(clk),
        .rst(rst),
        .o_1khz(w_1khz)
        );

endmodule

//-------------------------------------------------------------------------------------------

module bcd_decoder(
    bcd,
    fnd_data
);

    input [3:0] bcd;
    output reg [7:0] fnd_data;

    always @(bcd) begin
        case (bcd)
        4'd0 : fnd_data = 8'hc0;
        4'd1 : fnd_data = 8'hf9;
        4'd2 : fnd_data = 8'ha4;
        4'd3 : fnd_data = 8'hb0;
        4'd4 : fnd_data = 8'h99;
        4'd5 : fnd_data = 8'h92;
        4'd6 : fnd_data = 8'h82;
        4'd7 : fnd_data = 8'hf8;
        4'd8 : fnd_data = 8'h80;
        4'd9 : fnd_data = 8'h90;
        default : fnd_data = 8'hff;
        endcase
    end

endmodule

//-------------------------------------------------------------------------------------------

module digital_spliter(
    cnt_data,
    digit_1,
    digit_10,
    digit_100,
    digit_1000
    );

    input [13:0] cnt_data; // [7:0] sum + carry -> 9bit
    output [3:0] digit_1;
    output [3:0] digit_10;
    output [3:0] digit_100;
    output [3:0] digit_1000;

    assign digit_1 = cnt_data % 10;
    assign digit_10 = cnt_data / 10 % 10;
    assign digit_100 = cnt_data / 100 % 10;
    assign digit_1000 = cnt_data / 1000 % 10;

endmodule

//-------------------------------------------------------------------------------------------

module mux_4x1(
    sel,
    digit_1,
    digit_10,
    digit_100,
    digit_1000,
    bcd_data
);

    input [1:0] sel;
    input [3:0] digit_1;
    input [3:0] digit_10;
    input [3:0] digit_100;
    input [3:0] digit_1000;

    output reg [3:0] bcd_data;

    always @(*) begin
        case(sel)
        2'b00 : bcd_data = digit_1;
        2'b01 : bcd_data = digit_10;
        2'b10 : bcd_data = digit_100;
        2'b11 : bcd_data = digit_1000;
        default : bcd_data = digit_1;
        endcase
    end
    
endmodule

//-------------------------------------------------------------------------------------------

module mux_2x4(
    sel,
    fnd_com
);

    input [1:0] sel;

    output reg [3:0] fnd_com;

    always @(*) begin
        case(sel)
        2'b00 : fnd_com = 4'b1110; // digit_1
        2'b01 : fnd_com = 4'b1101; // digit_10
        2'b10 : fnd_com = 4'b1011; // digit_100
        2'b11 : fnd_com = 4'b0111; // digit_1000
        default : fnd_com = 4'b1111;
        endcase
    end
    
endmodule

//-------------------------------------------------------------------------------------------

module counter_4(
    clk,
    rst,
    digit_sel
);

    input clk;
    input rst;

    output [1:0] digit_sel;

    reg [1:0] cnt;

    always @(posedge clk, posedge rst) begin
        if(rst) begin
            cnt <= 2'b0;
        end
        else begin
            cnt <= cnt + 1;
        end
    end

    assign digit_sel = cnt;

endmodule

//-------------------------------------------------------------------------------------------

module clk_div_1khz(
    clk,
    rst,
    o_1khz
);

    input clk;
    input rst;

    output reg o_1khz;
    
    reg [16:0] cnt;

    always @(posedge clk, posedge rst) begin
        if(rst) begin
            cnt <= 17'd0;
            o_1khz <= 1'b0;
        end
        else begin
            if(cnt == 100_000 - 1) begin
                cnt <= 17'd0;
                o_1khz <= 1'b1;
            end
            else begin
            cnt <= cnt + 1;
            o_1khz <= 1'b0;
            end
        end
    end

endmodule