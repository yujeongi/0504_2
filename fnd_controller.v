`timescale 1ns / 1ps

module fnd_controller #(  //stopwatch,watch
    parameter MSEC_WIDTH = 7,
    SEC_WIDTH = 6,
    MIN_WIDTH = 6,
    HOUR_WIDTH = 5,
    DIST_WIDTH = 9,  //sr04
    HUMID_WIDTH = 8,  //dht11
    TEMP_WIDTH = 8  //dht11
) (
    input                     clk,
    input                     rst,
    input  [             3:0] sw,
    input  [MSEC_WIDTH - 1:0] msec,
    input  [ SEC_WIDTH - 1:0] sec,
    input  [ MIN_WIDTH - 1:0] min,
    input  [HOUR_WIDTH - 1:0] hour,
    input  [  DIST_WIDTH-1:0] distance,     //sr04
    input  [ HUMID_WIDTH-1:0] humidity,     //dht11
    input  [  TEMP_WIDTH-1:0] temperature,  //dht11
    output [             3:0] led,
    output [             3:0] fnd_com,
    output [             7:0] fnd_data,
    output [            31:0] out_digit     // to pc
);

    wire [3:0] w_out_mux_time, w_out_mux_msec_sec, w_out_mux_min_hour;
    wire [3:0] w_out_mux_sensor, w_out_mux_dist, w_out_mux_temp_humid;
    wire [3:0] w_out_mux;
    wire [3:0] w_msec_digit_1, w_msec_digit_10;
    wire [3:0] w_sec_digit_1, w_sec_digit_10;
    wire [3:0] w_min_digit_1, w_min_digit_10;
    wire [3:0] w_hour_digit_1, w_hour_digit_10;
    wire [3:0] w_dist_digit_1, w_dist_digit_10, w_dist_digit_100, w_dist_digit_1000;
    wire [3:0] w_humid_digit_1, w_humid_digit_10, w_temp_digit_1, w_temp_digit_10;
    wire [2:0] w_digit_sel;  //counter 8
    wire w_1khz;
    wire w_dotonoff;

    wire [31:0] data_bank[0:3];
    assign data_bank[0] = { //watch
        w_hour_digit_10,
        w_hour_digit_1,
        w_min_digit_10,
        w_min_digit_1,
        w_sec_digit_10,
        w_sec_digit_1,
        w_msec_digit_10,
        w_msec_digit_1
    };
    assign data_bank[1] = { //stopwatch
        w_hour_digit_10,
        w_hour_digit_1,
        w_min_digit_10,
        w_min_digit_1,
        w_sec_digit_10,
        w_sec_digit_1,
        w_msec_digit_10,
        w_msec_digit_1
    };
    assign data_bank[2] = { //sr04
        16'h0000,
        w_dist_digit_1000,
        w_dist_digit_100,
        w_dist_digit_10,
        w_dist_digit_1
    };
    assign data_bank[3] = { //dht11
        16'h0000,
        w_humid_digit_10,
        w_humid_digit_1,
        w_temp_digit_10,
        w_temp_digit_1
    };
    wire [1:0] select = (sw[3]) ? {1'b1, sw[2]} : {1'b0, sw[1]}; //00: watch, 01:stopwatch, 10: sr04, 11:dht11
    assign out_digit = data_bank[select];

    assign led = sw;


    //digit split
    digit_splitter #(
        .BIT_WIDTH(MSEC_WIDTH)
    ) U_MSEC_DS (
        .digit_in(msec),
        .digit_1 (w_msec_digit_1),
        .digit_10(w_msec_digit_10)
    );

    digit_splitter #(
        .BIT_WIDTH(SEC_WIDTH)
    ) U_SEC_DS (
        .digit_in(sec),
        .digit_1 (w_sec_digit_1),
        .digit_10(w_sec_digit_10)
    );

    digit_splitter #(
        .BIT_WIDTH(MIN_WIDTH)
    ) U_MIN_DS (
        .digit_in(min),
        .digit_1 (w_min_digit_1),
        .digit_10(w_min_digit_10)
    );

    digit_splitter #(
        .BIT_WIDTH(HOUR_WIDTH)
    ) U_HOUR_DS (
        .digit_in(hour),
        .digit_1 (w_hour_digit_1),
        .digit_10(w_hour_digit_10)
    );

    digit_splitter_sr04 U_SR04_DS (
        .digit_in(distance),
        .digit_1(w_dist_digit_1),
        .digit_10(w_dist_digit_10),
        .digit_100(w_dist_digit_100),
        .digit_1000(w_dist_digit_1000)
    );

    digit_splitter_dht11 U_DHT11_DS (
        .digit_in_humid(humidity),
        .digit_in_temp (temperature),
        .digit_1_temp  (w_temp_digit_1),
        .digit_10_temp (w_temp_digit_10),
        .digit_1_humid (w_humid_digit_1),
        .digit_10_humid(w_humid_digit_10)
    );


    comparator U_COMP_DOTONOFF (
        .comp_in  (msec),
        .dot_onoff(w_dotonoff)
    );

    mux_8x1 U_MUX_MSEC_SEC (
        .in0(w_msec_digit_1),
        .in1(w_msec_digit_10),
        .in2(w_sec_digit_1),
        .in3(w_sec_digit_10),
        .in4(4'hF),
        .in5(4'hF),
        .in6({3'b111, w_dotonoff}),  // for dot display
        .in7(4'hF),
        .sel(w_digit_sel),  // to select input
        .out_mux(w_out_mux_msec_sec)  //OR output reg
    );

    mux_8x1 U_MUX_MIN_HOUR (
        .in0(w_min_digit_1),
        .in1(w_min_digit_10),
        .in2(w_hour_digit_1),
        .in3(w_hour_digit_10),
        .in4(4'hF),
        .in5(4'hF),
        .in6({3'b111, w_dotonoff}),
        .in7(4'hF),
        .sel(w_digit_sel),
        .out_mux(w_out_mux_min_hour)
    );

    mux_8x1 U_MUX_SR04 (
        .in0(w_dist_digit_1),
        .in1(w_dist_digit_10),
        .in2(w_dist_digit_100),
        .in3(w_dist_digit_1000),
        .in4(4'hF),
        .in5(4'hF),
        .in6({3'b111, w_dotonoff}),
        .in7(4'hF),
        .sel(w_digit_sel),
        .out_mux(w_out_mux_dist)
    );

    mux_8x1 U_MUX_DHT11 (
        .in0(w_temp_digit_1),
        .in1(w_temp_digit_10),
        .in2(w_humid_digit_1),
        .in3(w_humid_digit_10),
        .in4(4'hF),
        .in5(4'hF),
        .in6({3'b111, w_dotonoff}),
        .in7(4'hF),
        .sel(w_digit_sel),
        .out_mux(w_out_mux_temp_humid)
    );

    mux_2x1 U_MUX_2x1_time (
        .in0(w_out_mux_msec_sec),
        .in1(w_out_mux_min_hour),
        .sel(sw[0]),
        .out_mux(w_out_mux_time)
    );

    mux_2x1 U_MUX_2x1_sensor (
        .in0(w_out_mux_dist),
        .in1(w_out_mux_temp_humid),
        .sel(sw[2]),
        .out_mux(w_out_mux_sensor)
    );
    mux_2x1 U_MUX_2x1 (
        .in0(w_out_mux_time),
        .in1(w_out_mux_sensor),
        .sel(sw[3]),
        .out_mux(w_out_mux)
    );

    bcd U_BCD (
        .bin(w_out_mux),
        .bcd_data(fnd_data)
    );

    clk_div_1khz U_CLK_DIV_1KHZ (
        .clk(clk),
        .rst(rst),
        .o_1khz(w_1khz)
    );

    counter_8 U_COUNTER_8 (
        .clk(w_1khz),
        .rst(rst),
        .digit_sel(w_digit_sel)
    );

    decoder_2x4 U_DECODER_2x4 (
        .decoder_in(w_digit_sel[1:0]),
        .fnd_com(fnd_com)
    );


endmodule

module comparator (
    input [6:0] comp_in,
    output dot_onoff
);

    assign dot_onoff = (comp_in > 49);  // 0~49ms까지 켜짐.

endmodule


module mux_2x1 (
    input [3:0] in0,  //msec_sec
    input [3:0] in1,  //min_hour
    input sel,
    output [3:0] out_mux
);

    assign out_mux = (sel) ? in1 : in0;

endmodule

module clk_div_1khz (
    input  clk,
    input  rst,
    output o_1khz
);

    reg [15:0] counter_reg;
    reg o_1khz_reg;

    assign o_1khz = o_1khz_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 16'd0;
            o_1khz_reg  <= 1'b0;
        end else begin
            counter_reg <= counter_reg + 1;  //65000까지
            if (counter_reg == 50_000 - 1) begin
                counter_reg <= 16'd0;
                o_1khz_reg  <= ~o_1khz_reg;

            end
        end
    end
endmodule

module counter_8 (
    input clk,
    input rst,
    output [2:0] digit_sel
);

    reg [2:0] counter_reg;


    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
        end else begin
            counter_reg <= counter_reg + 1;
        end
    end
    assign digit_sel = counter_reg;

endmodule


module decoder_2x4 (
    input [1:0] decoder_in,
    output reg [3:0] fnd_com
);

    always @(*) begin
        case (decoder_in)
            2'b00:   fnd_com = 4'b1110;
            2'b01:   fnd_com = 4'b1101;
            2'b10:   fnd_com = 4'b1011;
            2'b11:   fnd_com = 4'b0111;
            default: fnd_com = 4'b1111;
        endcase
    end

endmodule

module digit_splitter #(
    parameter BIT_WIDTH = 7
) (
    input [BIT_WIDTH-1:0] digit_in,
    output [3:0] digit_1,
    output [3:0] digit_10
);

    assign digit_1  = digit_in % 10;  // digit 1
    assign digit_10 = (digit_in / 10) % 10;  // digit 10

endmodule


module digit_splitter_sr04 #(
    parameter BIT_WIDTH = 9
) (
    input [BIT_WIDTH-1:0] digit_in,
    output [3:0] digit_1,
    output [3:0] digit_10,
    output [3:0] digit_100,
    output [3:0] digit_1000
);

    assign digit_1 = digit_in % 10;
    assign digit_10 = (digit_in / 10) % 10;
    assign digit_100 = (digit_in / 100) % 10;
    assign digit_1000 = 4'h0;


endmodule

module digit_splitter_dht11 #(
    parameter BIT_WIDTH = 8
) (
    input [BIT_WIDTH-1:0] digit_in_humid,
    input [BIT_WIDTH-1:0] digit_in_temp,
    output [3:0] digit_1_temp,
    output [3:0] digit_10_temp,
    output [3:0] digit_1_humid,
    output [3:0] digit_10_humid
);

    assign digit_1_temp   = digit_in_temp % 10;
    assign digit_10_temp  = (digit_in_temp / 10) % 10;
    assign digit_1_humid  = digit_in_humid % 10;
    assign digit_10_humid = (digit_in_humid / 10) % 10;


endmodule


module mux_8x1 (
    input [3:0] in0,
    input [3:0] in1,
    input [3:0] in2,
    input [3:0] in3,
    input [3:0] in4,
    input [3:0] in5,
    input [3:0] in6,
    input [3:0] in7,
    input [2:0] sel,  // to select input
    output [3:0] out_mux  //OR output reg
);


    reg [3:0] out_reg;
    assign out_mux = out_reg;


    always @(*) begin
        case (sel)
            3'b000:  out_reg = in0;
            3'b001:  out_reg = in1;
            3'b010:  out_reg = in2;
            3'b011:  out_reg = in3;
            3'b100:  out_reg = in4;
            3'b101:  out_reg = in5;
            3'b110:  out_reg = in6;
            3'b111:  out_reg = in7;
            default: out_reg = 4'b0000;  // or 4'bxxxx
        endcase
    end

endmodule


module bcd (
    input [3:0] bin,
    output reg [7:0] bcd_data
);

    always @(bin) begin
        case (bin)
            4'b0000: bcd_data = 8'hC0;  //0
            4'b0001: bcd_data = 8'hF9;  //1
            4'b0010: bcd_data = 8'hA4;  //2
            4'b0011: bcd_data = 8'hB0;  //3
            4'b0100: bcd_data = 8'h99;  //4
            4'b0101: bcd_data = 8'h92;  //5
            4'b0110: bcd_data = 8'h82;  //6
            4'b0111: bcd_data = 8'hF8;  //7
            4'b1000: bcd_data = 8'h80;  //8
            4'b1001: bcd_data = 8'h90;  //9
            4'b1010: bcd_data = 8'h88;  //A
            4'b1011: bcd_data = 8'h83;  //B
            4'b1100: bcd_data = 8'hC6;  //C
            4'b1101: bcd_data = 8'hA1;  //D
            4'b1110: bcd_data = 8'h7F;  //dot on
            4'b1111: bcd_data = 8'hFF;  //all off
            default: bcd_data = 8'hFF;
        endcase

    end

endmodule
