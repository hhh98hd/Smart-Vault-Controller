`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Module Name: Test for climate_control
// Author     : Huy Hoang Hoang - u7671528
// Description: Test temperature
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module tb_climate_control_temperature();
    parameter CLK_PERIOD = 10;
    
    reg  clk;
    reg  [5:0] sw;
    reg  [3:0] people_count;
    wire climate_con_status;
    wire [2:0] current_temp;
    
    climate_control test_design(
        .clk(clk),
        .sw(sw),
        .people_count(people_count),
        .climate_con_status(climate_con_status),
        .current_temp(current_temp)
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
    
        sw = 6'b110000;
        people_count = 4'd0;
        
        $display("[TEST 01] Outside temperature is %d", 5'd20 + sw[5:3]);
        
        #30 if(current_temp != 3'd6) begin
             $display("[TEST 01] FAILED: The room temperature should be 26, not %d", 5'd20 + current_temp);
             $finish();
        end
            
         $display("[TEST 01] PASSED");
        //--------------------------------------------------- 
    end

endmodule

