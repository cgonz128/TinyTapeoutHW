<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

This is a simple ALU that implements Flog2, logical OR, AND, and SUBTRACT
uio_in[3:0] controls what operation is performed 
operation==4'b0001 SUB. ui_in[7:2]- + { ui_in[1:0], uio_in[7:4]}
operation==4'b0010 ADD. ui_in[7:2] + {ui_in[1:0], uio_in[7:4]}
operation==4'b0100 OR. ui_in[7:2] | { ui_in[1:0], uio_in[7:4]}
operation==4'b1000 FLOG2 ui_in[7:0]
else y = 0


## How to test

You can use test/tb.v for a verilog test simulation. 
## External hardware

No external hardware is needed