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
; Example that chases the LED's from left to right on CPU1, then
; chases from right to left on CPU2.  Mutual exclusion is used to
; co-ordinate whose turn it is.
;

        .include startup.s

LEDS    .equ    $8100

cold_start:
warm_start:

loop:
        jsr     mutex_lock      ; Acquire the mutex for this CPU.
;
    .if CPU1
        ldx     #0              ; CPU1 chases from LED0 to LED4.
    .else
        ldx     #4              ; CPU2 chases from LED4 to LED0.
    .endif
chase_leds:
        lda     #1
        sta     LEDS,x
        jsr     delay
        lda     #0
        sta     LEDS,x
    .if CPU1
        inx
        cpx     #5
        bcc     chase_leds
    .else
        dex
        bpl     chase_leds
    .endif
;
        jsr     mutex_unlock    ; Release the mutex.
        bra     loop            ; Go around again.
;
; Delay of approximately 100ms.  Destroys A and Y.  Preserves X.
;
delay:
        lda     #156
        ldy     #0
delay_loop:
        dey
        bne     delay_loop
        sec
        sbc     #1
        bne     delay_loop
        rts
;
hw_init:
        rts
;
; Interrupt handlers.
;
irqbrk:
nmi:
        rti
;
        .org    $FFFA
        .dw     nmi
        .dw     reset
        .dw     irqbrk
