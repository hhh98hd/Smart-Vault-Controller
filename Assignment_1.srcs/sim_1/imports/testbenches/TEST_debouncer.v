`timescale 1ns / 1ps

module TEST_debouncer();

reg switchA, sysclk, reset;
wire deb_out;

initial begin
sysclk=0;
forever #5 sysclk=~sysclk; //clock generation at 100 MHz
end

debouncer UUT (.switchIn(switchA), .clk(sysclk), .reset(reset), .debounceout(deb_out)); //instantiation of test module

initial begin  //signal changes for testing
    reset=1;
    #20 reset=0;
    switchA=1;
end

endmodule
