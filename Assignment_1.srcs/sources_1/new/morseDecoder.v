`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: morseDecoder
// Author     : Gia Minh Nguyen - u7556893
// Description: Morse code signal handling and conversion
// 
//////////////////////////////////////////////////////////////////////////////////


module morseDecoder(
    input wire [4:0] morse_in,
    output reg [3:0] bin_out
    );
    
    // Morse to binary-signal
    parameter m0 = 5'b11111,
              m1 = 5'b01111,
              m2 = 5'b00111,
              m3 = 5'b00011,
              m4 = 5'b00001,
              m5 = 5'b00000,
              m6 = 5'b10000,
              m7 = 5'b11000,
              m8 = 5'b11100,
              m9 = 5'b11110;
    
    // Morse to decimal          
    always @ (*) begin
        case(morse_in)
            m0: begin
                bin_out = 4'd0;
            end
            m1: begin
                bin_out = 4'd1;
            end
            m2: begin
                bin_out = 4'd2;
            end
            m3: begin
                bin_out = 4'd3;
            end
            m4: begin
                bin_out = 4'd4;
            end
            m5: begin
                bin_out = 4'd5;
            end
            m6: begin
                bin_out = 4'd6;
            end
            m7: begin
                bin_out = 4'd7;
            end
            m8: begin
                bin_out = 4'd8;
            end
            m9: begin
                bin_out = 4'd9;
            end
            default begin
                bin_out = 4'd10;
            end
        endcase
    end
endmodule
