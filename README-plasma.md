# How to use torch height probing with plasma cutting in Fusion360

## Things to do in Fusion360
* Select a plasma tool and adjust the kerf width to suite your machine.
* Make sure you set the CutHeight, PierceHeight and PierceDelay for the tool to match your plasma cutter.
* Make sure that the stock is the same thickness as the model, make sure no stock is added on top of the model.
* On all operations select either:
    *. Top Height as 'Stock Top' and enter the cutting head height for normal cutting (like 0.8mm).
  or
    *. Select Top Height as 'Stock Top' and set to *0* and then the tools *cutHeight* will be used for cutting.
* Make sure that the tools *pierceHeight* is greater than the cutting height (like 1.5mm) (topheight plus offset or tool.cutHeight).
* Under Passes | Compensation Type select 'In computer'.

## Things to do in the post options:
* Set 'Use Z touchoff probe routine' to Yes
* Set 'Plasma touch probe offset' to the difference between where the torch tip (the probe) touches the material and where the probe triggers.
  * This is always in millimeters.
  * So if your probe triggers 5.3mm after the probe touches the material, enter 5.3, (always a positive number).
* Set 'Spindle on/off/ delay' to the desired Pierce delay in seconds or to Zero, if it is zero then the *tools* PierceDelay will be used. 

## Things you can adjust by editing the post:
* Open the .cps file in Notepad
* Search for 'USER ADJUST'
* You can change the probe distance and probe feedrate to suite your machine.
* Feedrate cannot be lower than 50mm/min, this is a GRBL internal limit.
* Note that changing the probe feedrate will change the point at which the probe triggers, so once you have figured out the probe offset
  you should NOT change the probe feedrate.
