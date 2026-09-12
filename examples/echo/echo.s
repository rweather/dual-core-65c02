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
; Echo everything that is typed on the serial port on CPU1 and
; blink a LED on CPU2.
;

        .include bios.s

LED     .equ    $8100

cold_start:
warm_start:

    .if CPU1

        ldx     #0
print_msg:
        lda     msg,x
        beq     loop
        jsr     put_char
        inx
        bne     print_msg
loop:
        jsr     get_char
        bcc     loop
        cmp     #$08
        beq     backspace
        cmp     #$7F
        beq     backspace
        cmp     #$0D
        beq     crlf
        jsr     put_char
        bra     loop
backspace:
        lda     #$08
        jsr     put_char
        lda     #$20
        jsr     put_char
        lda     #$08
        jsr     put_char
        bra     loop
crlf:
        lda     #$0A
        jsr     put_char
        lda     #$0D
        jsr     put_char
        bra     loop

msg:
        .db     "HELLORLD!"
        .db     $0D,$0A
        .db     $0D,$0A
        .db     "Type something ..."
        .db     $0D,$0A,0

    .else ; CPU2

loop:
        lda     #1          ; Turn the LED on.
        jsr     set_led
        lda     #0          ; Turn the LED off.
        jsr     set_led
        jmp     loop        ; Go around again.

;
; Set the LED repeatedly for approximately half a second at 2MHz.
; We keep setting the state over and over to check for bus contention
; between the two CPU's.
;
set_led:
        ldx     #0
        ldy     #240
set_led_loop:
        sta     LED
        dex
        bne     set_led_loop
        dey
        bne     set_led_loop
        rts

    .endif ; CPU2
;
; Initialize the hardware.
;
hw_init:
        rts
;
        .org    $FFFA
        .dw     nmi
        .dw     reset
        .dw     irqbrk
