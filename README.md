# Sega XY Diagnostic ROM  
#### David Shuman (davidshuman@gmail.com)
#### v1.0 August 22, 2015
#### Please do not redistribute the diagnostic ROM data without this README.

This README should be distributed in a ZIP archive also containing the file "sega-xydiag-U25.bin."  The .bin file is object code that may be programmed into a 2716 EPROM.  

The programmed 2716 EPROM replaces U25 on the CPU board to provide:
  * **Full-screen grid patterns,** in seven different colors, for monitor adjustment
  * **Improved RAM testing,** including tests of RAM on the CPU board and Universal Sound Board

The new ROM provides only these diagnostic functions and cannot be used to run the game.  To run the game, reinstall the original U25 ROM on the CPU board.  

### REQUIRED HARDWARE  
For the diagnostic ROM to operate, the G80 system must have, in addition to a working power supply:
  * A working CPU board (with or without good RAM at U26-U29)
  * A working pair of XY Control and XY Timing boards (with or without good RAM at U30, U29, U28, U26, U25, and U24 -- **HOWEVER, working 2114 RAMs must be installed at U31 and U27 for the diagnostics to run**).  These boards provide clock and interrupt signals to the CPU board.  

Neither the EPROM board nor the Speech board is required to run the diagnostic ROM.  Also note that any of the boards can be inserted into any of the card cage slots.  The six slots are identical and none is specific to any one card.  

### OPTIONAL HARDWARE
  * Vector Monitor:  For displaying the grid patterns and the results of the RAM test.  (The LED on the CPU Board can also be used to interpret the results of the RAM test.)
  * Universal Sound Board:  The new diagnostic ROM includes a test of the 6116 RAM at U50 and U51 on the Universal Sound Board used in Star Trek, Tac/Scan, and Zektor.  If this board is not present, the diagnostics will report U50 and U51 as faulty.
  * Control Panel:  the P1 start button can be used to advance from the RAM test to the grid pattern, and to cycle through the available colors of the grid pattern.  The pushbutton on the CPU board may also be used for this purpose.

### RAM TEST
The original Sega self-test tested only the eight 2114 RAM chips on the XY Control board, and was prone to reporting false negatives -- that is, the self-test would often fail to detect faulty RAMs that, during game play, would cause errors in program execution or graphics.  The tests performed by the new diagnostic ROM are designed to be more thorough and reliable, and also test, in addition to the XY Control board RAM, the four 2114 RAMs on the CPU board and the two 6116 RAMs on the Universal Sound Board (if that board is present).  

When the diagnostic ROM is installed, the RAM test will run automatically when the system is powered up and RAMs U31 and U27 on the XY Control board (which the test uses as scratchpad RAM and for storing vector data) are good.  If the test fails to run, try installing new 2114 RAM chips at U31 and U27 on the XY Control board.  

The RAM test writes and reads various data to system RAM, reads it back, and verifies that the data read is the same as the data written.  If the data read from a given memory location does not match the data written, the physical chip associated with that memory location is identified as bad.  

#### Display of RAM Test Results

The RAM test takes only a second to complete.  When it is finished, the monitor will display a status word comprising fourteen characters, each a "1" or a "0."  A "1" indicates that the RAM chip associated with that character passed the RAM test with no errors.  A "0" indicates that one or more memory locations in the RAM chip associated with that character failed one or more write/read tests.  
```
Table 1:  Correlation of Status Word Digits With Physical Chips
Char        Chip             Char        Chip             Char        Chip
1st       CPU bd U26         5th     XY Ctl bd U31        13th    Sound bd U51
2nd       CPU bd U27         6th     XY Ctl bd U30        14th    Sound bd U50
3rd       CPU bd U28         7th     XY Ctl bd U29
4th       CPU bd U29         8th     XY Ctl bd U28
                             9th     XY Ctl bd U27
                             10th    XY Ctl bd U26
                             11th    XY Ctl bd U25
                             12th    XY Ctl bd U24
```
For example, if the display shows:
```
               1 1 1 1   1 1 1 0 1 1 1 1   1 1
```
All RAM chips tested OK except for U28 on the XY Control board.

Similarly, if the display shows:
```
               0 1 1 1   1 1 1 1 1 1 1 1   0 0
```
All RAM chips tested OK except for U26 on the CPU board and chips U50 and U51 on the Universal Sound Board.  Note that the last two digits will also display "0" if the Universal Sound Board, which is used only in Star Trek and Tac/Scan, is not installed.  

To provide test results information when the vector monitor is missing or non-operational, the LED on the CPU board provides a second visual indication of the results of the RAM test by blinking either an "All Clear" indication or a flash code indicating a bad RAM.  The flash code can be interpreted as follows:  

 * One flash followed by a long pause:  all chips tested OK.
 * One to four flashes, representing a first digit; then a short pause; then one to four flashes, representing a second digit; then a long pause:  at least one chip failed the RAM test.

```
Table 2:  Two-Digit LED Flash Codes
  "C." = CPU Board   "X." = XY Control Board   "S." = Universal Sound Board
       first digit =>        1       2       3       4
   second digit       1    C.U26   X.U31   X.U27   S.U51
        |             2    C.U27   X.U30   X.U26   S.U50
        V             3    C.U28   X.U29   X.U25    ---
                      4    C.U29   X.U28   X.U24    ---
```
For example, if the LED flashes 3 times, then pauses, then four times, followed by a longer pause, the RAM test has identified U24 on the XY Control Board as faulty.  

The LED flash code is capable of identifying only a single chip.  If more than one chip fails the RAM test, only the chip represented by the lowest-order character in the status word (see Table 1 above) will be identified by the LED flash code.  For example, if both CPU board chip U27 and XY Control board chip U28 fail the RAM test, the LED will blink the code for C.U27 but not for X.U28.  If, in this example, C.U27 were replaced with a good RAM and the test run again, the LED would then blink the code indicating X.U28 is bad.  

There are two additional 2114 RAM chips on the Universal Sound Board, U44 and U45, that cannot be directly accessed by the CPU board and consequently cannot be tested by the new diagnostic ROM.  To test U44 and U45, swap them with other 2114's on the CPU board or XY Control board and re-run the RAM test.  

To exit the RAM test and display the grid pattern, press P1 Start on the control panel or the pushbutton on the CPU board near the LED.   

### GRID TEST PATTERN

The original Sega self-test did not provide an adequate suite of graphical test patterns for adjusting the purity and convergence of the vector monitor.  The new diagnostic ROM provides a full-screen grid pattern suitable for detecting and correcting purity and convergence problems as well as adjusting width, height, and centering.  

The first pattern displayed after exiting the RAM test will be a white grid.  Press P1 Start or the CPU pushbutton to change the grid color to the next color in the cycle:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;white => red => green => blue => yellow (R+G) => purple (R+B) => aqua (B+G) => white (R+B+G)  

As with any image that extends along the edges of the screen, the grid test pattern places moderate stress on the deflection circuitry of the vector monitor.  Accordingly, it is advised that the grid pattern be displayed no longer than is necessary to perform adjustments to the monitor.  