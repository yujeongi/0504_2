`timescale 1ns / 1ps

module ascii_sender (
    input clk,
    input rst,
    input status,
    input full,
    input [3:0] sw, //sw[2], sw[3]만 쓸건데 일단은 걍 다받음
    //{sw[2], sw[3]} = 00:stopwatch, 01:watch, 10:SR04, 11:DHT11
    input [31:0] data_in,
    output push,
    output [7:0] data_out
);
    parameter   IDLE= 0,
                SEND_DATA_MSB=1,
                SEND_DATA_2=2,
                SEND_DATA_3=3,
                SEND_DATA_4=4,
                SEND_DATA_5 = 5,
                SEND_DATA_6 = 6,
                SEND_DATA_7 = 7,
                SEND_DATA_LSB = 8,
                SEND_UNIT_PERCENT = 9, //'%' 전송
    SEND_UNIT_STAR = 10,  //'*' 전송
    SEND_UNIT_CM = 11,  // 'cm' 전송
    SEND_UNIT_COLON = 12,  //':' 전송
    SEND_BLANK = 13,
                WAIT_DATA_2=14,
                WAIT_DATA_4=15,
                WAIT_DATA_6=16,
                WAIT_DATA_LSB=17,
                WAIT_BLANK = 18;

    reg push_reg, push_next;
    reg [4:0] c_state, n_state;
    reg [7:0] data_out_reg, data_out_next;
    reg [1:0] cm_cnt_reg, cm_cnt_next;  // for cm_cnt_next
    reg [2:0] time_cnt_reg, time_cnt_next;
    //reg status_reg;

    assign push = push_reg;
    assign data_out = data_out_reg;

    //wire status_pulse = status & ~status_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            push_reg     <= 0;
            c_state      <= 0;
            data_out_reg <= 0;
            cm_cnt_reg   <= 0;
            time_cnt_reg <= 0;
            //status_reg   <= 0;
        end else begin
            push_reg     <= push_next;
            c_state      <= n_state;
            data_out_reg <= data_out_next;
            cm_cnt_reg   <= cm_cnt_next;
            time_cnt_reg <= time_cnt_next;
            //status_reg   <= status;
        end
    end

    always @(*) begin
        push_next     = 1'b0;
        n_state       = c_state;
        data_out_next = data_out_reg;
        cm_cnt_next   = cm_cnt_reg;
        time_cnt_next = time_cnt_reg;
        case (c_state)
            IDLE: begin
                if (status && !full) begin
                    push_next = 0;
                    n_state   = SEND_DATA_MSB;
                end
            end
            SEND_DATA_MSB: begin
                if (!full) begin
                    push_next = 1;
                    data_out_next = {4'h3, data_in[31:28]};
                    n_state = SEND_DATA_2;
                end
            end
            SEND_DATA_2: begin
                if (!full) begin
                    push_next = 1;
                    data_out_next = {4'h3, data_in[27:24]};
                    n_state = WAIT_DATA_2;
                end
            end
            WAIT_DATA_2: begin
                push_next = 0;
                if (!sw[3]) begin  //timer
                    time_cnt_next = 0;
                    n_state = SEND_UNIT_COLON;
                end else if (sw[3]) begin // sensor
                    n_state = SEND_DATA_3;
                end
            end
            SEND_DATA_3: begin
                if (!full) begin
                    push_next = 1;
                    data_out_next = {4'h3, data_in[23:20]};
                    n_state = SEND_DATA_4;
                end
            end
            SEND_DATA_4: begin
                if (!full) begin
                    push_next = 1;
                    data_out_next = {4'h3, data_in[19:16]};
                    n_state = WAIT_DATA_4;
                end
            end
            WAIT_DATA_4: begin
                push_next=0;
                if (!sw[3]) begin  //timer
                    n_state = SEND_UNIT_COLON;
                end else if (sw[3]) begin //sensor
                    n_state = SEND_DATA_5;
                end
            end
            SEND_DATA_5: begin
                if (!full) begin
                    push_next = 1;
                    data_out_next = {4'h3, data_in[15:12]};
                    n_state = SEND_DATA_6;
                end
            end
            SEND_DATA_6: begin
                if (!full) begin
                    push_next = 1;
                    data_out_next = {4'h3, data_in[11:8]};
                    n_state = WAIT_DATA_6;
                end
            end
            WAIT_DATA_6: begin
                push_next=0;
                if (sw[3] && sw[2]) begin  //sensor, dht11
                    n_state = SEND_UNIT_PERCENT;
                end else if (!sw[3]) begin  //timer
                    n_state = SEND_UNIT_COLON;
                end else if (sw[3] && !sw[2]) begin //sensor, sr04
                    n_state = SEND_DATA_7;
                end
            end
            SEND_DATA_7: begin
                if (!full) begin
                    push_next = 1;
                    data_out_next = {4'h3, data_in[7:4]};
                    n_state = SEND_DATA_LSB;
                end
            end
            SEND_DATA_LSB: begin
                if (!full) begin
                    push_next = 1;
                    data_out_next = {4'h3, data_in[3:0]};
                    n_state = WAIT_DATA_LSB;
                end
            end
            WAIT_DATA_LSB: begin
                push_next=0;
                if (sw[3] && sw[2]) begin  //dht11
                    n_state = SEND_UNIT_STAR;
                end else if (sw[3] && !sw[2]) begin  //sr04
                    cm_cnt_next = 0;
                    n_state = SEND_UNIT_CM;
                end
            end
            SEND_UNIT_PERCENT: begin
                if (!full) begin
                    push_next = 1;
                    data_out_next = 8'h25;  // %
                    n_state = SEND_DATA_7;
                end
            end
            SEND_UNIT_STAR: begin
                if (!full) begin
                    push_next = 1;
                    data_out_next = 8'h2a;  // *
                    n_state = SEND_BLANK;
                end
            end
            SEND_UNIT_CM: begin
                if (!full) begin
                    if (cm_cnt_reg == 1) begin
                        push_next = 1;
                        data_out_next = 8'h6d;  //m
                        n_state = SEND_BLANK;
                    end else begin
                        push_next = 1;
                        cm_cnt_next = cm_cnt_reg + 1;
                        data_out_next = 8'h63;  //c
                        n_state = SEND_UNIT_CM;
                    end
                end
            end
            SEND_UNIT_COLON: begin
                if (!full) begin
                    push_next = 1;
                    data_out_next = 8'h3a;  // :
                    case (time_cnt_reg)
                        0: n_state = SEND_DATA_3;
                        1: n_state = SEND_DATA_5;
                        2: n_state = SEND_DATA_7;
                        3: n_state = SEND_BLANK;
                        default: n_state = SEND_BLANK; //예상치 못한 값일때 탈출
                    endcase
                    time_cnt_next = time_cnt_reg + 1;
                end
            end
            SEND_BLANK: begin
                if (!full) begin
                    push_next = 1;
                    cm_cnt_next = 0;
                    time_cnt_next = 0;
                    data_out_next = 8'h20;  //Space
                    n_state = IDLE;
                end
            end
        endcase
    end
endmodule
