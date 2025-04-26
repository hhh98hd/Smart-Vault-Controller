module debouncer # (parameter integer DELAY = 3_333_333) (
input wire switchIn,
input wire clk,
input wire reset,
output wire debounceout);
    wire beat;
    clockDividerHB #(.THRESHOLD(DELAY)) CDHB (.clk(clk),.reset(reset),.enable(1'b1),.dividedClk(),.beat(beat));
    reg[2:0] pipeline;
    always @(posedge clk) begin
        //pipeline <= 3'd0;
        if (beat) begin
        pipeline[0] <= switchIn;
        pipeline[1] <= pipeline[0];
        pipeline[2] <= pipeline[1];
        end
    end

    assign debounceout = &pipeline;
endmodule
