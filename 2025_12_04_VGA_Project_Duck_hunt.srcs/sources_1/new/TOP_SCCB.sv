`timescale 1ns / 1ps

module Top_SCCB (
    input  logic clk,
    input  logic reset,
    output logic SCL,
    output logic SDA
);

    wire I2C_clk_400khz;
    wire I2C_clk_en;

    wire [7:0] addr;
    wire [15:0] dataRom;
    logic startSig;

    always @(posedge clk or posedge reset) begin
        if(reset) begin
            startSig=1;
        end else begin
            startSig=0;
        end
    end
    I2C_clk_gen U_I2C_clk_gen (
        .clk           (clk),
        .reset         (reset),
        .I2C_clk_en    (I2C_clk_en),
        .I2C_clk_400khz(I2C_clk_400khz)
    );


    SCCB_controller U_SCCB_controller (
        .clk           (clk),
        .reset         (reset),
        .startSig      (startSig),
        .I2C_clk_400khz(I2C_clk_400khz),
        .initData      ({8'h42, dataRom}),
        .SCL           (SCL),
        .SDA           (SDA),
        .I2C_clk_en    (I2C_clk_en),
        .addr          (addr)
    );

    OV7670_config_rom U_OV7670_config_rom (
        .clk (clk),
        .rom_addr(addr),
        .rom_data(dataRom)
    );

endmodule
