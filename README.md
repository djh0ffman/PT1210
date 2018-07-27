# PT-1210
PT-1210 Amiga DJ Software


The PT-1210 MK1 v1.0

The ProTracker Turntable

Credits

Original Concept - Hoffman & Akira
Code - Hoffman
Graphics - Akira
System Kill Code - Stingray
Testing - Akira & Tecon

------------------------------------------------------------------------------

** WHAT IS IT ** 

PT-1210 is a program for DJ'ing ProTracker modules. It essentially turns
your Amiga into a turntable / CDJ with nudge, pitch control and so on.

It has a number of features but the most important one is that it can
re-pitch the samples played to match the BPM you want to play the tune at.
This means drum and music loops will still be in sync and the other
instruments will still be in key.

** WHAT DO I NEED **

It will run on pretty much any Amiga, OSC/ESC, AGA, Accelerated and so on.
I would recommend however that you run it using a CF card on the IDE port
with 2 meg of chip ram. If you are using two Amigas I would also recommend
that they are the same type, like two A1200's or two A600's. You can also
use a hard drive, PCMCIA adapter CF Card, SD or even floppy disk.

** HOW DO I USE IT ** 

Put all your modules in a folder with the program and run it. When it starts
it will scan current folder for any ProTracker modules and add them to the file
selector (M.K.). It will also try to determine the BPM. Simply select a module and
it will load it, take you to the player screen and start playing. 


** KEYS FOR FILE SELECTA MODE **

HELP        = Switch screens (load and DJ mode)
UP / DOWN   = Select file
RETURN      = Load Tune
F10         = Sort list by BPM (toggles asc / desc)
F9          = Sort list by Filename (toggles asc / desc)
F8          = Show Kb
ESCAPE      = Quit (hold for a second)
A-Z / 0-9   = Pick first file with matching first letter
F1          = Re-scan folder (used when running from floppy drive)

NOTE: Quit will not work if a tune is playing!

** KEYS FOR DJ MODE **

