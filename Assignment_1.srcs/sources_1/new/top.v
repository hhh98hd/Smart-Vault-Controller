`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//                 ENGN4213 DIGITAL SYSTEMS AND MICROPROCESSORS
//                    ASSIGNMENT 1: SMART VAULT CONTROLLER
// 
// Group: 18
// Member 1: Huy Hoang Hoang - u7671528
// Member 2: Gia Minh Nguyen - u7556893
//
// Module Name: top
// Description: top module of the circuit, combines the sub-modules and
//              pre-process IO inputs if needed
//////////////////////////////////////////////////////////////////////////////////


module top(
    input wire clk,
    
    input  wire        enter,
    input  wire        door_master,
    input  wire        security_reset,
    input  wire        morse_key,
    input  wire        master_control,
    
    input  wire [15:0] SW,
    
    output wire [15:0] LED,
    output wire [6:0]  SEG,
    output wire        DP,
    output wire [3:0]  ANODE
    );
    
    //---------------------------------------------------
    //--                 Shared variables              --
    //---------------------------------------------------
    wire [3:0] people_count;          // Output of access_control.
    wire [2:0] current_temp;          // Output of climate_control. To be displayed on SSDs in ssds_control.
    wire       climate_con_status;    // Output of climate_control. Indicates climate control ON or OFF.
    wire       last_morse_output;     // Most recent morse character: "b1" means "-", "b0" means "."
    wire       morse_display_status;  // Determines if morse-displaying SSD should be ON or OFF
    
    //---------------------------------------------------
    //--                Debounce and SPOT              --
    //---------------------------------------------------
    wire spot_out_enter, deb_out_enter;
    wire                 deb_out_door_m;
    wire                 deb_out_security_r;
    wire                 deb_out_morse_key;
    wire                 deb_out_people_inc;
    wire                 deb_out_people_dec;
    
    // Debounce time: ~0.1s
    debouncer #(.DELAY(1_666_666)) deb_enter       (.switchIn(enter),         .clk(clk), .debounceout(deb_out_enter),      .reset());
    debouncer #(.DELAY(1_666_666)) deb_door_m      (.switchIn(door_master),   .clk(clk), .debounceout(deb_out_door_m),     .reset());
    debouncer #(.DELAY(1_666_666)) deb_security_r  (.switchIn(security_reset),.clk(clk), .debounceout(deb_out_security_r), .reset());
    debouncer #(.DELAY(1_666_666)) deb_morse_key   (.switchIn(morse_key),     .clk(clk), .debounceout(deb_out_morse_key),  .reset());
    
    // Debounce time: ~0.2s (switch needs longer debounce time than buttons due to physical features)
    debouncer #(.DELAY(3_333_333)) deb_sw_inc      (.switchIn(SW[7]),         .clk(clk), .debounceout(deb_out_people_inc), .reset());
    debouncer #(.DELAY(3_333_333)) deb_sw_dec      (.switchIn(SW[8]),         .clk(clk), .debounceout(deb_out_people_dec), .reset());
    
    // SPOT signal passthrough (to avoid double-click)
    spot spot_enter      (.spot_in(deb_out_enter),      .spot_out(spot_out_enter),      .clk(clk));
    
    
    //---------------------------------------------------
    //--              Modules instantiation            --
    //---------------------------------------------------
    access_control  acc_con (
        .clk(clk), 
        .enter(spot_out_enter), 
        .door_master(deb_out_door_m), 
        .security_reset(deb_out_security_r), 
        .morse_key(deb_out_morse_key), 
        .master_control(master_control),
        .sw(SW[6:0]),
        .inc_people(deb_out_people_inc),
        .dec_people(deb_out_people_dec), 
        .led(LED),
        .people_count(people_count),
        .last_morse_output(last_morse_output),
        .morse_display_status(morse_display_status));
        
    climate_control cli_con (
        .clk(clk), 
        .sw(SW[14:9]),
        .people_count(people_count), 
        .climate_con_status(climate_con_status), 
        .current_temp(current_temp));
    
    ssds_control    ssd_con (
        .clk(clk), 
        .people_count(people_count), 
        .current_temp(current_temp), 
        .climate_con_status(climate_con_status), 
        .last_morse_output(last_morse_output),
        .morse_display_status(morse_display_status),
        .cathode(SEG), 
        .DP(DP),
        .anode(ANODE));
    
endmodule
