`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: morse_processing
// Author     : Gia Minh Nguyen - u7556893
//              Huy Hoang Hoang - u7671528
// Description: Process morse key input, determines if user want to type dot or 
//              dash, send a spot signal that simulates a normal button press to
//              notify that a new morse character has just been registered.
// 
// Dependencies: clockDividerHB, spot
// 
//////////////////////////////////////////////////////////////////////////////////


module morse_processing # (parameter integer LIMIT = 13_000_000, MORSE_RELEASED = 1'b0, MORSE_PRESSED = 1'b1) (
    input  wire        clk,
    input  wire        morse_key,
    output reg         last_morse_output,
    output wire        morse_trigger
    );
    
    wire morse_beat;
    reg  morse_clk_reset;
    reg  morse_clk_en;
    
    // clock for processing morse signal, LIMIT determines the time limit for a ".", press duration > LIMIT will be considered as "_"
    clockDividerHB #(.THRESHOLD(LIMIT)) CD_morse (.clk(clk),.reset(morse_clk_reset),.enable(morse_clk_en),.dividedClk(),.beat(morse_beat));
    
    // A pulse to notify other components that a morse key has just been registered
    reg morse_notify;
    spot SPOT_MORSE (.spot_in(morse_notify), .spot_out(morse_trigger), .clk(clk));
    
    reg       morse_key_state, morse_next_state;  // 1: key pressed, 0: key released
    reg [31:0] morse_time_unit;  // count the time unit to determine if it is a dot or a dash
                                 // morse_time_unit < 1 => dot, morse_time_unit >= 1 => dash
    
    // state memory
    always @ (posedge clk) begin
        morse_key_state <= morse_next_state;
    end

     // morse timing procedural
    always @(posedge clk) begin
        if(morse_beat & morse_clk_en) morse_time_unit <= morse_time_unit + 32'd1;
        else if(morse_clk_reset) morse_time_unit <= 32'd0;
    end
    
    // next state logic
    always @ (*) begin
        case(morse_key_state)
            MORSE_RELEASED: begin
                morse_notify = 1'b0;
                if(morse_key) begin
                    morse_clk_reset  = 1'b0;
                    morse_clk_en     = 1'b1;
                    morse_next_state = MORSE_PRESSED;
                end else begin
                    morse_clk_reset  = 1'b1;
                    morse_clk_en     = 1'b0;
                    morse_next_state = MORSE_RELEASED;
                end
            end
            MORSE_PRESSED: begin
                if(~morse_key) begin
                    morse_notify = 1'b1;
                    if(morse_time_unit >= 1) last_morse_output = 1'b1;
                    else                     last_morse_output = 1'b0;
                    morse_next_state = MORSE_RELEASED;
                end else begin
                    morse_next_state = MORSE_PRESSED;
                end
            end
            default: begin  // initialise values to avoid inferred latch
                morse_notify = 1'b0;
                last_morse_output = 1'b0;
            end
        endcase
    end
endmodule
