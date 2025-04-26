`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.03.2024 15:51:54
// Design Name: 
// Module Name: clockDividerHB2
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


module clockDividerHB2
    # (parameter integer THRESHOLD = 50_000_000,
       parameter integer ON_TIME = 20_000_000)
    (
    input wire clk,
    input wire reset,
    input wire enable,
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
    
    assign beat = (counter >= THRESHOLD - ON_TIME) & (counter <= THRESHOLD - 1) & (dividedClk);
endmodule
