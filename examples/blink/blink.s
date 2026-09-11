;
; Copyright (C) 2026 Rhys Weatherley
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
; Example that blinks alternate LED's on different CPU's.
;

        .include bios.s

    .if CPU1
LED1    .equ    $8100
LED2    .equ    $8102
LED3    .equ    $8104
    .else
LED1    .equ    $8101
LED2    .equ    $8103
LED3    .equ    $8103       ; Repeat LED2 to maintain timing.
    .endif

cold_start:
warm_start:

    .if CPU2
        lda     #0
        jsr     set_leds    ; Offset CPU2's blinks from CPU1's.
    .endif

loop:
        lda     #1          ; Turn the LED's on.
        jsr     set_leds
        lda     #0          ; Turn the LED's off.
        jsr     set_leds
        jmp     loop        ; Go around again.

;
; Set the LED's repeatedly for approximately half a second at 2MHz.
; We keep setting the state over and over to check for bus contention
; between the two CPU's.
;
set_leds:
        ldx     #0
        ldy     #230
set_leds_loop:
        sta     LED1
        sta     LED2
        sta     LED3
        dex
        bne     set_leds_loop
        dey
        bne     set_leds_loop
        rts
;
; Initialize the hardware.
;
hw_init:
        stz     LED1
        stz     LED2
        stz     LED3
        rts
;
        .org    $FFFA
        .dw     nmi
        .dw     reset
        .dw     irqbrk
