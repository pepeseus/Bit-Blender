module midi_processor(
    input wire clk_in, //system clock
    input wire rst_in, //system reset
    input wire [3:0] status,
    input wire [7:0] data_byte1,
    input wire [7:0] data_byte2, // release velocity; unused for now
    input wire valid_in,
    output logic isNoteOn,
    output logic [23:0] cycles_between_samples,
    output logic valid_out
);


    always_ff @(posedge clk_in or posedge rst_in) begin
        if (rst_in) begin
            isNoteOn <= 1'b0;
            cycles_between_samples <= 24'd747; // middle C
            valid_out <= 0;
        end else if (valid_in) begin
            valid_out <= 1;
            if (status == 4'b1001 && data_byte2 != 8'd0) begin // note on
                isNoteOn <= 1'b1;
            end else begin
                isNoteOn <= 1'b0;
            end

            // Handle cycles_between_samples
            case (data_byte1)
                8'd0: cycles_between_samples <= 24'd23889;
                8'd1: cycles_between_samples <= 24'd22548;
                8'd2: cycles_between_samples <= 24'd21283;
                8'd3: cycles_between_samples <= 24'd20088;
                8'd4: cycles_between_samples <= 24'd18961;
                8'd5: cycles_between_samples <= 24'd17897;
                8'd6: cycles_between_samples <= 24'd16892;
                8'd7: cycles_between_samples <= 24'd15944;
                8'd8: cycles_between_samples <= 24'd15049;
                8'd9: cycles_between_samples <= 24'd14205;
                8'd10: cycles_between_samples <= 24'd13407;
                8'd11: cycles_between_samples <= 24'd12655;
                8'd12: cycles_between_samples <= 24'd11945;
                8'd13: cycles_between_samples <= 24'd11274;
                8'd14: cycles_between_samples <= 24'd10641;
                8'd15: cycles_between_samples <= 24'd10044;
                8'd16: cycles_between_samples <= 24'd9480;
                8'd17: cycles_between_samples <= 24'd8948;
                8'd18: cycles_between_samples <= 24'd8446;
                8'd19: cycles_between_samples <= 24'd7972;
                8'd20: cycles_between_samples <= 24'd7525;
                8'd21: cycles_between_samples <= 24'd7102;
                8'd22: cycles_between_samples <= 24'd6704;
                8'd23: cycles_between_samples <= 24'd6327;
                8'd24: cycles_between_samples <= 24'd5972;
                8'd25: cycles_between_samples <= 24'd5637;
                8'd26: cycles_between_samples <= 24'd5321;
                8'd27: cycles_between_samples <= 24'd5022;
                8'd28: cycles_between_samples <= 24'd4740;
                8'd29: cycles_between_samples <= 24'd4474;
                8'd30: cycles_between_samples <= 24'd4223;
                8'd31: cycles_between_samples <= 24'd3986;
                8'd32: cycles_between_samples <= 24'd3762;
                8'd33: cycles_between_samples <= 24'd3551;
                8'd34: cycles_between_samples <= 24'd3352;
                8'd35: cycles_between_samples <= 24'd3164;
                8'd36: cycles_between_samples <= 24'd2986;
                8'd37: cycles_between_samples <= 24'd2819;
                8'd38: cycles_between_samples <= 24'd2660;
                8'd39: cycles_between_samples <= 24'd2511;
                8'd40: cycles_between_samples <= 24'd2370;
                8'd41: cycles_between_samples <= 24'd2237;
                8'd42: cycles_between_samples <= 24'd2112;
                8'd43: cycles_between_samples <= 24'd1993;
                8'd44: cycles_between_samples <= 24'd1881;
                8'd45: cycles_between_samples <= 24'd1776;
                8'd46: cycles_between_samples <= 24'd1676;
                8'd47: cycles_between_samples <= 24'd1582;
                8'd48: cycles_between_samples <= 24'd1493;
                8'd49: cycles_between_samples <= 24'd1409;
                8'd50: cycles_between_samples <= 24'd1330;
                8'd51: cycles_between_samples <= 24'd1256;
                8'd52: cycles_between_samples <= 24'd1185;
                8'd53: cycles_between_samples <= 24'd1119;
                8'd54: cycles_between_samples <= 24'd1056;
                8'd55: cycles_between_samples <= 24'd997;
                8'd56: cycles_between_samples <= 24'd941;
                8'd57: cycles_between_samples <= 24'd888;
                8'd58: cycles_between_samples <= 24'd838;
                8'd59: cycles_between_samples <= 24'd791; 
                8'd60: cycles_between_samples <= 24'd747; // middle C
                8'd61: cycles_between_samples <= 24'd705;
                8'd62: cycles_between_samples <= 24'd665;
                8'd63: cycles_between_samples <= 24'd628;
                8'd64: cycles_between_samples <= 24'd593;
                8'd65: cycles_between_samples <= 24'd559;
                8'd66: cycles_between_samples <= 24'd528;
                8'd67: cycles_between_samples <= 24'd498;
                8'd68: cycles_between_samples <= 24'd470;
                8'd69: cycles_between_samples <= 24'd444;
                8'd70: cycles_between_samples <= 24'd419;
                8'd71: cycles_between_samples <= 24'd395;
                8'd72: cycles_between_samples <= 24'd373;
                8'd73: cycles_between_samples <= 24'd352;
                8'd74: cycles_between_samples <= 24'd333;
                8'd75: cycles_between_samples <= 24'd314;
                8'd76: cycles_between_samples <= 24'd296;
                8'd77: cycles_between_samples <= 24'd280;
                8'd78: cycles_between_samples <= 24'd264;
                8'd79: cycles_between_samples <= 24'd249;
                8'd80: cycles_between_samples <= 24'd235;
                8'd81: cycles_between_samples <= 24'd222;
                8'd82: cycles_between_samples <= 24'd209;
                8'd83: cycles_between_samples <= 24'd198;
                8'd84: cycles_between_samples <= 24'd187;
                8'd85: cycles_between_samples <= 24'd176;
                8'd86: cycles_between_samples <= 24'd166;
                8'd87: cycles_between_samples <= 24'd157;
                8'd88: cycles_between_samples <= 24'd148;
                8'd89: cycles_between_samples <= 24'd140;
                8'd90: cycles_between_samples <= 24'd132;
                8'd91: cycles_between_samples <= 24'd125;
                8'd92: cycles_between_samples <= 24'd118;
                8'd93: cycles_between_samples <= 24'd111;
                8'd94: cycles_between_samples <= 24'd105;
                8'd95: cycles_between_samples <= 24'd99;
                8'd96: cycles_between_samples <= 24'd93;
                8'd97: cycles_between_samples <= 24'd88;
                8'd98: cycles_between_samples <= 24'd83;
                8'd99: cycles_between_samples <= 24'd78;
                8'd100: cycles_between_samples <= 24'd74;
                8'd101: cycles_between_samples <= 24'd70;
                8'd102: cycles_between_samples <= 24'd66;
                8'd103: cycles_between_samples <= 24'd62;
                8'd104: cycles_between_samples <= 24'd59;
                8'd105: cycles_between_samples <= 24'd55;
                8'd106: cycles_between_samples <= 24'd52;
                8'd107: cycles_between_samples <= 24'd49;
                8'd108: cycles_between_samples <= 24'd47;
                8'd109: cycles_between_samples <= 24'd44;
                8'd110: cycles_between_samples <= 24'd42;
                8'd111: cycles_between_samples <= 24'd39;
                8'd112: cycles_between_samples <= 24'd37;
                8'd113: cycles_between_samples <= 24'd35;
                8'd114: cycles_between_samples <= 24'd33;
                8'd115: cycles_between_samples <= 24'd31;
                8'd116: cycles_between_samples <= 24'd29;
                8'd117: cycles_between_samples <= 24'd28;
                8'd118: cycles_between_samples <= 24'd26;
                8'd119: cycles_between_samples <= 24'd25;
                8'd120: cycles_between_samples <= 24'd24;
                8'd122: cycles_between_samples <= 24'd20;
                8'd123: cycles_between_samples <= 24'd19;
                8'd124: cycles_between_samples <= 24'd18;
                8'd125: cycles_between_samples <= 24'd17;
                8'd126: cycles_between_samples <= 24'd16;
                8'd127: cycles_between_samples <= 24'd15;
                default: cycles_between_samples <= 24'd747; // middle C
            endcase
        end else begin
            valid_out <= 0;
        end
    end

endmodule // midi_processor

