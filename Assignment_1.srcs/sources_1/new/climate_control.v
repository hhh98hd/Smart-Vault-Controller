`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Module Name: climate_control
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

module climate_control(
    input  wire clk,
    input  wire [5:0] sw, // sw[5:3] -> Outside temperature  sw[2:0] -> Desired temperature
    input  wire [3:0] people_count,
    output reg        climate_con_status,
    output reg [2:0]  current_temp
    );
    
    reg [1:0] current_state;
    parameter DISPLAY_OFF = 2'd0, ON = 2'd1, OFF = 2'd2;
    
    wire blink_beat;
    reg display_blink;
    // 0.5s
    clockDividerHB #(.THRESHOLD(25_000_000)) climate_off_beat_timer (.clk(clk),
                                                                     .reset(1'b0),
                                                                     .enable(1'b1),
                                                                     .dividedClk(),
                                                                     .beat(blink_beat)); 
    
    wire [2:0] new_temp;
    temperature_controller temp_con (
        .clk(clk),
        .current_state(current_state),
        .people_count(people_count),
        .outside_temp(sw[5:3]),
        .desired_temp(sw[2:0]),
        .current_temp(new_temp)
    );
    
    wire [1:0] state;
    climate_fsm fsm(
        .clk(clk),
        .people_count(people_count),
        .current_state(state)
    );
    
    // State updating process
    always @(posedge clk) begin
        current_temp <= new_temp;
        current_state <= state;
    end
    
    // Temperature display blinking process
    always @(posedge clk) begin
        if(blink_beat) display_blink <= ~display_blink;
    end
    
    // Logic for temperature display
    always @(*) begin
        case(current_state)
            DISPLAY_OFF: begin
                climate_con_status = 1'b0;
            end
            
            ON: begin
                climate_con_status = 1'b1;
            end
            
            OFF: begin
                climate_con_status = display_blink;
            end
            
            default: begin
                climate_con_status = 1'b1;
            end
        endcase 
    end 
endmodule
