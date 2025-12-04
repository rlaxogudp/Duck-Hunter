`timescale 1ns / 1ps


module SCCB_controller (
    input  logic        clk,
    input  logic        reset,
    input  logic        I2C_clk_400khz,
    input  logic [23:0] initData,
    input               startSig,
    output logic        SCL,
    output logic        SDA,
    output logic        I2C_clk_en,
    output logic [ 7:0] addr
);

    typedef enum {
        SCL_IDLE,
        SCL_START,
        SCL_H2L,
        SCL_L2L,
        SCL_L2H,
        SCL_H2H,
        SCL_STOP
    } scl_e;

    typedef enum {
        SDA_IDLE,
        SDA_START,
        DEVICE_ID,
        ADDRESS_REG,
        DATA_REG,
        SDA_STOP
    } sda_e;

    scl_e scl_state;
    sda_e sda_state, sda_state_next;

    logic [5:0] bitCount, bitCount_next;
    logic [5:0] dataBit, dataBit_next;

    logic r_scl;
    logic r_sda, r_sda_next;
    logic r_I2C_clk_en;
    logic [7:0] r_addr, r_addr_next;
    logic initProcess, initProcess_next;

    assign SCL = r_scl;
    assign SDA = r_sda;
    assign I2C_clk_en = r_I2C_clk_en;
    assign addr = r_addr;

    always_ff @(posedge clk) begin : SCL_FSM_sequen
        if (reset) begin
            scl_state    <= SCL_IDLE;
            r_scl        <= 1'b1;
            r_I2C_clk_en <= 0;
        end else begin
            case (scl_state)
                SCL_IDLE: begin
                    if (sda_state == SDA_START) begin
                        r_I2C_clk_en <= 1'b1;
                        scl_state <= SCL_START;
                    end
                end
                SCL_START: begin
                    if (I2C_clk_400khz) begin
                        r_scl <= 1'b0;
                        scl_state <= SCL_H2L;
                    end
                end
                SCL_H2L: begin
                    if (I2C_clk_400khz) begin
                        r_scl <= 1'b0;
                        scl_state <= SCL_L2L;
                    end
                end
                SCL_L2L: begin
                    if (I2C_clk_400khz) begin
                        r_scl <= 1'b1;
                        scl_state <= SCL_L2H;
                    end
                end
                SCL_L2H: begin
                    if (I2C_clk_400khz) begin
                        if (sda_state == SDA_STOP) begin
                            r_scl <= 1'b1;
                            scl_state <= SCL_STOP;
                        end else begin
                            r_scl <= 1'b1;
                            scl_state <= SCL_H2H;
                        end
                    end
                end
                SCL_H2H: begin
                    if (I2C_clk_400khz) begin
                        r_scl <= 1'b0;
                        scl_state <= SCL_H2L;
                    end
                end
                SCL_STOP: begin
                    if (I2C_clk_400khz) begin
                        if (initProcess) begin
                            r_I2C_clk_en <= 1'b1;
                        end else begin
                            r_I2C_clk_en <= 1'b0;
                        end
                        r_scl <= 1'b1;
                        scl_state <= SCL_IDLE;
                    end
                end
            endcase
        end
    end

    always_ff @(posedge clk) begin : SDA_FSM
        if (reset) begin
            r_sda       <= 1'b1;
            sda_state   <= SDA_IDLE;
            bitCount    <= 0;
            dataBit     <= 23;
            r_addr      <= 0;
            initProcess <= 0;
        end else begin
            sda_state   <= sda_state_next;
            bitCount    <= bitCount_next;
            dataBit     <= dataBit_next;
            r_sda       <= r_sda_next;
            r_addr      <= r_addr_next;
            initProcess <= initProcess_next;

        end
    end

    always_comb begin : SDA_FSM_comb
        r_sda_next = r_sda;
        sda_state_next = sda_state;
        bitCount_next = bitCount;
        dataBit_next = dataBit;
        initProcess_next = initProcess;
        r_addr_next = r_addr;
        case (sda_state)
            SDA_IDLE: begin
                if (startSig) begin
                    initProcess_next = 1;
                    r_sda_next = 1'b0;
                    sda_state_next = SDA_START;
                end else if (initProcess) begin
                    if (I2C_clk_400khz) begin
                        r_sda_next = 1'b0;
                        sda_state_next = SDA_START;
                    end
                end
            end
            SDA_START: begin
                if (scl_state == SCL_H2L) sda_state_next = DEVICE_ID;
            end
            DEVICE_ID: begin
                case (scl_state)
                    SCL_H2L: begin
                        if (I2C_clk_400khz) begin
                            if (bitCount == 9) begin
                                bitCount_next = 1;
                                r_sda_next = initData[dataBit];
                                dataBit_next = dataBit - 1;
                                sda_state_next = ADDRESS_REG;
                            end else if (bitCount == 8) begin
                                r_sda_next = 1'bx;
                                bitCount_next = bitCount + 1;
                            end else if (bitCount < 8) begin
                                dataBit_next = dataBit - 1;
                                r_sda_next = initData[dataBit];
                                bitCount_next = bitCount + 1;
                            end
                        end
                    end
                    SCL_L2L: r_sda_next = r_sda;
                    SCL_L2H: r_sda_next = r_sda;
                    SCL_H2H: r_sda_next = r_sda;
                endcase
            end
            ADDRESS_REG: begin
                case (scl_state)
                    SCL_H2L: begin
                        if (I2C_clk_400khz) begin
                            if (bitCount == 9) begin
                                bitCount_next = 1;
                                r_sda_next = initData[dataBit];
                                dataBit_next = dataBit - 1;
                                sda_state_next = DATA_REG;
                            end else if (bitCount == 8) begin
                                r_sda_next = 1'bx;
                                bitCount_next = bitCount + 1;
                            end else if (bitCount < 8) begin
                                r_sda_next = initData[dataBit];
                                dataBit_next = dataBit - 1;
                                bitCount_next = bitCount + 1;
                            end
                        end
                    end
                    SCL_L2L: r_sda_next = r_sda;
                    SCL_L2H: r_sda_next = r_sda;
                    SCL_H2H: r_sda_next = r_sda;
                endcase
            end
            DATA_REG: begin
                case (scl_state)
                    SCL_H2L: begin
                        if (I2C_clk_400khz) begin
                            if (bitCount == 9) begin
                                bitCount_next = 1;
                                r_sda_next = initData[dataBit];
                                bitCount_next = 0;
                                dataBit_next = 23;
                                r_sda_next = 0;
                                sda_state_next = SDA_STOP;
                            end else if (bitCount == 8) begin
                                r_sda_next = 1'bx;
                                bitCount_next = bitCount + 1;
                            end else if (bitCount < 8) begin
                                r_sda_next = initData[dataBit];
                                if (dataBit == 0) dataBit_next = dataBit;
                                else dataBit_next = dataBit - 1;
                                bitCount_next = bitCount + 1;
                            end
                        end
                    end
                    SCL_L2L: r_sda_next = r_sda;
                    SCL_L2H: r_sda_next = r_sda;
                    SCL_H2H: r_sda_next = r_sda;
                endcase
            end
            SDA_STOP: begin
                case (scl_state)
                    SCL_L2L: r_sda_next = 0;
                    SCL_L2H: begin
                        if (I2C_clk_400khz) begin
                            if ((r_addr < 75) && (r_addr >= 0)) begin
                                r_addr_next = r_addr + 1;
                                initProcess_next = 1;
                            end else begin
                                initProcess_next = 0;
                            end
                            r_sda_next = 1'b1;
                            bitCount_next = 0;
                            dataBit_next = 23;
                            sda_state_next = SDA_IDLE;
                        end
                    end
                    SCL_H2H: r_sda_next = r_sda;
                endcase
            end
        endcase
    end

endmodule

module I2C_clk_gen (
    input  logic clk,
    input  logic reset,
    input  logic I2C_clk_en,
    output logic I2C_clk_400khz
);

    logic [$clog2(250)-1:0] counter;  //2.5us period == 400khz

    always_ff @(posedge clk) begin : I2C_clk_400khz_gen
        if (reset) begin
            I2C_clk_400khz <= 0;
            counter <= 0;
        end else begin
            if (I2C_clk_en) begin
                if (counter == 250-1) begin
                    I2C_clk_400khz <= 1;
                    counter <= 0;
                end else begin
                    I2C_clk_400khz <= 0;
                    counter <= counter + 1;
                end
            end else begin
                I2C_clk_400khz <= 0;
                counter <= 0;
            end
        end
    end

endmodule