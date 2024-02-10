/**
   Original sample post:
   Copyright (C) 2012-2022 by Autodesk, Inc.
   All rights reserved.

   RS-274D Multi-axis post processor configuration.
   The above post sample forms the basis for this post.

   $Revision: 44023 7d0062d6193198b074b1bb174154c949e72cb2df $
   $Date: 2022-11-04 21:33:14 $
   $Id$

   FORKID {2EECF092-D7C3-4ACA-BFE6-377B72950FE9}

   This post:
   Additions based on the OpenBuildsFusion360PostGRBL.cps
   Custom Post-Processor for grblHAL based Openbuilds-style CNC machines
   For BlackboxX32 based on ESP32 for grblHAL with 4th axis

   DOES NOT DO LASER AND PLASMA - ONLY MILLING

   Made possible by
   Swarfer  https://github.com/swarfer/GRBL-Post-Processor
   Sharmstr https://github.com/sharmstr/GRBL-Post-Processor
   Strooom  https://github.com/Strooom/GRBL-Post-Processor
   This post-Processor should work on GRBLhal-based machines

   Changelog
   xx/Dec/2022 - V0.0.1     : Initial version (Swarfer)
   Jan 2024 - V0.0.2b : machine simulation

*/
obversion = 'V0.0.2_beta';
debugMode = false;
description = "OB BBx32 Multi-axis Post Processor Milling Only";
vendor = "Openbuilds";
vendorUrl = "http://www.openbuilds.com";
machineControl = "grblHAL 1.1 ESP32 / BlackBox X32 XYZA",
legal = "Copyright (C) 2012-2023 by Autodesk, Inc. and OpenBuilds.com";
model = "grblHAL";
certificationLevel = 2;
minimumRevision = 45892;

longDescription = "MultiAxis post for Blackbox X32 with single rotary axis A or plain XYZ - MILLING ONLY.";

extension = "gcode";
setCodePage("ascii");

var permittedCommentChars = " ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789.,=_-*/\\:";
capabilities = CAPABILITY_MILLING | CAPABILITY_MACHINE_SIMULATION;
tolerance = spatial(0.002, MM);

minimumChordLength = spatial(0.25, MM);
minimumCircularRadius = spatial(0.125, MM); // 0.125
maximumCircularRadius = spatial(1000, MM);
minimumCircularSweep = toRad(0.1);
maximumCircularSweep = toRad(180);
allowHelicalMoves = true;
allowSpiralMoves = false;
allowedCircularPlanes = (1 << PLANE_XY); // allow only XY plane
// if you need vertical arcs then uncomment the line below
allowedCircularPlanes = (1 << PLANE_XY) | (1 << PLANE_ZX) | (1 << PLANE_YZ); // allow all planes, recentering arcs solves YZ/XZ arcs
// if you allow vertical arcs then be aware that ObCONTROL will not display the gocde correctly, but it WILL cut correctly.

/*
   useMultiAxisFeatures: { // DTS remove this and make always false
   title      : "Use G68.2",
   description: "Enable to output G68.2 blocks for 3+2 operations, disable to output rotary angles.",
   group      : "multiAxis",
   scope      : ["machine", "post"],
   type       : "boolean",
   value      : false
   },
*/

var showSequenceNumbers = false; // DTS - never want line numbers
var preloadTool = false;         // DTS - never want to preload
var forceCyclesOff = true;       // DTS - wait until CONTROL can display cycles before enabling this

// user-defined properties
properties =
   {
   optionalStop: {
      title: "Optional stop",
      description: "Outputs optional stop code when necessary in the code.",
      group: "preferences",
      type: "boolean",
      value: true,
      scope: "post"
      },
   useToolChange: { // replaces generateMultiple
      title: "Use Toolchange M6",
      description: "Use tool change codes (true) or use , file per tool output (false).",
      group: "preferences",
      type: "boolean",
      value: false,
      scope: "post"
      },
   routerType: {
      group: "spindle",
      title: "SPINDLE Router type",
      description: "Select the type of spindle you have.",
      type: "enum",
      value: "other",
      values: [
         { title: "Other", id: "other" },
         { title: "Router11", id: "Router11" },
         { title: "Makita RT0701", id: "Makita" },
         { title: "Dewalt 611", id: "Dewalt" }
      ]
      },
   spindleOnOffDelay:  {
      group: "spindle",
      title: "SPINDLE on/off delay",
      description: "Time (in seconds) the spindle needs to get up to speed or stop",
      type: "number",
      value: 1.5
      },
   
   /*
      preloadTool: {
      title      : "Preload tool",
      description: "Preloads the next tool at a tool change (if any).",
      group      : "preferences",
      type       : "boolean",
      value      : true,
      scope      : "post"
      },
   */
   safePositionMethod: {
      title: "Safe Retracts",
      description: "Select your desired retract option. 'Clearance Height' retracts to the operation clearance height.",
      group: "startEndPos",
      type: "enum",
      values: [
         //{title:"G28", id:"G28"},
         { title: "G53", id: "G53" },
         { title: "Clearance Height", id: "clearanceHeight" }
      ],
      value: "G53",
      scope: "post"
      },
   gotoMCSatend: {
      group: "startEndPos",
      title: "EndPos: Use Machine Coordinates (G53) at end of job?",
      description: "Yes will do G53 G0 x{machinehomeX} y(machinehomeY) (Machine Coordinates), No will do G0 x(machinehomeX) y(machinehomeY) (Work Coordinates) at end of program",
      type: "boolean",
      scope: "post",
      value: false
      },
   machineHomeX: {
      group: "startEndPos",
      title: "EndPos: End of job X position (MM).",
      description: "(G53 or G54) X position to move to in Millimeters",
      type: "spatial",
      scope: "post",
      value: toPreciseUnit(-10, MM)
      },
   machineHomeY: {
      group: "startEndPos",
      title: "EndPos: End of job Y position (MM).",
      description: "(G53 or G54) Y position to move to in Millimeters.",
      type: "spatial",
      scope: "post",
      value: toPreciseUnit(-10, MM)
      },
   machineHomeZ: {
      group: "startEndPos",
      title: "startEndPos: START and End of job Z position (MCS Only) (MM)",
      description: "G53 Z position to move to in Millimeters, normally negative.  Moves to this distance below Z home.",
      type: "spatial",
      scope: "post",
      value: toPreciseUnit(-10, MM)
      },

   safeRetractDistance: {
      title: "Safe retract distance for rewinds",
      description: "Specifies the distance to add to retract distance when rewinding rotary axes.",
      group: "multiAxis",
      type: "spatial",
      value: 0,
      scope: "post"
      },
   useABCPrepositioning: {
      title: "Preposition rotaries",
      description: "Enable to preposition rotary axes prior to G68.2 blocks.",
      group: "multiAxis",
      scope: ["machine", "post"],
      type: "boolean",
      value: true
      },
   /*
      showSequenceNumbers: {
      title      : "Use sequence numbers",
      description: "'Yes' outputs sequence numbers on each block, 'Only on tool change' outputs sequence numbers on tool change blocks only, and 'No' disables the output of sequence numbers.",
      group      : "formats",
      type       : "enum",
      values     : [
         {title:"Yes", id:"true"},
         {title:"No", id:"false"},
         {title:"Only on tool change", id:"toolChange"}
      ],
      value: "false",
      scope: "post"
      },
      sequenceNumberStart: {
      title      : "Start sequence number",
      description: "The number at which to start the sequence numbers.",
      group      : "formats",
      type       : "integer",
      value      : 10,
      scope      : "post"
      },
      sequenceNumberIncrement: {
      title      : "Sequence number increment",
      description: "The amount by which the sequence number is incremented by in each block.",
      group      : "formats",
      type       : "integer",
      value      : 5,
      scope      : "post"
      },
   */
   separateWordsWithSpace: {
      title: "Separate words with space",
      description: "Adds spaces between words if 'yes' is selected.",
      group: "formats",
      type: "boolean",
      value: true,
      scope: "post"
      },
   showNotes: {
      title: "Show notes",
      description: "Writes setup and operation notes as comments in the output code.",
      group: "formats",
      type: "boolean",
      value: true,
      scope: "post"
      },
   writeMachine: {
      title: "Write machine",
      description: "Output the machine settings in the header of the code.",
      group: "formats",
      type: "boolean",
      value: true,
      scope: "post"
      },
   writeTools: {
      title: "Write tool list",
      description: "Output a tool list in the header of the code.",
      group: "formats",
      type: "boolean",
      value: true,
      scope: "post"
      }
   };

// define the order of display
groupDefinitions = 
   {
   spindle: {     title:"Spindle Options", description:"Options for spindle control", collapsed: false, order: 5},
   startEndPos: { title:"Start and End positions", description:"Set options for start and end safety positioning", collapsed: false, order: 7},
   }   

var numberOfToolSlots = 9999;
var numberOfSections = 0;

var wcsDefinitions =
   {
   useZeroOffset: false, // set to 'true' to allow for workoffset 0, 'false' treats 0 as 1
   wcs: [
      { name: "Standard", format: "G", range: [54, 59] }, // standard WCS, output as G54-G59
      { name: "Extended", format: "G59.#", range: [1, 3] } // extended WCS, output as G59.7, etc.
   // {name:"Extended", format:"G54 P#", range:[1, 64]} // extended WCS, output as G54 P7, etc.
   ]
   };

var singleLineCoolant = false; // specifies to output multiple coolant codes in one line rather than in separate lines
// samples:
// {id: COOLANT_THROUGH_TOOL, on: 88, off: 89}
// {id: COOLANT_THROUGH_TOOL, on: [8, 88], off: [9, 89]}
// {id: COOLANT_THROUGH_TOOL, on: "M88 P3 (myComment)", off: "M89"}
var coolants = [
   { id: COOLANT_FLOOD, on: 8 },
   { id: COOLANT_MIST },  // not supported by X32
   { id: COOLANT_THROUGH_TOOL },
   { id: COOLANT_AIR },
   { id: COOLANT_AIR_THROUGH_TOOL },
   { id: COOLANT_SUCTION },
   { id: COOLANT_FLOOD_MIST },
   { id: COOLANT_FLOOD_THROUGH_TOOL },
   { id: COOLANT_OFF, off: 9 }
];

var gFormat = createFormat({ prefix: "G", decimals: 1 });
var mFormat = createFormat({ prefix: "M", decimals: 0 });
var hFormat = createFormat({ prefix: "H", decimals: 0 });
var dFormat = createFormat({ prefix: "D", decimals: 0 });

var xyzFormat = createFormat({ decimals: (unit == MM ? 3 : 4), type: FORMAT_REAL, minDigitsRight: 1 });
//var abcFormat = createFormat({decimals:3, type:FORMAT_REAL, scale:DEG});
var abcFormat = createFormat({ decimals: 3, type: FORMAT_REAL, scale: DEG, minDigitsRight: 1 });
var feedFormat = createFormat({ decimals: (unit == MM ? 1 : 2) });
var inverseTimeFormat = createFormat({ decimals: 3, type: FORMAT_REAL });
var toolFormat = createFormat({ decimals: 0 });
var rpmFormat = createFormat({ decimals: 0 });
var secFormat = createFormat({ decimals: 3, type: FORMAT_REAL }); // seconds - range 0.001-1000
var taperFormat = createFormat({ decimals: 1, scale: DEG });

