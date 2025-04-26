`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: ssds_control
// Author     : Gia Minh Nguyen - u7556893
// Description: multiple SSDs driver, manage SSDs and pass the appropriate content
//              to be displayed
// 
// Dependencies: clockDividerHB, sevenSegmentDecoder
//
//////////////////////////////////////////////////////////////////////////////////

module ssds_control(
    input  wire       clk,
    input  wire [3:0] people_count,
    input  wire [2:0] current_temp,
    input  wire       climate_con_status,
    input  wire       last_morse_output,
    input  wire       morse_display_status,
    output wire [6:0] cathode,
    output reg        DP,
    output reg  [3:0] anode
    );
    
    wire beat;
    
    reg [1:0] activeDisplay;
    
    reg [3:0] ssdValue;
    
    clockDividerHB #(.THRESHOLD(50_000)) CDHB (.clk(clk),.reset(1'b0),.enable(1'b1),.dividedClk(),.beat(beat));
    
    sevenSegmentDecoder SSD (.bcd(ssdValue), .ssd(cathode));
    
    always @ (posedge clk) begin
        if (beat == 1) begin
            activeDisplay <= activeDisplay + 1'b1;
        end
    end
    
    //---------------------------------------------------
    //--                 SSDs DISPLAY                  --
    //---------------------------------------------------
    always @ (*) begin
        case(activeDisplay)
            2'b00 : begin 
                ssdValue = people_count;
                DP       = 1'b1;
                anode = 4'b0111;
            end
            
            2'b01 : begin  // display last morse input
                if(morse_display_status) begin
                    if(last_morse_output) begin  // display dash
                        ssdValue = 4'd10;
                        DP       = 1'b1;
                    end else begin              // display dot
                        ssdValue = 4'd11;       // out of defined range to trigger  the default case => all segments off
                        DP       = 1'b0;
                    end                 
                    anode = 4'b1011; 
                end else begin
                    ssdValue = 4'd0;
                    DP       = 1'b1;
                    anode    = 4'b1111;
                end
            end
            
            // Temps only display when climate control is on.
            2'b10 : begin
                ssdValue = 4'd2;  // temp always in 2x range
                DP       = 1'b1;
                if (climate_con_status) anode = 4'b1101;
                else anode = 4'b1111;
            end
            2'b11 : begin 
                ssdValue = current_temp;
                DP       = 1'b1;
                if (climate_con_status) anode = 4'b1110;
                else anode = 4'b1111;
            end
        endcase 
    end
endmodule
