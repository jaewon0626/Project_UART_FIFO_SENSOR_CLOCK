module tick_gen(
    clk,
    rst,
    o_tick
    );

    input clk;
    input rst;

    output o_tick;

    parameter COUNT = 1000 - 1;
    localparam WIDTH = $clog2(COUNT);

    reg [WIDTH-1:0] cnt;
    reg r_tick;

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            cnt <= 0;
            r_tick <= 0;
        end
        else begin
            if(cnt == COUNT) begin
                cnt <= 0;
                r_tick <= 1;
            end
            else begin
                cnt <= cnt + 1;
                r_tick <= 0;
            end
        end
    end

    assign o_tick = r_tick;

endmodule