var xOutput = createOutputVariable({ prefix: "X" }, xyzFormat);
var yOutput = createOutputVariable({ prefix: "Y" }, xyzFormat);
var zOutput = createOutputVariable({ onchange: function ()
                                       {
                                       retracted = false;
                                       }, prefix: "Z"
                                   }, xyzFormat);
var aOutput = createOutputVariable({ prefix: "A" }, abcFormat);
var bOutput = createOutputVariable({ prefix: "B" }, abcFormat);
var cOutput = createOutputVariable({ prefix: "C" }, abcFormat);
var feedOutput = createOutputVariable({ prefix: "F" }, feedFormat);
var inverseTimeOutput = createOutputVariable({ prefix: "F", control: CONTROL_FORCE }, inverseTimeFormat);
var sOutput = createOutputVariable({ prefix: "S", control: CONTROL_FORCE }, rpmFormat);
var dOutput = createOutputVariable({}, dFormat);

// circular output
var iOutput = createOutputVariable({ prefix: "I", control: CONTROL_FORCE }, xyzFormat);
var jOutput = createOutputVariable({ prefix: "J", control: CONTROL_FORCE }, xyzFormat);
var kOutput = createOutputVariable({ prefix: "K", control: CONTROL_FORCE }, xyzFormat);

var gMotionModal = createOutputVariable({}, gFormat); // modal group 1 // G0-G3, ...
var gPlaneModal = createOutputVariable({ onchange: function ()
   {
   gMotionModal.reset();
   }
                                       }, gFormat); // modal group 2 // G17-19
var gAbsIncModal = createOutputVariable({}, gFormat); // modal group 3 // G90-91
var gFeedModeModal = createOutputVariable({}, gFormat); // modal group 5 // G93-94
var gUnitModal = createOutputVariable({}, gFormat); // modal group 6 // G20-21
var gCycleModal = createOutputVariable({}, gFormat); // modal group 9 // G81, ...
var gRetractModal = createOutputVariable({}, gFormat); // modal group 10 // G98-99
var gRotationModal = createOutputVariable({}, gFormat); // modal group 16 // G68-G69

// settings

var WARNING_WORK_OFFSET = 0;

// collected state
var fileSequenceNumber = 1; // DTS multifile naming
var currentworkOffset = 54; // the current WCS in use, so we can retract Z between sections if needed

var NsequenceNumber;
var retracted = false; // specifies that the tool has been retracted to the safe plane
var firstNote = true; // handles output of notes from multiple setups
var forceSpindleSpeed = false;
// from BB post - multifile output variables
var filesToGenerate = 1;       //used to figure out how many files will be generated so we can diplay in header
var fileIndexFormat = createFormat({ width: 2, zeropad: true, decimals: 0 });
var isNewfile = false;  // set true when a new file has just been started
var numberOfSections = 0;
var isLaser = false;  // todo - laser and plasma
var isPlasma = false;

var haveRapid = false;  // assume no rapid moves
var linmove = 1;        // linear move mode
var retractHeight = 1;  // will be set by onParameter and used in onLinear to detect rapids

var linearizeSmallArcs = false;     // arcs with radius < toolRadius have radius errors, linearize instead?
var toolRadius = toPreciseUnit(1, MM);
var lengthCompensated = false; // true if length compensation is on

/**
   Writes the specified block.
*/
function writeBlock()
   {
   if (!formatWords(arguments))
      {
      return;
      }
   if (showSequenceNumbers == true)
      {
      writeWords2("N" + NsequenceNumber, arguments);
      NsequenceNumber += getProperty("sequenceNumberIncrement", 1);
      }
   else
      {
      writeWords(arguments);
      }
   }

function formatComment(text,  indent )
   {
   indent = String(indent);
   //return "(" + String(text).replace(/[()]/g, "") + ")";
   return ("(" + indent + filterText(String(text), permittedCommentChars) + ")");
   }

/**
   Writes the specified block - used for tool changes only.
*/
function writeToolBlock()
   {
   if (getProperty("useToolChange", false))
      {
      writeComment("writeToolBock");
      //var show = getProperty("showSequenceNumbers",false);
      //setProperty("showSequenceNumbers", (show == "true" || show == "toolChange") ? "true" : "false");
      //todo - DTS - make tool calls optional
      writeBlock(arguments);
      //setProperty("showSequenceNumbers", show);
      }
   else
      {
      writeComment("Tool change avoided, see other file");
      }
   }

/**
   Output a comment.
   DTS - use multilines if needed
*/
function writeComment(text)
   {
   // split the line so no comment is longer than 70 chars
   text = filterText(text.trim(), permittedCommentChars);
   var indent = '';
   if (text.length > 70)
      {
      //text = String(text).replace( /[^a-zA-Z\d:=,.]+/g, " "); // remove illegal chars
      var bits = text.split(" "); // get all the words
      var out = '';
      for (i = 0; i < bits.length; i++)
         {
         out += bits[i] + " "; // additional space after first line
         if (out.length > 60)           // a long word on the end can take us to 80 chars!
            {
            writeln(formatComment(out.trim(), indent));
            out = "";
            indent = '   ';
            }
         }
      if (out.length > 0)
         writeln(formatComment(out.trim(),indent));
      }
   else
      writeln(formatComment(text,''));
   }

// Start of machine configuration logic
var compensateToolLength = false; // add the tool length to the pivot distance for nonTCP rotary heads
var useMultiAxisFeatures = false; // not for grblHAL, enable to use control enabled tilted plane, can be overridden with a property
var useABCPrepositioning = false; // enable to preposition rotary axes prior to tilted plane output, can be overridden with a property
var forceMultiAxisIndexing = false; // force multi-axis indexing for 3D programs
var eulerConvention = EULER_ZXZ_R; // euler angle convention for 3+2 operations

// internal variables, do not change
var receivedMachineConfiguration;
var operationSupportsTCP;
var multiAxisFeedrate;

/**
   Activates the machine configuration (both from CAM and hardcoded)
*/
function activateMachine()
   {
   if (debugMode) writeComment("DEBUG activateMachine");
   // disable unsupported rotary axes output
   if (!machineConfiguration.isMachineCoordinate(0) && (typeof aOutput != "undefined"))
      {
      if (debugMode) writeComment("DEBUG activateMachine A disable");
      aOutput.disable();
      }
   if (!machineConfiguration.isMachineCoordinate(1) && (typeof bOutput != "undefined"))
      {
      if (debugMode) writeComment("DEBUG activateMachine B disable");
      bOutput.disable();
      }
   if (!machineConfiguration.isMachineCoordinate(2) && (typeof cOutput != "undefined"))
      {
      if (debugMode) writeComment("DEBUG activateMachine C disable");
      cOutput.disable();
      }

   // setup usage of multiAxisFeatures
   useMultiAxisFeatures = getProperty("useMultiAxisFeatures") != undefined ? getProperty("useMultiAxisFeatures") :
                          (typeof useMultiAxisFeatures != "undefined" ? useMultiAxisFeatures : false);
   useABCPrepositioning = getProperty("useABCPrepositioning") != undefined ? getProperty("useABCPrepositioning") :
                          (typeof useABCPrepositioning != "undefined" ? useABCPrepositioning : false);
   if (debugMode) writeComment("DEBUG useMultiAxisFeatures " + useMultiAxisFeatures);
   if (debugMode) writeComment("DEBUG useABCPrepositioning " + useABCPrepositioning);
   // don't need to modify any settings if 3-axis machine
   if (!machineConfiguration.isMultiAxisConfiguration())
      {
      return;
      }

   // save multi-axis feedrate settings from machine configuration
   var mode = machineConfiguration.getMultiAxisFeedrateMode();
   var type = mode == FEED_INVERSE_TIME ? machineConfiguration.getMultiAxisFeedrateInverseTimeUnits() :
              (mode == FEED_DPM ? machineConfiguration.getMultiAxisFeedrateDPMType() : DPM_STANDARD);
   multiAxisFeedrate =
      {
      mode: mode,
      maximum: machineConfiguration.getMultiAxisFeedrateMaximum(),
      type: type,
      tolerance: mode == FEED_DPM ? machineConfiguration.getMultiAxisFeedrateOutputTolerance() : 0,
      bpwRatio : mode == FEED_DPM ? machineConfiguration.getMultiAxisFeedrateBpwRatio() : 1
      };

   // setup of retract/reconfigure  TAG: Only needed until post kernel supports these machine config settings
   if (receivedMachineConfiguration && machineConfiguration.performRewinds())
      {
      safeRetractDistance = machineConfiguration.getSafeRetractDistance();
      safePlungeFeed = machineConfiguration.getSafePlungeFeedrate();
      safeRetractFeed = machineConfiguration.getSafeRetractFeedrate();
      }
   if (typeof safeRetractDistance == "number" && getProperty("safeRetractDistance") != undefined && getProperty("safeRetractDistance") != 0)
      {
      safeRetractDistance = getProperty("safeRetractDistance");
      }

   // setup for head configurations
   if (machineConfiguration.isHeadConfiguration())
      {
      compensateToolLength = typeof compensateToolLength == "undefined" ? false : compensateToolLength;
      }

   // calculate the ABC angles and adjust the points for multi-axis operations
   // rotary heads may require the tool length be added to the pivot length
   // so we need to optimize each section individually
   if (machineConfiguration.isHeadConfiguration() && compensateToolLength)
      {
      writeComment('compensating')   ;
      for (var i = 0; i < getNumberOfSections(); ++i)
         {
         var section = getSection(i);
         if (section.isMultiAxis())
            {
            machineConfiguration.setToolLength(section.getTool().overallLength); // define the tool length for head adjustments
            section.optimizeMachineAnglesByMachine(machineConfiguration, OPTIMIZE_AXIS);
            }
         }
      }
   else     // tables and rotary heads with TCP support can be optimized with a single call
      {
      if (debugMode) writeComment('optimizing machine angles')   ;
      optimizeMachineAngles2(OPTIMIZE_AXIS);
      }
   }

