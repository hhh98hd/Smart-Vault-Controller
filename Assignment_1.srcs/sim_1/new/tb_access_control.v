`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Module Name: Test for access_control
// Author     : Huy Hoang Hoang -u7671528
// Description: Test changeing the number of people inside the vault
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module tb_access_control();

    parameter CLK_PERIOD = 10;
    reg clk;
    reg enter, door_master, security_reset, morse_key, inc_people, dec_people;
    reg [6:0] sw;
    wire [3:0] num_people;
    wire [15:0] led;
    
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
        .people_count(num_people)    
    );
    
    initial  begin:
        stopat #10000;
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
    
    initial begin
        #20
        $display("[TEST 01] Increase number of people inside the vault");
    
        inc_people = 1'b0;
        dec_people = 1'b0;
        enter = 1'b0;
        door_master = 1'b0;
        security_reset = 1'b1;
        morse_key = 1'b0;
        
        #20 security_reset = 1'b0;
        
        #30 inc_people = 1'b1;
             
        #30 if(num_people != 4'd1) begin
            $display("[TEST 01] FAILED: Failed to increase from 0 to 1 people");
            $finish();
        end
        
        #30 inc_people = 1'b0;
        #30 if(num_people != 4'd2) begin
            $display("[TEST 01] FAILED: Failed to increase from 1 to 2 people");
            $finish();
        end
        
        #30 inc_people = 1'b1; // -> 3
        #30 inc_people = 1'b0; // -> 4
        #30 inc_people = 1'b1; // -> 5
        #30 inc_people = 1'b0; // -> 6
        #30 inc_people = 1'b1; // -> 7
        #30 inc_people = 1'b0; // -> 8
        #30 inc_people = 1'b1; // -> 9
        #30 inc_people = 1'b0; // -> 10
        #30 if(num_people > 4'd9) begin
            $display("[TEST 01] FAILED: The number of people should never exceed 9");
            $finish();
        end

        $display("[TEST 01] PASSED");
        
        #20
        $display("[TEST 02] Decrease number of people inside the vault");
    
        inc_people = 1'b0;
        dec_people = 1'b0;
        enter = 1'b0;
        door_master = 1'b0;
        security_reset = 1'b0;
        morse_key = 1'b0;
        
        #30 dec_people = 1'b1;
             
        #30 if(num_people != 4'd8) begin
            $display("[TEST 02] FAILED: Failed to decrease from 9 to 8 people");
            $finish();
        end
        
        #30 dec_people = 1'b0;
        #30 if(num_people != 4'd7) begin
            $display("[TEST 02] FAILED: Failed to decrease from 8 to 7 people");
            $finish();
        end
        
        #30 dec_people = 1'b1; // -> 6
        #30 dec_people = 1'b0; // -> 5
        #30 dec_people = 1'b1; // -> 4
        #30 dec_people = 1'b0; // -> 3
        #30 dec_people = 1'b1; // -> 2
        #30 dec_people = 1'b0; // -> 1
        #30 dec_people = 1'b1; // -> 0
        #30 dec_people = 1'b0; // -> 0
        #30 if(num_people > 4'd9) begin
            $display("[TEST 02] FAILED: The number of people should be never below 0");
            $finish();
        end

        $display("[TEST 02] PASSED");
    end    
endmodule 
