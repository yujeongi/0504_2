`timescale 1ns / 1ps

module BD (
    input  clk,
    input  rst,
    input  btnR,
    input  btnL,
    input  btnU,
    input  btnD,
    output o_btnr,
    output o_btnl,
    output o_btnu,
    output o_btnd
);

    button_debounce U_BTNR (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btnR),
        .o_btn(o_btnr)
    );
    button_debounce U_BTNL (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btnL),
        .o_btn(o_btnl)
    );
    button_debounce U_BTNU (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btnU),
        .o_btn(o_btnu)
    );
    button_debounce U_BTND (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btnD),
        .o_btn(o_btnd)
    );

endmodule

module button_debounce (
    input  clk,
    input  rst,
    input  i_btn,
    output o_btn
);

    parameter F_COUNT = 100_000_000 / 10_000;
    reg [$clog2(F_COUNT)-1:0] r_counter;
    reg clk_10khz;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            clk_10khz <= 1'b0;
            r_counter <= 0;
        end else begin
            if (r_counter == F_COUNT - 1) begin
                r_counter <= 0;
                clk_10khz <= 1'b1;
            end else begin
                r_counter <= r_counter + 1;
                clk_10khz <= 1'b0;
            end
        end
    end



    reg [7:0] sync_reg;
    wire debounce;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            sync_reg <= 8'b0;
        end else if (clk_10khz) begin
            sync_reg <= {i_btn, sync_reg[7:1]};
        end
    end



    assign debounce = &sync_reg;

    reg edge_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            edge_reg <= 1'b0;
        end else begin
            edge_reg <= debounce;
        end
    end

    assign o_btn = debounce & (~edge_reg);

endmodule