/**
   Defines a hardcoded machine configuration
*/
function defineMachine()
   {
   if (debugMode) writeComment("DEBUG defineMachine");
   if (!receivedMachineConfiguration)   // CAM provided machine configuration takes precedence
      {
      writeComment("Using hardcoded machine XYZ - if you want A-axis then define a suitable machine in Fusion360");
      // if (true) { // hardcoded machine configuration takes precedence
      // define machine kinematics
      var useTCP = false;
      // todo - allow user to choose axis direction
      //var aAxis = createAxis({coordinate:X, table:true, axis:[1, 0, 0], offset:[0, 0, 0], range:[0,360], cyclic:true, preference:-1, tcp:useTCP});
      //machineConfiguration = new MachineConfiguration(aAxis);
      machineConfiguration = new MachineConfiguration();
      machineConfiguration.setVendor("OpenBuilds");
      machineConfiguration.setModel("BBx32");
      machineConfiguration.setDescription(description);

      // multiaxis settings
      if (machineConfiguration.isHeadConfiguration())
         {
         machineConfiguration.setVirtualTooltip(false); // translate the pivot point to the virtual tool tip for nonTCP rotary heads
         }

      // retract / reconfigure
      var performRewinds = false; // set to true to enable the retract/reconfigure logic
      if (performRewinds)
         {
         machineConfiguration.enableMachineRewinds(); // enables the retract/reconfigure logic
         safeRetractDistance = (unit == IN) ? 1 : 25; // additional distance to retract out of stock, can be overridden with a property
         safeRetractFeed = (unit == IN) ? 20 : 500; // retract feed rate
         safePlungeFeed = (unit == IN) ? 10 : 250; // plunge feed rate
         machineConfiguration.setSafeRetractDistance(safeRetractDistance);
         machineConfiguration.setSafeRetractFeedrate(safeRetractFeed);
         machineConfiguration.setSafePlungeFeedrate(safePlungeFeed);
         var stockExpansion = new Vector(toPreciseUnit(0.1, IN), toPreciseUnit(0.1, IN), toPreciseUnit(0.1, IN)); // expand stock XYZ values
         machineConfiguration.setRewindStockExpansion(stockExpansion);
         }

      // multi-axis feedrates
      if (machineConfiguration.isMultiAxisConfiguration())
         {
         machineConfiguration.setMultiAxisFeedrate(
            useTCP ? FEED_FPM : getProperty("useDPMFeeds") ? FEED_DPM : FEED_INVERSE_TIME,
            9999.99, // maximum output value for inverse time feed rates
            getProperty("useDPMFeeds") ? DPM_COMBINATION : INVERSE_MINUTES, // INVERSE_MINUTES/INVERSE_SECONDS or DPM_COMBINATION/DPM_STANDARD
            0.5, // tolerance to determine when the DPM feed has changed
            1.0 // ratio of rotary accuracy to linear accuracy for DPM calculations
         );
         }

      /* home positions */
      // machineConfiguration.setHomePositionX(toPreciseUnit(0, IN));
      // machineConfiguration.setHomePositionY(toPreciseUnit(0, IN));
      // machineConfiguration.setRetractPlane(toPreciseUnit(0, IN));

      // define the machine configuration
      setMachineConfiguration(machineConfiguration); // inform post kernel of hardcoded machine configuration
      if (receivedMachineConfiguration)
         {
         warning(localize("The provided CAM machine configuration is overwritten by the postprocessor."));
         receivedMachineConfiguration = false; // CAM provided machine configuration is overwritten
         }
      }
   }
// End of machine configuration logic

function onOpen()
   {
   if (debugMode)
      {
      warning("debugMode is true");
      }
   //setWriteInvocations(debugMode);
   // define and enable machine configuration
   receivedMachineConfiguration = machineConfiguration.isReceived();
   if (typeof defineMachine == "function")
      {
      defineMachine(); // hardcoded machine configuration
      }
   activateMachine(); // enable the machine optimizations and settings

   gRotationModal.format(69); // Default to G69 Rotation Off

   if (!getProperty("separateWordsWithSpace"))
      {
      setWordSeparator("");
      }

   showSequenceNumbers = getProperty("showSequenceNumbers", false);
   NsequenceNumber = getProperty("sequenceNumberStart", 1);
   preloadTool = getProperty("preloadTool", false);
   numberOfSections = getNumberOfSections();

   numberOfSections = getNumberOfSections();
   checkforDuplicatetools(); // sets filesToGenerate
   writeHeader(0);

   if (programName)
      {
      writeComment(programName);
      }
   if (programComment)
      {
      writeComment(programComment);
      }

   // dump machine configuration
   var vendor = machineConfiguration.getVendor();
   var model = machineConfiguration.getModel();
   var description = machineConfiguration.getDescription();

   if (getProperty("writeMachine") && (vendor || model || description))
      {
      writeComment(localize("Machine"));
      if (vendor)
         {
         writeComment("  " + localize("vendor") + ": " + vendor);
         }
      if (model)
         {
         writeComment("  " + localize("model") + ": " + model);
         }
      if (description)
         {
         writeComment("  " + localize("description") + ": " + description);
         }
      }

   // dump tool information
   if (getProperty("writeTools"))
      {
      var zRanges = {};
      if (is3D())
         {
         var numberOfSections = getNumberOfSections();
         for (var i = 0; i < numberOfSections; ++i)
            {
            var section = getSection(i);
            var zRange = section.getGlobalZRange();
            var tool = section.getTool();
            if (zRanges[tool.number])
               {
               zRanges[tool.number].expandToRange(zRange);
               }
            else
               {
               zRanges[tool.number] = zRange;
               }
            }
         }

      var tools = getToolTable();
      if (tools.getNumberOfTools() > 0)
         {
         for (var i = 0; i < tools.getNumberOfTools(); ++i)
            {
            var tool = tools.getTool(i);
            var comment = "T" + toolFormat.format(tool.number) + " " +
                          "D=" + xyzFormat.format(tool.diameter) + " " +
                          localize("CR") + "=" + xyzFormat.format(tool.cornerRadius);
            if ((tool.taperAngle > 0) && (tool.taperAngle < Math.PI))
               {
               comment += " " + localize("TAPER") + "=" + taperFormat.format(tool.taperAngle) + localize("deg");
               }
            if (zRanges[tool.number])
               {
               comment += " - " + localize("ZMIN") + "=" + xyzFormat.format(zRanges[tool.number].getMinimum());
               }
            comment += " - " + getToolTypeName(tool.type);
            writeComment(comment);
            }
         }
      }

   // output setup notes
   if (getProperty("showNotes"))
      {
      writeSetupNotes();
      }

   if ((getNumberOfSections() > 0) && (getSection(0).workOffset == 0))
      {
      for (var i = 0; i < getNumberOfSections(); ++i)
         {
         if (getSection(i).workOffset > 0)
            {
            error(localize("Using multiple work offsets is not possible if the initial work offset is 0."));
            return;
            }
         }
      }

   // absolute coordinates and feed per min
   //writeBlock(gAbsIncModal.format(90), gFeedModeModal.format(94), gFeedModeModal.format(49));
   writeBlock(gAbsIncModal.format(90), gFeedModeModal.format(94), writeBlock(gPlaneModal.format(17)) );

   switch (unit)
      {
      case IN:
         writeBlock(gUnitModal.format(20));
         break;
      case MM:
         writeBlock(gUnitModal.format(21));
         break;
      }
   }

function onComment(message)
   {
   writeComment(message);
   }

/** Force output of X, Y, and Z. */
function forceXYZ()
   {
   xOutput.reset();
   yOutput.reset();
   zOutput.reset();
   }

/** Force output of A, B, and C. */
function forceABC()
   {
   aOutput.reset();
   bOutput.reset();
   cOutput.reset();
   }

/** Force output of X, Y, Z, A, B, C, and F on next output. */
function forceAny()
   {
   forceXYZ();
   forceABC();
   feedOutput.reset();
   }

var lengthCompensationActive = false;
/** Disables length compensation if currently active or if forced. */
function disableLengthCompensation(force)
   {
      if (lengthCompensationActive || force)
         {
         if (debugMode) writeComment('DEBUG disableLengthCompensation');
         validate(retracted, "Cannot cancel length compensation if the machine is not fully retracted.");
         writeBlock(gFormat.format(49));
         lengthCompensationActive = false;
         }
   }

var currentWorkPlaneABC = undefined;

function forceWorkPlane()
   {
   currentWorkPlaneABC = undefined;
   }

function defineWorkPlane(_section, _setWorkPlane)
   {
   var abc = new Vector(0, 0, 0);
   if (forceMultiAxisIndexing || !is3D() || machineConfiguration.isMultiAxisConfiguration())   // use 5-axis indexing for multi-axis mode
      {
      // set working plane after datum shift

      if (_section.isMultiAxis())
         {
         cancelTransformation();
         if (_setWorkPlane)
            {
            forceWorkPlane();
            }
         if (machineConfiguration.isMultiAxisConfiguration())
            {
            abc = _section.getInitialToolAxisABC();
            if (_setWorkPlane)
               {
               onCommand(COMMAND_UNLOCK_MULTI_AXIS);
               positionABC(abc, true);
               }
            }
         else
            {
            if (_setWorkPlane)
               {
               var d = _section.getGlobalInitialToolAxis();
               // position
               writeBlock(
                  gAbsIncModal.format(90),
                  gMotionModal.format(0),
                  "I" + xyzFormat.format(d.x), "J" + xyzFormat.format(d.y), "K" + xyzFormat.format(d.z)
               );
               }
            }
         }
      else
         {
         if (useMultiAxisFeatures)
            {
            abc = _section.workPlane.getEuler2(eulerConvention);
            cancelTransformation();
            }
         else
            {
            abc = getWorkPlaneMachineABC(_section.workPlane, true);
            }
         if (_setWorkPlane)
            {
            setWorkPlane(abc);
            }
         }
      }
   else     // pure 3D
      {
      var remaining = _section.workPlane;
      if (!isSameDirection(remaining.forward, new Vector(0, 0, 1)))
         {
         error(localize("Tool orientation is not supported."));
         return abc;
         }
      setRotation(remaining);
      }
   if (currentSection && (currentSection.getId() == _section.getId()))
      {
      operationSupportsTCP = (_section.isMultiAxis() || !useMultiAxisFeatures) && _section.getOptimizedTCPMode() == OPTIMIZE_NONE;
      }
   return abc;
   }

function cancelWorkPlane()
   {
   writeBlock(gRotationModal.format(69)); // cancel frame
   forceWorkPlane();
   }

function setWorkPlane(abc)
   {
   if (is3D() && !machineConfiguration.isMultiAxisConfiguration())
      {
      return; // ignore
      }
   if (!((currentWorkPlaneABC == undefined) ||
         abcFormat.areDifferent(abc.x, currentWorkPlaneABC.x) ||
         abcFormat.areDifferent(abc.y, currentWorkPlaneABC.y) ||
         abcFormat.areDifferent(abc.z, currentWorkPlaneABC.z)))
      {
      return; // no change
      }
   onCommand(COMMAND_UNLOCK_MULTI_AXIS);

   if (!retracted)
      {
      writeRetract(Z);
      }

   if (useMultiAxisFeatures)
      {
      cancelWorkPlane();
      if (machineConfiguration.isMultiAxisConfiguration())
         {
         var machineABC = abc.isNonZero() ? getWorkPlaneMachineABC(currentSection.workPlane, false) : abc;
         if (useABCPrepositioning || abc.isZero())
            {
            positionABC(machineABC, true);
            }
         setCurrentABC(machineABC); // required for machine simulation
         }
      if (abc.isNonZero())
         {
         gRotationModal.reset();
         writeBlock(gRotationModal.format(68.2), "X" + xyzFormat.format(0), "Y" + xyzFormat.format(0), "Z" + xyzFormat.format(0), "I" + abcFormat.format(abc.x), "J" + abcFormat.format(abc.y), "K" + abcFormat.format(abc.z)); // set frame
         writeBlock(gFormat.format(53.1)); // turn machine
         }
      }
   else
      {
      positionABC(abc, true);
      }
   onCommand(COMMAND_LOCK_MULTI_AXIS);

   currentWorkPlaneABC = abc;
   }

