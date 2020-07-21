# OpenBuilds Fusion360 Postprocessor

Creates .nc files optimized for GRBL based Openbuilds-style machines.
Supports router and laser operations.

V1.0.18 now includes laser operations. 
1. Laser mode supports lasers with and without Z motions.
1. It is left to the operator to correctly set GRBL parameter $32 as needed on a machine that combines a router and laser head.
1. The laser is regarded as an extra tool so when posting multiple operations the
   router code and laser code will be in seperate output .gcode files 
   (exactly as for multiple tool outputs, each tool in its own file).
1. Laser power is scaled between 0 and 1000 (GRBL spindle RPM defaults).  
   You can edit this post to cater for non-default settings. Refer to the 'calcPower' function.

### Credits ###

@swarfer David the Swarfer (lead maintainer)
@sharmstr - multifile output
@Strooom - Initial work
