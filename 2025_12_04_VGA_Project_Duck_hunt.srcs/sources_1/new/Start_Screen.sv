module Text_Screen_Gen #(
    parameter H_RES = 320,
    parameter V_RES = 240
) (
    input logic clk,
    input logic [9:0] x_pixel,
    input logic [9:0] y_pixel,
    input logic is_stop_mode,  // PAUSE 상태
    input logic is_play_mode,  // PLAY/SHOOT 상태 (타이머 표시용)
    input logic is_game_over,  // GAME OVER 상태
    input logic [5:0] seconds_left,  // 남은 시간 (0~60)
    input logic [15:0] score_value,  // ★ 점수 입력
    input logic [5:0] bullets_remaining,  // ★ 추가 - 남은 총알
    output logic is_text,
    output logic [11:0] text_color
);
    // --- 깜빡임 타이머 ---
    logic [23:0] blink_timer;
    logic        show_blink_text;
    always_ff @(posedge clk) begin
        blink_timer <= blink_timer + 1;
        show_blink_text <= blink_timer[23];
    end

    // =================================================================
    // 1. 폰트 데이터 정의 (8x8)
    // =================================================================
    logic [7:0] font_S[0:7] = '{
        8'h3C,
        8'h66,
        8'h60,
        8'h3C,
        8'h06,
        8'h66,
        8'h3C,
        8'h00
    };
    logic [7:0] font_T[0:7] = '{
        8'hFE,
        8'h18,
        8'h18,
        8'h18,
        8'h18,
        8'h18,
        8'h18,
        8'h00
    };
    logic [7:0] font_A[0:7] = '{
        8'h3C,
        8'h66,
        8'h66,
        8'h7E,
        8'h66,
        8'h66,
        8'h66,
        8'h00
    };
    logic [7:0] font_R[0:7] = '{
        8'hFC,
        8'h66,
        8'h66,
        8'h7C,
        8'h6C,
        8'h66,
        8'h66,
        8'h00
    };
    logic [7:0] font_O[0:7] = '{
        8'h3C,
        8'h66,
        8'h66,
        8'h66,
        8'h66,
        8'h66,
        8'h3C,
        8'h00
    };
    logic [7:0] font_P[0:7] = '{
        8'hFC,
        8'h66,
        8'h66,
        8'h7C,
        8'h60,
        8'h60,
        8'h60,
        8'h00
    };
    logic [7:0] font_E[0:7] = '{
        8'hFE,
        8'h60,
        8'h60,
        8'h7C,
        8'h60,
        8'h60,
        8'hFE,
        8'h00
    };
    logic [7:0] font_B[0:7] = '{
        8'hFC,
        8'h66,
        8'h66,
        8'h7C,
        8'h66,
        8'h66,
        8'hFC,
        8'h00
    };
    logic [7:0] font_U[0:7] = '{
        8'h66,
        8'h66,
        8'h66,
        8'h66,
        8'h66,
        8'h66,
        8'h3C,
        8'h00
    };
    logic [7:0] font_N[0:7] = '{
        8'h66,
        8'h76,
        8'h7E,
        8'h7E,
        8'h6E,
        8'h66,
        8'h66,
        8'h00
    };
    logic [7:0] font_G[0:7] = '{
        8'h3C,
        8'h66,
        8'h60,
        8'h6E,
        8'h66,
        8'h66,
        8'h3C,
        8'h00
    };
    logic [7:0] font_M[0:7] = '{
        8'hC6,
        8'hEE,
        8'hFE,
        8'hD6,
        8'hC6,
        8'hC6,
        8'hC6,
        8'h00
    };
    logic [7:0] font_V[0:7] = '{
        8'h66,
        8'h66,
        8'h66,
        8'h66,
        8'h66,
        8'h3C,
        8'h18,
        8'h00
    };
    logic [7:0] font_C[0:7] = '{
        8'h3C,
        8'h66,
        8'h60,
        8'h60,
        8'h60,
        8'h66,
        8'h3C,
        8'h00
    };
    logic [7:0] font_COL[0:7] = '{
        8'h00,
        8'h18,
        8'h18,
        8'h00,
        8'h18,
        8'h18,
        8'h00,
        8'h00
    };  // : (Colon)
    logic [7:0] font_SPC[0:7] = '{
        8'h00,
        8'h00,
        8'h00,
        8'h00,
        8'h00,
        8'h00,
        8'h00,
        8'h00
    };

    logic [7:0] font_NUM[0:9][0:7];

    initial begin
        font_NUM[0] = '{8'h3C, 8'h66, 8'h66, 8'h66, 8'h66, 8'h66, 8'h3C, 8'h00};
        font_NUM[1] = '{8'h18, 8'h38, 8'h18, 8'h18, 8'h18, 8'h18, 8'h3C, 8'h00};
        font_NUM[2] = '{8'h3C, 8'h66, 8'h06, 8'h0C, 8'h30, 8'h60, 8'hFE, 8'h00};
        font_NUM[3] = '{8'h3C, 8'h66, 8'h06, 8'h1C, 8'h06, 8'h66, 8'h3C, 8'h00};
        font_NUM[4] = '{8'h0C, 8'h1C, 8'h3C, 8'h6C, 8'hFE, 8'h0C, 8'h0C, 8'h00};
        font_NUM[5] = '{8'hFE, 8'h60, 8'h60, 8'h7C, 8'h06, 8'h66, 8'h3C, 8'h00};
        font_NUM[6] = '{8'h3C, 8'h66, 8'h60, 8'h7C, 8'h66, 8'h66, 8'h3C, 8'h00};
        font_NUM[7] = '{8'hFE, 8'h06, 8'h0C, 8'h18, 8'h30, 8'h30, 8'h30, 8'h00};
        font_NUM[8] = '{8'h3C, 8'h66, 8'h66, 8'h3C, 8'h66, 8'h66, 8'h3C, 8'h00};
        font_NUM[9] = '{8'h3C, 8'h66, 8'h66, 8'h3E, 8'h06, 8'h66, 8'h3C, 8'h00};
    end

    // ★ [추가] 총알 아이콘 (8x8)
    logic [7:0] font_BULLET[0:7] = '{
        8'b00001111,
        8'b00111111,
        8'b01111111,
        8'b11111111,
        8'b11111110,
        8'b01111111,
        8'b00111111,
        8'b00001111
    };

    // ★ [추가] 곱하기(x) 기호 폰트
    logic [7:0] font_X[0:7] = '{
        8'b00000000,
        8'b01100110,
        8'b00111100,
        8'b00011000,
        8'b00111100,
        8'b01100110,
        8'b00000000,
        8'b00000000
    };

    // =================================================================
    // 2. 텍스트 그룹별 로직
    // =================================================================

    // (A) START
    localparam SCALE_S = 4;
    localparam START_X = (H_RES - (32 * 5)) / 2;
    localparam START_Y = 80;
    logic pixel_on_s;

    // (B) PRESS BUTTON
    localparam SCALE_P = 2;
    localparam PRESS_X = (H_RES - (16 * 12)) / 2;
    localparam PRESS_Y = START_Y + 32 + 20;
    logic pixel_on_p;

    // (C) STOP
    localparam SCALE_ST = 4;
    localparam STOP_X = (H_RES - (32 * 4)) / 2;
    localparam STOP_Y = 100;
    logic pixel_on_st;

    // (D) TIMER (우상단)
    localparam SCALE_TM = 3;
    localparam TM_W = 8 * SCALE_TM;
    localparam TM_X = H_RES - (TM_W * 2) - 10;
    localparam TM_Y = 10;
    logic pixel_on_tm;
    logic [3:0] digit_tens, digit_ones;
    assign digit_tens = seconds_left / 10;
    assign digit_ones = seconds_left % 10;

    // (E) GAME OVER (중앙)
    localparam SCALE_GO = 4;
    localparam GO_W = 8 * SCALE_GO;
    localparam GO_X = (H_RES - (GO_W * 9)) / 2;
    localparam GO_Y = 60;
    logic pixel_on_go;

    // (F) SCORE : (GAME OVER 아래)
    localparam SCALE_SC = 2;
    localparam SC_W = 8 * SCALE_SC;
    localparam SC_X = (H_RES - (SC_W * 7)) / 2;
    localparam SC_Y = GO_Y + (8 * SCALE_GO) + 20;
    logic pixel_on_sc;

    // (G) SCORE Value (SCORE : 옆) - Game Over 전용
    localparam SCALE_SV = 2;
    localparam SV_W = 8 * SCALE_SV;
    localparam SV_X = SC_X + (SC_W * 7) + 4;
    localparam SV_Y = SC_Y;
    logic pixel_on_sv;

    // (H) GAME Score (좌상단 - PLAY/PAUSE)
    localparam SCALE_PLAY_SC = 2;  // 크기 2배
    localparam PLAY_LABEL_LEN = 7;  // "SCORE :"
    localparam PLAY_VALUE_LEN = 4;  // Max 4 digits
    localparam PLAY_SC_W = 8 * SCALE_PLAY_SC;
    localparam PLAY_SC_X = 10;  // 좌측 여백 10
    localparam PLAY_SC_Y = 10;  // 위쪽 여백 10
    localparam PLAY_VALUE_START_X = PLAY_SC_X + (PLAY_SC_W * PLAY_LABEL_LEN) + 4;  // Label + Gap
    logic pixel_on_play_sc_label;
    logic pixel_on_play_sc_value;

    // 점수 값 분리 (4자리 기준)
    logic [3:0] digit_thous, digit_hunds, digit_tens_sc, digit_ones_sc;

    assign digit_thous   = (score_value / 1000) % 10;
    assign digit_hunds   = (score_value / 100) % 10;
    assign digit_tens_sc = (score_value / 10) % 10;
    assign digit_ones_sc = score_value % 10;

    // (I) 총알 표시 (좌하단 - PLAY/PAUSE)
    localparam SCALE_BULLET = 2;
    localparam BULLET_ICON_LEN = 1;  // 아이콘 1개
    localparam BULLET_LABEL_LEN = 2;  // "x " (곱하기 기호 + 공백)
    localparam BULLET_VALUE_LEN = 2;  // 최대 2자리 (40)
    localparam BULLET_W = 8 * SCALE_BULLET;
    localparam BULLET_X = 10;  // 좌측 여백
    localparam BULLET_Y = V_RES - (8 * SCALE_BULLET) - 10;  // 하단에서 10픽셀 위

    localparam BULLET_LABEL_START_X = BULLET_X + (BULLET_ICON_LEN * BULLET_W) + 4;
    localparam BULLET_VALUE_START_X = BULLET_LABEL_START_X + (BULLET_LABEL_LEN * BULLET_W);

    logic pixel_on_bullet_icon;
    logic pixel_on_bullet_label;
    logic pixel_on_bullet_value;

    // 총알 수 분리 (2자리)
    logic [3:0] bullet_tens, bullet_ones;
    assign bullet_tens = bullets_remaining / 10;
    assign bullet_ones = bullets_remaining % 10;

    // =================================================================
    // 3. 픽셀 렌더링 로직 (통합)
    // =================================================================
    always_comb begin
        pixel_on_s = 0;
        pixel_on_p = 0;
        pixel_on_st = 0;
        pixel_on_tm = 0;
        pixel_on_go = 0;
        pixel_on_sc = 0;
        pixel_on_sv = 0;
        pixel_on_play_sc_label = 0;
        pixel_on_play_sc_value = 0;
        pixel_on_bullet_icon = 0;
        pixel_on_bullet_label = 0;
        pixel_on_bullet_value = 0;

        // -------------------------------------------------------------
        // (A) START & (B) PRESS BUTTON (대기 상태)
        // -------------------------------------------------------------
        if (!is_play_mode && !is_stop_mode && !is_game_over) begin
            // START
            if (x_pixel >= START_X && x_pixel < START_X + 5 * 32 && y_pixel >= START_Y && y_pixel < START_Y + 32) begin
                int char_idx = (x_pixel - START_X) / 32;
                int row = (y_pixel - START_Y) / SCALE_S;
                int col = 7 - ((x_pixel - START_X) % 32) / SCALE_S;
                case (char_idx)
                    0: pixel_on_s = font_S[row][col];
                    1: pixel_on_s = font_T[row][col];
                    2: pixel_on_s = font_A[row][col];
                    3: pixel_on_s = font_R[row][col];
                    4: pixel_on_s = font_T[row][col];
                endcase
            end
            // PRESS BUTTON (깜빡임)
            if (show_blink_text && x_pixel >= PRESS_X && x_pixel < PRESS_X + 12 * 16 && y_pixel >= PRESS_Y && y_pixel < PRESS_Y + 16) begin
                int char_idx = (x_pixel - PRESS_X) / 16;
                int row = (y_pixel - PRESS_Y) / SCALE_P;
                int col = 7 - ((x_pixel - PRESS_X) % 16) / SCALE_P;
                case (char_idx)
                    0:  pixel_on_p = font_P[row][col];
                    1:  pixel_on_p = font_R[row][col];
                    2:  pixel_on_p = font_E[row][col];
                    3:  pixel_on_p = font_S[row][col];
                    4:  pixel_on_p = font_S[row][col];
                    5:  pixel_on_p = font_SPC[row][col];
                    6:  pixel_on_p = font_B[row][col];
                    7:  pixel_on_p = font_U[row][col];
                    8:  pixel_on_p = font_T[row][col];
                    9:  pixel_on_p = font_T[row][col];
                    10: pixel_on_p = font_O[row][col];
                    11: pixel_on_p = font_N[row][col];
                endcase
            end
        end

        // -------------------------------------------------------------
        // (C) STOP (일시 정지)
        // -------------------------------------------------------------
        if (is_stop_mode) begin
            // STOP 라벨
            if (x_pixel >= STOP_X && x_pixel < STOP_X + 4 * 32 && y_pixel >= STOP_Y && y_pixel < STOP_Y + 32) begin
                int char_idx = (x_pixel - STOP_X) / 32;
                int row = (y_pixel - STOP_Y) / SCALE_ST;
                int col = 7 - ((x_pixel - STOP_X) % 32) / SCALE_ST;
                case (char_idx)
                    0: pixel_on_st = font_S[row][col];
                    1: pixel_on_st = font_T[row][col];
                    2: pixel_on_st = font_O[row][col];
                    3: pixel_on_st = font_P[row][col];
                endcase
            end
        end

        // -------------------------------------------------------------
        // (D) 타이머 & (H) GAME Score & (I) 총알 (게임 중 or 일시정지)
        // -------------------------------------------------------------
        if (is_play_mode || is_stop_mode) begin
            // (D) 타이머 (우상단)
            if (x_pixel >= TM_X && x_pixel < TM_X + 2 * TM_W && y_pixel >= TM_Y && y_pixel < TM_Y + (8 * SCALE_TM)) begin
                int char_idx = (x_pixel - TM_X) / TM_W;
                int row = (y_pixel - TM_Y) / SCALE_TM;
                int col = 7 - ((x_pixel - TM_X) % TM_W) / SCALE_TM;
                if (char_idx == 0) pixel_on_tm = font_NUM[digit_tens][row][col];
                else if (char_idx == 1)
                    pixel_on_tm = font_NUM[digit_ones][row][col];
            end

            // (H) GAME Score (좌상단)

            // 1. Label Render: "SCORE :"
            if (x_pixel >= PLAY_SC_X && x_pixel < PLAY_SC_X + PLAY_LABEL_LEN * PLAY_SC_W && y_pixel >= PLAY_SC_Y && y_pixel < PLAY_SC_Y + (8*SCALE_PLAY_SC)) begin
                int char_idx = (x_pixel - PLAY_SC_X) / PLAY_SC_W;
                int row = (y_pixel - PLAY_SC_Y) / SCALE_PLAY_SC;
                int col = 7 - ((x_pixel - PLAY_SC_X) % PLAY_SC_W) / SCALE_PLAY_SC;
                case (char_idx)
                    0: pixel_on_play_sc_label = font_S[row][col];
                    1: pixel_on_play_sc_label = font_C[row][col];
                    2: pixel_on_play_sc_label = font_O[row][col];
                    3: pixel_on_play_sc_label = font_R[row][col];
                    4: pixel_on_play_sc_label = font_E[row][col];
                    5: pixel_on_play_sc_label = font_SPC[row][col];
                    6: pixel_on_play_sc_label = font_COL[row][col];
                endcase
            end

            // 2. Value Render (4 digits)
            if (x_pixel >= PLAY_VALUE_START_X && x_pixel < PLAY_VALUE_START_X + PLAY_VALUE_LEN * PLAY_SC_W && y_pixel >= PLAY_SC_Y && y_pixel < PLAY_SC_Y + (8*SCALE_PLAY_SC)) begin
                int char_idx = (x_pixel - PLAY_VALUE_START_X) / PLAY_SC_W;
                int row = (y_pixel - PLAY_SC_Y) / SCALE_PLAY_SC;
                int col = 7 - ((x_pixel - PLAY_VALUE_START_X) % PLAY_SC_W) / SCALE_PLAY_SC;

                case (char_idx)
                    0: pixel_on_play_sc_value = font_NUM[digit_thous][row][col];
                    1: pixel_on_play_sc_value = font_NUM[digit_hunds][row][col];
                    2:
                    pixel_on_play_sc_value = font_NUM[digit_tens_sc][row][col];
                    3:
                    pixel_on_play_sc_value = font_NUM[digit_ones_sc][row][col];
                    default: pixel_on_play_sc_value = 1'b0;
                endcase

                // 불필요한 선행 0은 출력하지 않습니다.
                if (char_idx == 0 && digit_thous == 0 && score_value < 1000)
                    pixel_on_play_sc_value = 1'b0;
                if (char_idx == 1 && digit_thous == 0 && digit_hunds == 0 && score_value < 100)
                    pixel_on_play_sc_value = 1'b0;
                if (char_idx == 2 && digit_thous == 0 && digit_hunds == 0 && digit_tens_sc == 0 && score_value < 10)
                    pixel_on_play_sc_value = 1'b0;
            end

            // (I) 총알 표시 (좌하단)

            // 1. 총알 아이콘
            if (x_pixel >= BULLET_X && 
                x_pixel < BULLET_X + (BULLET_ICON_LEN * BULLET_W) && 
                y_pixel >= BULLET_Y && 
                y_pixel < BULLET_Y + (8 * SCALE_BULLET)) begin
                int row = (y_pixel - BULLET_Y) / SCALE_BULLET;
                int col = 7 - ((x_pixel - BULLET_X) % BULLET_W) / SCALE_BULLET;
                pixel_on_bullet_icon = font_BULLET[row][col];
            end

            // 2. "x " 라벨
            if (x_pixel >= BULLET_LABEL_START_X && 
                x_pixel < BULLET_LABEL_START_X + (BULLET_LABEL_LEN * BULLET_W) && 
                y_pixel >= BULLET_Y && 
                y_pixel < BULLET_Y + (8 * SCALE_BULLET)) begin
                int char_idx = (x_pixel - BULLET_LABEL_START_X) / BULLET_W;
                int row = (y_pixel - BULLET_Y) / SCALE_BULLET;
                int col = 7 - ((x_pixel - BULLET_LABEL_START_X) % BULLET_W) / SCALE_BULLET;
                case (char_idx)
                    0: pixel_on_bullet_label = font_X[row][col];
                    1: pixel_on_bullet_label = font_SPC[row][col];
                endcase
            end

            // 3. 총알 숫자 (2자리)
            if (x_pixel >= BULLET_VALUE_START_X && 
                x_pixel < BULLET_VALUE_START_X + (BULLET_VALUE_LEN * BULLET_W) && 
                y_pixel >= BULLET_Y && 
                y_pixel < BULLET_Y + (8 * SCALE_BULLET)) begin
                int char_idx = (x_pixel - BULLET_VALUE_START_X) / BULLET_W;
                int row = (y_pixel - BULLET_Y) / SCALE_BULLET;
                int col = 7 - ((x_pixel - BULLET_VALUE_START_X) % BULLET_W) / SCALE_BULLET;

                case (char_idx)
                    0: pixel_on_bullet_value = font_NUM[bullet_tens][row][col];
                    1: pixel_on_bullet_value = font_NUM[bullet_ones][row][col];
                    default: pixel_on_bullet_value = 1'b0;
                endcase

                // 10 미만일 때 선행 0 숨김
                if (char_idx == 0 && bullet_tens == 0)
                    pixel_on_bullet_value = 1'b0;
            end

        end  // end of is_play_mode || is_stop_mode

        // -------------------------------------------------------------
        // (E) GAME OVER & (F) SCORE & (G) SCORE VALUE (게임 오버 상태)
        // -------------------------------------------------------------
        if (is_game_over) begin
            // (E) GAME OVER
            if (x_pixel >= GO_X && x_pixel < GO_X + 9 * GO_W && y_pixel >= GO_Y && y_pixel < GO_Y + (8 * SCALE_GO)) begin
                int char_idx = (x_pixel - GO_X) / GO_W;
                int row = (y_pixel - GO_Y) / SCALE_GO;
                int col = 7 - ((x_pixel - GO_X) % GO_W) / SCALE_GO;
                case (char_idx)
                    0: pixel_on_go = font_G[row][col];
                    1: pixel_on_go = font_A[row][col];
                    2: pixel_on_go = font_M[row][col];
                    3: pixel_on_go = font_E[row][col];
                    4: pixel_on_go = font_SPC[row][col];
                    5: pixel_on_go = font_O[row][col];
                    6: pixel_on_go = font_V[row][col];
                    7: pixel_on_go = font_E[row][col];
                    8: pixel_on_go = font_R[row][col];
                endcase
            end

            // (F) SCORE :
            if (x_pixel >= SC_X && x_pixel < SC_X + 7 * SC_W && y_pixel >= SC_Y && y_pixel < SC_Y + (8 * SCALE_SC)) begin
                int char_idx = (x_pixel - SC_X) / SC_W;
                int row = (y_pixel - SC_Y) / SCALE_SC;
                int col = 7 - ((x_pixel - SC_X) % SC_W) / SCALE_SC;
                case (char_idx)
                    0: pixel_on_sc = font_S[row][col];
                    1: pixel_on_sc = font_C[row][col];
                    2: pixel_on_sc = font_O[row][col];
                    3: pixel_on_sc = font_R[row][col];
                    4: pixel_on_sc = font_E[row][col];
                    5: pixel_on_sc = font_SPC[row][col];
                    6: pixel_on_sc = font_COL[row][col];
                endcase
            end

            // (G) SCORE VALUE (4자리 출력)
            if (x_pixel >= SV_X && x_pixel < SV_X + 4 * SV_W && y_pixel >= SV_Y && y_pixel < SV_Y + (8 * SCALE_SV)) begin
                int char_idx = (x_pixel - SV_X) / SV_W;
                int row = (y_pixel - SV_Y) / SCALE_SV;
                int col = 7 - ((x_pixel - SV_X) % SV_W) / SCALE_SV;

                case (char_idx)
                    0: pixel_on_sv = font_NUM[digit_thous][row][col];
                    1: pixel_on_sv = font_NUM[digit_hunds][row][col];
                    2: pixel_on_sv = font_NUM[digit_tens_sc][row][col];
                    3: pixel_on_sv = font_NUM[digit_ones_sc][row][col];
                    default: pixel_on_sv = 1'b0;
                endcase

                // 불필요한 선행 0은 출력하지 않습니다.
                if (char_idx == 0 && digit_thous == 0 && score_value < 1000)
                    pixel_on_sv = 1'b0;
                if (char_idx == 1 && digit_thous == 0 && digit_hunds == 0 && score_value < 100)
                    pixel_on_sv = 1'b0;
                if (char_idx == 2 && digit_thous == 0 && digit_hunds == 0 && digit_tens_sc == 0 && score_value < 10)
                    pixel_on_sv = 1'b0;
            end
        end
    end

    // =================================================================
    // 4. 최종 출력 조합
    // =================================================================
    always_comb begin
        is_text = 0;
        text_color = 12'h000;

        if (pixel_on_s) begin
            is_text = 1;
            text_color = 12'hFFF;  // START: 흰색
        end else if (pixel_on_p) begin
            is_text = 1;
            text_color = 12'hFF0;  // PRESS BUTTON: 노란색
        end else if (pixel_on_st) begin
            is_text = 1;
            text_color = 12'hF00;  // STOP: 빨간색
        end else if (pixel_on_tm) begin
            is_text = 1;
            text_color = 12'hFF0;  // TIMER: 노란색
        end else if (pixel_on_go) begin
            is_text = 1;
            text_color = 12'hF00;  // GAME OVER: 빨간색
        end else if (pixel_on_sc) begin
            is_text = 1;
            text_color = 12'hFFF;  // SCORE: 흰색 (Game Over Label)
        end else if (pixel_on_sv) begin
            is_text = 1;
            text_color = 12'hFF0;  // 점수 값: 노란색 (Game Over Value)
        end else if (pixel_on_play_sc_label) begin  // ★ 게임 중 점수 라벨
            is_text = 1;
            text_color = 12'hFFF;  // 흰색
        end else if (pixel_on_play_sc_value) begin  // ★ 게임 중 점수 값
            is_text = 1;
            text_color = 12'hFF0;  // 노란색
        end else if (pixel_on_bullet_icon) begin  // ★ 총알 아이콘
            is_text = 1;
            text_color = 12'hF80;  // 주황색
        end else if (pixel_on_bullet_label) begin  // ★ 총알 라벨 "x "
            is_text = 1;
            text_color = 12'hFFF;  // 흰색
        end else if (pixel_on_bullet_value) begin  // ★ 총알 숫자 (추가!)
            is_text = 1;
            if (bullets_remaining < 10) text_color = 12'hFF0;  // 빨간색
            else text_color = 12'hFF0;  // 노란색
        end
    end

endmodule
