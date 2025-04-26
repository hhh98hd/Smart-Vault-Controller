# Xilinx Basys3 Smart Vault Controller

## Overview
The smart-vault is a highly secure room in a bank that has  several automated functions, such as multi-factor authentication, remote locking, real-time 
monitoring, alarm system, and smart room settings like control of lights and temperature. These functions work based on inputs from various sensors and user interface.
In this projecct, these features are implemented on a Xilinx Basys3 Development Boaard, with sensor inputs mimicked by the board's integrated switches, and user interface realised using integrated LEDs and SSD.

## High Level Architecture
  There is a container module at the top level (top.v) that encapsulates other modules in our system. This top module serves several purposes: First, it pre-processes the necessary I/O inputs, thus eliminating the need for debouncing and SPOT at the individual modules level. Debouncers are needed for the morse_key, people incrementing/decrementing switches and the ENTER button as we don’t want instantaneous repeated signals caused by the inputs’ bounces. the debounced enter signal will then also be passed through a SPOT module which is critical, without it, the vault controller will have cycled through several states that waits for the ENTER input to be HIGH, because at the clock speed of 100 Mhz, a human’s fastest press and release of a button would have taken several thousand clock cycles, while state is updated on every cycle. Preprocessing the other inputs are not necessary as DOOR MASTER, SECURITY_RESET and MASTER CONTROL set the next states to IDLE_ENTER and ALARM_RESET respectively, which their next state transition conditions has been carefully constrained to not be affected by those three buttons, hence it is not possible to skip a state even if the buttons bounce or are held longer than expected. The temperature switches also do not need preprocessing as they set absolute temperature values.  
	Secondly, it acts as a mediator that distributes I/O inputs to each sub-module and links the sub-modules to make one complete system. This approach localizes the major functions into their respective sub-modules, making the sources modular, and increasing readability and comprehensibility for the development or maintenance process.   
	There are three modules under top: access control (access_control.v), climate control (climate_control.v), and SSD control (ssd_control.v). Access control is responsible for vault entry and exit, while climate control adjusts vault temperature according to requirements. Though they work independently most of the time, there are vital signal lines that need to be shared between the sub-modules. (Refer to Figure 2) The number of people inside the vault needs to be passed from access_control to climate_control to determine the climate control status. All the outputs that are displayed via the SSDs will be passed to the ssd_control sub-module. ssd_control is the driver for the SSDs, hence it manages all the details such as controlling anodes and cathodes based on the decimal/binary inputs, so the other modules do not need to worry about individual cathodes and their corresponding segment.
 
![image](https://github.com/user-attachments/assets/e794f871-5178-4b78-a0b9-2a66331f4d46)

 ## Access Control Module
The Access Control module consists of several functions: people incrementing and decrementing (people inc/dec), morse signal processing, morse decoder/translator, and the finite state machine (FSM) for access control. As the functions suggested, the module control the entering, exiting operations of the vault’s controller, as well as controlling the number of people inside the vault.

## Climate Control Module
This module accepts number of people from access_control and temperature data from slide switches, while it outputs the vault’s temperature and the current climate control status to top module, which in turn relays this information to ssd_control for displaying the current temperature.
The module’s behaviours are mainly determined by its current state and inputs to the module. There are 3 states:  
**ON**: This state is maintained as long as there is people inside the vault.  
**OFF**: This state is activated in 10 seconds after the last person leaves the vault. The vault temperature is not regulated in this state. Instead, the vault temperature will gradually change toward the outside temperature. Additionally, the temperature display will blink during this state to indicate that climate control is off.  
**DISPLAY OFF**: Upon power up, the system automatically goes to this state. Apart from that, this state is also activated 20 seconds after the climate control is off. Its behaviours are similar to those in the OFF state, but with the temperature display turned off
 ![image](https://github.com/user-attachments/assets/92ef31ce-6ba8-4fa6-98f8-41a9c879004d)

## SSD Control Module
This module encapsulates sevenSegmentDecoder. It is dedicated to controlling the 4 SSDs to display the values of its inputs. This module accepts people count, last morse key, climate control state, and vault temperature from the modules climate_control and access_control accumulatively.

