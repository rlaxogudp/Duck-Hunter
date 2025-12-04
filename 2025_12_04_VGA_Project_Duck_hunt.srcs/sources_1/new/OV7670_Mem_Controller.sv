`timescale 1ns / 1ps

module OV7670_Mem_Controller (
    input  logic        pclk,
    input  logic        reset,
    //OV7670 side
    input  logic        href,
    input  logic        vsync,
    input  logic [ 7:0] data,
    //memory side
    output logic        we,
    output logic [16:0] wAddr,
    output logic [15:0] wdata
);
    logic [17:0] pixelCounter;
    logic [15:0] pixelData;

    assign wdata = pixelData;

    // QQVGA 픽셀 수의 최대 주소 정의 (160 * 120 - 1 = 19199)
    // localparam WADDR_MAX = 19200 - 1; //qqvga
    localparam WADDR_MAX = 4800 - 1; //qqqvga

    always_ff @(posedge pclk) begin
        if (reset) begin
            pixelCounter <= 0;
            pixelData    <= 0;
            we           <= 1'b0;
            wAddr        <= 0;
        end else begin
            if (href) begin
                if (pixelCounter[0] == 1'b0) begin
                    we              <= 1'b0;
                    pixelData[15:8] <= data;
                end else begin
                    we             <= 1'b1;
                    pixelData[7:0] <= data;

                    // QQVGA 주소 리셋 로직 추가
                    if (wAddr == WADDR_MAX) begin
                        wAddr <= 0;
                    end else begin
                        wAddr <= wAddr + 1;
                    end
                end
                pixelCounter <= pixelCounter + 1;
            end else if (vsync) begin  // vsync가 들어오면 프레임 시작으로 간주하고 리셋 [cite: 37]
                we           <= 1'b0;
                pixelCounter <= 0;
                wAddr        <= 0;
            end
        end
    end
endmodule
