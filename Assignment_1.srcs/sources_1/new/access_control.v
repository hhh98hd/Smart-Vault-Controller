`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: access_control
// Author     : Gia Minh Nguyen - u7556893
// Description: Part I - controls for entering, exiting the vault
// 
// Dependencies: ssds_control, clockDividerHB, clockDividerHB2, morse_processing
//               morseDecoder
//
//////////////////////////////////////////////////////////////////////////////////


module access_control(
    input wire clk,
    
    input  wire        enter,
    input  wire        door_master,
    input  wire        security_reset,
    input  wire        morse_key,
    input  wire        master_control,
    
    input  wire [6:0]  sw,
    input  wire        inc_people,
    input  wire        dec_people,
    
    output reg  [15:0] led,
    output reg  [3:0]  people_count,
    
    output wire        last_morse_output,
    output wire        morse_display_status
    );
                      
    //---------------------------------------------------
    //--           HB clocks and timer duration        --
    //---------------------------------------------------
    wire beat;
    reg timer_reset;  // reset HB clock
    reg timer_en;
    clockDividerHB #(.THRESHOLD(50_000_000)) CDHB (.clk(clk),.reset(timer_reset),.enable(timer_en),.dividedClk(),.beat(beat));
        
    //HB clocks for ALARM and TRAP LEDs
    wire alarm_beat;
    wire trap_beat;
    clockDividerHB2 #(.THRESHOLD(100_000_000), .ON_TIME(15_000_000)) ALARMHB (.clk(clk),.reset(1'b0),.enable(1'b1),.dividedClk(),.beat(alarm_beat));
    clockDividerHB2 #(.THRESHOLD(25_000_000), .ON_TIME(15_000_000)) TRAPHB (.clk(clk),.reset(1'b0),.enable(1'b1),.dividedClk(),.beat(trap_beat));
    
    parameter duration_alarm = 8'd20,
              duration_door_open = 8'd30,
              duration_door_progress = 8'd1;
    reg [7:0] timer;
    
    
    //---------------------------------------------------
    //--    Morse signal processing and registering    --
    //---------------------------------------------------
    reg [9:0] input_morse_seq;
    wire morse_trigger;
    
    // Morse represented in binary
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
    
    // states to display last morse inputs 
    assign morse_display_status = ((state >= IDLE_EXIT) & (state <= MORSE_CHECK)); // | ((state >= SAVE_0) & (state <= SAVE_9));
    
    // morse key processing unit, output last morse key: dot (1'b0) or dash (1'b1), limit: 0.24s
    morse_processing #(.LIMIT(12_000_000)) MP (.clk(clk), .morse_key(morse_key), .last_morse_output(last_morse_output), .morse_trigger(morse_trigger));
    
    // Morse to binary decoder
    reg [4:0] morse_decoder_in;
    wire [3:0] morse_decoder_out;
    morseDecoder MorseDecoder (.morse_in(morse_decoder_in), .bin_out(morse_decoder_out));
    
    //---------------------------------------------------
    //--          Defining accepted passwords          --
    //---------------------------------------------------
    wire [6:0] enter_pwd;  // password for entering
    wire [9:0] morse_seq;  // accepted morse codes for exiting
    wire       morse_seq_check;
    
    assign enter_pwd = 7'd18;  // pin password must equal to team number => d18 = 7'b0010010
    
    // "-" in morse = b1, "." in morse = b0
    assign morse_seq_check = (input_morse_seq == {m0, m7}) |  // 07 ----- --...
                             (input_morse_seq == {m1, m0}) |  // 10 .---- -----
                             (input_morse_seq == {m2, m3}) |  // 23 ..--- ...--
                             (input_morse_seq == {m3, m4}) |  // 34 ...-- ....-
                             (input_morse_seq == {m5, m6}) |  // 56 ..... -....
                             (input_morse_seq == {m6, m7}) |  // 67 -.... --...
                             (input_morse_seq == {m7, m2}) |  // 72 --... ..---
                             (input_morse_seq == {m7, m8}) |  // 78 --... ---..
                             (input_morse_seq == {m3, m7}) |  // 37 ...-- --...
                             (input_morse_seq == {m4, m5}) |  // 45 ....- .....
                             (input_morse_seq == {m8, m9}) |  // 89 ---.. ----.
                             (input_morse_seq == {m9, m2});   // 92 ----. ..---
                       
    
    //---------------------------------------------------
    //--           People increment/decrement          --
    //---------------------------------------------------
    reg inc_sw_last_state;
    reg dec_sw_last_state;
    
    always @(posedge clk) begin
        if(state == OPEN_3) begin  // people can only enter and exit once door is fully opened
            if ((inc_people == (~inc_sw_last_state)) & (people_count < 4'd9)) begin
                people_count <= people_count + 4'd1;
            end
            else if ((dec_people == (~dec_sw_last_state)) & (people_count > 4'd0)) begin
                people_count <= people_count - 4'd1;
            end
        end else if (state == IDLE_ENTER) begin  // force people to 0 upon master_reset
            people_count <= 4'd0;
        end
        inc_sw_last_state <= inc_people;
        dec_sw_last_state <= dec_people;
    end
    
    
    //---------------------------------------------------
    //--                       FSM                     --
    //---------------------------------------------------
    reg [4:0] state, nextstate;
    wire timer_states;
    wire overridable_states;
    
    // Defining the states
    parameter IDLE_ENTER    = 5'd0,  // waiting for enter code
              OPEN_0        = 5'd1,  // started opening door
              OPEN_1        = 5'd2,  // opened 1/3
              OPEN_2        = 5'd3,  // opened 2/3
              OPEN_3        = 5'd4,  // fully opened 
              CLOSE_0       = 5'd5,  // start closing door
              CLOSE_1       = 5'd6,  // closed 1/3
              CLOSE_2       = 5'd7,  // closed 2/3
              CLOSE_3       = 5'd8,  // closed 3/3
              IDLE_EXIT     = 5'd9,  // waiting for exit morse code
              MORSE_1       = 5'd10, // 1st morse digit entered
              MORSE_2       = 5'd11, // 2nd morse digit entered
              MORSE_3       = 5'd12, // 3rd ___________________
              MORSE_4       = 5'd13, // 4th ___________________
              MORSE_5       = 5'd14, // 5th ___________________
              MORSE_6       = 5'd15, // 6th ___________________
              MORSE_7       = 5'd16, // 7th ___________________
              MORSE_8       = 5'd17, // 8th ___________________
              MORSE_9       = 5'd18, // 9th ___________________
              MORSE_CHECK   = 5'd19, // 10th morse digit entered => check
              ALARM         = 5'd20,
              ALARM_RESET   = 5'd21, // Intermediate state to reset the alarm and system's timer
              TRAP          = 5'd22;
    
    // states that need a countdown timer, if not in these states: reset timer
    assign timer_states = state == OPEN_0  |
                          state == OPEN_1  |
                          state == OPEN_2  |
                          state == OPEN_3  |
                          state == CLOSE_0 |
                          state == CLOSE_1 |
                          state == CLOSE_2 |
                          state == ALARM;
                          
    //states that can be overide by DOOR_MASTER
    assign overridable_states = state == IDLE_ENTER | 
                                state == IDLE_EXIT  |
                                state == MORSE_1    |
                                state == MORSE_2    |
                                state == MORSE_3    |
                                state == MORSE_4    |
                                state == MORSE_5    |
                                state == MORSE_6    |
                                state == MORSE_7    |
                                state == MORSE_8    |
                                state == MORSE_9    |
                                state == MORSE_CHECK|
                                state == ALARM      |
                                state == TRAP;
                                                       
    // state memory
    always @ (posedge clk) begin
        if(master_control)                        state <= IDLE_ENTER;
        else if(door_master & overridable_states) state <= ALARM_RESET;
        else                                      state <= nextstate;
    end
    
    // next state logic
    always @ (state) begin     
        case(state)
            IDLE_ENTER: begin
                if(enter & (sw == enter_pwd)) begin
                    nextstate = OPEN_0;
                end else if (enter & (sw != enter_pwd)) begin
                    nextstate = ALARM;
                end else begin
                    nextstate = IDLE_ENTER;
                end
            end
            
            OPEN_0: begin
                if(timer >= duration_door_progress) begin
                    nextstate = OPEN_1;
                end else begin
                    nextstate = OPEN_0;
                end 
            end
            
            OPEN_1: begin
                if(timer >= (duration_door_progress * 2)) begin
                    nextstate = OPEN_2;
                end else begin
                    nextstate = OPEN_1;
                end
            end
            
            OPEN_2: begin
                if(timer >= (duration_door_progress * 3)) begin
                    nextstate = OPEN_3;
                end else begin
                    nextstate = OPEN_2;
                end
            end
            
            OPEN_3: begin  // Door fully opened, allow people enter and exit
                if(timer >= (duration_door_progress * 3 + duration_door_open)) begin
                    nextstate = CLOSE_0;
                end else begin
                    nextstate = OPEN_3;
                end
            end
            
            CLOSE_0: begin
                if(timer >= (duration_door_progress * 4 + duration_door_open)) begin
                    nextstate = CLOSE_1;
                end else begin
                    nextstate = CLOSE_0;
                end
            end
            
            CLOSE_1: begin
                if(timer >= (duration_door_progress * 5 + duration_door_open)) begin
                    nextstate = CLOSE_2;
                end else begin
                    nextstate = CLOSE_1;
                end 
            end
            
            CLOSE_2: begin
                if(timer >= (duration_door_progress * 6 + duration_door_open)) begin
                    nextstate = CLOSE_3;
                end else begin
                    nextstate = CLOSE_2;
                end
            end
            
            CLOSE_3: begin
                if(people_count > 0) nextstate = IDLE_EXIT;
                else                 nextstate = IDLE_ENTER;
            end
                        
            IDLE_EXIT: begin
                if(morse_trigger) begin
                    nextstate = MORSE_1;
                end else begin
                    nextstate = IDLE_EXIT;
                end
            end
            
            MORSE_1: begin
                if(morse_trigger) begin 
                    nextstate = MORSE_2;
                end else begin
                    nextstate = MORSE_1; 
                end
            end
            
            MORSE_2: begin
                if(morse_trigger) begin
                    nextstate = MORSE_3;
                end else begin
                    nextstate = MORSE_2; 
                end
            end
            
            MORSE_3: begin
                if(morse_trigger) begin
                    nextstate = MORSE_4;
                end else begin
                    nextstate = MORSE_3; 
                end
            end
            
            MORSE_4: begin
                if(morse_trigger) begin
                    nextstate = MORSE_5;
                end else begin
                    nextstate = MORSE_4; 
                end
            end
            
            MORSE_5: begin
                if(morse_trigger) begin
                    nextstate = MORSE_6;
                end else begin
                    nextstate = MORSE_5; 
                end
            end
            
            MORSE_6: begin
                if(morse_trigger) begin
                    nextstate = MORSE_7;
                end else begin
                    nextstate = MORSE_6; 
                end
            end
            
            MORSE_7: begin
                if(morse_trigger) begin 
                    nextstate = MORSE_8;
                end else begin
                    nextstate = MORSE_7; 
                end
            end
            
            MORSE_8: begin
                if(morse_trigger) begin
                    nextstate = MORSE_9;
                end else begin
                    nextstate = MORSE_8; 
                end
            end
            
            MORSE_9: begin
                if(morse_trigger) begin
                    nextstate = MORSE_CHECK;
                end else begin
                    nextstate = MORSE_9; 
                end
            end
            
            MORSE_CHECK: begin
                if(morse_seq_check) nextstate = OPEN_0;
                else                nextstate = IDLE_EXIT;
            end
                        
            ALARM: begin
                if(timer >= duration_alarm) begin
                    nextstate = TRAP;
                end else if(enter & (sw == enter_pwd)) begin
                    nextstate = ALARM_RESET;
                end else if(security_reset) begin
                    nextstate = IDLE_ENTER;
                end else if(enter & (sw != enter_pwd)) begin
                    nextstate = TRAP;
                end else begin
                    nextstate = ALARM;
                end
            end
            
            // intermediate state if password is correct, to reset timer before opening door
            ALARM_RESET: begin
                if(timer > 0) nextstate = ALARM_RESET;
                else          nextstate = OPEN_0;
            end
            
            TRAP: begin
                if(security_reset) nextstate = IDLE_ENTER;
                else               nextstate = TRAP;
            end
            
            default: begin
                nextstate = IDLE_ENTER;
            end
        endcase
    end
    
    // timer procedural
    always @ (posedge clk) begin
        if (timer_states) begin
            timer_en    <= 1'b1;
            timer_reset <= 1'b0;
        end else begin
            timer_en    <= 1'b0;
            timer_reset <= 1'b1;
        end
        
        if(timer_reset) begin
            timer <= 8'd0;
        end else if (timer_states & beat) begin
            timer <= timer + 8'd1;
        end
    end
    
    // output logic
    always @ (posedge clk) begin 
        case(state)
            IDLE_ENTER: begin
                led = 16'b1111_0000_0000_0000;
            end
            OPEN_0: begin
                led[15:8] = 8'b0111_0000;
            end
            OPEN_1: begin
                led[15:12] = 4'b0011;
            end
            OPEN_2: begin
                led[15:12] = 4'b0001;
            end
            OPEN_3: begin
                led[15:12] = 4'b0000;
            end
            CLOSE_0: begin
                led[15:12] = 4'b0001;
            end
            CLOSE_1: begin
                led[15:12] = 4'b0011;
            end
            CLOSE_2: begin
                led[15:12] = 4'b0111;
            end
            CLOSE_3: begin
                led[15:12] = 4'b1111;
            end
            
            IDLE_EXIT: begin
                input_morse_seq[9] = last_morse_output;
            end
            MORSE_1: begin
                input_morse_seq[8] = last_morse_output;
            end
            MORSE_2: begin
                input_morse_seq[7] = last_morse_output;
            end
            MORSE_3: begin
                input_morse_seq[6] = last_morse_output;
            end
            MORSE_4: begin
                input_morse_seq[5] = last_morse_output;
                morse_decoder_in   = input_morse_seq[9:5];
            end
            MORSE_5: begin
                input_morse_seq[4] = last_morse_output;
                led[7:4]           = morse_decoder_out;
            end
            MORSE_6: begin
                input_morse_seq[3] = last_morse_output;
            end
            MORSE_7: begin
                input_morse_seq[2] = last_morse_output;
            end
            MORSE_8: begin
                input_morse_seq[1] = last_morse_output;
            end
            MORSE_9: begin
                input_morse_seq[0] = last_morse_output;
                morse_decoder_in   = input_morse_seq[4:0];
            end
            MORSE_CHECK: begin
                led[3:0]   = morse_decoder_out;
            end
            
            ALARM: begin
                if(alarm_beat) led[11:8] = 4'b1111;
                else           led[11:8] = 4'b0000;
            end
            ALARM_RESET: begin
                led[11:8] = 4'b0000;
            end
            TRAP: begin
                if(trap_beat) led[11:8]  = 4'b1111;
                else           led[11:8] = 4'b0000;
            end
            default: begin
            end
        endcase
    end          
endmodule