HELP        = Switch screens (load and DJ mode)
LEFT        = Nudge backward
RIGHT       = Nudge forward
SHIFT LEFT  = Hard nudge forward
SHIFT RIGHT = Hard nudge back 
UP          = Increase BPM
DOWN        = Decrease BPM
SHIFT UP    = Increase BPM fine tune
SHUFT DOWN  = Decrease BPM fine tune
SPACE       = Stop / Play
TAB         = Toggle repitch on / off
`           = Kills sound DMA
1/2/3/4		= Mute / Un-Mute Channel

              Pattern / Position Functions
F1          = Jump to cue pattern
F2          = Jump to cue pattern after current pattern ends
F3          = Set current pattern as cue
F10         = Pattern Loop (start / stop / deactivate)
+           = Move forward one pattern (shift moves loop size)
-           = Move back one pattern (shift moves loops size)
SHIFT +     = Move forward line loop size
SHIFT -     = Move back line loop size
CTRL +      = Move cue pattern forward
CTRL -      = Move cue pattern back

              Line Loop Functions
F6          = Decrease loop size
F7          = Increase loop size
F5          = Activate loop
F4          = Toggle Slip On / Off

** PATTERN LOOPING **

F10 will cycle through the pattern loop modes. The first press will store the
loop start point and the second press will store the loop end point. The
third press will then deactivate the loop. 

** LINE LOOPING **

Line looping enables you to loop small sections of the current pattern. The
loop start point currently quantises to a beat (assuming speed 6) so
positions 0,4,8,12,16,20,24,28... etc.

Slip mode is enabled by default. If you activate a loop with this ON, it continues
increase the track position while looping. This means when you deactivate
the loop, the track drops into the position of the tune as if you never
looped it. You can switch to normal loop mode which will continue playing
the track from after the loop point when deactivated.

** BPM DETECTION **

The BPM detection works by looking at the first line of the first pattern
within the module. This seems to work pretty well as it's always the first
thing you set.  However, if no BPM is set on the first line, then it will
assume that it is VBR timing rather than CIA and set the BPM to 125.
This is fine as long as the tune has been written at, say for example
a tempo of 6 or 3 as this is 125 BPM. If the module is written with
no CIA timing and a tempo of say 5, then the BPM will be inacurate.

BTW - there is no way around this! ( i think! )

** WHY ON EARTH DID YOU MAKE THIS PROGRAM? **

It started as a discussion on the EAB forum where Akira was asking if the
repitch function would be possible. After some more posts I started making
a little proof of concept program with just one module. It worked and much
better then we expected it to as well! Gradually over time I've added more
functions, things like looping, pattern display, scopes and so on.

** CAN I HAVE A SYSTEM FRIENDLY VERSION **

Of course!, if you want to code it yourself! My serious lack of coding skill
on the Amiga  means I ONLY know how to bang on the hardware! If you are
seriously interested in producing a system friendly version, get in touch.

** MY MODULE SOUNDS WEIRD **

The player is one of the original ProTracker replay sources so it should be
pretty dam accurate. If it sounds weird, check it in ProTracker v2.3d first
and fix it there. If it still sounds weird, provide us with an example and 
we'll take a look.

Becareful when pitching tunes up higher in BPM. As you probably know the Paula
chip can only play samples up to a certain pitch. If your module runs the
samples high in pitch and you push then tempo up too much, they wont go any
further.


** I WROTE MY MODULE FT2 AND IT CRASHES PROTRACKER! **

There are a number of modules that exist where they have no REPLEN set on the
samples. Our guess is they've been written in FastTracker or similar. These
actually crash ProTracker when trying to play them. Crashing is a bad thing
so we apply a patch to the modules on load to fix this issue.

** USING DIFFERENT AMIGAS **

I've tried using an A600 alongside an A1200 and found that by default they do
sound different. This is because they made the A600 badly and chopped a lot of
the high end off the sound. There is a hardware hack, ask Akira! I also noticed
that the timing was slightly different between the two Amigas which we believe
is a small difference in the two systems CIA chips. There is a fine pitch adjust
which should help with this timing issue.

** DO I NEED TO BE AWARE OF ANYTHING WEIRD THAT MIGHT HAPPEN **

DO NOT UNPLUG A PCMCIA CARD WHILE ITS RUNNING! IT GOES FUCKING MENTAL!

Also, it seems that SPS formatted drives can sometimes result in module corruption
during loading. We've not found a way of recreating this issue yet so are yet to
resolve it. Quick work around is to run it from PCMCIA card instead.

** WHO ARE YOU **

We are people who love the Amiga, love ProTracker and love DJ'ing. 

------------------------------------------------------------------------------

Change log.

2014-05-06
Fixed bug where scopes would crash if they hit a sample 0.
Added folder re-scan function but crashes if you switch floppy disk! (no good!)

2014-04-14
Final build before Revision, which means we are now V1.0.
Program now quits if no modules are found in the folder (used to crash)

STATIC SCROLLER ALERT!!!

Firstly massive thanks to Akira for all his hard work with ideas, testing, graphics,
PR and generally everything else. It's been enough work getting the code done let
alone managing everything else surrounding the release of this program. 

Next up massive props to Tecon, the only man I know to exploit more bugs in the PT
replay source than me! Your the reason it's so dam solid now, great bug hunting.

Lastly a big thank you to all the people who have shown an interest in this little
program. When we started this project I never knew so many people wanted to dust 
off their Amiga's and hook them up to their mixers. I hope you all enjoy playing
ProTracker mods in the mix with this tool. Now you can all stop harassing Akira
for a release!!


2013-03-21
BPM re-arranged, now shows fine as larger digits and percentage diff
Slip mode light changed
Removed one line for file selecta
Copper bug fixed in file selecta
Added Chip Ram notification on startup
Added F8 Kb file size in file selecta
Added lovely splash screen
Added some easter fun!
Added A-Z 0-9 keys for finding file

2013-03-05
Added fine tune BPM, working well but needs UI changes
Added Cue Point mover (CTRL + -)

2013-02-28 - Tecons test run!
Added blank sample so empty samples play this instead otherwise junk gets played. 
Reset some variables in PT Replay on load so E6 command doesnt freak 
Fonts now supports Underscore char
Implemented n_altperiod so ARPS and Vibrato now work with Re-Pitch
Bug where ED command caused pitch change too early now fixed

2014-02-26
Implemented new pattern loop sprites
Grid now above and below the track display
Pattern cue slip now flashes when engaged
Near end of track warning now flashes track bar
Increased BPM range again with saftey
Diabled VB Interrupt during loading as it could cause screen corruption
Fixed bug where if number of tunes is less the screen, you could scroll
past and fuck everything up!
Implemented Shift + / - which moves the size of the loop

2014-02-24
Track bar now replaced with overall track display with pattern splits

2014-02-14 - Datastorm!
Scopes now switch off when track is paused and when new track is loaded
Fixed bug where loading new tune would show the pattern from the last tune
Code split for fast mem not working, need to speak to someone about that

2013-12-17 - Code name UI!
Added graphics from Akira and complete UI re-work
Shaved loads of memory usage
Ditched all old UI code
Split code into fast mem if available

2013-09-23
Added fix for what looks like lame FT2 modules where the REPLEN isn't set
BPM detection will now default to 125 if not found on first line of the mod
Max tunes raised to 200
Fixed bug when max number of tunes is reached it wont load anything
File selector over scroll fixed (when less than a screens worth of tunes)
Added key repeat function on tempo and file selection
Quit is now done by holding ESCAPE key in file selector only
Added file sorting by name and BPM

2013-09-04
Added channel toggles on screen!
Fixed $F00 bug (god was dividing by zero!)
stopped tune from restarting after ending
Temporary fix on loading error but still buggy
Fix for VBR CIA (Again?)

2013-09-02
Fixed bug where ARP's and Vibrato wouldn't work
however don't re-pitch chip tunes, they sound shit
Added pattern move forward and back
Counter remove from display, pointless
Pattern Loop now shows start and end only when activated
Pattern Lock removed from display
Now resets all values when loading a tune
TO DO - Song cue point store

2013-05-17
Pattern display added
File selector supports more files
File selector now shows BPM! (BPM Detection on based on first line of mod)
Files no longer need to be called mod., file is now checked for M.K.

2012-09-09 
Inital beater

