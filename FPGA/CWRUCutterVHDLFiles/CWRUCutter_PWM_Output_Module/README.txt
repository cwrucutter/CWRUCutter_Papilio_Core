There are two versions of the PWM output module. 

The first version is named wb_PWM_OUT. This module receives a command from the ZPUino soft processor,generates a PWM signal, and sends it back to the ZPUino soft processor to be output there.
The second version, PWM_OUT_NO_WB receives the command from the ZPUino and generates the PWM signal, but then directly outputs it to an atached pin.