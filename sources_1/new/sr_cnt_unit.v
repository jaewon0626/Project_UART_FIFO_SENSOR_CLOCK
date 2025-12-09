`timescale 1ns / 1ps

module sr04_cnt_unit (
    //input
    input        clk,
    input        reset,
    input        start,
    input        tick_1us,
    input        echo,
    //output
    output       done,
    output       trigger,
    output [8:0] distance // for 400cm
);
    
    parameter [2:0] IDLE = 0, START = 1, WAIT_ECHO = 2, DETECTION = 3, CALCULATION = 4;

    reg [2:0]                   current_state, next_state;
    reg [$clog2(400*58)-1 : 0]  current_tick_count, next_tick_count; //400*58은 1us를 58로 나눠야 1cm이기 때문에 400cm까지 측정할 것이므로
    reg                         current_trigger, next_trigger;
    reg [8:0]                   current_distance_reg, next_distance_reg;
    reg                         current_done, next_done;

    assign trigger  = current_trigger;
    assign distance = current_distance_reg;
    assign done = current_done;    

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            current_state         <= IDLE;
            current_tick_count    <= 0;
            current_trigger       <= 0;
            current_distance_reg  <= 0;
            current_done          <= 0;
        end else begin
            current_state        <= next_state;
            current_tick_count   <= next_tick_count;
            current_trigger      <= next_trigger;
            current_distance_reg <= next_distance_reg;
            current_done         <= next_done;
        end
    end

    always @(*) begin
        next_state        = current_state;
        next_tick_count   = current_tick_count;
        next_trigger      = current_trigger;
        next_distance_reg = current_distance_reg;
        next_done         = current_done;
        case (current_state)
            IDLE:begin
                next_done = 0;
                next_trigger = 0;
                if (start) begin
                    next_trigger        = 1;
                    next_tick_count     = 0;
                    next_distance_reg   = 0;
                    next_state          = START;
                end
            end

            START:begin
                if (tick_1us) begin
                    if (current_tick_count == 10) begin
                        next_trigger    = 0;
                        next_tick_count = 0;
                        next_state      = WAIT_ECHO;
                    end else begin
                        next_tick_count = current_tick_count + 1;
                    end
                end
            end

            WAIT_ECHO: begin
                if (tick_1us) begin
                    if (echo) begin
                        next_state = DETECTION;
                    end
                    
                end
            end

            DETECTION:begin
                if (echo & tick_1us) begin
                    next_tick_count = current_tick_count + 1;
                end else begin
                    if (echo == 0) begin
                        next_state = CALCULATION;
                    end
                end
            end

            CALCULATION:begin 
                next_distance_reg = current_tick_count / 58;
                next_done = 1;
                next_state = IDLE;
            end
        endcase
    end

endmodule
