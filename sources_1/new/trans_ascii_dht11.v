`timescale 1ns / 1ps

module trans_ascii_dht11 (
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] rh_data,    // 상대습도 값
    input  wire [7:0] t_data,     // 온도 값
    input  wire       dht11_done, // 측정 완료 펄스
    output reg  [7:0] ascii,
    output reg        go_ascii
);

    // 상태 정의 (0…14)
    localparam 
        IDLE          = 4'd0,
        P_LEAD_SPACE  = 4'd1,   // 선두 공백
        P_R           = 4'd2,
        P_H           = 4'd3,
        P_COL1        = 4'd4,
        P_RH10        = 4'd5,
        P_RH1         = 4'd6,
        P_PCNT        = 4'd7,
        P_COMMA       = 4'd8,
        P_T           = 4'd9,
        P_COL2        = 4'd10,
        P_T10         = 4'd11,
        P_T1          = 4'd12,
        P_C           = 4'd13,
        P_NEWLINE     = 4'd14;

    reg [3:0] c_state, n_state;

    // 각 자리 숫자 추출
    wire [3:0] rh10 = rh_data / 10;
    wire [3:0] rh1  = rh_data % 10;
    wire [3:0] t10  = t_data  / 10;
    wire [3:0] t1   = t_data  % 10;

    // 상태 전이 (동기)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            c_state  <= IDLE;
            go_ascii <= 1'b0;
        end else begin
            c_state  <= n_state;
            go_ascii <= (n_state != IDLE);
        end
    end

    // 다음 상태 결정
    always @(*) begin
        n_state = c_state;
        case (c_state)
            IDLE:        if (dht11_done)      n_state = P_LEAD_SPACE;
            P_LEAD_SPACE:                     n_state = P_R;
            P_R:                              n_state = P_H;
            P_H:                              n_state = P_COL1;
            P_COL1:                           n_state = P_RH10;
            P_RH10:                           n_state = P_RH1;
            P_RH1:                            n_state = P_PCNT;
            P_PCNT:                           n_state = P_COMMA;
            P_COMMA:                          n_state = P_T;
            P_T:                              n_state = P_COL2;
            P_COL2:                           n_state = P_T10;
            P_T10:                            n_state = P_T1;
            P_T1:                             n_state = P_C;
            P_C:                              n_state = P_NEWLINE;
            P_NEWLINE:                        n_state = IDLE;
            default:                          n_state = IDLE;
        endcase
    end

    // ASCII 코드 결정
    always @(*) begin
        case (c_state)
            P_LEAD_SPACE: ascii = " ";        // 첫 번째 공백
            P_R:          ascii = "R";
            P_H:          ascii = "H";
            P_COL1:       ascii = ":";
            P_RH10:       ascii = rh10 + 8'd48; // ascii 0
            P_RH1:        ascii = rh1  + 8'd48; // ascii 0
            P_PCNT:       ascii = "%";
            P_COMMA:      ascii = ",";
            P_T:          ascii = "T";
            P_COL2:       ascii = ":";
            P_T10:        ascii = t10 + 8'd48; // ascii 0
            P_T1:         ascii = t1  + 8'd48; // ascii 0
            P_C:          ascii = "C";
            P_NEWLINE:    ascii = 8'h0a;      // 줄바꿈
            default:      ascii = 8'h00;
        endcase
    end

endmodule