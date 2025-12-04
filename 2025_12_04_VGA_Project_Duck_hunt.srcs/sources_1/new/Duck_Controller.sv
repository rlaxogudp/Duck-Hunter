`timescale 1ns / 1ps

// 1. 오리 ROM
module Duck_Rom_Code #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 13,
    parameter MEM_DEPTH  = 8192,
    parameter MEM_FILE   = "duck_move.mem"
) (
    input logic clk,
    input logic [ADDR_WIDTH-1:0] addr,
    output logic [DATA_WIDTH-1:0] data
);
    (* rom_style = "block" *) logic [DATA_WIDTH-1:0] rom[0:MEM_DEPTH-1];
    initial $readmemh(MEM_FILE, rom);
    always_ff @(posedge clk) data <= rom[addr];
endmodule

// 2. 폭발 ROM
module Bomb_Rom_Code #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 13,
    parameter MEM_DEPTH  = 2250,
    parameter MEM_FILE   = "bomb.mem"
) (
    input logic clk,
    input logic [ADDR_WIDTH-1:0] addr,
    output logic [DATA_WIDTH-1:0] data
);
    (* rom_style = "block" *) logic [DATA_WIDTH-1:0] rom[0:MEM_DEPTH-1];
    initial $readmemh(MEM_FILE, rom);
    always_ff @(posedge clk) data <= rom[addr];
endmodule

// 3. 오리 컨트롤러
module Duck_Controller #(
    parameter H_RES       = 320,
    parameter V_RES       = 240,
    parameter DUCK_W      = 50,
    parameter DUCK_H      = 45,
    parameter DUCK_TYPE   = 0,
    parameter RANDOM_SEED = 8'hA5
) (
    input logic clk,
    input logic reset,
    input logic pause,
    input logic hit,

    input logic hurry_up,

    input logic [9:0] x_pixel,
    input logic [9:0] y_pixel,

    input logic [15:0] duck_rom_data,
    input logic [15:0] bomb_rom_data,

    output logic [12:0] rom_addr,
    output logic        is_duck,
    output logic [15:0] duck_pixel_out,
    output logic        exploding,

    // ★ [추가] 오리 위치 출력을 위한 포트
    output logic [9:0] duck_x_out,
    output logic [9:0] duck_y_out,

    // ★ [추가] 오리 활성화 상태 출력
    output logic duck_active
);
    typedef enum logic [1:0] {
        S_IDLE,
        S_FLY,
        S_BOOM
    } duck_state_t;
    duck_state_t state;

    logic [26:0] wait_timer;
    logic [26:0] wait_limit;
    logic [23:0] boom_timer;
    localparam BOOM_DURATION = 3_000_000;

    logic [9:0] duck_x, duck_y;
    logic [18:0] speed_cnt;
    logic [18:0] current_speed_limit;
    logic [23:0] anim_cnt;
    logic        frame_toggle;
    localparam ANIM_SPEED = 5_000_000;
    localparam FRAME_OFFSET = 50 * 45;
    logic       is_facing_left;

    logic [7:0] random_reg;
    logic [1:0] spawn_type;
    logic [9:0] rand_y_horz;

    assign current_speed_limit = (spawn_type == 0) ?
                                 (hurry_up ? 19'd110_000 : 19'd150_000) : 
                                 (hurry_up ? 19'd150_000 : 19'd250_000);
    assign exploding = (state == S_BOOM);

    // ★ [추가] 오리 위치 출력
    assign duck_x_out = duck_x;
    assign duck_y_out = duck_y;

    // ★ [추가] 오리 활성화 상태 (날고 있거나 폭발 중일 때만 true)
    assign duck_active = (state == S_FLY || state == S_BOOM);

    always_ff @(posedge clk or posedge reset) begin
        if (reset) random_reg <= RANDOM_SEED;
        else
            random_reg <= {
                random_reg[6:0],
                random_reg[7] ^ random_reg[5] ^ random_reg[4] ^ random_reg[3]
            };
    end

    assign rand_y_horz = (random_reg % (V_RES - DUCK_H - 20)) + 10;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= S_IDLE;
            wait_timer <= 0;
            boom_timer <= 0;
            duck_x <= 0;
            duck_y <= 0;
            speed_cnt <= 0;
            anim_cnt <= 0;
            frame_toggle <= 0;
            is_facing_left <= 0;
            spawn_type <= 2'b11;
            wait_limit <= 25_000_000;
        end else begin
            case (state)
                S_IDLE: begin
                    if (!pause) begin  // ★ pause 체크 추가
                        if (wait_timer < wait_limit)
                            wait_timer <= wait_timer + 1;
                        else begin
                            wait_timer <= 0;
                            state <= S_FLY;
                            wait_limit <= 25_000_000 + {random_reg, 18'd0};

                            case (random_reg % 4)
                                0: begin
                                    spawn_type <= 0;
                                    duck_x <= 0;
                                    duck_y <= rand_y_horz;
                                    is_facing_left <= 0;
                                end
                                1: begin
                                    spawn_type <= 1;
                                    duck_x <= (H_RES - DUCK_W) - 10;
                                    duck_y <= (V_RES - DUCK_H) - 10;
                                    is_facing_left <= 1;
                                end
                                2: begin
                                    spawn_type <= 2;
                                    duck_x <= 10;
                                    duck_y <= (V_RES - DUCK_H) - 10;
                                    is_facing_left <= 0;
                                end
                                3: begin
                                    spawn_type <= 0;
                                    duck_x <= (H_RES - DUCK_W);
                                    duck_y <= rand_y_horz;
                                    is_facing_left <= 1;
                                end
                                default: begin
                                    spawn_type <= 0;
                                    duck_x <= 0;
                                    duck_y <= rand_y_horz;
                                    is_facing_left <= 0;
                                end
                            endcase
                        end
                    end  // ★ !pause 끝
                end

                S_FLY: begin
                    if (hit) begin
                        state <= S_BOOM;
                        boom_timer <= 0;
                    end else if (!pause) begin  // ★ pause 체크 추가
                        if (speed_cnt < current_speed_limit)
                            speed_cnt <= speed_cnt + 1;
                        else begin
                            speed_cnt <= 0;
                            case (spawn_type)
                                0: begin
                                    if (!is_facing_left) begin
                                        if (duck_x < H_RES - DUCK_W)
                                            duck_x <= duck_x + 1;
                                        else is_facing_left <= 1;
                                    end else begin
                                        if (duck_x > 0) duck_x <= duck_x - 1;
                                        else state <= S_IDLE;
                                    end
                                end
                                1: begin
                                    if (duck_x > 0 && duck_y > 0) begin
                                        duck_x <= duck_x - 1;
                                        duck_y <= duck_y - 1;
                                    end else state <= S_IDLE;
                                end
                                2: begin
                                    if (duck_x < (H_RES - DUCK_W) && duck_y > 0) begin
                                        duck_x <= duck_x + 1;
                                        duck_y <= duck_y - 1;
                                    end else state <= S_IDLE;
                                end
                            endcase
                        end

                        if (anim_cnt < ANIM_SPEED) anim_cnt <= anim_cnt + 1;
                        else begin
                            anim_cnt <= 0;
                            frame_toggle <= ~frame_toggle;
                        end
                    end  // ★ !pause 끝
                end

                S_BOOM: begin
                    if (!pause) begin  // ★ pause 체크 추가
                        if (boom_timer < BOOM_DURATION)
                            boom_timer <= boom_timer + 1;
                        else state <= S_IDLE;
                    end
                end
            endcase
        end
    end

    logic in_box;
    assign in_box = (x_pixel >= duck_x) && (x_pixel < duck_x + DUCK_W) && 
                    (y_pixel >= duck_y) && (y_pixel < duck_y + DUCK_H);

    logic [9:0] col_idx, row_idx;
    logic [15:0] base_addr;

    always_comb begin
        is_duck = 0;
        rom_addr = 0;
        duck_pixel_out = 16'h0000;

        if (in_box && state == S_FLY) begin  // ← S_FLY 상태일 때만
            is_duck   = 1;
            row_idx   = y_pixel - duck_y;
            col_idx   = x_pixel - duck_x;

            base_addr = (frame_toggle) ? FRAME_OFFSET : 0;
            if (is_facing_left)
                rom_addr = base_addr + (row_idx * DUCK_W) + ((DUCK_W - 1) - col_idx);
            else rom_addr = base_addr + (row_idx * DUCK_W) + col_idx;

            duck_pixel_out = duck_rom_data;
        end else if (in_box && state == S_BOOM) begin  // ← S_BOOM 상태 분리
            is_duck = 1;
            row_idx = y_pixel - duck_y;
            col_idx = x_pixel - duck_x;
            rom_addr = (row_idx * DUCK_W) + col_idx;
            duck_pixel_out = bomb_rom_data;
        end
    end
endmodule
