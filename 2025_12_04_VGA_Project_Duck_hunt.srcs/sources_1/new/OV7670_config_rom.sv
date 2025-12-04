`timescale 1ns / 1ps

module OV7670_config_rom (
    input  logic        clk,
    input  logic [ 7:0] rom_addr,
    output logic [15:0] rom_data
);
    // dout = {Reg_Addr[7:0], Data[7:0]}
    // FF_FF: End of ROM marker
    // FFF0: Delay marker (Not implemented in controller, but kept for future proofing)
  always @(posedge clk) begin
        case (rom_addr)
            // -----------------------------------------------------------
            // 시스템 초기화 및 클럭 설정
            // -----------------------------------------------------------
            // COM7 (0x12) - Bit[7]=1: SCCB Register Reset [cite: 452]
            0: rom_data <= 16'h12_80;  
            1: rom_data <= 16'hFF_F0;  // Delay (Controller implementation dependent)

            // COM7 (0x12) - Bit[2]=1: RGB selection[cite: 452]. All resolution flags (Bit 3,4,5) are 0 (VGA base for scaling).
            2: rom_data <= 16'h12_04;  
            
            // CLKRC (0x11) - Bit[7]: Reserved, Bit[6]=1: Use external clock directly (no pre-scale) [cite: 452]
            // Bit[5:0]=0: Internal clock pre-scalar (F(int)=F(in)/1) [cite: 452]
            3: rom_data <= 16'h11_80;  
            
            // -----------------------------------------------------------
            // 해상도 및 포맷 설정
            // -----------------------------------------------------------
            // COM3 (0x0C) - Bit[3]=1: Scale enable, Bit[2]=1: DCW enable [cite: 444]
            4: rom_data <= 16'h0C_04;  

            // COM14 (0x3E) - Bit[4]=1: DCW/Scaling PCLK enable. Bit[3]=1: Manual scaling enable[cite: 494]. Bit[2:0]=010 (Divided by 4)[cite: 494].
            5: rom_data <= 16'h3E_1B;  

            // COM1 (0x04) - Bit[6]=0: Disable CCIR656 format[cite: 437].
            6: rom_data <= 16'h04_00;  

            // COM15 (0x40) - Bit[5:4]=01: RGB 565[cite: 494]. Bit[7:6]=11: Full output range [00] to [FF][cite: 494].
            7: rom_data <= 16'h40_d0;  

            // TSLB (0x3A) - Controls YUV/RGB output sequence (Bit[3]) and Auto Window (Bit[0])[cite: 487]. Value 0x04 is often used for RGB setup.
            8: rom_data <= 16'h3a_04;  
            
            // -----------------------------------------------------------
            // 노출 및 이득 제어 (Exposure and Gain Control)
            // -----------------------------------------------------------
            // COM9 (0x14) - Bit[6:4]=001: Gain Ceiling 4x[cite: 459]. Bit[0]=0: Freeze AGC/AEC disabled.
            9: rom_data <= 16'h14_18;  

            // -----------------------------------------------------------
            // 색상 매트릭스 (Color Matrix Coefficients)
            // -----------------------------------------------------------
            10: rom_data <= 16'h4F_B3; // MTX1 (0x4F) [cite: 504]
            11: rom_data <= 16'h50_B3; // MTX2 (0x50) [cite: 504]
            12: rom_data <= 16'h51_00; // MTX3 (0x51) [cite: 512]
            13: rom_data <= 16'h52_3d; // MTX4 (0x52) [cite: 512]
            14: rom_data <= 16'h53_A7; // MTX5 (0x53) [cite: 512]
            15: rom_data <= 16'h54_E4; // MTX6 (0x54) [cite: 512]
            16: rom_data <= 16'h58_9E; // MTXS (0x58) - Matrix Coefficient Sign [cite: 512]

            // -----------------------------------------------------------
            // 윈도우 및 감마 설정
            // -----------------------------------------------------------
            // COM13 (0x3D) - Bit[7]=1: Gamma enable[cite: 494]. Bit[6]=1: UV saturation auto adjustment[cite: 494].
            17: rom_data <= 16'h3D_C0; 

            // Windowing (VGA Base)
            18: rom_data <= 16'h17_17; // HSTART (Horizontal Frame Start High 8-bit) [cite: 459]
            19: rom_data <= 16'h18_05; // HSTOP (Horizontal Frame End High 8-bit) [cite: 459]
            20: rom_data <= 16'h32_00; // HREF (0x32) - HREF control (Edge offset) [cite: 477]
            21: rom_data <= 16'h19_03; // VSTART (Vertical Frame Start High 8-bit) [cite: 459]
            22: rom_data <= 16'h1A_7B; // VSTOP (Vertical Frame End High 8-bit) [cite: 459]
            23: rom_data <= 16'h03_00; // VREF (0x03) - Vertical Frame Control (VSTART/VSTOP low bits) [cite: 437]

            // COM6 (0x0F) - Reset Timings[cite: 444].
            24: rom_data <= 16'h0F_41; 

            // MVFP (0x1E) - Bit[5]=0, Bit[4]=0: Normal Image (No Mirror/VFlip)[cite: 469].
            25: rom_data <= 16'h1E_00; 

            // CHLF (0x33) - Array Current Control (often a required magic value)[cite: 477].
            26: rom_data <= 16'h33_0B; 

            // COM12 (0x3C) - Bit[7]=0: No HREF when VSYNC is low[cite: 494].
            27: rom_data <= 16'h3C_78; 

            // GFIX (0x69) - Fix Gain Control (used if AGC is disabled)[cite: 521].
            28: rom_data <= 16'h69_00; 

            // REG74 (0x74) - Digital Gain Control[cite: 539].
            29: rom_data <= 16'h74_00; 

            // Reserved/ABLC (Automatic Black Level Compensation)
            30: rom_data <= 16'hB0_84; // Reserved[cite: 556].
            31: rom_data <= 16'hB1_0c; // ABLC1 (0xB1)[cite: 556].
            32: rom_data <= 16'hB2_0e; // Reserved[cite: 556].
            33: rom_data <= 16'hB3_80; // THL_ST (0xB3) - ABLC Target[cite: 556].

            // -----------------------------------------------------------
            // 스케일링 설정 (SCALING)
            // -----------------------------------------------------------
            // SCALING_XSC (0x70) & YSC (0x71) - Horizontal/Vertical Scale Factor[cite: 521, 529].
            34: rom_data <= 16'h70_3A; 
            35: rom_data <= 16'h71_35; 

            // SCALING_DCWCTR (0x72) - Bit[5:4]=10: Vert down sample by 4. Bit[1:0]=10: Horiz down sample by 4[cite: 529].
            // (VGA/4 = QQVGA 160x120)
            36: rom_data <= 16'h72_33; 

            // SCALING_PCLK_DIV (0x73) - Clock divider control for DSP scale[cite: 530]. 0xF1 often used for stability.
            37: rom_data <= 16'h73_F3; 

            // SCALING_PCLK_DELAY (0xA2) - Scaling output delay[cite: 547].
            38: rom_data <= 16'ha2_02; 

            // -----------------------------------------------------------
            // 감마 곡선 (Gamma Curve)
            // -----------------------------------------------------------
            39: rom_data <= 16'h7a_20; // SLOP (0x7A)[cite: 539].
            40: rom_data <= 16'h7b_10; // GAM1 (0x7B)[cite: 539].
            41: rom_data <= 16'h7c_1e; // GAM2 (0x7C)[cite: 539].
            42: rom_data <= 16'h7d_35; // GAM3 (0x7D)[cite: 539].
            43: rom_data <= 16'h7e_5a; // GAM4 (0x7E)[cite: 539].
            44: rom_data <= 16'h7f_69; // GAM5 (0x7F)[cite: 539].
            45: rom_data <= 16'h80_76; // GAM6 (0x80)[cite: 539].
            46: rom_data <= 16'h81_80; // GAM7 (0x81)[cite: 539].
            47: rom_data <= 16'h82_88; // GAM8 (0x82)[cite: 539].
            48: rom_data <= 16'h83_8f; // GAM9 (0x83)[cite: 539].
            49: rom_data <= 16'h84_96; // GAM10 (0x84)[cite: 539].
            50: rom_data <= 16'h85_a3; // GAM11 (0x85)[cite: 539].
            51: rom_data <= 16'h86_af; // GAM12 (0x86)[cite: 539].
            52: rom_data <= 16'h87_c4; // GAM13 (0x87)[cite: 539].
            53: rom_data <= 16'h88_d7; // GAM14 (0x88)[cite: 539].
            54: rom_data <= 16'h89_e8; // GAM15 (0x89)[cite: 547].

            // -----------------------------------------------------------
            // AGC/AEC/AWB 자동 제어 (Automatic Control)
            // -----------------------------------------------------------
            // COM8 (0x13) - 0xE0: Disable AGC/AEC/AWB[cite: 452].
            55: rom_data <= 16'h13_e0;  
            56: rom_data <= 16'h00_00;  // GAIN (0x00) - Set Gain to 0[cite: 437].
            57: rom_data <= 16'h10_00;  // AECH (0x10) - Exposure Value[cite: 444].
            58: rom_data <= 16'h0d_40;  // COM4 (0x0D) - Average option (1/4 Window)[cite: 444].
            59: rom_data <= 16'h14_18;  // COM9 (0x14) - Gain Ceiling 4x[cite: 459].
            60: rom_data <= 16'ha5_05;  // BD50MAX (0xA5) - 50Hz Banding Step Limit[cite: 547].
            61: rom_data <= 16'hab_07;  // BD60MAX (0xAB) - 60Hz Banding Step Limit[cite: 556].
            62: rom_data <= 16'h24_95;  // AEW (0x24) - AGC/AEC Upper Limit[cite: 469].
            63: rom_data <= 16'h25_33;  // AEB (0x25) - AGC/AEC Lower Limit[cite: 469].
            64: rom_data <= 16'h26_e3;  // VPT (0x26) - AGC/AEC Fast Mode Region[cite: 469].
            65: rom_data <= 16'h9f_78;  // HAECC1 (0x9F) - Histogram-based AEC/AGC Control[cite: 547].
            66: rom_data <= 16'ha0_68;  // HAECC2 (0xA0)[cite: 547].
            67: rom_data <= 16'ha1_03;  // Reserved (0xA1)[cite: 547].
            68: rom_data <= 16'ha6_d8;  // HAECC3 (0xA6)[cite: 547].
            69: rom_data <= 16'ha7_d8;  // HAECC4 (0xA7)[cite: 547].
            70: rom_data <= 16'ha8_f0;  // HAECC5 (0xA8)[cite: 547].
            71: rom_data <= 16'ha9_90;  // HAECC6 (0xA9)[cite: 547].
            72: rom_data <= 16'haa_94;  // HAECC7 (0xAA) - AEC Algorithm Selection[cite: 556].
            // COM8 (0x13) - 0xE7: Enable AGC/AEC/AWB[cite: 452].
            73: rom_data <= 16'h13_e7;  
            74: rom_data <= 16'h69_07; // GFIX (0x69) - Fix Gain Control[cite: 521].

            default: rom_data <= 16'hFF_FF;  // End of ROM
        endcase
    end
endmodule
