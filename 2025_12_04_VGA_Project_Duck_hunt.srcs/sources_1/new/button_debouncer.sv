`timescale 1ns / 1ps


// module btn_debounce (
//     input  clk,
//     input  rst,
//     input  i_btn,
//     output o_btn
// );

//     // 100M > 1M
//     reg [$clog2(100)-1:0] counter_reg;
//     reg clk_reg;

//     reg [7:0] q_reg, q_next;
//     reg  edge_reg;
//     wire debounce;

//     // clock devider
//     always @(posedge clk, posedge rst) begin
//         if (rst) begin
//             counter_reg <= 0;
//             clk_reg   <= 1'b0;
//         end else begin
//             if (counter_reg == 99) begin
//                 counter_reg <= 0;
//                 clk_reg   <= 1'b1;
//             end else begin
//                 counter_reg <= counter_reg + 1;
//                 clk_reg   <= 1'b0;
//             end
//         end
//     end

//     // debounce, shift register
//     always @(posedge clk_reg, posedge rst) begin
//         if (rst) begin
//             q_reg <= 0;
//         end else begin
//             q_reg <= q_next;
//         end
//     end

//     // Serial imnput, Paraller output shift register
//     always @(*) begin
//         q_next = {i_btn, q_reg[7:1]};
//     end

//     // all q_next & with debounce(4 input AND)
//     assign debounce = &q_reg;

//     // Q5 output    
//     always @(posedge clk, posedge rst) begin
//         if (rst) begin
//             edge_reg <= 1'b0;
//         end else begin
//             edge_reg <= debounce;
//         end
//     end

//     // edge output 
//     assign o_btn = ~edge_reg & debounce;

// endmodule

module button_debouncer #(
    parameter DEBOUNCE_TIME = 1_000_000
) (
    input  logic clk,
    input  logic reset,
    input  logic btn_in,
    output logic btn_stable,
    output logic btn_pulse
);

    logic [$clog2(DEBOUNCE_TIME)-1:0] counter;
    logic btn_sync_0, btn_sync_1;
    logic btn_prev;

    always_ff @(posedge clk) begin
        if (reset) begin
            btn_sync_0 <= 1'b0;
            btn_sync_1 <= 1'b0;
        end else begin
            btn_sync_0 <= btn_in;
            btn_sync_1 <= btn_sync_0;
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            counter <= '0;
            btn_stable <= 1'b0;
        end else begin
            if (btn_sync_1 == btn_stable) begin
                counter <= '0;
            end else begin
                if (counter == DEBOUNCE_TIME - 1) begin
                    btn_stable <= btn_sync_1;
                    counter <= '0;
                end else begin
                    counter <= counter + 1;
                end
            end
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            btn_prev  <= 1'b0;
            btn_pulse <= 1'b0;
        end else begin
            btn_prev  <= btn_stable;
            btn_pulse <= btn_stable && !btn_prev;
        end
    end

endmodule