Build 1
------------------------------------------


papilio_one_500k.bit
------------------------------------------
This build includes a dual encoder module, a triple PWM input, and two UARTS.

The dual encoder module is attached to wishbone slot 5. 
	The first encoder is connected to pins CL3 and CL4 (C3 and C4 respectively)
	The second encoder is connected to pins CL5 and CL6 (C5 and C6 respectively)

The triple PWM module is attached to wishbone slot 6. It's pinouts are not permenant and will change.
	The first PWM input is connected to pin CH5 (C13)
	The first PWM input is connected to pin CH6 (C14)
	The first PWM input is connected to pin CH7 (C15)

The first UART is attached to wishbone slot 9.
	The TX pin of the UART is attached to pin CL0 (C0)
	The RX pin of the UART is attached to pin CL2 (C2)

The second UART is attached to wishbone slot 10.
	The TX pin of the UART is attached to pin CL7 (C7)
	The RX pin of the UART is attached to pin CH1 (C9)




Build001_7_10_14.ino
-------------------------------------------
This is a placeholder file for when an actual ZPUino program is ready.
It has been given this name since the ZAP IDE requires the .ino file to have the same name as the folder containing it.