function getWorkPlaneMachineABC(workPlane, rotate)
   {
   var W = workPlane; // map to global frame

   var currentABC = isFirstSection() ? new Vector(0, 0, 0) : getCurrentDirection();
   var abc = machineConfiguration.getABCByPreference(W, currentABC, ABC, PREFER_PREFERENCE, ENABLE_ALL);

   var direction = machineConfiguration.getDirection(abc);
   if (!isSameDirection(direction, W.forward))
      {
      error(localize("Orientation not supported."));
      }

   if (rotate && !currentSection.isOptimizedForMachine())
      {
      machineConfiguration.setToolLength(compensateToolLength ? currentSection.getTool().overallLength : 0); // define the tool length for head adjustments
      currentSection.optimize3DPositionsByMachine(machineConfiguration, abc, OPTIMIZE_AXIS);
      }
   return abc;
   }

function positionABC(abc, force)
   {
   if (typeof unwindABC == "function")
      {
      unwindABC(abc, false);
      }
   if (force)
      {
      forceABC();
      }
   var a = aOutput.format(abc.x);
   var b = bOutput.format(abc.y);
   var c = cOutput.format(abc.z);
   if (a || b || c)
      {
      if (!retracted)
         {
         if (typeof moveToSafeRetractPosition == "function")
            {
            moveToSafeRetractPosition();
            }
         else
            {
            writeRetract(Z);
            }
         }
      onCommand(COMMAND_UNLOCK_MULTI_AXIS);
      gMotionModal.reset();
      writeBlock(gMotionModal.format(0), a, b, c);
      setCurrentABC(abc); // required for machine simulation
      }
   }

function onPassThrough(text)
   {
   writeNotes(text);
   }

function onParameter(name, value)
   {
   switch (name)
      {
      case "job-notes": // write setup notes when multiple setups are used
         if (!firstNote)
            {
            writeNotes(value, true);
            }
         firstNote = false;
         break;
      }
   name = name.replace(" ", "_"); // dratted indexOF cannot have spaces in it!
   if ( (name.indexOf("retractHeight_value") >= 0 ) )   // == "operation:retractHeight value")
      {
      retractHeight = value;
      if (debugMode) writeComment("DEBUG onParameter:retractHeight = " + retractHeight);
      }      
   }

function writeNotes(text, asComment)
   {
   if (text)
      {
      var lines = String(text).split("\n");
      var r2 = new RegExp("[\\s]+$", "g");
      for (line in lines)
         {
         var comment = lines[line].replace(r2, "");
         if (comment)
            {
            if (asComment)
               {
               onComment(comment);
               }
            else
               {
               writeln(comment);
               }
            }
         }
      }
   }

function onSection()
   {
   var nmbrOfSections = getNumberOfSections();  // how many operations are there in total
   var sectionId = getCurrentSectionId();       // what is the number of this operation (starts from 0)
   var section = getSection(sectionId);         // what is the section-object for this operation
   var tool = section.getTool();
   var maxfeedrate = section.getMaximumFeedrate();
   haveRapid = false; // drilling sections will have rapids even when other ops do not

   onRadiusCompensation(); // must check every section
   toolRadius = tool.diameter / 2.0;

   var insertToolCall = isToolChangeNeeded("number");

   var splitHere = !getProperty("useToolChange") && insertToolCall && !isFirstSection();

   var newWorkOffset = isNewWorkOffset();
   var newWorkPlane = isNewWorkPlane();

   // cleanup before tool change
   if (insertToolCall || newWorkOffset || newWorkPlane)
      {
      // stop spindle before retract during tool change
      if (insertToolCall && !isFirstSection())
         {
         onCommand(COMMAND_STOP_SPINDLE);
         }
      // retract to safe plane
      if (!is3D() && insertToolCall)   //DTS - dont really want to retract all the way for plain XYZ operations
         {
         zOutput.reset();
         writeRetract(Z);
         }
      // cancel tool length compensation
      if (insertToolCall && !isFirstSection())
         {
         if (!retracted)
            writeRetract(Z);
         disableLengthCompensation(false);
         }
      }

   if (splitHere)
      {
      writeComment("splitting");   
      //writeBlock(mFormat.format(30)); // stop program
      // todo -bug here, first file has null gcode
      debug("splitting file " + fileSequenceNumber);
      fileSequenceNumber++;
      //var fileIndexFormat = createFormat({width:3, zeropad: true, decimals:0});
      //var path = FileSystem.replaceExtension(getOutputPath(), fileIndexFormat.format(fileSequenceNumber) + "of" + filesToGenerate + "." + extension);
      var path = makeFileName(fileSequenceNumber);
      if (isRedirecting())
         {
         warning('still redirecting in onsection');
         closeRedirection();
         }
      redirectToFile(path);
      forceAny();
      writeHeader(getCurrentSectionId());
      isNewfile = true;  // trigger a spindleondelay
      }
   // DTS below this goes into new file
   writeln("");
   if (debugMode) writeComment("DEBUG onSection " + (sectionId + 1));
   // Insert a small comment section to identify the related G-Code in a large multi-operations file
   var comment = "Operation " + (sectionId + 1) + " of " + nmbrOfSections;
   if (hasParameter("operation-comment"))
      {
      comment = comment + " : " + getParameter("operation-comment");
      }
   writeComment(comment);
   if (debugMode)
      writeComment("DEBUG retractHeight = " + retractHeight);

   // output section notes
   if (getProperty("showNotes"))
      {
      writeSectionNotes();
      }

   if (insertToolCall && getProperty("useToolChange"))
      {
      if (debugMode) writeComment('DEBUG insert tool call');
      forceWorkPlane();

      setCoolant(COOLANT_OFF);

      if (!isFirstSection() && getProperty("optionalStop"))
         {
         onCommand(COMMAND_OPTIONAL_STOP);
         }

      if (tool.number > numberOfToolSlots)
         {
         warning(localize("Tool number exceeds maximum value."));
         }

      disableLengthCompensation(false);
      writeToolBlock("T" + toolFormat.format(tool.number), mFormat.format(6));
      if (tool.comment)
         {
         writeComment(tool.comment);
         }
      var showToolZMin = false;
      if (showToolZMin)
         {
         if (is3D())
            {
            var zRange = toolZRange();
            writeComment(localize("ZMIN") + "=" + zRange.getMinimum());
            }
         }

      if (preloadTool) // DTS always false
         {
         var nextTool = getNextTool(tool.number);
         if (nextTool)
            {
            writeBlock("T" + toolFormat.format(nextTool.number));
            }
         else
            {
            // preload first tool
            var firstToolNumber = getFirstTool().number;
            if (tool.number != firstToolNumber)
               {
               writeBlock("T" + toolFormat.format(firstToolNumber));
               }
            }
         }
      }

   var spindleChanged = tool.type != TOOL_PROBE &&
                        (insertToolCall || forceSpindleSpeed || isFirstSection() ||
                         (rpmFormat.areDifferent(spindleSpeed, sOutput.getCurrent())) ||
                         (tool.clockwise != getPreviousSection().getTool().clockwise));
   if (spindleChanged)
      {
      forceSpindleSpeed = false;
      if (spindleSpeed < 1)
         {
         error(localize("Spindle speed out of range."));
         return;
         }
      if (spindleSpeed > 99999)
         {
         warning(localize("Spindle speed exceeds maximum value."));
         }
      var rpmchanged = !isFirstSection() && rpmFormat.areDifferent(spindleSpeed, sOutput.getCurrent())
      if (debugMode) writeComment('DEBUG rpmchanged ' + rpmchanged);
      s = sOutput.format(spindleSpeed);
      if (s)
         mFormat.format(1); // always output M if S changed
      m = mFormat.format(tool.clockwise ? 3 : 4)
      writeBlock(m, s);
      //if (s && !m) // means a speed change, spindle was already on, delay half the time
      if ( rpmchanged )
         onDwell(getProperty('spindleOnOffDelay') / 2);
      else   
         // spindle on delay if needed
         if (m && (isFirstSection() || isNewfile))
            onDwell( getProperty('spindleOnOffDelay') );
      }

   // wcs
   if (insertToolCall)   // force work offset when changing tool
      {
      currentWorkOffset = undefined;
      }

   if (currentSection.workOffset != currentWorkOffset)
      {
      writeBlock(currentSection.wcs);
      currentWorkOffset = currentSection.workOffset;
      forceWorkPlane();
      }

   forceXYZ();

   // position rotary axes for multi-axis and 3+2 operations
   var abc = defineWorkPlane(currentSection, true);

   // set coolant after we have positioned at Z
   setCoolant(tool.coolant);

   forceAny();

   var initialPosition = getFramePosition(currentSection.getInitialPosition());
   if (!retracted && !insertToolCall)
      {
      if (getCurrentPosition().z < initialPosition.z)
         {
         writeBlock(gMotionModal.format(0), zOutput.format(initialPosition.z));
         }
      }

   if (insertToolCall || !lengthCompensationActive || retracted || (!isFirstSection() && getPreviousSection().isMultiAxis()))
      {
      //if (debugMode) writeComment("1146");
      var lengthOffset = tool.lengthOffset;
      //if (debugMode) writeComment("lengthoffset " + zOutput.format(lengthOffset));
      if (lengthOffset > numberOfToolSlots)
         {
         error(localize("Length offset out of range."));
         return;
         }

      gMotionModal.reset();
      writeBlock(gPlaneModal.format(17));

      // cancel compensation prior to enabling it, required when switching G43/G43.4 modes
      disableLengthCompensation(false);

      if (!machineConfiguration.isHeadConfiguration())
         {
         //if (debugMode) writeComment("1162 start");
         writeBlock(
            gAbsIncModal.format(90),
            gMotionModal.format(0), xOutput.format(initialPosition.x), yOutput.format(initialPosition.y)
            );
         //writeBlock(gMotionModal.format(0), gFormat.format(getOffsetCode()), zOutput.format(initialPosition.z), hFormat.format(lengthOffset));
         //writeBlock(gMotionModal.format(0), gFormat.format(getOffsetCode()), zOutput.format(initialPosition.z), ' ; 1253');
         //if (debugMode) writeComment("1162 end");
         }
      else
         {
         //if (debugMode) writeComment('1172');
         writeBlock(
            gAbsIncModal.format(90),
            gMotionModal.format(0),
            gFormat.format(getOffsetCode()), xOutput.format(initialPosition.x),
            yOutput.format(initialPosition.y),
            zOutput.format(initialPosition.z), hFormat.format(lengthOffset), ' ; 1264');
         }
      lengthCompensationActive = false; // DTS force false
      }
   else
      {
      if (debugMode) writeComment('DEBUG 1185');
      writeBlock(
         gAbsIncModal.format(90),
         gMotionModal.format(0),
         xOutput.format(initialPosition.x),
         yOutput.format(initialPosition.y)
      );
      }

   //validate(lengthCompensationActive, "Length compensation is not active.");
   }

function onSectionEnd()
   {
   if (debugMode) writeComment("DEBUG onSectionEnd begin " + getCurrentSectionId() + 1)   ;
   writeBlock(gPlaneModal.format(17));
   if (!isLastSection() && (getNextSection().getTool().coolant != tool.coolant))
      {
      setCoolant(COOLANT_OFF);
      }
   writeBlock(gFeedModeModal.format(94));
     
   if (isRedirecting())
      {
      if (isLastSection() ||  ( tool.number != getNextSection().getTool().number ) )
         {
         writeln("");
         onCommand(COMMAND_STOP_SPINDLE);
         if (debugMode) writeComment('DEBUG onsectionend calling onclose');
         onClose();
         closeRedirection();
         }
      }
   forceAny();
   if (debugMode) writeComment("DEBUG onSectionEnd end " + getCurrentSectionId() + 1)   ;   
   }

