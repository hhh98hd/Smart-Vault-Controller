`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: clockDividerHB
// Description: produce divided clock and HB at variable THRESHOLD
//////////////////////////////////////////////////////////////////////////////////


module clockDividerHB # (parameter integer THRESHOLD = 50_000_000) (
    input wire clk,
    input wire enable,
    input wire reset,
    output reg dividedClk,
    output wire beat
    );
    
    reg [31:0] counter;
    
    always @ (posedge clk) begin
        if (reset==1'b1 || counter >= THRESHOLD - 1) begin
            counter <= 32'd0;
        end else if (enable == 1'b1) begin
            counter <= counter + 1'b1;
        end
    end
    
    always @ (posedge clk) begin
        if (reset == 1'b1) begin
            dividedClk <= 1'b0;
        end else if (counter >= THRESHOLD - 1) begin
            dividedClk <= ~dividedClk;
        end
    end
    
    assign beat = (counter == THRESHOLD - 1) & (dividedClk);
    
    
endmodule
