`timescale 1ns / 1ps

module Red_Detector_Threshold (
    input  logic        clk,
    input  logic        reset,
    input  logic        detect_enable,
    input  logic        href,
    input  logic        vsync,
    input  logic [15:0] pixel_data,
    output logic        red_detected,
    output logic [15:0] red_pixel_count
);

    // ★★★ 빨간색 감지를 위한 임계값 ★★★
    localparam [15:0] MIN_RED_PIXELS = 16'd80;

    // ★★★ 중앙 영역에서만 감지 ★★★
    // 옵션 1: 전체 영역
    localparam [8:0] DETECT_X_START = 9'd0;
    localparam [8:0] DETECT_X_END = 9'd80;
    localparam [7:0] DETECT_Y_START = 8'd0;
    localparam [7:0] DETECT_Y_END = 8'd60;

    // 옵션 2: 중앙에 더 가깝게
    // localparam [8:0] DETECT_X_START = 9'd13;
    // localparam [8:0] DETECT_X_END = 9'd67;
    // localparam [7:0] DETECT_Y_START = 8'd3;
    // localparam [7:0] DETECT_Y_END = 8'd57;

    // ★★★ 빨간색 임계값 ★★★
    localparam [4:0] RED_MIN = 5'd12;
    localparam [5:0] GREEN_MAX = 6'd18;
    localparam [4:0] BLUE_MAX = 5'd15;

    logic [4:0] red_value;
    logic [5:0] green_value;
    logic [4:0] blue_value;
    logic is_red_pixel;

    logic [15:0] red_count;
    logic prev_vsync;
    logic frame_ended;

    // QQQVGA (80x60) 카운터
    logic [8:0] pixel_x;
    logic [7:0] pixel_y;
    logic in_detect_area;

    assign red_value = pixel_data[15:11];
    assign green_value = pixel_data[10:5];
    assign blue_value = pixel_data[4:0];

    // 빨간색 감지 로직
    assign is_red_pixel = (red_value >= RED_MIN) && 
                         (green_value <= GREEN_MAX) && 
                         (blue_value <= BLUE_MAX);

    assign in_detect_area = (pixel_x >= DETECT_X_START) && (pixel_x < DETECT_X_END) && 
                           (pixel_y >= DETECT_Y_START) && (pixel_y < DETECT_Y_END);

    always_ff @(posedge clk) begin
        if (reset) begin
            red_count <= 16'd0;
            red_detected <= 1'b0;
            red_pixel_count <= 16'd0;
            prev_vsync <= 1'b0;
            frame_ended <= 1'b0;
            pixel_x <= 9'd0;
            pixel_y <= 8'd0;
        end else begin
            prev_vsync <= vsync;

            if (detect_enable) begin
                // 프레임 시작 시 카운터 초기화 (vsync 하강 에지)
                if (prev_vsync && !vsync) begin
                    red_count <= 16'd0;
                    frame_ended <= 1'b0;
                    pixel_x <= 9'd0;
                    pixel_y <= 8'd0;
                end else if (href) begin
                    if (in_detect_area && is_red_pixel) begin
                        red_count <= red_count + 1;
                    end

                    // QQQVGA (X=79, Y=59) 카운터 로직
                    if (pixel_x < 9'd79) begin
                        pixel_x <= pixel_x + 1;
                    end else begin
                        pixel_x <= 9'd0;
                        if (pixel_y < 8'd59) begin
                            pixel_y <= pixel_y + 1;
                        end
                    end
                end else if (!prev_vsync && vsync) begin
                    // 프레임 종료 및 감지 판정 (vsync 상승 에지)
                    frame_ended <= 1'b1;
                    red_pixel_count <= red_count;
                    red_detected <= (red_count >= MIN_RED_PIXELS);
                end
            end else begin
                // 감지 비활성화 상태
                if (frame_ended) begin
                    frame_ended <= 1'b0;
                end
                red_detected <= 1'b0;
            end
        end
    end

endmodule