function onDwell(seconds)
   {
   if (seconds > 99999.999)
      {
      warning(localize("Dwelling time is out of range."));
      }
   seconds = clamp(0.001, seconds, 99999.999);
   writeBlock(gFormat.format(4), "P" + secFormat.format(seconds));
   }

function onSpindleSpeed(spindleSpeed)
   {
   writeBlock(sOutput.format(spindleSpeed));
   gMotionModal.reset(); // force a G word after a spindle speed change to keep CONTROL happy
   }

function onCycle()
   {
   writeBlock(gPlaneModal.format(17));
   }

   // return formatted x,y,z,R for drill cycles
function getCommonCycle(x, y, z, r)
   {
   forceXYZ();
   return [xOutput.format(x), yOutput.format(y),
           zOutput.format(z),
           "R" + xyzFormat.format(r)];
   }

// DTS  - some of these not supported - turn off until CONTROL support cycle display
function onCyclePoint(x, y, z)
   {
   if (forceCyclesOff)
      {
      expandCyclePoint(x, y, z);
      return;
      }
   var forward;
   if (currentSection.isOptimizedForMachine())
      {
      forward = machineConfiguration.getOptimizedDirection(currentSection.workPlane.forward, getCurrentDirection(), false, false);
      }
   else
      {
      forward = getRotation().forward;
      }
   // if not in XY plane then expand
   if (!isSameDirection(forward, new Vector(0, 0, 1)))
      {
      expandCyclePoint(x, y, z);
      return;
      }
   if (isFirstCyclePoint())
      {
      repositionToCycleClearance(cycle, x, y, z);

      var F = cycle.feedrate;
      var P = !cycle.dwell ? 0 : clamp(0.001, cycle.dwell, 99999.999); // in seconds
      var Q = !cycle.incrementalDepth ? cycle.depth / 2 : clamp(0.01, cycle.incrementalDepth, cycle.depth);

      switch (cycleType)
         {
         case "drilling":
            writeComment("drilling");
            writeBlock(
               gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format(81),
               getCommonCycle(x, y, z, cycle.retract),
               feedOutput.format(F)
            );
            break;
         case "counter-boring":
            writeComment("counter-boring"); // also drill with dwell
            if (P > 0)
               {
               writeBlock(
                  gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format(82),
                  getCommonCycle(x, y, z, cycle.retract),
                  "P" + secFormat.format(P), // not optional
                  feedOutput.format(F)
               );
               }
            else
               {
               writeComment("no P given");
               writeBlock(
                  gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format(82),
                  getCommonCycle(x, y, z, cycle.retract),
                  "P" + secFormat.format(0.1), // not optional
                  feedOutput.format(F)
               );
               }
            break;
         case "chip-breaking":
            writeComment("chipbreak");
            //            expandCyclePoint(x, y, z);
            writeBlock(
               gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format(73),
               getCommonCycle(x, y, z, cycle.retract),
               "Q" + xyzFormat.format(Q),
               feedOutput.format(F)
            );
            break;
         case "deep-drilling":
            writeComment("deep drill");
            if (P > 0)
               {
               expandCyclePoint(x, y, z);
               }
            else
               {
               writeBlock(
                  gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format(83),
                  getCommonCycle(x, y, z, cycle.retract),
                  "Q" + xyzFormat.format(Q),
                  feedOutput.format(F)
               );
               }
            break;
         case "tapping":
            writeComment("tapping"); //todo unsupport
            if (!F)
               {
               F = tool.getTappingFeedrate();
               }
            writeBlock(
               gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format((tool.type == TOOL_TAP_LEFT_HAND) ? 74 : 84),
               getCommonCycle(x, y, z, cycle.retract),
               feedOutput.format(F)
            );
            break;
         case "left-tapping":    // todo unsupport
            writeComment("left tapping");
            if (!F)
               {
               F = tool.getTappingFeedrate();
               }
            writeBlock(
               gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format(74),
               getCommonCycle(x, y, z, cycle.retract),
               feedOutput.format(F)
            );
            break;
         case "right-tapping":
            writeComment("right tapping"); //todo unsupport
            if (!F)
               {
               F = tool.getTappingFeedrate();
               }
            writeBlock(
               gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format(84),
               getCommonCycle(x, y, z, cycle.retract),
               feedOutput.format(F)
            );
            break;
         case "fine-boring": // not supported
            expandCyclePoint(x, y, z);
            break;
         case "back-boring": // todo unsupport
            writeComment("back boring");
            if (P > 0)
               {
               expandCyclePoint(x, y, z);
               }
            else
               {
               var I = cycle.shift * 1;
               var J = cycle.shift * 0;
               writeBlock(
                  gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format(87),
                  getCommonCycle(x, y, z, cycle.retract),
                  "I" + xyzFormat.format(I),
                  "J" + xyzFormat.format(J),
                  "K" + xyzFormat.format(cycle.bottom - cycle.backBoreDistance),
                  feedOutput.format(F)
               );
               }
            break;
         case "reaming":   // todo unsupport
            writeComment("reaming");
            if (feedFormat.getResultingValue(cycle.feedrate) != feedFormat.getResultingValue(cycle.retractFeedrate))
               {
               expandCyclePoint(x, y, z);
               break;
               }
            writeBlock(
               gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format(85),
               getCommonCycle(x, y, z, cycle.retract),
               feedOutput.format(F)
            );
            break;
         case "stop-boring": // todo unsupport
            writeComment("stop boring");
            writeBlock(
               gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format(86),
               getCommonCycle(x, y, z, cycle.retract),
               feedOutput.format(F),
               // conditional(P > 0, "P" + secFormat.format(P)),
               "P" + secFormat.format(P) // not optional
            );
            break;
         case "manual-boring": // todo unsupport
            writeComment("manual boring");
            writeBlock(
               gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format(88),
               getCommonCycle(x, y, z, cycle.retract),
               "P" + secFormat.format(P), // not optional
               feedOutput.format(F)
            );
            break;
         case "boring": // todo unsupport
            writeComment("boring");
            if (feedFormat.getResultingValue(cycle.feedrate) != feedFormat.getResultingValue(cycle.retractFeedrate))
               {
               expandCyclePoint(x, y, z);
               break;
               }
            if (P > 0)
               {
               writeBlock(
                  gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format(89),
                  getCommonCycle(x, y, z, cycle.retract),
                  "P" + secFormat.format(P), // not optional
                  feedOutput.format(F)
               );
               }
            else
               {
               writeBlock(
                  gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format(85),
                  getCommonCycle(x, y, z, cycle.retract),
                  feedOutput.format(F)
               );
               }
            break;
         default:
            expandCyclePoint(x, y, z);
         }
      }
   else
      {
      if (cycleExpanded)
         {
         expandCyclePoint(x, y, z);
         }
      else
         {
         var _x = xOutput.format(x);
         var _y = yOutput.format(y);
         if (!_x && !_y)
            {
            xOutput.reset(); // at least one axis is required
            _x = xOutput.format(x);
            }
         writeBlock("   ", _x, _y);
         }
      }
   }

function onCycleEnd()
   {
   if (!cycleExpanded)
      {
      writeBlock(gCycleModal.format(80));
      zOutput.reset();
      }
   }

var pendingRadiusCompensation = -1;
// DTS - no radius comp in grblHAL
function onRadiusCompensation()
   {
   //pendingRadiusCompensation = radiusCompensation;
   pendingRadiusCompensation = -1; // always off   - warn too?
   if (radiusCompensation > 0)
      error('Radius compensation not supported, set it to "in computer"');
   }

// DTS - do we need rapid detect?
// probably, even if the user license cannot do multiaxis we must still do something for 3axis
function onRapid(_x, _y, _z)
   {
   haveRapid = true;
   var x = xOutput.format(_x);
   var y = yOutput.format(_y);
   var z = zOutput.format(_z);
   if (x || y || z)
      {
      if (pendingRadiusCompensation >= 0)
         {
         error(localize("Radius compensation mode cannot be changed at rapid traversal."));
         return;
         }
      writeBlock(gMotionModal.format(0), x, y, z);
      feedOutput.reset();
      }
   }

function onLinear(_x, _y, _z, feed)
   {
   // at least one axis is required
   if (haveRapid || (pendingRadiusCompensation >= 0) )
      {
      // ensure that we end at desired position when compensation is turned off
      // and always output X and Y after a rapid else arcs may go mad
      xOutput.reset();
      yOutput.reset();
      }
   var x = xOutput.format(_x);
   var y = yOutput.format(_y);
   var z = zOutput.format(_z);
   var f = feedOutput.format(feed);
   if (x || y || z)
      {
      linmove = 1;          // have to have a default!
      if (!haveRapid)  // if z is changing
         {
         if (_z < retractHeight) // compare it to retractHeight, below that is G1, >= is G0
            linmove = 1;
         else
            linmove = 0;
         if (debugMode && (linmove == 0)) writeComment("DEBUG NOrapid " + _z + ' ' + retractHeight);
         }
      writeBlock(gMotionModal.format(linmove), x, y, z, f);
      }
   else
      if (f)
         {
         if (getNextRecord().isMotion())   // try not to output feed without motion
            {
            if (debugMode) writeComment('DEBUG onlinear feedoutput reset')   ;
            feedOutput.reset(); // force feed on next line
            }
         else
            {
               if (debugMode) writeComment('DEBUG onLinear feedoutput')   ;
            writeBlock(gMotionModal.format(1), f);
            }
         }
   }

// DTS - might get tricky here if no rapids coming from engine
function onRapid5D(_x, _y, _z, _a, _b, _c)
   {
   haveRapid = true;
   if (!currentSection.isOptimizedForMachine())
      {
      error(localize("This post configuration has not been customized for 5-axis simultaneous toolpath."));
      return;
      }
   if (pendingRadiusCompensation >= 0)
      {
      error(localize("Radius compensation mode cannot be changed at rapid traversal."));
      return;
      }
   var x = xOutput.format(_x);
   var y = yOutput.format(_y);
   var z = zOutput.format(_z);
   var a = aOutput.format(_a);
   var b = bOutput.format(_b);
   var c = cOutput.format(_c);
   if (x || y || z || a || b || c)
      {
      writeBlock(gMotionModal.format(0), x, y, z, a, b, c);
      feedOutput.reset();
      }
   }

