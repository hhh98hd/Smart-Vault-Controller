`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/13/2024 12:40:48 AM
// Design Name: 
// Module Name: tb_access_morse_validation
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_access_morse_validation();
    parameter CLK_PERIOD = 10;
    
    reg clk;
    reg enter, door_master, security_reset, morse_key, inc_people, dec_people;
    reg [6:0] sw;
    wire [3:0] num_people;
    wire [15:0] led;
    wire last_morse_output, morse_display_status;
    
    access_control test_design (
        .clk(clk),
        .enter(enter),
        .door_master(door_master),
        .security_reset(security_reset),
        .morse_key(morse_key),
        .sw(sw),
        .inc_people(inc_people),
        .dec_people(dec_people),
        .led(led),
        .people_count(num_people),
        .last_morse_output(last_morse_output),
        .morse_display_status(morse_display_status)  
    );
    
    initial  begin:
        stopat #10_000;
        $display("TESTING FINISHED");
        $finish();
    end
    
    // Simulate CLK signal
    initial begin
        $display("TESTING STARTED");
        clk <= 1'b0;
        forever begin
            #(CLK_PERIOD/2);
            clk <= !clk;
        end    
    end
endmodule
