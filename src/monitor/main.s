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
; Configure platform-specific defines.
;
ANSI_ESCAPES    .equ    1
CPU_65C02       .equ    1
DUAL_CORE_65C02 .equ    1
RAMTOP          .equ    $8000
SYSCLK          .equ    2000

        .include bios.s

    .if CPU1

hw_init:
        jsr     set_default_output
        jsr     set_default_input
        lda     #<MPEEKKEY
        ldy     #>MPEEKKEY
        sta     PEEKSWL
        sty     PEEKSWH
        rts

cold_start:
        ldx     #banner-messages
        jsr     print_message
warm_start:
        jmp     MON1

        .include memmap.s
        .include ascii.s

        .org    $E800
        .include opcodes.s
        .include disassembler.s
        .include assembler.s
        .include tracing.s
        .include help.s
        .include escapes.s

        .org    $F800
        .include monitor.s

    .else ; CPU2

;
; Disable code on CPU2 for the time being.  Fix this later.
;
hw_init:
        rts
cold_start:
warm_start:
        jmp     warm_start

    .endif ; CPU2

        .org    $FFFA
        .dw     nmi
        .dw     reset
        .dw     irqbrk
