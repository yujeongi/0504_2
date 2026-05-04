`timescale 1ns / 1ps

module sr04 (
    input        clk,
    input        rst,
    input        measure, //측정시작
    input        echo, //<-sensor
    output       trig, // ->sensor
    output [8:0] distance
);

    wire w_tick_us;

//    ila_0 U_ILA0(
//    .clk(clk), //only system clock
//    .probe0(w_sr04_start),
//    .probe1(w_distance)
//);

    sr04_controller U_SR04_CNTL (
        .clk       (clk),
        .rst       (rst),
        .sr04_start(measure),
        .tick_us   (w_tick_us),
        .echo      (echo),
        .trig      (trig),
        .distance  (distance)
    );

    tick_gen_us_sr04 U_TICK_GEN_US_SR04 (
        .clk    (clk),
        .rst    (rst),
        .tick_us(w_tick_us)
    );

endmodule



module sr04_controller (
    input        clk,
    input        rst,
    input        sr04_start,
    input        tick_us,
    input        echo,
    output       trig,
    output [8:0] distance //400cm
);

    parameter IDLE = 0, START = 1, WAIT = 2, RESPONSE = 3;

    reg trig_reg, trig_next;
    reg [8:0] distance_reg, distance_next; //400
    reg [5:0] tick_cnt_reg, tick_cnt_next; //58
    reg [1:0] c_state, n_state; //4
    assign trig = trig_reg;
    assign distance = distance_reg;  //cm, 근데 오류

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            trig_reg     <= 0;
            tick_cnt_reg <= 0;
            c_state      <= 0;
            distance_reg <= 0;
        end else begin
            trig_reg     <= trig_next;
            tick_cnt_reg <= tick_cnt_next;
            c_state      <= n_state;
            distance_reg <= distance_next;
        end
    end

    always @(*) begin
        trig_next     = trig_reg;
        tick_cnt_next = tick_cnt_reg;
        n_state       = c_state;
        distance_next = distance_reg;
        case (c_state)
            IDLE: begin
                trig_next = 0;
                if (sr04_start) begin
                    tick_cnt_next = 0;
                    n_state = START;
                end
            end
            START: begin //센서 깨우기
                trig_next = 1;
                if (tick_us) begin
                    tick_cnt_next = tick_cnt_reg + 1;
                    if (tick_cnt_reg >= 11) begin
                        n_state = WAIT;
                    end
                end
            end
            WAIT: begin //초음파 발사
                trig_next = 0;
                if (tick_us && echo) begin
                    tick_cnt_next = 0;
                    distance_next = 0;
                    n_state = RESPONSE;
                end
            end
            RESPONSE: begin
                if (tick_us && echo) begin
                    tick_cnt_next = tick_cnt_reg + 1;
                    if (tick_cnt_reg == 57) begin
                        tick_cnt_next = 0;
                        distance_next = distance_reg + 1;
                    end
                end else if (!echo) begin
                    tick_cnt_next = 0;
                    n_state = IDLE;
                end
            end
        endcase
    end

endmodule



module tick_gen_us_sr04 (  //나같으면 us안함. 바꾸려면 바꾸던가.
    input      clk,
    input      rst,
    output reg tick_us
);
    parameter F_COUNT = 100_000_000 / 1_000_000;  //1us
    reg [$clog2(F_COUNT)-1:0] counter_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            tick_us     <= 1'b0;
        end else begin
            counter_reg <= counter_reg + 1;
            if (counter_reg == F_COUNT - 1) begin
                counter_reg <= 0;
                tick_us     <= 1'b1;
            end else begin
                tick_us <= 1'b0;
            end
        end
    end

endmodule
