`timescale 1ns / 1ps

module uart (
    input        clk,
    input        rst,
    input        tx_start,
    input  [7:0] tx_data,   //tx_data
    input        rx,
    output [7:0] rx_data,
    output       rx_done,
    output       tx_busy,
    output       tx
);

    wire w_b_tick;

    uart_rx U_UART_RX (
        .clk(clk),
        .rst(rst),
        .b_tick(w_b_tick),
        .rx(rx),
        .rx_data(rx_data),
        .rx_done(rx_done)
    );


    uart_tx U_UART_TX (
        .clk     (clk),
        .rst     (rst),       //fsm 이니까
        .tx_start(tx_start),  // start trigger
        .tx_data (tx_data),   //0000_1100 : ascii '0'
        .b_tick  (w_b_tick),
        .tx_busy (tx_busy),
        .tx      (tx)
    );

    baud_tick_gen U_BAUD_TICK_GEN (
        .clk     (clk),
        .rst     (rst),
        .o_b_tick(w_b_tick)
    );

endmodule


//verification 할 때 uart 씀.
module uart_rx (
    input        clk,
    input        rst,
    input        b_tick,
    input        rx,
    output [7:0] rx_data,
    output       rx_done
);

    parameter IDLE = 0, START = 1, DATA = 2, STOP = 3;
    reg [1:0] c_state, n_state;
    reg [4:0] b_tick_cnt_reg, b_tick_cnt_next;
    reg [2:0] bit_cnt_reg, bit_cnt_next;
    reg [7:0] data_reg, data_next;  //내부에서 쓰는것*
    reg rx_done_reg, rx_done_next;  // 동기맞추겟음.

    assign rx_done = rx_done_reg;  //최종연결.
    assign rx_data = data_reg;


    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state        <= IDLE;
            b_tick_cnt_reg <= 0;
            bit_cnt_reg    <= 0;
            data_reg       <= 8'h00;
            rx_done_reg    <= 1'b0;
        end else begin
            c_state        <= n_state;
            b_tick_cnt_reg <= b_tick_cnt_next;
            bit_cnt_reg    <= bit_cnt_next;
            data_reg       <= data_next;
            rx_done_reg    <= rx_done_next;
        end
    end

    //next, output
    always @(*) begin
        n_state         = c_state;
        b_tick_cnt_next = b_tick_cnt_reg;
        bit_cnt_next    = bit_cnt_reg;
        data_next       = data_reg;
        rx_done_next    = rx_done_reg;
        case (c_state)
            IDLE: begin
                rx_done_next = 1'b0; //STOP에서 IDLE로 변하는 순간. 왠진 모름 씨앙~!!
                if (b_tick && (!rx)) begin
                    b_tick_cnt_next = 0;
                    n_state = START;
                end
            end
            START: begin
                if (b_tick) begin
                    if (b_tick_cnt_reg == 7) begin
                        b_tick_cnt_next = 0;
                        bit_cnt_next    = 0;
                        n_state         = DATA;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
            DATA: begin
                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin
                        // bit right shift
                        data_next = {rx, data_reg[7:1]};  //shift
                        b_tick_cnt_next = 0;
                        if (bit_cnt_reg == 7) begin
                            b_tick_cnt_next = 0;  //빼먹엇네염
                            n_state         = STOP;
                        end else begin
                            bit_cnt_next = bit_cnt_reg + 1;
                        end
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
            STOP: begin
                if (b_tick) begin
                    //if (b_tick_cnt_reg == 23 || (b_tick_cnt_reg>16) && !rx) begin //23->15
                    if (b_tick_cnt_reg == 23) begin 
                        rx_done_next = 1'b1; //다음상승엣지에서 IDLE되면 0으로 변함. 한클럭의 tick됨.
                        n_state = IDLE;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
            default: ;
        endcase
    end


endmodule


module uart_tx (
    input        clk,
    input        rst,       //fsm 이니까
    input        tx_start,  // start trigger
    input  [7:0] tx_data,
    input        b_tick,
    output       tx_busy,
    output       tx
);

    parameter IDLE = 0, START = 1;
    parameter DATA = 2, STOP = 3;

    reg [1:0] c_state, n_state;  //state parameter 바뀌면 바뀌어야.
    reg tx_reg, tx_next;
    //tx data register
    reg [7:0] data_reg, data_next;  //next는 always의 출력 개념.
    reg [2:0] bit_count_reg, bit_count_next;
    reg [3:0] b_tick_cnt_reg, b_tick_cnt_next;
    reg tx_busy_reg, tx_busy_next;

    assign tx = tx_reg;
    assign tx_busy = tx_busy_reg;



    //state register
    // currnet: output, next:input
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state        <= IDLE;
            tx_reg         <= 1'b1;  // tx==0이 스타트.
            data_reg       <= 8'h00;
            bit_count_reg  <= 3'b000;
            b_tick_cnt_reg <= 4'h0;
            tx_busy_reg    <= 1'b0;
        end else begin
            c_state        <= n_state;
            tx_reg         <= tx_next;
            data_reg       <= data_next;
            bit_count_reg  <= bit_count_next;
            b_tick_cnt_reg <= b_tick_cnt_next;
            tx_busy_reg    <= tx_busy_next;
        end
    end


    // next st CL, output
    // output을 밀리도 해도 된다는데 뭔솔
    // output은 순차논리
    // blahblah_next는 조합논리에서 쓰는 값
    always @(*) begin
        n_state         = c_state;  // n_state
        tx_next         = tx_reg;  // tx output
        data_next       = data_reg;
        bit_count_next  = bit_count_reg;  //CL이니까 초기화. 유지.
        tx_busy_next    = tx_busy_reg;
        b_tick_cnt_next = b_tick_cnt_reg;
        case (c_state)
            IDLE: begin
                tx_next = 1'b1;
                tx_busy_next = 1'b0; //idle에서는 모든걸 초기화시키면 좋으니깐...
                if (tx_start) begin  // 비동기신호
                    tx_busy_next = 1'b1; // start에 들어가는것보다 한클럭 더 빨리 가기위해 밀리 처리.
                    data_next = tx_data;
                    b_tick_cnt_next = 0;
                    n_state = START;
                end
            end
            START: begin
                tx_next = 1'b0;
                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin
                        b_tick_cnt_next = 0;
                        bit_count_next = 3'b000; // 여기다 말고 다른데 넣으면 타이밍이 바뀌는 것.
                        n_state = DATA;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
            DATA: begin
                //parallel output
                //tx_next = data_reg[bit_count_reg];

                //to output from bit0 of data_reg
                tx_next = data_reg[0];

                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin
                        b_tick_cnt_next = 0;  // 무조건 초기화
                        if (bit_count_reg == 7) begin
                            n_state = STOP;
                        end else begin
                            //right shift 1bit data register -> PISO
                            //베릴로그적인 shift표현
                            data_next = {
                                1'b0, data_reg[7:1]
                            };  //틱이 발생할 때
                            bit_count_next = bit_count_reg + 1; //현재값에서 하나 더해서 다음 값을 바꿔라. 다음 상승 엣지에서
                            n_state = DATA;
                        end
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
            STOP: begin
                tx_next = 1'b1;
                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin
                        tx_busy_next = 1'b0;
                        n_state = IDLE;

                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end  //default 안써도 됨.
        endcase

    end

    //bit_count를 0~7 변수 3비트
    //state를 idle, wait, start, stop, bit 5개로 줄이기
    //asm 두 버전 비교
    //시뮬레이션 두 버전 비교
    //reg, next 따로 두는게 이해안되면 해보든가. 래치 안만들고.
    //반복문 아님. bit_count register를 둬서 같은 로직을 쓰겟다는거임.


endmodule


//  bayd tucj * 16
module baud_tick_gen (
    input clk,
    input rst,
    output reg o_b_tick
);

    //baud tick 9600 tick gen
    parameter F_COUNT = 100_000_000 / (9600 * 16);  //16배속
    parameter WIDTH = $clog2(F_COUNT) - 1;

    reg [WIDTH:0] counter_reg;

    always @(posedge clk, posedge rst) begin  //rst은 비동기
        if (rst) begin // o_b_tick이라는 output reg있고 rst시키면 플립플롭 하나 만든거임.
            counter_reg <= 0;
            o_b_tick <= 1'b0;
        end else begin
            // period 9600 hz
            counter_reg <= counter_reg + 1;  // 잘 설명하래...
            if (counter_reg == F_COUNT - 1) begin
                counter_reg <= 0;  //9601x, 9600o
                o_b_tick <= 1;
            end else begin
                o_b_tick <= 1'b0;
            end
        end
    end

endmodule
