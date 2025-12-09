`timescale 1ns / 1ps

module trans_ascii_time(
    input            clk,
    input            rst,
    input     [23:0] time_data,  // distance 
    input            time_done,  // 측정 완료 펄스
    output reg [7:0] ascii,
    output reg       go_ascii
);

  localparam 
        IDLE          = 4'd0,
        P_LEAD_SPACE  = 4'd1,
        P_T           = 4'd2,
        P_I           = 4'd3,
        P_M           = 4'd4,
        P_E           = 4'd5,
        P_COL1        = 4'd6,
        P_HOUR10      = 4'd7,
        P_HOUR1       = 4'd8,
        P_COL2        = 4'd9,
        P_MIN10       = 4'd11,
        P_MIN1        = 4'd12,
        P_COL3        = 4'd13,
        P_SEC10       = 4'd14,
        P_SEC1        = 4'd15,
        P_NEWLINE     = 5'd16;

  reg [4:0] c_state, n_state;

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
      IDLE:         if (time_done) n_state = P_LEAD_SPACE;
      P_LEAD_SPACE:                n_state = P_T;
      P_T:                         n_state = P_I;
      P_I:                         n_state = P_M;
      P_M:                         n_state = P_E;
      P_E:                         n_state = P_COL1;
      P_COL1:                      n_state = P_HOUR10;
      P_HOUR10:                    n_state = P_HOUR1;
      P_HOUR1:                     n_state = P_COL2;
      P_COL2:                      n_state = P_MIN10;
      P_MIN10:                     n_state = P_MIN1;
      P_MIN1:                      n_state = P_COL3;
      P_COL3:                      n_state = P_SEC10;
      P_SEC10:                     n_state = P_SEC1;
      P_SEC1:                      n_state = P_NEWLINE;
      P_NEWLINE:                   n_state = IDLE;
      default:                     n_state = IDLE;
    endcase
  end

  // ASCII 코드 결정
  always @(*) begin
    case (c_state)
      P_LEAD_SPACE: ascii = " ";  // 첫 번째 공백
      P_T:          ascii = "T";
      P_I:          ascii = "I";
      P_M:          ascii = "M";
      P_E:          ascii = "E";
      P_COL1:       ascii = ":";
      P_HOUR10:     ascii = time_data[23:20] + 8'd48;
      P_HOUR1:      ascii = time_data[19:16] + 8'd48;
      P_COL2:       ascii = ":";
      P_MIN10:      ascii = time_data[15:12] + 8'd48;
      P_MIN1:       ascii = time_data[11:8] + 8'd48;
      P_COL3:       ascii = ":";
      P_SEC10:      ascii = time_data[7:4] + 8'd48;
      P_SEC1:       ascii = time_data[3:0] + 8'd48;
      P_NEWLINE:    ascii = 8'h0a;
      default:      ascii = 8'h00;
    endcase
  end

endmodule
