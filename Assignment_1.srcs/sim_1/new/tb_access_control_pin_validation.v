`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Module Name: Test for access_control
// Author     : Huy Hoang Hoang - u7671528
// Description: Test validating entered PIN
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module tb_access_control_pin_validation();
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
    
    initial begin
        //---------------------------------------------------
        //--                     TEST01                    --
        //---------------------------------------------------
        #20 $display("[TEST 01] Initial state");
    
        inc_people = 1'b0;
        dec_people = 1'b0;
        sw = 1'b0;
        door_master = 1'b0;
        security_reset = 1'b0;
        morse_key = 1'b0;
        sw = 7'd0;
        
        #30 if(led[15:12] != 4'b1111)
            $display("[TEST 01] FAILED Door should be closed by default, actual: %b", led[15:12]);
            $finish();
        #30 if(led[11:8] != 4'b0000)
            $display("[TEST 02] FAILED: Alarm should be off by default, actual: %b", led[11:8]);
            $finish();     
            
         $display("[TEST 01] PASSED");
        //---------------------------------------------------    
        
        //---------------------------------------------------
        //--                     TEST02                    --
        //---------------------------------------------------
        #20 $display("[TEST 02] Enter a valid PIN");
    
        inc_people = 1'b0;
        dec_people = 1'b0;
        enter = 1'b0;
        door_master = 1'b0;
        security_reset = 1'b0;
        morse_key = 1'b0;
        
        sw = 7'b001_0010;
        #30 enter = 1'b1;
        #30 enter = 1'b0;
                
        $display("[TEST 02] Entered PIN: %b (%d)", sw, sw);
        #100 if(led[11:8] != 4'b0000) begin
            $display("[TEST 02] FAILED: Alarm should NOT be triggered upon a valid PIN entered, actual: %b", led[11:8]);
            $finish();
        end
            
        $display("[TEST 02] PASSED");
        //---------------------------------------------------
        
        //---------------------------------------------------
        //--                     TEST03                    --
        //---------------------------------------------------
        #20 $display("[TEST 03] Enter an invalid PIN");
    
        inc_people = 1'b0;
        dec_people = 1'b0;
        enter = 1'b0;
        door_master = 1'b0;
        security_reset = 1'b0;
        morse_key = 1'b0;
        
        sw = 7'b001_1010;
        #30 enter = 1'b1;
        #30 enter = 1'b0;
        
        $display("[TEST 03] Entered PIN: %b (%d)", sw, sw);
        #100 if(led[11:8] != 4'b1111) begin
            $display("[TEST 03] FAILED: Alarm should be triggered upon an invalid PIN entered, actual: %b", led[11:8]);
            $finish();
       end 
        
        $display("[TEST 03] PASSED");
        //---------------------------------------------------
        
        //---------------------------------------------------
        //--                     TEST04                    --
        //---------------------------------------------------
        #20 $display("[TEST 04] Enter a valid PIN without ENTER");
    
        inc_people = 1'b0;
        dec_people = 1'b0;
        enter = 1'b0;
        door_master = 1'b0;
        security_reset = 1'b0;
        morse_key = 1'b0;
        
        sw = 7'b001_0010;
        
        #30 if(led[15:12] != 4'b1111) begin
            $display("[TEST 04] FAILED: PIN should NOT be validated without pressing ENTER, actual: %b", led[15:12]);
            $finish();
        end
            
        $display("[TEST 04] PASSED");
        //---------------------------------------------------
        
        //---------------------------------------------------
        //--                     TEST05                    --
        //---------------------------------------------------
        #20 $display("[TEST 05] Enter an invalid PIN without ENTER");
    
        inc_people = 1'b0;
        dec_people = 1'b0;
        enter = 1'b0;
        door_master = 1'b0;
        security_reset = 1'b0;
        morse_key = 1'b0;
        
        sw = 7'b001_1010;
        #30 enter = 1'b1;
        #30 enter = 1'b0;
        
        #30 if(led[15:12] != 4'b1111) begin
            $display("[TEST 05] FAILED: PIN should NOT be validated without pressing ENTER, actual: %b", led[15:12]);
            $finish();
        end     
            
        $display("[TEST 05] PASSED");
        //---------------------------------------------------
             
        $finish();
    end
    
endmodule
