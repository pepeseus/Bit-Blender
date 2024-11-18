module crc32_mpeg2(
    input wire clk_in,
    input wire rst_in,
    input wire data_valid_in,
    input wire data_in,
    output logic [31:0] data_out
);

    logic outer_line;
    logic hold_1_2;
    logic hold_2_3;
    logic hold_4_5;
    logic hold_5_6;
    logic hold_7_8;
    logic hold_8_9;
    logic hold_10_11;
    logic hold_11_12;
    logic hold_12_13;
    logic hold_16_17;
    logic hold_22_23;
    logic hold_23_24;
    logic hold_26_27;

    assign outer_line = data_in ^ data_out[31];
    assign hold_1_2 = outer_line ^ data_out[0];
    assign hold_2_3 = outer_line ^ data_out[1];
    assign hold_4_5 = outer_line ^ data_out[3];
    assign hold_5_6 = outer_line ^ data_out[4];
    assign hold_7_8 = outer_line ^ data_out[6];
    assign hold_8_9 = outer_line ^ data_out[7];
    assign hold_10_11 = outer_line ^ data_out[9];
    assign hold_11_12 = outer_line ^ data_out[10];
    assign hold_12_13 = outer_line ^ data_out[11];
    assign hold_16_17 = outer_line ^ data_out[15];
    assign hold_22_23 = outer_line ^ data_out[21];
    assign hold_23_24 = outer_line ^ data_out[22];
    assign hold_26_27 = outer_line ^ data_out[25];

    always_ff @(posedge clk_in)begin
        if (rst_in) begin
            data_out <= 32'hFFFF_FFFF;
        end
        else if (data_valid_in) begin
            data_out <= {data_out[30:26], hold_26_27, data_out[24:23], hold_23_24, hold_22_23, data_out[20:16], hold_16_17, data_out[14:12], hold_12_13, hold_11_12, hold_10_11, data_out[8], hold_8_9, hold_7_8, data_out[5], hold_5_6, hold_4_5, data_out[2], hold_2_3, hold_1_2, outer_line};
        end
    end
 
endmodule