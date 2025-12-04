`timescale 1ns / 1ps
module DuckHunt_System (
    input  logic       clk,
    input  logic       reset,
    input  logic       sw_cam,
    input  logic       btn_shoot,         // btnR
    input  logic       btn_start,         // btnU
    input  logic       btn_stop,          // btnD
    input  logic       btn_exit,          // btnL
    input  logic       btn_pistol,        // 외부 입력 버튼
    output logic       xclk,
    input  logic       pclk,
    input  logic       href,
    input  logic       vsync,
    input  logic [7:0] data,
    output logic       h_sync,
    output logic       v_sync,
    output logic [3:0] r_port,
    output logic [3:0] g_port,
    output logic [3:0] b_port,
    output logic       SCL,
    output logic       SDA,
    output logic       red_detected_led,
    output logic [7:0] score_count
);
    // 내부 신호
    logic sys_clk, DE;
    logic [9:0] x_pixel, y_pixel;

    logic [16:0] cam_rAddr, cam_wAddr, bg_addr;
    logic [15:0] cam_rData, cam_wData, bg_data;
    logic cam_we;

    logic btn_shoot_stable, btn_shoot_pulse, btn_start_pulse;
    logic btn_stop_pulse, btn_pistol_pulse, btn_exit_pulse;

    logic red_detected;
    logic [15:0] red_pixel_count, score;
    logic prev_red_detected, shot_in_progress;

    // Duck1/Bomb 신호
    logic [12:0] duck1_addr;
    logic [15:0] duck1_data, bomb_data, duck1_pixel;
    logic is_duck1;
    logic duck1_exploding;
    logic [9:0] duck1_x, duck1_y;
    logic duck1_active;

    // Duck2 신호
    logic [12:0] duck2_addr;
    logic [15:0] duck2_data, duck2_pixel;
    logic is_duck2;
    logic duck2_exploding;
    logic [9:0] duck2_x, duck2_y;
    logic duck2_active;

    // 텍스트/게임 시간
    logic is_text;
    logic [11:0] text_color;
    logic [5:0] game_time_sec;
    logic [$clog2(100_000_000)-1:0] one_sec_cnt;

    localparam GAME_DURATION = 60;

    // ★ [추가] 총알 시스템
    logic [5:0] bullets_remaining;  // 0~63 (50발 저장 가능)
    localparam MAX_BULLETS = 50;

    // 피격 신호 (오리별로 분리)
    logic duck1_hit, duck2_hit;
    logic [7:0] hit1_pulse_cnt, hit2_pulse_cnt;
    // 게임 상태
    typedef enum logic [2:0] {
        S_WAIT,
        S_PLAY,
        S_PAUSE,
        S_SHOOT,
        S_GAMEOVER
    } game_state_t;
    game_state_t game_state;

    logic game_pause, duck_reset;

    assign xclk = sys_clk;
    assign red_detected_led = red_detected;
    assign score_count = score[7:0];
    assign game_pause = (game_state == S_PAUSE || game_state == S_SHOOT || game_state == S_GAMEOVER);
    assign duck_reset = reset || (game_state == S_WAIT) || (game_state == S_GAMEOVER);

    button_debouncer U_BTN_SHOOT (
        .clk(clk),
        .reset(reset),
        .btn_in(btn_shoot),
        .btn_stable(btn_shoot_stable),
        .btn_pulse(btn_shoot_pulse)
    );
    button_debouncer U_BTN_START (
        .clk(clk),
        .reset(reset),
        .btn_in(btn_start),
        .btn_stable(),
        .btn_pulse(btn_start_pulse)
    );
    button_debouncer U_BTN_STOP (
        .clk(clk),
        .reset(reset),
        .btn_in(btn_stop),
        .btn_stable(),
        .btn_pulse(btn_stop_pulse)
    );
    button_debouncer U_BTN_EXIT (
        .clk(clk),
        .reset(reset),
        .btn_in(btn_exit),
        .btn_stable(),
        .btn_pulse(btn_exit_pulse)
    );
    button_debouncer U_BTN_PISTOL (
        .clk(clk),
        .reset(reset),
        .btn_in(btn_pistol),
        .btn_stable(),
        .btn_pulse(btn_pistol_pulse)
    );
    typedef enum logic [1:0] {
        S_IDLE,
        S_SHOOTING,
        S_WAIT_RESULT
    } shoot_state_t;
    shoot_state_t shoot_state;

    logic [26:0] timer;

    localparam SHOOT_DURATION = 27'd5_000_000;  // 50ms
    localparam TIMER_1SEC = 100_000_000;

    // 크로스헤어 중심 좌표 (카메라 영역 중심)
    localparam int CAM_X0 = 580;
    localparam int CAM_Y0 = 420;
    localparam int CAM_W = 60;
    localparam int CAM_H = 60;
    localparam int CX = CAM_X0 + CAM_W / 2;  // 610
    localparam int CY = CAM_Y0 + CAM_H / 2;  // 450

    // 각 오리의 중심 좌표 계산
    logic [9:0] duck1_center_x, duck1_center_y;
    logic [9:0] duck2_center_x, duck2_center_y;

    // VGA 좌표를 실제 픽셀 좌표로 변환 (x2 스케일)
    assign duck1_center_x = (duck1_x * 2) + 25;
    assign duck1_center_y = (duck1_y * 2) + 22;
    assign duck2_center_x = (duck2_x * 2) + 25;
    assign duck2_center_y = (duck2_y * 2) + 22;

    // 크로스헤어와의 거리 계산 (제곱 거리)
    logic [20:0] dist1_sq, dist2_sq;
    logic [10:0] dx1, dy1, dx2, dy2;
    
    always_comb begin
        dx1 = (duck1_center_x > CX) ? (duck1_center_x - CX) : (CX - duck1_center_x);
        dy1 = (duck1_center_y > CY) ? (duck1_center_y - CY) : (CY - duck1_center_y);
        dx2 = (duck2_center_x > CX) ? (duck2_center_x - CX) : (CX - duck2_center_x);
        dy2 = (duck2_center_y > CY) ? (duck2_center_y - CY) : (CY - duck2_center_y);
        dist1_sq = (dx1 * dx1) + (dy1 * dy1);
        dist2_sq = (dx2 * dx2) + (dy2 * dy2);
    end
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            game_state <= S_WAIT;
            score <= 0;
            shoot_state <= S_IDLE;
            shot_in_progress <= 0;
            timer <= 0;
            one_sec_cnt <= 0;
            game_time_sec <= GAME_DURATION;
            prev_red_detected <= 0;
            hit1_pulse_cnt <= 0;
            hit2_pulse_cnt <= 0;
            duck1_hit <= 0;
            duck2_hit <= 0;
            bullets_remaining <= MAX_BULLETS;  // ★ 총알 초기화
        end else begin
            // Exit 버튼 처리 (최우선 순위)
            if (btn_exit_pulse) begin
                game_state <= S_WAIT;
                score <= 0;
                shoot_state <= S_IDLE;
                shot_in_progress <= 0;
                timer <= 0;
                one_sec_cnt <= 0;
                game_time_sec <= GAME_DURATION;
                prev_red_detected <= 0;
                hit1_pulse_cnt <= 0;
                hit2_pulse_cnt <= 0;
                duck1_hit <= 0;
                duck2_hit <= 0;
                bullets_remaining <= MAX_BULLETS;  // ★ 총알 초기화
            end else begin
                // Hit 펄스 처리
                if (hit1_pulse_cnt > 0) begin
                    duck1_hit <= 1;
                    hit1_pulse_cnt <= hit1_pulse_cnt - 1;
                end else duck1_hit <= 0;
                if (hit2_pulse_cnt > 0) begin
                    duck2_hit <= 1;
                    hit2_pulse_cnt <= hit2_pulse_cnt - 1;
                end else duck2_hit <= 0;
                if (shoot_state == S_IDLE && game_state == S_PLAY) begin
                    if (one_sec_cnt < TIMER_1SEC)
                        one_sec_cnt <= one_sec_cnt + 1;
                    else begin
                        one_sec_cnt <= 0;
                        if (game_time_sec > 0)
                            game_time_sec <= game_time_sec - 1;
                        else game_state <= S_GAMEOVER;
                    end
                end
                case (game_state)
                    S_WAIT: begin
                        if (btn_start_pulse) begin
                            game_state <= S_PLAY;
                            bullets_remaining <= MAX_BULLETS;  // ★ 게임 시작 시 총알 리셋
                        end
                    end
                    S_PLAY: begin
                        if (btn_stop_pulse) begin
                            game_state <= S_PAUSE;
                        end 
                        // ★ [수정] 총알이 있을 때만 사격 가능
                        else if ((btn_shoot_pulse | btn_pistol_pulse) && bullets_remaining > 0) begin
                            game_state <= S_SHOOT;
                            shoot_state <= S_SHOOTING;
                            shot_in_progress <= 1;
                            timer <= 0;
                            prev_red_detected <= 0;
                            bullets_remaining <= bullets_remaining - 1;  // ★ 총알 소모
                        end  // ★ [추가] 총알이 0이 되면 게임 오버
                        else if (bullets_remaining == 0) begin
                            game_state <= S_GAMEOVER;
                        end
                    end
                    S_PAUSE: if (btn_start_pulse) game_state <= S_PLAY;
                    S_SHOOT: begin
                        timer <= timer + 1;
                        if (timer >= SHOOT_DURATION) begin
                            game_state <= S_PLAY;
                            shoot_state <= S_WAIT_RESULT;
                            shot_in_progress <= 0;
                            timer <= 0;
                        end
                    end
                    S_GAMEOVER: begin
                        if (btn_start_pulse) begin
                            game_state <= S_WAIT;
                            score <= 0;
                            game_time_sec <= GAME_DURATION;
                            one_sec_cnt <= 0;
                            bullets_remaining <= MAX_BULLETS;  // ★ 총알 리셋
                        end
                    end
                endcase
                // 적중 판정 로직
                if (shoot_state == S_WAIT_RESULT) begin
                    if (red_detected && !prev_red_detected) begin
                        if (duck1_active && !duck1_exploding && duck2_active && !duck2_exploding) begin
                            if (dist1_sq < dist2_sq) begin
                                score <= score + 1;
                                hit1_pulse_cnt <= 8'd100;
                            end else begin
                                score <= score + 1;
                                hit2_pulse_cnt <= 8'd100;
                            end
                        end else if (duck1_active && !duck1_exploding) begin
                            score <= score + 1;
                            hit1_pulse_cnt <= 8'd100;
                        end else if (duck2_active && !duck2_exploding) begin
                            score <= score + 1;
                            hit2_pulse_cnt <= 8'd100;
                        end
                    end
                    prev_red_detected <= red_detected;
                    timer <= timer + 1;
                    if (timer >= 24'd1_000_000) begin
                        shoot_state <= S_IDLE;
                        timer <= 0;
                    end
                end
            end
        end
    end
    Top_SCCB U_SCCB (
        .clk  (clk),
        .reset(reset),
        .SCL  (SCL),
        .SDA  (SDA)
    );
    pclk_gen U_PXL_CLK_GEN (
        .clk  (clk),
        .reset(reset),
        .pclk (sys_clk)
    );
    VGA_Syncher U_VGA_Syncher (
        .clk(sys_clk),
        .reset(reset),
        .h_sync(h_sync),
        .v_sync(v_sync),
        .DE(DE),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel)
    );
    ImgROM U_ImgROM (
        .clk (sys_clk),
        .addr(bg_addr),
        .data(bg_data)
    );
    frame_buffer U_Frame_Buffer (
        .wclk(pclk),
        .we(cam_we),
        .wAddr(cam_wAddr),
        .wData(cam_wData),
        .rclk(sys_clk),
        .oe(1'b1),
        .rAddr(cam_rAddr),
        .rData(cam_rData)
    );
    OV7670_Mem_Controller U_OV7670_Mem_Controller (
        .pclk(pclk),
        .reset(reset),
        .href(href),
        .vsync(vsync),
        .data(data),
        .we(cam_we),
        .wAddr(cam_wAddr),
        .wdata(cam_wData)
    );
    Red_Detector_Threshold U_Red_Detector (
        .clk(pclk),
        .reset(reset),
        .detect_enable(shot_in_progress),
        .href(href),
        .vsync(vsync),
        .pixel_data(cam_wData),
        .red_detected(red_detected),
        .red_pixel_count(red_pixel_count)
    );
    // ROM 인스턴스 (Duck1용)
    Duck_Rom_Code #(
        .DATA_WIDTH(16),
        .ADDR_WIDTH(13),
        .MEM_DEPTH (8192)
    ) U_Duck_ROM (
        .clk (sys_clk),
        .addr(duck1_addr),
        .data(duck1_data)
    );
    // ROM 인스턴스 (Duck2용)
    Duck_Rom_Code #(
        .DATA_WIDTH(16),
        .ADDR_WIDTH(13),
        .MEM_DEPTH (8192)
    ) U_Duck2_ROM (
        .clk (sys_clk),
        .addr(duck2_addr),
        .data(duck2_data)
    );
    // Bomb ROM (Duck1용)
    Bomb_Rom_Code #(
        .DATA_WIDTH(16),
        .ADDR_WIDTH(13),
        .MEM_DEPTH (2250)
    ) U_Bomb1_ROM (
        .clk (sys_clk),
        .addr(duck1_addr),
        .data(bomb_data)
    );
    // Bomb ROM (Duck2용)
    logic [15:0] bomb2_data;
    Bomb_Rom_Code #(
        .DATA_WIDTH(16),
        .ADDR_WIDTH(13),
        .MEM_DEPTH (2250)
    ) U_Bomb2_ROM (
        .clk (sys_clk),
        .addr(duck2_addr),
        .data(bomb2_data)
    );
    // 오리 컨트롤러 1
    Duck_Controller #(
        .H_RES(320),
        .V_RES(240),
        .DUCK_TYPE(0),
        .RANDOM_SEED(8'hA5)
    ) U_Duck_1 (
        .clk(sys_clk),
        .reset(duck_reset),
        .pause(game_pause),
        .hit(duck1_hit),
        .hurry_up(game_time_sec < 30),
        .x_pixel({1'b0, x_pixel[9:1]}),
        .y_pixel({1'b0, y_pixel[9:1]}),
        .duck_rom_data(duck1_data),
        .bomb_rom_data(bomb_data),
        .rom_addr(duck1_addr),
        .is_duck(is_duck1),
        .duck_pixel_out(duck1_pixel),
        .exploding(duck1_exploding),
        .duck_x_out(duck1_x),
        .duck_y_out(duck1_y),
        .duck_active(duck1_active)
    );
    // 오리 컨트롤러 2
    Duck_Controller #(
        .H_RES(320),
        .V_RES(240),
        .DUCK_TYPE(1),
        .RANDOM_SEED(8'h3C)
    ) U_Duck_2 (
        .clk(sys_clk),
        .reset(duck_reset),
        .pause(game_pause),
        .hit(duck2_hit),
        .hurry_up(game_time_sec < 30),
        .x_pixel({1'b0, x_pixel[9:1]}),
        .y_pixel({1'b0, y_pixel[9:1]}),
        .duck_rom_data(duck2_data),
        .bomb_rom_data(bomb2_data),
        .rom_addr(duck2_addr),
        .is_duck(is_duck2),
        .duck_pixel_out(duck2_pixel),
        .exploding(duck2_exploding),
        .duck_x_out(duck2_x),
        .duck_y_out(duck2_y),
        .duck_active(duck2_active)
    );
    // ★ [수정] Text_Screen_Gen에 총알 정보 추가
    Text_Screen_Gen U_Text_Gen (
        .clk(sys_clk),
        .x_pixel({1'b0, x_pixel[9:1]}),
        .y_pixel({1'b0, y_pixel[9:1]}),
        .is_stop_mode(game_state == S_PAUSE),
        .is_play_mode(game_state == S_PLAY || game_state == S_SHOOT),
        .is_game_over(game_state == S_GAMEOVER),
        .seconds_left(game_time_sec),
        .score_value(score),
        .bullets_remaining(bullets_remaining),  // ★ 추가
        .is_text(is_text),
        .text_color(text_color)
    );
    // 최종 디스플레이
    Game_Display_Controller U_Game_Display (
        .clk(sys_clk),
        .reset(reset),
        .DE(DE),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .bg_data(bg_data),
        .bg_addr(bg_addr),
        .cam_data(cam_rData),
        .cam_addr(cam_rAddr),
        .score(score),
        .shooting(shot_in_progress),
        .show_cam(sw_cam),
        .invert_bg( ((game_time_sec < 30) && (game_state == S_PLAY || game_state == S_SHOOT || game_state == S_GAMEOVER)) ),
        .is_duck1(is_duck1),
        .duck1_pixel(duck1_pixel),
        .is_duck2(is_duck2),
        .duck2_pixel(duck2_pixel),
        .is_text(is_text),
        .text_color(text_color),
        .r_port(r_port),
        .g_port(g_port),
        .b_port(b_port)
    );
endmodule
