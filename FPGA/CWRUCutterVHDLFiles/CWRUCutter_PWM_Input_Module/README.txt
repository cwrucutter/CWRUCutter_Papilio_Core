The CWRUCutter PWM Input module has two versions. 

The single input module connects one PWM signal and breaks it down into a positive cycle time and total cycle time.
The positive cycle time is output over the wishbone bus to ZPUino and is written to position 0 on the register, and the total cycle time is written to position 1 on the register.

Similar to the single input module, the three input module puts the positive/total cycle times on position
0/1 for the first input, 2/3 for the second, and 4/5 for the third input.