function onLinear5D(_x, _y, _z, _a, _b, _c, feed, feedMode)
   {
   if (!currentSection.isOptimizedForMachine())
      {
      error(localize("This post configuration has not been customized for 5-axis simultaneous toolpath."));
      return;
      }
   // at least one axis is required
   if (pendingRadiusCompensation >= 0)
      {
      error(localize("Radius compensation cannot be activated/deactivated for 5-axis move."));
      return;
      }
   var x = xOutput.format(_x);
   var y = yOutput.format(_y);
   var z = zOutput.format(_z);
   var a = aOutput.format(_a);
   var b = bOutput.format(_b);
   var c = cOutput.format(_c);

   // get feedrate number
   if (feedMode == FEED_INVERSE_TIME)
      {
      feedOutput.reset();
      }
   var fMode = feedMode == FEED_INVERSE_TIME ? 93 : 94;
   var f = feedMode == FEED_INVERSE_TIME ? inverseTimeOutput.format(feed) : feedOutput.format(feed);

   if (x || y || z || a || b || c)
      {
      writeBlock(gFeedModeModal.format(fMode), gMotionModal.format(1), x, y, z, a, b, c, f);
      }
   else
      if (f)
         {
         if (getNextRecord().isMotion())   // try not to output feed without motion
            {
            feedOutput.reset(); // force feed on next line
            }
         else
            {
            writeBlock(gFeedModeModal.format(fMode), gMotionModal.format(1), f);
            }
         }
   }

// this code was generated with the help of ChatGPT AI
// calculate the centers for the 2 circles passing through both points at the given radius
// if error then returns -9.9375 for all coordinates
// define points as var point1 = { x: 0, y: 0 };
// returns an array of 2 of those things
function calculateCircleCenters(point1, point2, radius)
   {
   // Calculate the distance between the points
   var distance = Math.sqrt(     Math.pow(point2.x - point1.x, 2) + Math.pow(point2.y - point1.y, 2)   );
   if (distance > (radius * 2))
      {
      //-9.9375 is perfectly stored by doubles and singles and will pass an equality test
      center1X = center1Y = center2X = center2Y = -9.9375;
      }
   else
      {
      // Calculate the midpoint between the points
      var midpointX = (point1.x + point2.x) / 2;
      var midpointY = (point1.y + point2.y) / 2;

      // Calculate the angle between the line connecting the points and the x-axis
      var angle = Math.atan2(point2.y - point1.y, point2.x - point1.x);

      // Calculate the distance from the midpoint to the center of each circle
      var halfChordLength = Math.sqrt(Math.pow(radius, 2) - Math.pow(distance / 2, 2));

      // Calculate the centers of the circles
      var center1X = midpointX + halfChordLength * Math.cos(angle + Math.PI / 2);
      var center1Y = midpointY + halfChordLength * Math.sin(angle + Math.PI / 2);

      var center2X = midpointX + halfChordLength * Math.cos(angle - Math.PI / 2);
      var center2Y = midpointY + halfChordLength * Math.sin(angle - Math.PI / 2);
      }

   // Return the centers of the circles as an array of objects
   return [
      { x: center1X, y: center1Y },
      { x: center2X, y: center2Y }   ];
   }

// given the 2 points and existing center, find a new, more accurate center
// only works in x,y
// point parameters are Vectors
// returns a Vector point with the revised center values in x,y, ignore Z
function newCenter(p1, p2, oldcenter, radius)
   {
   // inputs are vectors, convert
   var point1 = { x: p1.x, y: p1.y };
   var point2 = { x: p2.x, y: p2.y };

   var newcenters = calculateCircleCenters(point1, point2, radius);
   if ((newcenters[0].x == newcenters[1].x) && (newcenters[0].y == -9.9375))
      {
      // error in calculation, distance between points > diameter
      return oldcenter;   
      }
   // now find the new center that is closest to the old center
   //writeComment("nc1 " + newcenters[0].x + " " + newcenters[0].y);
   nc1 = new Vector(newcenters[0].x, newcenters[0].y, 0); // note Z is not valid
   //writeComment("nc2 " + newcenters[1].x + " " + newcenters[1].y);
   nc2 = new Vector(newcenters[1].x, newcenters[1].y, 0);
   d1 = Vector.diff(oldcenter, nc1).length;
   d2 = Vector.diff(oldcenter, nc2).length;
   if (d1 < d2)
      return nc1;
   else
      return nc2;
   }

/*
   helper for on Circular - calculates a new center for arcs with differing radii
   returns the revised center vector
*/   
function ReCenter(start, end, center, radius, cp)
   {
      var r1,r2,diff,pdiff;
   
   switch (cp)
      {
      case PLANE_XY:
         writeComment('recenter XY');
         var nCenter = newCenter(start, end, center,  radius );
         // writeComment("old center " + center.x + " , " + center.y);
         // writeComment("new center " + nCenter.x + " , " + nCenter.y);
         center.x = nCenter.x;
         center.y = nCenter.y;
         center.z = (start.z + end.z) / 2.0;

         r1 = Vector.diff(start, center).length;
         r2 = Vector.diff(end, center).length;
         if (r1 != r2)
            {
            diff = r1 - r2;
            pdiff = Math.abs(diff / r1 * 100);
            if (pdiff  > 0.01)
               {
               if (debugMode) writeComment("DEBUG Recenter R1 " + r1 + " r2 " + r2 + " d " + (r1 - r2) + " pdoff " + pdiff );
               }
            }
         break;
      case PLANE_ZX:
         writeComment('recenter ZX');
         // generate fake x,y vectors
         var st = new Vector( start.x, start.z, 0);
         var ed = new Vector(end.x, end.z, 0)
         var ct = new Vector(center.x, center.z, 0);
         var nCenter = newCenter( st, ed, ct,  radius);
         // translate fake x,y values
         center.x = nCenter.x;
         center.z = nCenter.y;
         r1 = Vector.diff(start, center).length;
         r2 = Vector.diff(end, center).length;
         if (r1 != r2)
            {
            diff = r1 - r2;
            pdiff = Math.abs(diff / r1 * 100);
            if (pdiff  > 0.01)
               {
               if (debugMode) writeComment("DEBUG ZX R1 " + r1 + " r2 " + r2 + " d " + (r1 - r2) + " pdoff " + pdiff );
               }
            }
         break;
      case PLANE_YZ:
         writeComment('recenter YZ');
         var st = new Vector(start.z, start.y, 0);
         var ed = new Vector(end.z, end.y, 0)
         var ct = new Vector(center.z, center.y, 0);
         var nCenter = newCenter(st, ed, ct,  radius);
         center.y = nCenter.y;
         center.z = nCenter.x;
         r1 = Vector.diff(start, center).length;
         r2 = Vector.diff(end, center).length;
         if (r1 != r2)
            {
            diff = r1 - r2;
            pdiff = Math.abs(diff / r1 * 100);
            if (pdiff  > 0.01)
               {
               if (debugMode) writeComment("DEBUG YZ R1 " + r1 + " r2 " + r2 + " d " + (r1 - r2) + " pdoff " + pdiff );
               }
            }
         break;
      }
   return center;
   }

function onCircular(clockwise, cx, cy, cz, x, y, z, feed)
   {
   // one of X/Y and I/J are required
   // DTS nix that, at least XY and IJ always required for grbl in XY plane
   if (pendingRadiusCompensation >= 0)
      {
      error(localize("Radius compensation cannot be activated/deactivated for a circular move."));
      return;
      }

   var start = getCurrentPosition();
   var center = new Vector(cx, cy, cz);
   var end = new Vector(x, y, z);
   var cp = getCircularPlane();
   //writeComment("cp " + cp);

   if (isFullCircle())
      {
      writeComment("full circle");
      linearize(tolerance);
      return;
      }

   // first fix the center 'height'
   // for an XY plane, fix Z to be between start.z and end.z
   switch (cp)
      {
      case PLANE_XY:
         center.z = (start.z + end.z) / 2.0; // doing this fixes most arc radius lengths
         break;
      case PLANE_YZ:
         // fix X
         center.x = (start.x + end.x) / 2.0;
         break;
      case PLANE_ZX:
         // fix Y
         center.y = (start.y + end.y) / 2.0;
         break;
      default:
         writeComment("no plane");
      }
   // check for differing radii
   var r1 = Vector.diff(start, center).length;
   var r2 = Vector.diff(end, center).length;
   // if linearizing and this is small, don't bother to recenter
   //if ( !(properties.linearizeSmallArcs &&  (r1 < toolRadius)) )

   if ( (r1 < toolRadius) && (r1 != r2) )  // always recenter small arcs
         {
         var diff = r1 - r2;
         var pdiff = Math.abs(diff / r1 * 100);
         // if percentage difference too great
         if (pdiff > 0.01)
            {
            //writeComment("recenter");
            // adjust center to make radii equal
            if (debugMode) writeComment("DEBUG r1 " + r1 + " r2 " + r2 + " d " + (r1 - r2) + " pdoff " + pdiff );
            center = ReCenter(start, end, center, (r1 + r2) /2, cp);
            }
         }

   // DTS - arcs smaller than bitradius always have significant radius errors, so get radius and linearize them 
   // (because we cannot change minimumCircularRadius here)
   // note that larger arcs still have radius errors, but they are a much smaller percentage of the radius
   // todo - grblHAL yet to be tested thoroughly for arc limits
   var rad = Vector.diff(start,center).length;

   if (rad < toPreciseUnit(2, MM))
      if (linearizeSmallArcs && (rad < toolRadius))
         {
         debugMode = true;   
         if (debugMode) writeComment("DEBUG linearizing arc radius " + round(rad, 4) + " toolRadius " + round(toolRadius, 3) + ' plane=' + cp);
         linearize(tolerance);
         if (debugMode) writeComment("DEBUG done");
         debugMode = false;
         return;
         }
   
   switch (cp)
      {
      case PLANE_XY:
         xOutput.reset(); // always have X and Y, Z will output if it changed
         yOutput.reset();
         iOutput.reset();  // always have ijk as needed
         jOutput.reset();
         writeBlock(gPlaneModal.format(17), gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), iOutput.format(center.x - start.x), jOutput.format(center.y - start.y), feedOutput.format(feed));
         break;
      case PLANE_ZX:
         xOutput.reset(); // always have X and Z, Y will output if it changed
         zOutput.reset();
         iOutput.reset();  // always have ijk as needed
         kOutput.reset();
         writeBlock(gPlaneModal.format(18), gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), iOutput.format(center.x - start.x), kOutput.format(center.z - start.z), feedOutput.format(feed));
         break;
      case PLANE_YZ:
         zOutput.reset(); // always have Z and Y, X will output if it changed
         yOutput.reset();
         jOutput.reset();
         kOutput.reset();
         writeBlock(gPlaneModal.format(19), gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), jOutput.format(center.y - start.y), kOutput.format(center.z - start.z), feedOutput.format(feed));
         break;
      default:
         linearize(tolerance);
      }
   }

var currentCoolantMode = COOLANT_OFF;
var coolantOff = undefined;
var forceCoolant = false;

function setCoolant(coolant)
   {
   if (debugMode) writeComment('DEBUG setCoolant ' + coolant);
   var coolantCodes = getCoolantCodes(coolant);
   if (Array.isArray(coolantCodes))
      {
      if (singleLineCoolant)
         {
         writeBlock(coolantCodes.join(getWordSeparator()));
         }
      else
         {
         for (var c in coolantCodes)
            {
            writeBlock(coolantCodes[c]);
            }
         }
      return undefined;
      }
   return coolantCodes;
   }

