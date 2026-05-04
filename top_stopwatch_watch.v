`timescale 1ns / 1ps

module top_stopwatch_watch #(
    parameter MSEC_WIDTH = 7,
    SEC_WIDTH = 6,
    MIN_WIDTH = 6,
    HOUR_WIDTH = 5
) (
    input                   clk,
    input                   rst,
    input                   btnR,
    input                   btnL,
    input                   btnU,
    input                   btnD,
    input                   sw,          //sw[1]
    output [MSEC_WIDTH-1:0] final_msec,
    output [ SEC_WIDTH-1:0] final_sec,
    output [ MIN_WIDTH-1:0] final_min,
    output [HOUR_WIDTH-1:0] final_hour
);

    wire [MSEC_WIDTH-1:0] sw_msec, w_msec;
    wire [SEC_WIDTH-1:0] sw_sec, w_sec;
    wire [MIN_WIDTH-1:0] sw_min, w_min;
    wire [HOUR_WIDTH-1:0] sw_hour, w_hour;

    assign final_msec = (sw) ? sw_msec : w_msec;
    assign final_sec  = (sw) ? sw_sec : w_sec;
    assign final_min  = (sw) ? sw_min : w_min;
    assign final_hour = (sw) ? sw_hour : w_hour;

    wire w_runstop, w_clear, w_mode;
    wire b_hour_up, b_hour_down, b_min_up, b_min_down;

    wire btnR_watch = (!sw) ? btnR : 1'b0;
    wire btnL_watch = (!sw) ? btnL : 1'b0;
    wire btnU_watch = (!sw) ? btnU : 1'b0;
    wire btnD_watch = (!sw) ? btnD : 1'b0;

    wire btnR_stopwatch = (sw) ? btnR : 1'b0;
    wire btnL_stopwatch = (sw) ? btnL : 1'b0;
    wire btnD_stopwatch = (sw) ? btnD : 1'b0;


    stopwatch_control_unit U_STOPWATCH_CONTROL_UNIT (
        .clk(clk),
        .rst(rst),
        .sw1(sw),
        .i_mode(btnD_stopwatch),
        .i_clear(btnL_stopwatch),
        .i_run_stop(btnR_stopwatch),
        .o_run_stop(w_runstop),
        .o_clear(w_clear),
        .o_mode(w_mode)
    );

    stopwatch_datapath U_STOPWATCH_DATAPATH (
        .clk(clk),
        .rst(rst),
        .i_runstop(w_runstop),
        .i_clear(w_clear),
        .i_mode(w_mode),
        .msec(sw_msec),
        .sec(sw_sec),
        .min(sw_min),
        .hour(sw_hour)
    );

    watch_control_unit U_WATCH_CONTROL_UNIT (
        .clk(clk),
        .rst(rst),
        .sw1(sw),
        .i_btnR(btnR_watch),
        .i_btnL(btnL_watch),
        .i_btnD(btnD_watch),
        .i_btnU(btnU_watch),
        .o_btn_hour_up(b_hour_up),
        .o_btn_hour_down(b_hour_down),
        .o_btn_min_up(b_min_up),
        .o_btn_min_down(b_min_down)
    );

    watch_datapath U_WATCH_DATAPATH (
        .clk(clk),
        .rst(rst),
        .b_hour_up(b_hour_up),
        .b_hour_down(b_hour_down),
        .b_min_up(b_min_up),
        .b_min_down(b_min_down),
        .msec(w_msec),
        .sec(w_sec),
        .min(w_min),
        .hour(w_hour)
    );


endmodule

//watch
module watch_datapath #(
    parameter MSEC_WIDTH = 7,
    SEC_WIDTH = 6,
    MIN_WIDTH = 6,
    HOUR_WIDTH = 5
) (
    input clk,
    input rst,
    input b_hour_up,
    input b_hour_down,
    input b_min_up,
    input b_min_down,
    output [MSEC_WIDTH - 1:0] msec,  // 0~99
    output [SEC_WIDTH - 1:0] sec,  // 0~59
    output [MIN_WIDTH - 1:0] min,  // 0~59
    output [HOUR_WIDTH - 1:0] hour  // 0~23
);

    wire w_tick_100hz;
    wire t_msec_up;
    wire t_sec_up;
    wire w_min_up, w_min_down;


    watch_tick_gen_100hz U_TICK_GEN_100HZ_W (
        .clk(clk),
        .rst(rst),
        .o_tick_100hz(w_tick_100hz)
    );


    watch_tick_counter #(
        .TIMES(100),
        .BIT_WIDTH(MSEC_WIDTH),
        .INITIAL_VALUE(0)
    ) U_MSEC_TICK_COUNTER_W (
        .clk(clk),
        .rst(rst),
        .i_btn_up_tick(1'b0),
        .i_btn_down_tick(1'b0),
        .i_time_tick_up(w_tick_100hz),
        .i_time_tick_down(1'b0),
        .time_counter(msec),
        .o_tick_up(t_msec_up),
        .o_tick_down(1'b0)
    );


    watch_tick_counter #(
        .TIMES(60),
        .BIT_WIDTH(SEC_WIDTH),
        .INITIAL_VALUE(0)
    ) U_SEC_TICK_COUNTER_W (
        .clk(clk),
        .rst(rst),
        .i_btn_up_tick(1'b0),
        .i_btn_down_tick(1'b0),
        .i_time_tick_up(t_msec_up),
        .i_time_tick_down(1'b0),
        .time_counter(sec),
        .o_tick_up(t_sec_up),
        .o_tick_down(1'b0)
    );


    watch_tick_counter #(
        .TIMES(60),
        .BIT_WIDTH(MIN_WIDTH),
        .INITIAL_VALUE(0)
    ) U_MIN_TICK_COUNTER_W (
        .clk(clk),
        .rst(rst),
        .i_btn_up_tick(b_min_up),
        .i_btn_down_tick(b_min_down),
        .i_time_tick_up(t_sec_up),
        .i_time_tick_down(1'b0),
        .time_counter(min),
        .o_tick_up(w_min_up),
        .o_tick_down(w_min_down)
    );


    watch_tick_counter #(
        .TIMES(24),
        .BIT_WIDTH(HOUR_WIDTH),
        .INITIAL_VALUE(12)
    ) U_HOUR_TICK_COUNTER_W (
        .clk(clk),
        .rst(rst),
        .i_btn_up_tick(b_hour_up),
        .i_btn_down_tick(b_hour_down),
        .i_time_tick_up(w_min_up),
        .i_time_tick_down(w_min_down),
        .time_counter(hour),
        .o_tick_up(1'b0),
        .o_tick_down(1'b0)
    );

endmodule



module watch_tick_gen_100hz (
    input clk,
    input rst,
    output reg o_tick_100hz
);

    parameter F_COUNT = 1_000_000;  //100hz
    reg [$clog2(F_COUNT)-1:0] counter_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg  <= 0;
            o_tick_100hz <= 0;
        end else if (counter_reg == F_COUNT - 1) begin
            counter_reg  <= 0;
            o_tick_100hz <= 1;
        end else begin
            counter_reg  <= counter_reg + 1;
            o_tick_100hz <= 0;
        end
    end
endmodule


module watch_tick_counter #(
    parameter TIMES = 100,
    BIT_WIDTH = 7,
    INITIAL_VALUE = 0
) (
    input clk,
    input rst,
    input i_btn_up_tick,
    input i_btn_down_tick,
    input i_time_tick_up,
    input i_time_tick_down,
    output [BIT_WIDTH - 1 : 0] time_counter,
    output reg o_tick_up,
    output reg o_tick_down
);

    reg [BIT_WIDTH-1:0] counter_reg, counter_next;
    assign time_counter = counter_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= INITIAL_VALUE;
        end else begin
            counter_reg <= counter_next;
        end
    end

    always @(*) begin
        counter_next = counter_reg;
        o_tick_up = 1'b0;
        o_tick_down = 1'b0;

        if (i_btn_up_tick || i_time_tick_up) begin
            counter_next = counter_reg + 1;
            if (counter_reg == TIMES - 1) begin
                counter_next = 0;
                o_tick_up = 1;
            end
        end else if (i_btn_down_tick || i_time_tick_down) begin
            counter_next = counter_reg - 1;
            if (counter_reg == 0) begin
                counter_next = TIMES - 1;
                o_tick_down  = 1;
            end
        end
    end
endmodule



module watch_control_unit (
    input clk,
    input rst,
    input sw1,
    input i_btnR,
    input i_btnL,
    input i_btnD,
    input i_btnU,
    output reg o_btn_hour_up,
    output reg o_btn_hour_down,
    output reg o_btn_min_up,
    output reg o_btn_min_down,
    output [1:0] o_watch_state
);

    parameter [1:0] WATCH = 2'b00, HOUR_SET = 2'b01, MIN_SET = 2'b10;

    reg [1:0] c_state, n_state;

    always @(posedge clk, posedge rst) begin
        if (rst) c_state <= WATCH;
        else c_state <= n_state;
    end

    assign o_watch_state = c_state;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            o_btn_hour_up <= 1'b0;
            o_btn_hour_down <= 1'b0;
            o_btn_min_up <= 1'b0;
            o_btn_min_down <= 1'b0;
        end else begin
            o_btn_hour_up <= 1'b0;
            o_btn_hour_down <= 1'b0;
            o_btn_min_up <= 1'b0;
            o_btn_min_down <= 1'b0;

            case (c_state)
                HOUR_SET: begin
                    if (i_btnU) o_btn_hour_up <= 1'b1;
                    else if (i_btnD) o_btn_hour_down <= 1'b1;
                end
                MIN_SET: begin
                    if (i_btnU) o_btn_min_up <= 1'b1;
                    else if (i_btnD) o_btn_min_down <= 1'b1;
                end

                default: ;
            endcase
        end
    end


    always @(*) begin
        n_state = c_state;
        case (c_state)
            WATCH: begin
                if (i_btnR) n_state = HOUR_SET;
                else if (i_btnL) n_state = MIN_SET;
            end
            HOUR_SET: begin
                if (i_btnR) n_state = MIN_SET;
                else if (i_btnL) n_state = WATCH;
            end
            MIN_SET: begin
                if (i_btnR) n_state = WATCH;
                else if (i_btnL) n_state = HOUR_SET;
            end
            default: n_state = WATCH;
        endcase
    end

endmodule



//stopwatch
module stopwatch_datapath #(
    parameter MSEC_WIDTH = 7,
    SEC_WIDTH = 6,
    MIN_WIDTH = 6,
    HOUR_WIDTH = 5
) (
    input clk,
    input rst,
    input i_runstop,
    input i_clear,
    input i_mode,
    output [MSEC_WIDTH - 1:0] msec,
    output [SEC_WIDTH  - 1:0] sec,
    output [MIN_WIDTH  - 1:0] min,
    output [HOUR_WIDTH - 1:0] hour
);

    wire w_tick_100hz, w_sec_tick, w_min_tick, w_hour_tick;


    stopwatch_tick_gen_100hz U_TICK_GEN_100HZ_SW (
        .clk(clk),
        .rst(rst),
        .i_runstop(i_runstop),
        .i_clear(1'b0),
        .o_tick(w_tick_100hz)
    );


    stopwatch_tick_counter #(
        .TIMES(100),
        .BIT_WIDTH(MSEC_WIDTH)
    ) U_MSEC_TICK_COUNTER_SW (
        .clk(clk),
        .rst(rst),
        .i_tick(w_tick_100hz),
        .i_clear(i_clear),
        .i_mode(i_mode),
        .time_counter(msec),
        .o_tick(w_sec_tick)
    );


    stopwatch_tick_counter #(
        .TIMES(60),
        .BIT_WIDTH(SEC_WIDTH)
    ) U_SEC_TICK_COUNTER_SW (
        .clk(clk),
        .rst(rst),
        .i_tick(w_sec_tick),
        .i_clear(i_clear),
        .i_mode(i_mode),
        .time_counter(sec),
        .o_tick(w_min_tick)
    );


    stopwatch_tick_counter #(
        .TIMES(60),
        .BIT_WIDTH(MIN_WIDTH)
    ) U_MIN_TICK_COUNTER_SW (
        .clk(clk),
        .rst(rst),
        .i_tick(w_min_tick),
        .i_clear(i_clear),
        .i_mode(i_mode),
        .time_counter(min),
        .o_tick(w_hour_tick)
    );


    stopwatch_tick_counter #(
        .TIMES(24),
        .BIT_WIDTH(HOUR_WIDTH)
    ) U_HOUR_TICK_COUNTER_SW (
        .clk(clk),
        .rst(rst),
        .i_tick(w_hour_tick),
        .i_clear(i_clear),
        .i_mode(i_mode),
        .time_counter(hour),
        .o_tick()
    );

endmodule

module stopwatch_tick_counter #(
    parameter TIMES = 100,  // 가장 큰 수
    BIT_WIDTH = 7
) (
    input clk,
    input rst,
    input i_tick,
    input i_clear,
    input i_mode,
    output [BIT_WIDTH - 1 : 0] time_counter,
    output reg o_tick
);

    // counter register
    reg [BIT_WIDTH-1:0] counter_reg, counter_next;
    assign time_counter = counter_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
        end else begin
            counter_reg <= counter_next;
        end
    end

    //next counter CL : blocking =
    always @(*) begin
        counter_next = counter_reg;
        o_tick = 1'b0;
        if (i_tick) begin
            if (i_mode) begin
                counter_next = counter_reg - 1;
                if (counter_reg == 0) begin
                    counter_next = TIMES - 1;
                    o_tick = 1;
                end else begin
                    o_tick = 1'b0;
                end
            end else begin
                counter_next = counter_reg + 1;
                if (counter_reg == TIMES - 1) begin
                    o_tick = 1;
                    counter_next = 0;
                end else begin
                    o_tick = 0;
                end
            end
        end else if (i_clear) begin
            counter_next = 0;
            o_tick = 1'b0;
        end
    end

endmodule


module stopwatch_tick_gen_100hz (
    input clk,
    input rst,
    input i_runstop,
    input i_clear,
    output reg o_tick
);

    parameter F_COUNT = 1_000_000;  //100hz

    reg [$clog2(F_COUNT)-1:0] counter_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            o_tick <= 1'b0;
        end else begin
            if (i_clear) begin
                counter_reg <= 0;
                o_tick <= 1'b0;
            end else if (i_runstop) begin
                if (counter_reg == F_COUNT - 1) begin
                    counter_reg <= 0;
                    o_tick <= 1'b1;
                end else begin
                    counter_reg <= counter_reg + 1;
                    o_tick <= 1'b0;
                end
            end else begin
                o_tick <= 1'b0;
            end
        end
    end
endmodule





module stopwatch_control_unit (
    input clk,
    input rst,
    input sw1,
    input i_mode,
    input i_clear,
    input i_run_stop,
    output reg o_run_stop,
    output reg o_clear,
    output o_mode
);

    parameter [1:0] STOP = 2'b00, RUN = 2'b01, CLEAR = 2'b10, MODE = 2'b11;

    reg [1:0] c_state, n_state;
    reg mode_reg, mode_next;


    assign o_mode = mode_reg;


    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state  <= STOP;
            mode_reg <= 1'b0;
        end else begin
            c_state  <= n_state;
            mode_reg <= mode_next;
        end
    end


    always @(*) begin
        n_state = c_state;
        mode_next = mode_reg;
        o_clear = 1'b0;
        o_run_stop = 1'b0;

        case (c_state)
            STOP: begin
                o_run_stop = 1'b0;
                o_clear = 1'b0;
                if (i_run_stop) begin
                    n_state = RUN;
                end else if (i_clear) begin
                    n_state = CLEAR;
                end else if (i_mode) begin
                    n_state = MODE;
                end else begin
                    n_state = STOP;
                end
            end

            RUN: begin
                o_run_stop = 1'b1;
                if (i_run_stop) begin
                    n_state = STOP;
                end
            end

            CLEAR: begin
                o_clear = 1'b1;
                n_state = STOP;
            end

            MODE: begin
                mode_next = ~mode_reg;
                n_state   = STOP;
            end

            default: n_state = STOP;
        endcase
    end

endmodule
