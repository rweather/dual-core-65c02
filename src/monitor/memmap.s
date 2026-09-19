;
; memmap.s - Map of interesting locations in memory.
;
; Copyright (C) 2024 Rhys Weatherley
;
; Permission is hereby granted, free of charge, to any person obtaining a
; copy of this software and associated documentation files (the "Software"),
; to deal in the Software without restriction, including without limitation
; the rights to use, copy, modify, merge, publish, distribute, sublicense,
; and/or sell copies of the Software, and to permit persons to whom the
; Software is furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included
; in all copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
; OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
; FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
; DEALINGS IN THE SOFTWARE.
;

;
; Zero page.
;
            .include "zeropage.s"
;
; System vectors that the user can redirect.
;
BRKJMP      .equ    $3EF    ; "JMP" instruction to jump to the BREAK handler
BRKVER      .equ    $3F0    ; Address of the BREAK handler
RESTVR      .equ    $3F2    ; Address of the soft RESET handler
PWRIND      .equ    $3F4    ; Power-on indicator to detect hard-vs-soft RESET
USRADR      .equ    $3F8    ; "USR" subroutine calls jump to here
NMIADR      .equ    $3FB    ; NMI interrupts jump to here
IRQVER      .equ    $3FE    ; Address of the IRQ handler
;
; Other regions of memory.
;
STACK       .equ    $100    ; Stack (256 bytes)
    .ifndef DUAL_CORE_65C02
KEYBUF      .equ    $200    ; Keyboard buffer (256 bytes)
    .else
KEYBUF      .equ    $500    ; Keyboard buffer (256 bytes)
    .endif

    .ifdef DSE_CAT
;
; Slot 3 equates for the Dick Smith Cat / Laser 3000.
;
TEMPY       .equ    $4FB
TXTMOD      .equ    $57B    ; $04 for 40-column text, $10 for 80-column text
TEMPX       .equ    $5FB
BYTE        .equ    $67B    ; Byte read by KEYIN or output character
TEMPA       .equ    $6FB    ; Character under the cursor position
POWER       .equ    $77B
CHWHO       .equ    $47B    ; Horizontal position for output with "IO"
CVWHO       .equ    $7FB    ; Vertical position for output with "IO"
;
; I/O EQUATES
;
; See Chapter 2 of the "CAT Technical Reference Manual", for a description
; of the I/O map.  In particular, "Software Switches" and "Internal I/O".
;
; Software switches are activated by writing any value to the address.
; Not all of these are used by the kernel code.  Provided for documentation
; purposes to help understand how the switches actually work.
;
KEYBRD      .equ    $C000   ; Read keyboard data
KEYSTR      .equ    $C010   ; Clear keyboard strobe
BKDROP      .equ    $C008   ; Set border colour to black
BKDROP1     .equ    $C009   ; Set border colour to red
BKDROP2     .equ    $C00A   ; Set border colour to green
BKDROP3     .equ    $C00B   ; Set border colour to yellow
BKDROP4     .equ    $C00C   ; Set border colour to blue
BKDROP5     .equ    $C00D   ; Set border colour to magenta
BKDROP6     .equ    $C00E   ; Set border colour to cyan
BKDROP7     .equ    $C00F   ; Set border colour to white
BKGRND      .equ    $C018   ; Set background colour to black
BKGRND1     .equ    $C019   ; Set background colour to red
BKGRND2     .equ    $C01A   ; Set background colour to green
BKGRND3     .equ    $C01B   ; Set background colour to yellow
BKGRND4     .equ    $C01C   ; Set background colour to blue
BKGRND5     .equ    $C01D   ; Set background colour to magenta
BKGRND6     .equ    $C01E   ; Set background colour to cyan
BKGRND7     .equ    $C01F   ; Set background colour to white
TAPEOU      .equ    $C020   ; Cassette output
TEXTCR      .equ    $C028   ; Enable multi colour mode
TEXTCR1     .equ    $C029   ; Set to single colour mode with red pixels
TEXTCR2     .equ    $C02A   ; Set to single colour mode with green pixels
TEXTCR3     .equ    $C02B   ; Set to single colour mode with yellow pixels
TEXTCR4     .equ    $C02C   ; Set to single colour mode with blue pixels
TEXTCR5     .equ    $C02D   ; Set to single colour mode with magenta pixels
TEXTCR6     .equ    $C02E   ; Set to single colour mode with cyan pixels
TEXTCR7     .equ    $C02F   ; Set to single colour mode with white pixels
SPEAKR      .equ    $C030   ; Toggle speaker
VZTX40      .equ    $C04C   ; Set to low resolution mode
VZGRGB      .equ    $C04D   ; Set to RGB mode
VZGHGH      .equ    $C04E   ; Set to high resolution mode
VZTX80      .equ    $C04F   ; Set to 80-column mode
VZGRPH      .equ    $C050   ; Set to graphics mode
VZTEXT      .equ    $C051   ; Set to text mode
VZTEXT1     .equ    $C052   ; Set to pure text or graphics mode
VZTEXT2     .equ    $C053   ; Set to mixed text or graphics mode
VZPAG1      .equ    $C054   ; Display primary graphics page
VZPAG2      .equ    $C055   ; Display secondary graphics page
VZSELF      .equ    $C056   ; Turn off emulation
VZEMUL      .equ    $C057   ; Set emulation only
TAPEIN      .equ    $C060   ; Cassette input
BINFLG0     .equ    $C061   ; Binary flag 1 input
BINFLG1     .equ    $C062   ; Binary flag 2 input
BINFLG2     .equ    $C063   ; Binary flag 3 input
PADDL0      .equ    $C064   ; Game paddle 1 input
PADDL1      .equ    $C065   ; Game paddle 2 input
PADDL2      .equ    $C066   ; Game paddle 3 input
PADDL3      .equ    $C067   ; Game paddle 4 input
SONGEN      .equ    $C068   ; Write data to 76489 sound generator
PDLRES      .equ    $C070   ; Analog clear
SYSTEM      .equ    $C078
SBANK1      .equ    $C07C   ; Select memory bank for memory window 0 (0-15)
SBANK2      .equ    $C07D   ; Select memory bank for memory window 1 (0-15)
SBANK3      .equ    $C07E   ; Select memory bank for memory window 2 (0-15)
SBANK4      .equ    $C07F   ; Select memory bank for memory window 3 (0-15)
PRINTR      .equ    $C090   ; Write data to printer
PRTACK      .equ    $C1C0   ; Read printer acknowledge
PRTBSY      .equ    $C1C1   ; Read printer busy
HORZSC      .equ    $C1C2   ; Read horizontal blanking
VERTSC      .equ    $C1C3   ; Read vertical blanking
LINFRQ      .equ    $C1C4   ; Read 50/60Hz status
TWOMHZ      .equ    $C1C5   ; Read high resolution switch (SWR1) status
ROMCLR      .equ    $CFFF   ; Clear ROM bank switching
    .endif
