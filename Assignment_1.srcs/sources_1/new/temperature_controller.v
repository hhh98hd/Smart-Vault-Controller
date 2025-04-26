`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Module Name: temperature_controller
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

module temperature_controller(
    input wire clk,
    input wire[1:0] current_state,
    input wire[3:0] people_count,
    input wire[2:0] outside_temp,
    input wire[2:0] desired_temp,
    output reg[2:0] current_temp
    );
    
    parameter DISPLAY_OFF = 2'd0, ON = 2'd1, OFF = 2'd2;
    
    reg [2:0] next_temp;
    reg [2:0] target_temp;
    reg beat, initialized = 1'b0;
    
    wire fast_beat;
    clockDividerHB #(.THRESHOLD(25_500_000)) fast_timer (.clk(clk),.reset(1'b0),.enable(1'b1),.dividedClk(),.beat(fast_beat)); // 0.5s
    wire slow_beat;
    clockDividerHB #(.THRESHOLD(50_000_000)) slow_timer (.clk(clk),.reset(1'b0),.enable(1'b1),.dividedClk(),.beat(slow_beat)); // 1.0s
    wire off_beat;
    clockDividerHB #(.THRESHOLD(100_000_000)) off_timer (.clk(clk),.reset(1'b0),.enable(1'b1),.dividedClk(),.beat(off_beat));   // 2.0s
    
    //---------------------------------------------------
    //--                 FOR SIMULATION                --
    //---------------------------------------------------
//    reg reset = 1, enable = 0;
//    wire fast_beat;
//    clockDividerHB #(.THRESHOLD(25)) fast_timer (.clk(clk),.reset(reset),.enable(enable),.dividedClk(),.beat(fast_beat)); // 500ns
//    wire slow_beat;
//    clockDividerHB #(.THRESHOLD(50)) slow_timer (.clk(clk),.reset(reset),.enable(enable),.dividedClk(),.beat(slow_beat)); // 1000ns
//    wire off_beat;
//    clockDividerHB #(.THRESHOLD(100)) off_timer (.clk(clk),.reset(reset),.enable(enable),.dividedClk(),.beat(off_beat));   // 2000ns
//    initial begin
//        beat = 0;
//        initialized = 0;
//        current_temp = 0;
//        next_temp = 0;
//        #100 reset = 0;
//        #20 enable = 1;
//    end
    //-----------------------------------------------------
    
    // Logic for target temperature
    always @(*) begin
        case(current_state)
            OFF: begin
                target_temp = outside_temp;
            end
            
            ON: begin
                target_temp = desired_temp;
            end
            
            DISPLAY_OFF: begin
                target_temp = outside_temp;
            end            
        endcase
    end
       
    // Logic for beat selection
    always @(*) begin
        case(current_state)
            OFF: begin
                beat = off_beat;
            end
            
            ON: begin
               if(people_count <= 4'd5)
                   beat = fast_beat;
               else
                   beat = slow_beat;
            end
            
            DISPLAY_OFF: begin
                beat = off_beat;
            end            
        endcase
    end
        
    // Logic for for adjusting temperature
    always @(posedge clk) begin    
        // The initial vault temperature is equal to the outside temperature
        if(!initialized) begin
            next_temp <= outside_temp;
            current_temp <= outside_temp;
            initialized <= 1'b1;
        end else begin
            if(target_temp != current_temp) begin        
                next_temp <= (current_temp > target_temp) ? current_temp - 3'd1 : current_temp + 3'd1; 
            end else begin
                next_temp <= current_temp;
            end
            
            // Update the temperature periodically
            if(beat)
                current_temp <= next_temp;
            else
                current_temp <= current_temp;           
        end    
    end
endmodule

