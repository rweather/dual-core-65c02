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
; Print help for the monitor.
;
mon_HELP:
        stx     STOFLG
        lda     #<msg_help
        sta     SCRATCH1
        lda     #>msg_help
        sta     SCRATCH2
print_help:
        lda     (SCRATCH1),y
        beq     help_done
        jsr     MCOUT
        iny
        bne     print_help
        inc     SCRATCH2
        bne     print_help
help_done:
        rts
msg_help:
        .db     "nnnn", 9, 9, "Read memory at nnnn"
        EMITCRLF
        .db     "nnnn.mmmm", 9, "Read memory nnnn-mmmm"
        EMITCRLF
        .db     "nnnn:aa bb", 9, "Write to memory at nnnn"
        EMITCRLF
        .db     "nnnnG", 9, 9, "Run the subroutine at nnnn"
        EMITCRLF
        .db     "I", 9, 9, "Inspect registers"
        EMITCRLF
    .ifdef mon_LIST
        .db     "nnnnL", 9, 9, "Disassemble 20 instructions at nnnn"
        EMITCRLF
        .db     "L", 9, 9, "Disassemble next 20 instructions"
        EMITCRLF
    .endif
    .ifdef mon_ASSEM
        .db     "nnnn!", 9, 9, "Assemble instructions at nnnn"
        EMITCRLF
    .endif
        .db     "nn=r", 9, 9, "Set register r to nn (r = A,X,Y,P)"
        EMITCRLF
        .db     "nnnn<aaaa.bbbbM", 9, "Move memory from aaaa-bbbb to nnnn"
        EMITCRLF
    .ifdef mon_STEP
        .db     "nnnnS", 9, 9, "Single-step instruction at nnnn"
        EMITCRLF
        .db     "S", 9, 9, "Single-step next instruction"
        EMITCRLF
    .endif
    .ifdef mon_TRACE
        .db     "nnnnT", 9, 9, "Trace instructions from nnnn"
        EMITCRLF
    .endif
        .db     "nnnn<aaaa.bbbbV", 9, "Verify memory aaaa-bbbb against nnnn"
        EMITCRLF
        .db     "X", 9, 9, "Exit"
        EMITCRLF
        .db     0
