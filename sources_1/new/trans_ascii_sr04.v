`timescale 1ns / 1ps

module trans_ascii_sr04 (
    input            clk,
    input            rst,
    input      [8:0] dist_data,  // distance 
    input            sr04_done,  // 측정 완료 펄스
    output reg [7:0] ascii,
    output reg       go_ascii
);

  localparam 
        IDLE          = 4'd0,
        P_LEAD_SPACE  = 4'd1,
        P_D           = 4'd2,
        P_I           = 4'd3,
        P_S           = 4'd4,
        P_T           = 4'd5,
        P_COL1        = 4'd6,
        P_DIST1       = 4'd7,
        P_DIST2       = 4'd8,
        P_DIST3       = 4'd9,
        P_C           = 4'd11,
        P_M           = 4'd12,
        P_NEWLINE     = 4'd13;

  reg [3:0] c_state, n_state;

  // 각 자리 숫자 추출
  wire [3:0] dist1 = dist_data / 100 % 10;
  wire [3:0] dist10 = dist_data / 10 % 10;
  wire [3:0] dist100 = dist_data % 10;

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
      IDLE:         if (sr04_done) n_state = P_LEAD_SPACE;
      P_LEAD_SPACE: n_state = P_D;
      P_D:          n_state = P_I;
      P_I:          n_state = P_S;
      P_S:          n_state = P_T;
      P_T:          n_state = P_COL1;
      P_COL1:       n_state = P_DIST1;
      P_DIST1:      n_state = P_DIST2;
      P_DIST2:      n_state = P_DIST3;
      P_DIST3:      n_state = P_C;
      P_C:          n_state = P_M;
      P_M:          n_state = P_NEWLINE;
      P_NEWLINE:    n_state = IDLE;
      default:      n_state = IDLE;
    endcase
  end

  // ASCII 코드 결정
  always @(*) begin
    case (c_state)
      P_LEAD_SPACE: ascii = " ";  // 첫 번째 공백
      P_D:          ascii = "D";
      P_I:          ascii = "I";
      P_S:          ascii = "S";
      P_T:          ascii = "T";
      P_COL1:       ascii = ":";
      P_DIST1:      ascii = dist1 + 8'd48;
      P_DIST2:      ascii = dist10 + 8'd48;
      P_DIST3:      ascii = dist100 + 8'd48;
      P_C:          ascii = "C";
      P_M:          ascii = "M";
      P_NEWLINE:    ascii = 8'h0a;  // 줄바꿈
      default:      ascii = 8'h00;
    endcase
  end

endmodule
