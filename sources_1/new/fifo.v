`timescale 1ns / 1ps

module fifo (
    input        clk,
    input        rst,
    input  [7:0] w_data,
    input        push,
    input        pop,
    output [7:0] r_data,
    output       full,
    output       empty
);

    wire [3:0] w_addr, r_addr;

    register_file U_REGISTER_FILE (
        // input
        .clk(clk),
        .w_data(w_data),
        .w_addr(w_addr),
        .r_addr(r_addr),
        .wr_en((!full) && push),
        // output
        .r_data(r_data)
    );

    fifo_control_unit U_FIFO_CU (
        // input
        .clk(clk),
        .rst(rst),
        .push(push),
        .pop(pop),
        // output
        .w_addr(w_addr),
        .r_addr(r_addr),
        .full(full),
        .empty(empty)
    );

endmodule

module register_file (
    input        clk,
    input  [7:0] w_data,
    input  [3:0] w_addr,
    input  [3:0] r_addr,
    input        wr_en,
    output [7:0] r_data
);

    reg [7:0] mem[0:15];  // 8 bits, 4 spaces

    assign r_data = mem[r_addr];

    always @(posedge clk) begin
        if (wr_en) begin
            mem[w_addr] <= w_data;  // write to mem
        end
    end

endmodule

module fifo_control_unit (
    input        clk,
    input        rst,
    input        push,
    input        pop,
    output [3:0] w_addr,
    output [3:0] r_addr,
    output       full,
    output       empty
);

    reg [3:0] c_wptr, n_wptr;
    reg [3:0] c_rptr, n_rptr;
    reg c_full, n_full;
    reg c_empty, n_empty;

    assign w_addr = c_wptr;
    assign r_addr = c_rptr;
    assign full   = c_full;
    assign empty  = c_empty;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_wptr  <= 4'b0;
            c_rptr  <= 4'b0;
            c_full  <= 1'b0;
            c_empty <= 1'b1;
        end else begin
            c_wptr  <= n_wptr;
            c_rptr  <= n_rptr;
            c_full  <= n_full;
            c_empty <= n_empty;
        end
    end

    always @(*) begin
        n_wptr  = c_wptr;
        n_rptr  = c_rptr;
        n_full  = c_full;
        n_empty = c_empty;
        case ({
            push, pop
        })
            2'h1: begin  // pop
                if (!c_empty) begin
                    n_rptr = c_rptr + 1;
                    n_full = 1'b0;
                    if (c_wptr == n_rptr) begin
                        n_empty = 1'b1;
                    end
                end
            end
            2'h2: begin  // push
                if (!c_full) begin
                    n_wptr  = c_wptr + 1;
                    n_empty = 1'b0;
                    if (n_wptr == c_rptr) begin
                        n_full = 1'b1;
                    end
                end
            end
            2'h3: begin  // push && pop
                if (c_empty) begin
                    n_wptr  = c_wptr + 1;
                    n_empty = 1'b0;
                end else if (c_full) begin
                    n_rptr = c_rptr + 1;
                    n_full = 1'b0;
                end else begin
                    n_wptr = c_wptr + 1;
                end
            end
        endcase
    end

endmodule
