`timescale 1ns / 1ps

module top_all (
    input        clk,
    input        rst,
    input        btnR,
    input        btnL,
    input        btnU,
    input        btnD,
    input        rx,
    input  [3:0] sw,
    //sw[3] sensor(1) timer(0), sw[2] dht11(1) sr04(0), sw[1] stopwatch(1) watch(0)
    input        echo,      //sr04
    output       trig,      //sr04
    output [3:0] led,
    output [3:0] fnd_com,
    output [7:0] fnd_data,
    output       tx
);

    wire w_push, w_full;
    wire [31:0] w_out_digit;
    wire w_rx_empty, w_rx_pop, w_rx_push;
    wire w_tx_empty, w_tx_pop, w_tx_push, w_tx_full;
    wire [7:0] w_tx_pop_data, w_tx_push_data;
    wire [7:0] w_rx_pop_data, w_rx_push_data;
    wire w_btnr, w_btnl, w_btnu, w_btnd;
    wire w_keyr, w_keyl, w_keyu, w_keyd, w_keys, w_keym, w_keyt;
    wire w_r_final, w_l_final, w_u_final, w_d_final, w_s_final, w_m_final, w_t_final;
    wire [7:0] w_msec;
    wire [6:0] w_sec, w_min;
    wire [5:0] w_hour;
    wire [8:0] w_distance;
    wire [7:0] w_humidity, w_temperature;

    uart U_UART_RX (
        .clk     (clk),
        .rst     (rst),
        .tx_start(),                //x
        .tx_data (),                //x
        .rx      (rx),              //from pc
        .rx_data (w_rx_push_data),
        .rx_done (w_rx_push),
        .tx_busy (),                //x
        .tx      ()                 //x
    );

    fifo #(
        .DEPTH(64)
    ) U_FIFO_RX (
        .clk      (clk),
        .rst      (rst),
        .push_data(w_rx_push_data),
        .push     (w_rx_push),
        .pop      (w_rx_pop),
        .pop_data (w_rx_pop_data),
        .full     (),                //x
        .empty    (w_rx_empty)
    );

    BD U_BD (
        .clk   (clk),
        .rst   (rst),
        .btnR  (btnR),
        .btnL  (btnL),
        .btnU  (btnU),
        .btnD  (btnD),
        .o_btnr(w_btnr),
        .o_btnl(w_btnl),
        .o_btnu(w_btnu),
        .o_btnd(w_btnd)
    );

    ascii_decoder U_ASCII_DECODER (
        .clk    (clk),
        .rst    (rst),
        .key    (w_rx_pop_data),
        .i_valid(!w_rx_empty),
        .btnR   (w_keyr),
        .btnL   (w_keyl),
        .btnU   (w_keyu),
        .btnD   (w_keyd),
        .btnS   (w_keys),
        .btnM   (w_keym),
        .btnT   (w_keyt),
        .pop    (w_rx_pop)
    );

    control_unit_ascii U_CNTL_ASCII (
        .clk      (clk),
        .rst      (rst),
        .key_btnR (w_keyr),
        .key_btnL (w_keyl),
        .key_btnU (w_keyu),
        .key_btnD (w_keyd),
        .key_btnS (w_keys),
        .key_btnM (w_keym),
        .key_btnT (w_keyt),
        .fpga_btnR(w_btnr),
        .fpga_btnL(w_btnl),
        .fpga_btnU(w_btnu),
        .fpga_btnD(w_btnd),
        .r_final  (w_r_final),
        .l_final  (w_l_final),
        .u_final  (w_u_final),
        .d_final  (w_d_final),
        .s_final  (w_s_final),
        .m_final  (w_m_final),
        .t_final  (w_t_final)
    );


    top_stopwatch_watch U_TOP_STOPWATCH_WATCH (
        .clk       (clk),
        .rst       (rst),
        .btnR      (w_r_final),
        .btnL      (w_l_final),
        .btnU      (w_u_final),
        .btnD      (w_d_final),
        .sw        (sw[1]),
        .final_msec(w_msec),
        .final_sec (w_sec),
        .final_min (w_min),
        .final_hour(w_hour)
    );

    sr04 U_SR04 (
        .clk     (clk),
        .rst     (rst),
        .measure (w_m_final),
        .echo    (echo),       //<-sensor
        .trig    (trig),       // ->sensor
        .distance(w_distance)
    );

    dht11 U_DHT11 (
        .clk        (clk),
        .rst        (rst),
        .start      (w_t_final),
        .dht11      (),
        .valid      (),
        .humidity   (w_humidity),
        .temperature(w_temperature)
    );

    fnd_controller U_FND_CNTL (
        .clk        (clk),
        .rst        (rst),
        .sw         (sw),
        .msec       (w_msec),
        .sec        (w_sec),
        .min        (w_min),
        .hour       (w_hour),
        .distance   (w_distance),     //sr04
        .humidity   (w_humidity),     //dht11
        .temperature(w_temperature),  //dht11
        .led        (led),
        .fnd_com    (fnd_com),
        .fnd_data   (fnd_data),
        .out_digit  (w_out_digit)     // to pc
    );

    ascii_sender U_ASCII_SENDER (
        .clk     (clk),
        .rst     (rst),
        .status  (w_s_final),
        .full    (w_tx_full),
        .sw      (sw),
        .data_in (w_out_digit),
        .push    (w_tx_push),
        .data_out(w_tx_push_data)
    );

    fifo #(
        .DEPTH(64)
    ) U_FIFO_TX (
        .clk      (clk),
        .rst      (rst),
        .push_data(w_tx_push_data),
        .push     (w_tx_push),
        .pop      ((!w_tx_empty) && (!w_tx_pop)),  //?
        .pop_data (w_tx_pop_data),
        .full     (w_tx_full),
        .empty    (w_tx_empty)                     //x
    );


    uart U_UART_TX (
        .clk     (clk),
        .rst     (rst),
        .tx_start((!w_tx_empty) && (!w_tx_pop)),  //handshaking
        .tx_data (w_tx_pop_data),
        .rx      (),                              //x
        .rx_data (),                              //x
        .rx_done (),                              //x
        .tx_busy (w_tx_pop),
        .tx      (tx)                             //xdc
    );

endmodule

module control_unit_ascii (
    input      clk,
    input      rst,
    input      key_btnR,
    input      key_btnL,
    input      key_btnU,
    input      key_btnD,
    input      key_btnS,
    input      key_btnM,
    input      key_btnT,
    input      fpga_btnR,
    input      fpga_btnL,
    input      fpga_btnU,
    input      fpga_btnD,
    output reg r_final,
    output reg l_final,
    output reg u_final,
    output reg d_final,
    output reg s_final,
    output reg m_final,
    output reg t_final
);

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            r_final <= 0;
            l_final <= 0;
            u_final <= 0;
            d_final <= 0;
            s_final <= 0;
            m_final <= 0;
            t_final <= 0;
        end else begin
            r_final <= key_btnR || fpga_btnR;
            l_final <= key_btnL || fpga_btnL;
            u_final <= key_btnU || fpga_btnU;
            d_final <= key_btnD || fpga_btnD;
            s_final <= key_btnS;
            m_final <= key_btnM;
            t_final <= key_btnT;
        end
    end

endmodule
