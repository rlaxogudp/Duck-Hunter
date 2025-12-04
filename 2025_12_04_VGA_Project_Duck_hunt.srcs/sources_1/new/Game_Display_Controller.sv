`timescale 1ns / 1ps

module Game_Display_Controller (
    input  logic        clk,
    input  logic        reset,
    input  logic        DE,
    input  logic [ 9:0] x_pixel,
    input  logic [ 9:0] y_pixel,
    input  logic [15:0] bg_data,
    output logic [16:0] bg_addr,
    input  logic [15:0] cam_data,
    output logic [16:0] cam_addr,
    input  logic [15:0] score,
    input  logic        shooting,
    input  logic        show_cam,

    // ★ [추가] 배경 어둡게 하기 신호
    input logic invert_bg,

    // duck 1
    input logic        is_duck1,
    input logic [15:0] duck1_pixel,

    // duck 2
    input logic        is_duck2,
    input logic [15:0] duck2_pixel,

    input logic        is_text,
    input logic [11:0] text_color,

    output logic [3:0] r_port,
    output logic [3:0] g_port,
    output logic [3:0] b_port
);
    logic [3:0] bg_r, bg_g, bg_b;
    logic [8:0] bg_x;
    logic [7:0] bg_y;

    assign bg_x = x_pixel[9:1];
    assign bg_y = y_pixel[9:1];

    always_comb begin
        bg_addr = (bg_y * 9'd320) + bg_x;
    end

    always_comb begin
        bg_r = bg_data[15:12];
        bg_g = bg_data[10:7];
        bg_b = bg_data[4:1];
    end

    logic cam_area;

    assign cam_area = DE && (x_pixel >= 580) && (y_pixel >= 420);
    assign cam_addr = cam_area ? (80 * (y_pixel - 420) + (x_pixel - 570)) : 'bz;

    logic crosshair;
    localparam int CAM_X0 = 580;
    localparam int CAM_Y0 = 420;
    localparam int CAM_W = 60;
    localparam int CAM_H = 60;
    localparam int CX = CAM_X0 + CAM_W / 2;
    localparam int CY = CAM_Y0 + CAM_H / 2;
    localparam int HALF = 10;
    localparam int THICK = 1;

    assign crosshair = cam_area && (
    ((y_pixel >= CY - THICK) && (y_pixel <= CY + THICK) && (x_pixel >= CX - HALF) && (x_pixel <= CX + HALF)) ||
    ((x_pixel >= CX - THICK) && (x_pixel <= CX + THICK) && (y_pixel >= CY - HALF) && (y_pixel <= CY + HALF))
);

    always_ff @(posedge clk) begin
        if (reset) begin
            r_port <= 4'h0;
            g_port <= 4'h0;
            b_port <= 4'h0;
        end else begin
            if (DE) begin
                logic [3:0] temp_r, temp_g, temp_b;

                // ★ [수정] Night Mode 로직
                if (invert_bg) begin
                    temp_r = bg_r >> 2;
                    temp_g = bg_g >> 2;
                    temp_b = bg_b >> 1;
                end else begin
                    temp_r = bg_r;
                    temp_g = bg_g;
                    temp_b = bg_b;
                end

                // ★ show_camera가 1일 때만 카메라 표시
                if (cam_area && show_cam) begin
                    temp_r = cam_data[15:12];
                    temp_g = cam_data[10:7];
                    temp_b = cam_data[4:1];
                end

                // ★ show_camera가 1일 때만 크로스헤어 표시
                if (crosshair && show_cam) begin
                    temp_r = 4'hF;
                    temp_g = 4'h0;
                    temp_b = 4'h0;
                end

                // 오리 렌더링 (shooting이 아닐 때만)
                if (!shooting) begin
                    if (is_duck1 && (duck1_pixel != 16'h0000)) begin
                        temp_r = duck1_pixel[15:12];
                        temp_g = duck1_pixel[10:7];
                        temp_b = duck1_pixel[4:1];
                    end
                    if (is_duck2 && (duck2_pixel != 16'h0000)) begin
                        temp_r = duck2_pixel[15:12];
                        temp_g = duck2_pixel[10:7];
                        temp_b = duck2_pixel[4:1];
                    end
                end  // shooting 상태일 때
                else begin
                    temp_r = 4'h0;
                    temp_g = 4'h0;
                    temp_b = 4'h0;
                    if ((is_duck1 && duck1_pixel != 16'h0000) || (is_duck2 && duck2_pixel != 16'h0000)) begin
                        temp_r = 4'hF;
                        temp_g = 4'h0;
                        temp_b = 4'h0;
                    end
                end

                if (is_text) begin
                    temp_r = text_color[11:8];
                    temp_g = text_color[7:4];
                    temp_b = text_color[3:0];
                end

                r_port <= temp_r;
                g_port <= temp_g;
                b_port <= temp_b;
            end else begin
                r_port <= 4'h0;
                g_port <= 4'h0;
                b_port <= 4'h0;
            end
        end
    end

endmodule