function getCoolantCodes(coolant)
   {
   var multipleCoolantBlocks = new Array(); // create a formatted array to be passed into the outputted line
   if (!coolants)
      {
      error(localize("Coolants have not been defined."));
      }
   if (tool.type == TOOL_PROBE)   // avoid coolant output for probing
      {
      coolant = COOLANT_OFF;
      }
   if (coolant == currentCoolantMode && (!forceCoolant || coolant == COOLANT_OFF))
      {
      return undefined; // coolant is already active
      }
   if ((coolant != COOLANT_OFF) && (currentCoolantMode != COOLANT_OFF) && (coolantOff != undefined) && !forceCoolant)
      {
      if (Array.isArray(coolantOff))
         {
         for (var i in coolantOff)
            {
            multipleCoolantBlocks.push(coolantOff[i]);
            }
         }
      else
         {
         multipleCoolantBlocks.push(coolantOff);
         }
      }
   forceCoolant = false;

   var m;
   var coolantCodes = {};
   for (var c in coolants)   // find required coolant codes into the coolants array
      {
      if (coolants[c].id == coolant)
         {
         coolantCodes.on = coolants[c].on;
         if (coolants[c].off != undefined)
            {
            coolantCodes.off = coolants[c].off;
            break;
            }
         else
            {
            for (var i in coolants)
               {
               if (coolants[i].id == COOLANT_OFF)
                  {
                  coolantCodes.off = coolants[i].off;
                  break;
                  }
               }
            }
         }
      }
   if (coolant == COOLANT_OFF)
      {
      m = !coolantOff ? coolantCodes.off : coolantOff; // use the default coolant off command when an 'off' value is not specified
      }
   else
      {
      coolantOff = coolantCodes.off;
      m = coolantCodes.on;
      }

   if (!m)
      {
      onUnsupportedCoolant(coolant);
      m = 9;
      }
   else
      {
      if (Array.isArray(m))
         {
         for (var i in m)
            {
            multipleCoolantBlocks.push(m[i]);
            }
         }
      else
         {
         multipleCoolantBlocks.push(m);
         }
      currentCoolantMode = coolant;
      for (var i in multipleCoolantBlocks)
         {
         if (typeof multipleCoolantBlocks[i] == "number")
            {
            multipleCoolantBlocks[i] = mFormat.format(multipleCoolantBlocks[i]);
            }
         }
      return multipleCoolantBlocks; // return the single formatted coolant value
      }
   return undefined;
   }

var mapCommand =
   {
   COMMAND_END: 2,
   COMMAND_SPINDLE_CLOCKWISE: 3,
   COMMAND_SPINDLE_COUNTERCLOCKWISE: 4,
   COMMAND_STOP_SPINDLE: 5,
   COMMAND_ORIENTATE_SPINDLE: 19, // DTS - what is this?
   COMMAND_LOAD_TOOL: 6
   };

function onCommand(command)
   {
   //if (debugMode) writeComment('oncommand ' + command);
   switch (command)
      {
      case COMMAND_STOP:
         if (debugMode) writeComment('DEBUG oncommand stop' + command);
         writeBlock(mFormat.format(0));
         forceSpindleSpeed = true;
         forceCoolant = true;
         return;
      case COMMAND_OPTIONAL_STOP:
         if (debugMode) writeComment('DEBUG oncommand optstop' + command);
         writeBlock(mFormat.format(1));
         forceSpindleSpeed = true;
         forceCoolant = true;
         return;
      case COMMAND_COOLANT_ON:
         if (debugMode) writeComment('DEBUG oncommand coolon' + command);
         setCoolant(COOLANT_FLOOD);
         return;
      case COMMAND_COOLANT_OFF:
         if (debugMode) writeComment('DEBUG oncommand cooloff ' + command);
         setCoolant(COOLANT_OFF);
         return;
      case COMMAND_START_SPINDLE:
         if (debugMode) writeComment('DEBUG oncommand start ' + command);
         onCommand(tool.clockwise ? COMMAND_SPINDLE_CLOCKWISE : COMMAND_SPINDLE_COUNTERCLOCKWISE);
         return;
      case COMMAND_LOCK_MULTI_AXIS:
         //writeComment('oncommand lock ' + command);
         return;
      case COMMAND_UNLOCK_MULTI_AXIS:
         //writeComment('oncommand unlock ' + command);
         return;
      case COMMAND_BREAK_CONTROL:
         writeComment('oncommand break ' + command);
         return;
      case COMMAND_TOOL_MEASURE:
         writeComment('oncommand toolmeas ' + command);
         return;
      }

   var stringId = getCommandStringId(command);
   var mcode = mapCommand[stringId];
   //writeComment('oncommand mcode ' + mcode + " " + stringId);
   if (mcode != undefined)
      {
      if (debugMode) writeComment('DEBUG oncommand mapped ' + stringId + "=" + mcode);
      writeBlock(mFormat.format(mcode));
      }
   else
      {
      onUnsupportedCommand(command);
      }
   }


/** Output block to do safe retract and/or move to home position. */
function writeRetract()
   {
   if (debugMode) writeComment('DEBUG writeRetract start');
   var words = []; // store all retracted axes in an array
   var retractAxes = new Array(false, false, false);
   var method = getProperty("safePositionMethod");
   if (method == "clearanceHeight")
      {
      if (!is3D())
         {
         error(localize("Safe retract option 'Clearance Height' is only supported when all operations are along the setup Z-axis."));
         return;
         }
      }
   validate(arguments.length != 0, "No axis specified for writeRetract().");

   for (i in arguments)
      {
      //writeComment("argument " + i + " " + arguments[i])   ;
      retractAxes[arguments[i]] = true;
      }
   if ((retractAxes[0] || retractAxes[1]) && !retracted)   // retract Z first before moving to X/Y home
      {
      error(localize("Retracting in X/Y is not possible without being retracted in Z."));
      return;
      }
   // special conditions
   /*
      if (retractAxes[2]) { // Z doesn't use G53
      method = "G28";
      }
   */

   // define home positions
   var _xHome;
   var _yHome;
   var _zHome;
   if (method == "G28") // DTS - want G53 retracts
      {
      _xHome = toPreciseUnit(0, MM);
      _yHome = toPreciseUnit(0, MM);
      _zHome = toPreciseUnit(0, MM);
      }
   else
      {
      if (getProperty("gotoMCSatend", false))
         {
         _xHome = toPreciseUnit(getProperty('machineHomeX'), MM);
         _yHome = toPreciseUnit(getProperty('machineHomeY'), MM);
         }
      else
         {
         _xHome = machineConfiguration.hasHomePositionX() ? machineConfiguration.getHomePositionX() : toPreciseUnit(0, MM);
         _yHome = machineConfiguration.hasHomePositionY() ? machineConfiguration.getHomePositionY() : toPreciseUnit(0, MM);
         }
      if (method == "clearanceHeight")         
         {
         if (debugMode) writeComment('DEBUG Retract to initial.z');
         var section = getSection(0);         // what is the section-object for this operation
         var initialPosition = getFramePosition(section.getInitialPosition());         
         _zHome  = initialPosition.z;
         }
      else
         _zHome = machineConfiguration.getRetractPlane() != 0 ? machineConfiguration.getRetractPlane() : toPreciseUnit(getProperty('machineHomeZ'), MM);
      }

   for (var i = 0; i < arguments.length; ++i)
      {
      switch (arguments[i])
         {
         case X:
            words.push("X" + xyzFormat.format(_xHome));
            xOutput.reset();
            break;
         case Y:
            words.push("Y" + xyzFormat.format(_yHome));
            yOutput.reset();
            break;
         case Z:
            words.push("Z" + xyzFormat.format(_zHome));
            zOutput.reset();
            retracted = true;
            break;
         default:
            error(localize("Unsupported axis specified for writeRetract()."));
            return;
         }
      }
   if (words.length > 0)
      {
      switch (method)
         {
         case "G28":
            gMotionModal.reset();
            gAbsIncModal.reset();
            writeBlock(gFormat.format(28), gAbsIncModal.format(91), words);
            writeBlock(gAbsIncModal.format(90));
            break;
         case "G53":
            gMotionModal.reset();
            if (getProperty('gotoMCSatend'))
               writeBlock(gAbsIncModal.format(90), gFormat.format(53), gMotionModal.format(0), words);
            else
               {
               if (retractAxes[2]) //todo should probably check that x and y are absent
                  {
                  writeln("(This relies on homing, see https://openbuilds.com/search/127200199/?q=G53+fusion )");
                  writeBlock(gAbsIncModal.format(90), gFormat.format(53), gMotionModal.format(0), words);
                  }
               else
                  writeBlock(gAbsIncModal.format(90), gMotionModal.format(0), words);
               }
            break;
         case "clearanceHeight":
            writeBlock(gAbsIncModal.format(90), gMotionModal.format(0), words);
            break;
         default:
            error(localize("Unsupported safe position method."));
            return;
         }
      }
      if (debugMode) writeComment('DEBUG writeRetract end');
   }

// Start of onRewindMachine logic
/** Allow user to override the onRewind logic. */
function onRewindMachineEntry(_a, _b, _c)
   {
   return false;
   }

/** Retract to safe position before indexing rotaries. */
function onMoveToSafeRetractPosition()
   {
   writeRetract(Z); // retract to home position
   // cancel TCP so that tool doesn't follow rotaries
   if (currentSection.isMultiAxis() && operationSupportsTCP)
      {
      disableLengthCompensation(false);
      }
   // DTS - may need a property for this so user can select
   if (false)   // enable to move to safe position in X & Y
      {
      writeRetract(X, Y);
      }
   }

/** Rotate axes to new position above reentry position */
function onRotateAxes(_x, _y, _z, _a, _b, _c)
   {
   // position rotary axes
   xOutput.disable();
   yOutput.disable();
   zOutput.disable();
   invokeOnRapid5D(_x, _y, _z, _a, _b, _c);
   setCurrentABC(new Vector(_a, _b, _c));
   xOutput.enable();
   yOutput.enable();
   zOutput.enable();
   }

/** Return from safe position after indexing rotaries. */
function onReturnFromSafeRetractPosition(_x, _y, _z)
   {
   // reinstate TCP / tool length compensation
   if (!lengthCompensationActive)
      {
      writeComment('DEBUG tool offset  2334');
      writeBlock(gFormat.format(getOffsetCode()), hFormat.format(tool.lengthOffset), ' ; 2331');
      lengthCompensationActive = true;
      }

   // position in XY
   forceXYZ();
   xOutput.reset();
   yOutput.reset();
   zOutput.disable();
   invokeOnRapid(_x, _y, _z);

   // position in Z
   zOutput.enable();
   invokeOnRapid(_x, _y, _z);
   }
// End of onRewindMachine logic

function getOffsetCode()
   {
   //var offsetCode = 43.1;
   var offsetCode = 43.1;
   /* DTS grblHAL has no offset code
      if (currentSection.isMultiAxis() || (!useMultiAxisFeatures && !currentSection.isZOriented()))
      {
      if (machineConfiguration.isMultiAxisConfiguration() && operationSupportsTCP)
      {
         offsetCode = 43.4;
      }
      else if (!machineConfiguration.isMultiAxisConfiguration())
      {
         offsetCode = 43.5;
      }
      }
   */
   return offsetCode;
   }

