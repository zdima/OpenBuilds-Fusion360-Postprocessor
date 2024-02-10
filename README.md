# OpenBuilds Fusion360 Postprocessor

Creates .gcode files optimized for GRBL/grblHAL based Openbuilds-style machines.
Supports router, laser and plasma operations.

V1.0.39
1. fix missing drill cycles

V1.0.38 and V0.0.2_beta
1. Main post : Simple probing, each axis on its own, and XY corner, for BB4x with 3D probe, and machine simulation.
1. X32 4th axis beta post: machine simulation enabled.

V1.0.37
1. Tape splitting - allows setting a line count after which the gcode is split into a new file, see option 
   _Split on line count (0 for none)_
   in the Toolchange section of the post options.
   (It will also split on toolchanges if both options are selected)

V1.0.36
1. code to recenter arcs with bad radii   - this enables use of vertical arcs in lead-in/lead-out moves

V1.0.35
1. plasma pierce height override,  spindle speed change always with an M3, version number display   

V1.0.34
1. move coolant code to the spindle control line to help with restarts in OpenBuildsCONTROL

V1.0.32
1. fix long comments that were getting extra brackets

V1.0.31
1. improved laser and plasma paths, esp when 'stay down' is selected
1. laser pierce delay option when through cutting is selected
1. Select 'LASER: use Z motions at start and end' to have full Z movement with laser and plasma cuts

V1.0.25 supports plasma torch touchoff probing.
* Read the [instructions](https://github.com/OpenBuilds/OpenBuilds-Fusion360-Postprocessor/blob/master/README-plasma.md)

V1.0.21 now supports plasma cutting

V1.0.20 supports the Personal license restrictions and ultra long comments

V1.0.18 now includes laser operations. 
1. Laser mode supports lasers with and without Z motions.
1. It is left to the operator to correctly set GRBL parameter $32 as needed on a machine that combines a router and laser head.
1. The laser is regarded as an extra tool so when posting multiple operations the
   router code and laser code will be in seperate output .gcode files 
   (exactly as for multiple tool outputs, each tool in its own file).
1. Laser power is scaled between 0 and 1000 (GRBL spindle RPM defaults).  
   You can edit this post to cater for non-default settings. Refer to the 'calcPower' function.

### Credits ###

1. @swarfer David the Swarfer (lead maintainer).
1. @sharmstr - multifile output.
1. @Strooom - Initial work.
1. @AutoDesk - for the example posts and excellent Fusion360 software.
