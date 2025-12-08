`timescale 1ns / 1ps

module fifo_control_unit(
    input clk,
    input rst,
    input push,
    input pop,

    output [3:0] w_addr,
    output [3:0] r_addr,
    output full,
    output empty
    );

    reg [3:0] c_w_ptr, n_w_ptr;
    reg [3:0] c_r_ptr, n_r_ptr;
    reg c_full, n_full;
    reg c_empty, n_empty;

    always @(posedge clk, posedge rst) begin
        if(rst) begin
            // state IDLE
            c_w_ptr <= 4'b0;
            c_r_ptr <= 4'b0;
            c_full  <= 1'b0;
            c_empty <= 1'b1;
        end
        else begin
            c_w_ptr <= n_w_ptr;
            c_r_ptr <= n_r_ptr;
            c_full  <= n_full;
            c_empty <= n_empty;
        end
    end

    always @(*) begin
        n_w_ptr = c_w_ptr;
        n_r_ptr = c_r_ptr;
        n_full  = c_full;
        n_empty = c_empty;
        case ({push, pop})
            2'b01 : begin // pop 1
                if(!c_empty) begin
                    n_r_ptr = c_r_ptr + 1;
                    n_full = 1'b0;
                    if(c_w_ptr == n_r_ptr) begin
                        n_empty = 1'b1;
                    end
                end
            end
            2'b10 : begin // push 1
                if(!c_full) begin
                    n_w_ptr = c_w_ptr + 1;
                    n_empty = 1'b0;
                    if(n_w_ptr == c_r_ptr) begin
                        n_full = 1'b1;
                    end
                end
            end
            2'b11 : begin // push & pop 1
                if(c_empty) begin
                    n_w_ptr = c_w_ptr + 1;
                    n_empty = 1'b0;
                end
                else if(c_full) begin
                    n_r_ptr = c_r_ptr + 1;
                    n_full = 1'b0;
                end
                else begin
                    n_w_ptr = c_w_ptr + 1;
                    // n_r_ptr = c_r_ptr + 1;
                end
            end
        endcase
    end

    assign w_addr = c_w_ptr;
    assign r_addr = c_r_ptr;
    assign full = c_full;
    assign empty = c_empty;

endmodule
