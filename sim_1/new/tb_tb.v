`timescale 1ns / 1ps

module tb_tb();

    reg clk, rst, rx;
    wire tx;

    project_UART_FIFO DUT(  // project top module
    .clk(clk),
    .rst(rst),
    .rx(rx),
    //.sw,
    //btn_L,
    //.btn_R,
    //.btn_U,
    //.btn_D,
    //.trigger,
    //.led,
    .tx(tx)
    //.fnd_com,
    //.fnd_data,

    //inout dth11_io
);

    always #5 clk = ~clk;

    initial begin
        #0;
        clk = 0;
        rst = 1;
        rx = 1;
        #10;
        rst = 0;


        #(104160);
        //rx = 0;

        #(104160);
        //rx = 1;

        #(104160);
        //rx = 0;

        #(104160);
        //rx = 0;

        #(104160);
        //rx = 1;

        #(104160);
        //rx = 1;
        #(104160);
        //rx = 1;
        #(104160);
        //rx = 0;
        #(104160);
        //rx = 1;

        #(200000);
        $stop;
        
    end

endmodule
