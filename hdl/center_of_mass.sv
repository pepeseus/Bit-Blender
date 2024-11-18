`default_nettype none
module center_of_mass (
                         input wire clk_in,
                         input wire rst_in,
                         input wire [10:0] x_in,
                         input wire [9:0]  y_in,
                         input wire valid_in,
                         input wire tabulate_in,
                         output logic [10:0] x_out,
                         output logic [9:0] y_out,
                         output logic valid_out);

    localparam IDLE = 2'b00;
    localparam ADDING = 2'b01;
    localparam DIVIDING = 2'b10;
    // localparam OUTPUTTING = 2'b11;  // maybe not necessary?

    logic [1:0] state;

    logic [31:0] sum_x;
    logic [31:0] tot_x;

    logic [31:0] sum_y;
    logic [31:0] tot_y;

    logic [31:0] quotient_x;
    logic [31:0] quotient_y;
    logic [31:0] remainder_x;
    logic [31:0] remainder_y;
    logic data_valid_divider_x;
    logic data_valid_divider_y;
    logic error_divider_x;
    logic error_divider_y;
    logic busy_divider_x;
    logic busy_divider_y;

    logic x_good_to_go;
    logic y_good_to_go;

    always_ff @(posedge clk_in) begin

        if (rst_in) begin

            state <= IDLE;
            x_out <= 0;
            y_out <= 0;
            valid_out <= 0;
            sum_x <= 0;
            sum_y <= 0;
            tot_x <= 0;
            tot_y <= 0;
            x_good_to_go <= 0;
            y_good_to_go <= 0;

        end
        else begin

            case (state)

                IDLE: begin

                    valid_out <= 0;

                    if (valid_in) begin
                        state <= ADDING;
                        sum_x <= sum_x + x_in;
                        sum_y <= sum_y + y_in;
                        tot_x <= tot_x + 1;
                        tot_y <= tot_y + 1;

                    end
                    else begin

                        x_out <= 0;
                        y_out <= 0;
                        sum_x <= 0;
                        sum_y <= 0;
                        tot_x <= 0;
                        tot_y <= 0;

                    end

                end

                ADDING: begin

                    valid_out <= 0;

                    if (tabulate_in) begin

                        state <= DIVIDING;
                        x_good_to_go <= 0;
                        y_good_to_go <= 0;

                    end else if (valid_in) begin
                        sum_x <= sum_x + x_in;
                        sum_y <= sum_y + y_in;
                        tot_x <= tot_x + 1;
                        tot_y <= tot_y + 1;
                    end
                end

                DIVIDING: begin

                    if ((x_good_to_go && y_good_to_go) || (data_valid_divider_x && data_valid_divider_y)) begin

                        if (data_valid_divider_x && data_valid_divider_y) begin
                            x_out <= quotient_x;
                            y_out <= quotient_y;
                        end

                            if (valid_in) begin
                                state <= ADDING;
                                sum_x <= x_in;
                                sum_y <= y_in;
                                tot_x <= 1;
                                tot_y <= 1;
                                valid_out <= 1;
                            end
                            else begin
                                state <= IDLE;
                                valid_out <= 1;
                                sum_x <= 0;
                                sum_y <= 0;
                                tot_x <= 0;
                                tot_y <= 0;
                            end

                    end

                    if (data_valid_divider_x && data_valid_divider_y) begin
                        x_out <= quotient_x;
                        x_good_to_go <= 1;

                        y_out <= quotient_y;
                        y_good_to_go <= 1;
                    end
                    if (data_valid_divider_x) begin
                        x_out <= quotient_x;
                        x_good_to_go <= 1;
                    end
                    else if (data_valid_divider_y) begin
                        y_out <= quotient_y;
                        y_good_to_go <= 1;
                    end

                end

            endcase

        end

    end

    divider #(.WIDTH(32)) x_divider (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .dividend_in(sum_x),
        .divisor_in(tot_x),
        .data_valid_in(state == DIVIDING),
        .quotient_out(quotient_x),
        .remainder_out(remainder_x),
        .data_valid_out(data_valid_divider_x),
        .error_out(error_divider_x),
        .busy_out(busy_divider_x)
    );

    divider #(.WIDTH(32)) y_divider (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .dividend_in(sum_y),
        .divisor_in(tot_y),
        .data_valid_in(state == DIVIDING),
        .quotient_out(quotient_y),
        .remainder_out(remainder_y),
        .data_valid_out(data_valid_divider_y),
        .error_out(error_divider_y),
        .busy_out(busy_divider_y)
    );


endmodule

`default_nettype wire