function onClose()
   {
   if (debugMode) writeComment('DEBUG onclose');
   setCoolant(COOLANT_OFF);

   writeRetract(Z);
   disableLengthCompensation(true);

   setWorkPlane(new Vector(0, 0, 0)); // reset working plane

   writeRetract(X, Y);

   onImpliedCommand(COMMAND_END);
   onCommand(COMMAND_STOP_SPINDLE);
   writeBlock(mFormat.format(30)); // stop program, spindle stop, coolant off
   if (debugMode) writeComment('DEBUG onclose end');
   }

function writeHeader(secID)
   {
   if (debugMode) writeComment("DEBUG Header start " + secID + 1);

   numberOfSections = getNumberOfSections();

   var productName = getProduct();
   writeComment("Made in : " + productName);
   writeComment("G-Code optimized for " + machineControl + " controller");
   writeComment(description);
   cpsname = FileSystem.getFilename(getConfigurationPath());
   writeComment("Post-Processor : " + cpsname + " " + obversion);
   var unitstr = (unit == MM) ? 'mm' : 'inch';
   writeComment("Units = " + unitstr);
   if (isJet())
      {
      error("laser and plasma not implemented in this post")
      //writeComment("Laser UseZ = " + properties.UseZ);
      //writeComment("Laser UsePierce = " + properties.UsePierce);
      }

   if (allowedCircularPlanes == 1)
      {
      writeln("");   
      writeComment("Arcs are limited to the XY plane: if you want vertical arcs then edit allowedCircularPlanes in the CPS file");
      }
   else   
      {
      writeln("");   
      writeComment("Arcs can occur on XY,YZ,ZX planes: CONTROL may not display them correctly but they will cut correctly");
      }

   writeln("");
   if (hasGlobalParameter("document-path"))
      {
      var path = getGlobalParameter("document-path");
      if (path)
         {
         writeComment("Drawing name : " + path);
         }
      }

   if (programName)
      {
      writeComment("Program Name : " + programName);
      }
   if (programComment)
      {
      writeComment("Program Comments : " + programComment);
      }
   writeln("");

   if (!getProperty("useToolChange") && filesToGenerate > 1)
      {
      //if (debugMode) writeComment("not useToolChange 2168");
      writeComment(numberOfSections + " Operation" + ((numberOfSections == 1) ? "" : "s") + " in " + filesToGenerate + " files.");
      writeComment("File List:");
      //writeComment("  " +  FileSystem.getFilename(getOutputPath()));
      for (var i = 0; i < filesToGenerate; ++i)
         {
         //filenamePath = FileSystem.replaceExtension(getOutputPath(), fileIndexFormat.format(i + 1) + "of" + filesToGenerate + "." + extension);
         //filename = FileSystem.getFilename(filenamePath);
         filename = makeFileName(i + 1);
         writeComment("  " + filename);
         }
      writeln("");
      writeComment("This is file: " + fileSequenceNumber + " of " + filesToGenerate);
      writeln("");
      writeComment("This file contains the following operations: ");
      }
   else
      {
      if (debugMode) writeComment("DEBUG generate single with toolchanges 2465");
      writeComment(numberOfSections + " Operation" + ((numberOfSections == 1) ? "" : "s") + " : in 1 file");
      }

   for (var i = secID; i < numberOfSections; ++i)
      {
      var section = getSection(i);
      var tool = section.getTool();
      var rpm = section.getMaximumSpindleSpeed();

      if (section.hasParameter("operation-comment"))
         {
         writeComment((i + 1) + " : " + section.getParameter("operation-comment"));
         var op = section.getParameter("operation-comment")
         }
      else
         {
         writeComment(i + 1);
         var op = i + 1;
         }
      if (section.workOffset > 0)
         {
         writeComment("  Work Coordinate System : G" + (section.workOffset + 53));
         }
      writeComment("  Tool #" + tool.number + ": " + toTitleCase(getToolTypeName(tool.type)) + " " + tool.numberOfFlutes + " Flutes, Diam = " + xyzFormat.format(tool.diameter) + unitstr + ", Len = " + tool.fluteLength.toFixed(2) + unitstr);
      if (getProperty("routerType") != "other")
         {
         writeComment("  Spindle : RPM = " + round(rpm, 0) + ", set router dial to " + rpm2dial(rpm, op) + " for " + getProperty('routerType'));
         }
      else
         {
         writeComment("  Spindle : RPM = " + round(rpm, 0));
         }

      var machineTimeInSeconds = section.getCycleTime();
      var machineTimeHours = Math.floor(machineTimeInSeconds / 3600);
      machineTimeInSeconds = machineTimeInSeconds % 3600;
      var machineTimeMinutes = Math.floor(machineTimeInSeconds / 60);
      var machineTimeSeconds = Math.floor(machineTimeInSeconds % 60);
      var machineTimeText = "  Machining time : ";
      if (machineTimeHours > 0)
         {
         machineTimeText = machineTimeText + machineTimeHours + " hours " + machineTimeMinutes + " min ";
         }
      else
         if (machineTimeMinutes > 0)
            {
            machineTimeText = machineTimeText + machineTimeMinutes + " min ";
            }
      machineTimeText = machineTimeText + machineTimeSeconds + " sec";
      writeComment(machineTimeText);

      if (!getProperty("useToolChange") && (i + 1 < numberOfSections))
         {
         if (tool.number != getSection(i + 1).getTool().number)
            {
            writeln("");
            writeComment("Remaining operations located in additional files.");
            break;
            }
         }
      }
   writeln("");

   gAbsIncModal.reset();
   gFeedModeModal.reset();
   gPlaneModal.reset();
   writeBlock(gAbsIncModal.format(90), gFeedModeModal.format(94), gPlaneModal.format(17));
   gUnitModal.reset(); // always output this
   switch (unit)
      {
      case IN:
         writeBlock(gUnitModal.format(20));
         break;
      case MM:
         writeBlock(gUnitModal.format(21));
         break;
      }
   writeRetract(Z);
   if (debugMode) writeComment("DEBUG Header end");
   writeln("");
   }

/**
   check for duplicate tool numbers
   sets filesToGenerate
   @returns nothing
*/
function checkforDuplicatetools()
   {
   filesToGenerate = 1;
   for (var i = 0; i < getNumberOfSections(); ++i)
      {
      var sectioni = getSection(i);
      var tooli = sectioni.getTool();
      if (i < (getNumberOfSections() - 1) && (tooli.number != getSection(i + 1).getTool().number))
         {
         filesToGenerate++;
         }
      for (var j = i + 1; j < getNumberOfSections(); ++j)
         {
         var sectionj = getSection(j);
         var toolj = sectionj.getTool();
         if (tooli.number == toolj.number)
            {
            if (xyzFormat.areDifferent(tooli.diameter, toolj.diameter) ||
                  xyzFormat.areDifferent(tooli.cornerRadius, toolj.cornerRadius) ||
                  abcFormat.areDifferent(tooli.taperAngle, toolj.taperAngle) ||
                  (tooli.numberOfFlutes != toolj.numberOfFlutes))
               {
               error(
                  subst(
                     localize("Using the same tool number for different cutter geometry for operation '%1' and '%2'."),
                     sectioni.hasParameter("operation-comment") ? sectioni.getParameter("operation-comment") : ("#" + (i + 1)),
                     sectionj.hasParameter("operation-comment") ? sectionj.getParameter("operation-comment") : ("#" + (j + 1))
                  )
               );
               return;
               }
            }
         // else
         //    {
         //    if (properties.generateMultiple == false)
         //       {
         //       multipleToolError = true;
         //       }
         //    }
         }
      }
   if (getProperty('useToolChange'))
      filesToGenerate = 1;
   if (debugMode)
      writeComment("DEBUG files to Generate = " + filesToGenerate);
   }

function rpm2dial(rpm, op)
   {
   // translates an RPM for the spindle into a dial value, eg. for the Makita RT0700 and Dewalt 611 routers
   // additionally, check that spindle rpm is between minimum and maximum of what our spindle can do
   // array which maps spindle speeds to router dial settings,
   // according to Makita RT0700 Manual : 1=10000, 2=12000, 3=17000, 4=22000, 5=27000, 6=30000
   // according to Dewalt 611 Manual : 1=16000, 2=18200, 3=20400, 4=22600, 5=24800, 6=27000
   var routerType = getProperty("routerType");
   if (routerType == "Dewalt")
      {
      var speeds = [0, 16000, 18200, 20400, 22600, 24800, 27000];
      }
   else
      if (routerType == "Router11")
         {
         var speeds = [0, 10000, 14000, 18000, 23000, 27000, 32000];
         }
      else
         {
         // this is Makita R0701
         var speeds = [0, 10000, 12000, 17000, 22000, 27000, 30000];
         }
   if (rpm < speeds[1])
      {
      alert("Warning", rpm + " rpm is below minimum spindle RPM of " + speeds[1] + " rpm in the " + op + " operation.");
      return 1;
      }

   if (rpm > speeds[speeds.length - 1])
      {
      alert("Warning", rpm + " rpm is above maximum spindle RPM of " + speeds[speeds.length - 1] + " rpm in the " + op + " operation.");
      return (speeds.length - 1);
      }

   var i;
   for (i = 1; i < (speeds.length - 1); i++)
      {
      if ((rpm >= speeds[i]) && (rpm <= speeds[i + 1]))
         {
         return (((rpm - speeds[i]) / (speeds[i + 1] - speeds[i])) + i).toFixed(1);
         }
      }

   alert("Error", "Error in calculating router speed dial.");
   error("Fatal Error calculating router speed dial.");
   return 0;
   }

function toTitleCase(str)
   {
   // function to reformat a string to 'title case'
   return str.replace( /\w\S*/g, function (txt)
      {//              /\w\S*/g after an astyle run, fix this format
      return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase();
      });
   }

function round(num, digits)
   {
   return toFixedNumber(num, digits, 10)
   }

function toFixedNumber(num, digits, base)
   {
   var pow = Math.pow(base || 10, digits);  // cleverness found on web
   return Math.round(num * pow) / pow;
   }

function onTerminate()
   {
   // If we are generating multiple files, copy first file to add # of #
   // Then remove first file and recreate with file list - sharmstr
   if (filesToGenerate > 1)
      {
      //if (isRedirecting())   
      //   closeRedirection();
      var outputPath = getOutputPath();
      var outputFolder = FileSystem.getFolderPath(getOutputPath());
      var programFilename = FileSystem.getFilename(outputPath);
      var destfile = makeFileName(1);
      FileSystem.copyFile(outputPath, destfile );
      FileSystem.remove(outputPath);
      var file = new TextFile(outputFolder + "\\" + programFilename, true, "ansi");
      file.writeln("The following gcode files were created: ");
      for (var i = 0; i < filesToGenerate; ++i)
         {
         destfile = makeFileName(i + 1);
         file.writeln(destfile);
         }
      file.close();
      }
   }

/**
   make a numbered filename
   @param index the number of the file, from 1
*/
function makeFileName(index)
   {
   var fullname = getOutputPath();
   debug(fullname);
   fullname = fullname.replace(' ', '_');
   var filenamePath = FileSystem.replaceExtension(fullname, fileIndexFormat.format(index) + "of" + filesToGenerate + "." + extension);
   var filename = FileSystem.getFilename(filenamePath);
   debug(filename);
   return filenamePath;
   }
