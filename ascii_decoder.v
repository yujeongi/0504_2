`timescale 1ns / 1ps

module ascii_decoder (
    input        clk,
    input        rst,
    input  [7:0] key,
    input        i_valid,  //empty
    output       btnR,
    output       btnL,
    output       btnU,
    output       btnD,
    output       btnS,
    output       btnM,
    output       btnT,
    output       pop
);

    parameter IDLE = 0, BTNR = 1, BTNL = 2, BTNU = 3, BTND = 4, BTNS = 5, BTNM=6, BTNT=7;
    reg [2:0] c_state, n_state;
    reg
        btnR_reg,
        btnR_next,
        btnL_reg,
        btnL_next,
        btnU_reg,
        btnU_next,
        btnD_reg,
        btnD_next,
        btnS_reg,
        btnS_next,
        btnM_reg,
        btnM_next,
        btnT_reg,
        btnT_next;
    reg pop_reg, pop_next;

    assign btnR = btnR_reg;
    assign btnL = btnL_reg;
    assign btnU = btnU_reg;
    assign btnD = btnD_reg;
    assign btnS = btnS_reg;
    assign btnM = btnM_reg;
    assign btnT = btnT_reg;
    assign pop  = pop_reg;


    always @(posedge clk, posedge rst) begin
        if (rst) begin
            btnR_reg <= 1'b0;
            btnL_reg <= 1'b0;
            btnU_reg <= 1'b0;
            btnD_reg <= 1'b0;
            btnS_reg <= 1'b0;
            btnM_reg <= 1'b0;
            btnT_reg <= 1'b0;
            pop_reg  <= 1'b0;
            c_state  <= IDLE;
        end else begin
            btnR_reg <= btnR_next;
            btnL_reg <= btnL_next;
            btnU_reg <= btnU_next;
            btnD_reg <= btnD_next;
            btnS_reg <= btnS_next;
            btnM_reg <= btnM_next;
            btnT_reg <= btnT_next;
            pop_reg  <= pop_next;
            c_state  <= n_state;
        end
    end

    always @(*) begin
        btnR_next = 1'b0;
        btnL_next = 1'b0;
        btnU_next = 1'b0;
        btnD_next = 1'b0;
        btnS_next = 1'b0;
        btnM_next = 1'b0;
        btnT_next = 1'b0;
        pop_next  = 1'b0;
        n_state   = c_state;

        case (c_state)
            IDLE: begin
                if (i_valid) begin
                    pop_next = 1'b1;
                    case (key)
                        //BTNR
                        8'h52: begin
                            n_state = BTNR;
                        end
                        8'h72: begin
                            n_state = BTNR;
                        end
                        //BTNL
                        8'h4C: begin
                            n_state = BTNL;
                        end
                        8'h6C: begin
                            n_state = BTNL;
                        end
                        //BTNU
                        8'h55: begin
                            n_state = BTNU;
                        end
                        8'h75: begin
                            n_state = BTNU;
                        end
                        //BTND
                        8'h44: begin
                            n_state = BTND;
                        end
                        8'h64: begin
                            n_state = BTND;
                        end
                        //BTNS  
                        8'h53: begin
                            n_state = BTNS;
                        end
                        8'h73: begin
                            n_state = BTNS;
                        end
                        //BTNM  
                        8'h4D: begin
                            n_state = BTNS;
                        end
                        8'h6D: begin
                            n_state = BTNS;
                        end
                        //BTNT  
                        8'h54: begin
                            n_state = BTNT;
                        end
                        8'h74: begin
                            n_state = BTNT;
                        end
                        default: begin
                            n_state = IDLE;
                        end
                    endcase
                end
            end
            BTNR: begin
                btnR_next = 1'b1;
                n_state   = IDLE;
            end
            BTNL: begin
                btnL_next = 1'b1;
                n_state   = IDLE;
            end
            BTNU: begin
                btnU_next = 1'b1;
                n_state   = IDLE;
            end
            BTND: begin
                btnD_next = 1'b1;
                n_state   = IDLE;
            end
            BTNS: begin
                btnS_next = 1'b1;
                n_state   = IDLE;
            end
            BTNM: begin
                btnM_next = 1'b1;
                n_state   = IDLE;
            end
            BTNT: begin
                btnT_next = 1'b1;
                n_state   = IDLE;
            end
            default: n_state = IDLE;
        endcase
    end



endmodule
