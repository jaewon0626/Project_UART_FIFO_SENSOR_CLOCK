`timescale 1ns / 1ps

module DHT11_control_unit(
    //input
    input           clk, 
    input           reset,
    input           start,
    input           tick_10us,
    //output
    output          valid,  //?
    output          done,   //?
    output [6:0]    led,    //state, valid
    output [39:0]   dth11_data,//?

    //inout
    inout           dth11_io // tx, rx
);

    parameter [3:0] IDLE = 0, START = 1, WAIT = 2, SYNC_L = 3, 
    SYNC_H = 4, DATA_SYNC = 5, DATA_WAIT = 6, DATA_DETERMINE = 7, STOP_SYNC = 8, STOP = 9;

    reg [$clog2(1800)-1 : 0] tick_count_reg, tick_count_next;
    reg [$clog2(40)-1 : 0]   bits_count_reg, bits_count_next;
    reg [3:0] state_current, state_next;
    reg input_data;
    reg [39:0] dth11_data_current, dth11_data_next;
    reg valid_current, valid_next;
    reg [6:0] led_reg_current, led_reg_next;
    reg done_reg_current, done_reg_next;
    
    //to control tx state
    reg  tx_en_reg, tx_en_next;
    reg  tx_reg, tx_next;

    assign dth11_io   = (tx_en_reg) ? (tx_reg) : 1'bz;
    assign dth11_data = dth11_data_current;
    assign valid      = valid_current;
    assign led        = led_reg_current;
    assign done       = done_reg_current;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            tx_reg             <= 1;
            tx_en_reg          <= 1;
            state_current      <= IDLE;
            tick_count_reg     <= 0;
            bits_count_reg     <= 0;
            dth11_data_current <= 0;
            valid_current      <= 0;
            led_reg_current    <= 7'b0000000;
            done_reg_current   <= 0;
            input_data         <= 0;
        end else begin
            tx_reg             <= tx_next;
            tx_en_reg          <= tx_en_next;
            state_current      <= state_next;
            tick_count_reg     <= tick_count_next;
            bits_count_reg     <= bits_count_next;
            dth11_data_current <= dth11_data_next;
            valid_current      <= valid_next;
            led_reg_current    <= led_reg_next;
            done_reg_current   <= done_reg_next;
        end
    end

    always @(*) begin
        tx_next         = tx_reg;
        tx_en_next      = tx_en_reg;
        state_next      = state_current;
        tick_count_next = tick_count_reg;
        bits_count_next = bits_count_reg;
        dth11_data_next = dth11_data_current;
        valid_next      = valid_current;
        led_reg_next    = led_reg_current;
        done_reg_next   = done_reg_current;
        case (state_current)
            IDLE: begin
                tx_en_next = 1;
                tx_next    = 1;
                input_data = 0;
                done_reg_next = 0;
                if (start) begin
                    valid_next = 0;
                    led_reg_next = 7'b0000000;
                    state_next = START;
                end   
            end

            START: begin
                tx_next = 0;
                if (tick_10us) begin
                    if (tick_count_reg >= 1800) begin
                        tick_count_next = 0;
                        state_next      = WAIT;
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end

            WAIT: begin
                tx_next = 1;
                if (tick_10us) begin
                    if (tick_count_reg >= 3) begin
                        tick_count_next = 0;
                        tx_en_next      = 0;
                        state_next      = SYNC_L;
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end                    
                end
            end

            SYNC_L: begin
                if (tick_10us & dth11_io) begin
                    if (tick_count_reg >= 5) begin
                        tick_count_next = 0;
                        state_next      = SYNC_H;
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end

            SYNC_H: begin
                if (tick_10us & ~(dth11_io)) begin
                    if (tick_count_reg) begin
                        tick_count_next = 0;
                        state_next      = DATA_SYNC;
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end

            DATA_SYNC: begin
                if (dth11_io) begin
                    state_next = DATA_WAIT;
                end
            end

            DATA_WAIT: begin
                if (tick_10us) begin
                    tick_count_next = tick_count_reg + 1;
                    if (~dth11_io) begin
                        state_next = DATA_DETERMINE;
                    end
                end
            end

            DATA_DETERMINE: begin
                if (tick_10us) begin
                    if (tick_count_reg >= 5) begin
                        input_data = 1;
                    end else begin
                        input_data = 0;
                    end

                    tick_count_next = 0;

                    dth11_data_next = {dth11_data_current[39:1], input_data};

                    if (bits_count_reg == 39) begin
                        bits_count_next = 0;
                        state_next      = STOP_SYNC;
                    end else begin
                        bits_count_next = bits_count_reg + 1;
                        dth11_data_next = dth11_data_next << 1;
                        state_next = DATA_SYNC;
                    end
                end
            end

            STOP_SYNC: begin
                if (tick_10us) begin
                    if (tick_count_reg >= 5) begin
                        tick_count_next = 0;
                        state_next      = STOP;
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end

            STOP: begin
                if (tick_10us) begin
                    if (dth11_data_current[7:0] == dth11_data_current[15:8] + dth11_data_current[23:16] + dth11_data_current[31:24] + dth11_data_current[39:32]) begin
                        led_reg_next = 7'b1000000;
                        done_reg_next = 1;
                        valid_next = 1;
                        state_next = IDLE;
                    end else begin
                        led_reg_next = 7'b0000000;
                        valid_next = 0;
                        state_next = IDLE;
                    end
                end
            end
        endcase
    end

endmodule
