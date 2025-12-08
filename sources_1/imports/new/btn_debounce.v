`timescale 1ns / 1ps

module btn_debounce(
    clk,
    rst,
    i_btn,
    o_btn
    );

    input clk;
    input rst;
    input i_btn;

    output o_btn;

    reg [3:0] q_reg, q_next;

    reg [$clog2(100)-1:0] cnt;
    reg r_db_clk;

    wire debounce;

    /*
    // need to only FPGA
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            cnt <= 0;
            r_db_clk <= 0;
        end
        else begin
            if(cnt == (100-1)) begin
                cnt <= 0;
                r_db_clk <= 1;
            end
            else begin
                cnt <= cnt + 1;
                r_db_clk <= 0;
            end
        end
    end
    
    always @(posedge r_db_clk or posedge rst) begin
        if(rst) begin
            q_reg <= 0;
        end
        else begin
            q_reg <= q_next;
        end
    end
    */

    // shift register
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            q_reg <= 0;
        end
        else begin
            q_reg <= q_next;
        end
    end

    always @(*) begin
            q_next = {i_btn, q_reg[3:1]}; // when rising clk
    end

    assign debounce = &q_reg; // 4-input AND logic

    reg edge_reg;

    // delay FF
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            edge_reg <= 0;
        end
        else begin
            edge_reg <= debounce;
        end
    end

    assign o_btn = (~edge_reg & debounce);

endmodule
