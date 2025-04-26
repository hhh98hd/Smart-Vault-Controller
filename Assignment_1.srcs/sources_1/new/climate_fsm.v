`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Module Name: climate control FSM
// Author     : Huy Hoang Hoang - u7671528
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module climate_fsm(
    input wire clk,
    input wire [3:0] people_count,
    output reg [1:0] current_state
);
    
    reg [1:0] next_state;
    parameter DISPLAY_OFF = 2'd0, ON = 2'd1, OFF = 2'd2;
    
    reg display_off_enable = 1'b0;
    wire display_off_beat;
    clockDividerHB #(.THRESHOLD(1_000_000_000)) display_off_timer ( .clk(clk),
                                                                    .reset(1'b0),
                                                                    .enable(display_off_enable),
                                                                    .dividedClk(),
                                                                    .beat(display_off_beat) ); // 20s
    
    reg climate_off_enable = 1'b0;
    wire climate_off_beat;
    clockDividerHB #(.THRESHOLD(500000000)) climate_off_timer ( .clk(clk),
                                                                  .reset(1'b0),
                                                                  .enable(climate_off_enable),
                                                                  .dividedClk(),
                                                                  .beat(climate_off_beat)); // 10s
        
    //---------------------------------------------------
    //--                 FOR SIMULATION                --
    //---------------------------------------------------
//    wire display_off_beat, climate_off_beat;
//    reg display_off_enable = 1, display_off_reset = 1;
//    reg climate_off_enable = 1, climate_off_reset = 1;
//    clockDividerHB #(.THRESHOLD(50)) display_off_timer (.clk(clk),.reset(display_off_reset),.enable(display_off_enable),.dividedClk(),.beat(display_off_beat)); //1000ns
//    clockDividerHB #(.THRESHOLD(50)) climate_off (.clk(clk),.reset(climate_off_reset),.enable(climate_off_enable),.dividedClk(),.beat(climate_off_beat)); //1000ns

//    initial begin
//        current_state = DISPLAY_OFF;
//        next_state = DISPLAY_OFF;
//        #100 display_off_reset = 1'b0;
//        climate_off_reset =1'b0;
//        #20 display_off_enable = 1'b0;
//        climate_off_enable = 1'b0;
//    end
    //---------------------------------------------------
    
    always @(posedge clk) begin
        current_state <= next_state;
    end
    
    // State transition based on the number of people inside the vault
    always @(*) begin
        case(current_state)
            OFF: begin
                display_off_enable = 1'b1;
                climate_off_enable = 1'b0;
            
                // 20s elapsed -> Turn off the temperature display
                if(display_off_beat == 1'b1) begin
                    next_state = DISPLAY_OFF;
                end else if(people_count > 3'd0) begin
                    next_state = ON;
                end else
                    next_state = OFF;
            end
            
            ON: begin
                if(people_count == 3'd0) begin
                    // The usage of below non-blocking assignment is intentional to ensure correct timing
                    climate_off_enable <= 1'b1;      
                end        
                        
                // 10s elapsed -> Turn off climate control                  
                if(climate_off_beat == 1'b1 && people_count == 3'd0) begin
                    next_state = OFF;
                end else
                    next_state = ON;                     
            end
            
            DISPLAY_OFF: begin
                display_off_enable = 1'b0;
            
                if(people_count > 3'd0) begin
                    next_state = ON;
                end else
                    next_state = DISPLAY_OFF;
            end            
        endcase
    end

endmodule
