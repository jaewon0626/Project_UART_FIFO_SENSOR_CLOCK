`timescale 1ns / 1ps

module tb_dht11_cu();

    parameter US = 1000;

    reg clk;
    reg rst;
    reg start;
    reg dht_io_reg;
    reg io_en;
    reg [39:0] dht_test_data;

    wire tx;
    wire [9:0] state_led;
    wire dht_io;

    // wire dht_data;
    // wire valid;
    // wire done;

    assign dht_io = (io_en) ? 1'bz : dht_io_reg;

    always #5 clk = ~clk;

    integer i = 0;

    initial begin
        #0;
        clk = 0;
        rst = 1;
        start = 0;
        dht_io_reg = 0;
        io_en = 1;
        dht_test_data = 40'b0001_0010_0011_0100_0101_0110_0111_1000_1001_1010;

        #20;
        rst = 0;

        #20;
        start = 1;
        #(50*US);
        start = 0;

        wait(!dht_io);
        wait(dht_io);

        #(30*US);
        io_en = 0;
        dht_io_reg = 0;
        #(80*US);
        dht_io_reg = 1;
        #(80*US);
        for(i = 0; i < 40; i = i + 1) begin
            dht_io_reg = 0;
            #(50*US);

            if(dht_test_data[39-i] == 0) begin
                dht_io_reg = 1;
                #(29*US);
            end
            else begin
                dht_io_reg = 1;
                #(68*US);
            end
        end
        dht_io_reg = 0;
        #(50*US);
        io_en = 1;
        #50000;
        $stop;
    end

    top_uart_fifo_sensor U_UF_SENSOR(
        .clk(clk),
        .rst(rst),
        .btn_start(start),

        .tx(tx),

        .dht11_io(dht_io)
    );


endmodule
