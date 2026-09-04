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

        .include startup.s

    .if CPU1
LED1    .equ    $8300
LED2    .equ    $8302
LED3    .equ    $8304
LED4    .equ    $8306
    .else
LED1    .equ    $8301
LED2    .equ    $8303
LED3    .equ    $8305
LED4    .equ    $8307
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
        ldy     #192
set_leds_loop:
        sta     LED1
        sta     LED2
        sta     LED3
        sta     LED4
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
        stz     LED4
        rts
;
; Interrupt handlers.
;
irqbrk:
nmiadr:
        rti
;
        .org    $FFFA
        .dw     nmiadr
        .dw     reset
        .dw     irqbrk
