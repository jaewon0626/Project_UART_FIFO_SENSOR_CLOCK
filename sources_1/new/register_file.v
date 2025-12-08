`timescale 1ns / 1ps

module register_file(
    input clk,
    input [7:0] w_data,
    input [3:0] w_addr,
    input [3:0] r_addr,
    input we,

    output [7:0] r_data
    );

    reg [7:0] mem[0:14]; // register file(4) 주소 4개

    // write
    always @(posedge clk) begin
        if(we) begin
            mem[w_addr] <= w_data; // write to mem
        end 
    end

    // read
    assign r_data = mem[r_addr];

endmodule
