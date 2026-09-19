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
; "L" command for the monitor - disassemble instructions.
;
mon_LIST:
;
; Get the range of addresses or number of lines to be disassembled.
;
        lda     STOFLG          ; Do we have a "." range?
        cmp     #STODOT
        beq     list_range
        lda     CHKSUM          ; Do we have a single address argument?
        beq     list_20
        jsr     mon_DOT_2       ; Copy REG2 into REG1.
list_20:
        lda     #20
        sta     CHKSUM          ; Line count for disassembly.
        .db     $2C             ; Skip the next instruction.
list_range:
        stx     CHKSUM          ; List an explicit range, no line counts.
;
; Disassemble instructions until the limit is reached.
;
list_next:
        jsr     check_ctrl_c    ; Check for CTRL-C to stop disassembly.
        bcs     dis_no_oper
        jsr     disassemble     ; Disassemble a single instruction at REG1.
        jsr     MCROUT
        lda     OPCODL          ; Add the opcode length to REG1.
        clc
        adc     REG1L
        sta     REG1L
        lda     REG1H
        adc     #0
        sta     REG1H
        lda     CHKSUM          ; Address range or line count?
        beq     list_check_end
        dec     CHKSUM          ; Line count.
        bne     list_next
dis_no_oper:
        rts
list_check_end:
        lda     REG1H           ; Is REG1 > REG2?
        cmp     REG2H
        bne     list_check_end_2
        lda     REG1H
        cmp     REG2H
list_check_end_2:
        bcc     list_next
        beq     list_next
        rts
;
; Disassemble a single instruction at REG1.
;
disassemble:
;
; Print the address of the instruction.
;
    .ifdef ANSI_ESCAPES
        jsr     ansi_green
    .endif
        lda     REG1H
        ldx     REG1L
        jsr     MPRNAX
        lda     #CHAR_COLON
        jsr     MCOUT
    .ifdef ANSI_ESCAPES
        jsr     ansi_normal
    .endif
;
; Get the type, length, and name index of the opcode.
;
        ldy     #0
        sty     OPCODL
        lda     (REG1L),y
        tax
        lda     OPMODES,x
        sta     SCRATCH1
        asl     a               ; Opcode length is in bits 6 and 7 of the
        rol     OPCODL          ; opcode mode byte.
        asl     a
        rol     OPCODL
        lda     OPNAMEIDX,x
        sta     SCRATCH2
;
; Print the bytes of the instruction.
;
list_bytes:
        lda     #CHAR_SP
        jsr     MCOUT
        lda     (REG1L),y
        jsr     MPRBYTE
        iny
        cpy     OPCODL
        bcc     list_bytes
list_bytes_pad:
        jsr     MPRNSPC
        iny
        cpy     #4
        bcc     list_bytes_pad
;
; Print the opcode name.
;
    .ifdef ANSI_ESCAPES
        jsr     ansi_yellow
    .endif
        ldx     SCRATCH2
    .ifdef HIGH_ASCII
        lda     OPNAMES,x
        jsr     dis_to_upper
        lda     OPNAMES+1,x
        jsr     dis_to_upper
        lda     OPNAMES+2,x
        jsr     dis_to_upper
    .else
        lda     OPNAMES,x
        jsr     MCOUT
        lda     OPNAMES+1,x
        jsr     MCOUT
        lda     OPNAMES+2,x
        jsr     MCOUT
    .endif
    .ifdef ANSI_ESCAPES
        jsr     ansi_normal
    .endif
        jsr     MPRNSPC
;
; Determine how to dump the operands to the instruction.
;
        lda     SCRATCH1
        and     #$1F
        asl     a
        tax
        lda     dis_handler,x
        sta     REG4L
        lda     dis_handler+1,x
        sta     REG4H
        ldy     #1
        ldx     #0
    .ifndef DSE_CAT
        lda     #>(dis_add_spaces-1)
        pha
        lda     #<(dis_add_spaces-1)
        pha
    .endif
        jmp     (REG4L)
;
    .ifndef DSE_CAT
;
; Add spaces to the current line to align everything on the right.
;
dis_add_spaces:
        lda     #CHAR_SP
        jsr     MCOUT
        inx
        cpx     #12
        bcc     dis_add_spaces
        rts
    .endif
;
    .ifdef HIGH_ASCII
dis_to_upper:
        and     #$DF            ; Convert lower case real ASCII
        ora     #$80            ; into upper case high ASCII.
        jmp     MCOUT
    .endif
;
; Print a character and increment the character count in X.
;
dis_COUT:
        inx
        jmp     MCOUT
;
; Disassembly handlers for the operand types.
;
dis_handler:
        .dw     dis_ill         ; OP_ill
        .dw     dis_no_oper     ; OP_imp
        .dw     dis_imm         ; OP_imm
        .dw     dis_abs         ; OP_abs
        .dw     dis_abs_X       ; OP_abs_X
        .dw     dis_abs_Y       ; OP_abs_Y
        .dw     dis_X_ind       ; OP_X_ind
        .dw     dis_ind_Y       ; OP_ind_Y
        .dw     dis_zpg         ; OP_zpg
        .dw     dis_zpg_X       ; OP_zpg_X
        .dw     dis_zpg_Y       ; OP_zpg_Y
        .dw     dis_rel         ; OP_rel
        .dw     dis_ind         ; OP_ind
        .dw     dis_abs         ; OP_jsr
        .dw     dis_abs         ; OP_jmp
        .dw     dis_no_oper     ; OP_rts
        .dw     dis_no_oper     ; OP_rti
    .ifdef CPU_65C02
        .dw     dis_ind_zpg     ; OP_ind_zpg
        .dw     dis_ind_abs_X   ; OP_ind_abs_X
        .dw     dis_bit_zpg     ; OP_bit_zpg
        .dw     dis_zpg_rel     ; OP_zpg_rel
    .endif
;
; Illegal instruction.  Print the opcode byte.  The instruction name is "DB".
;
dis_ill:
        dey
        beq     dis_zpg
;
; Instruction with an immediate operand.
;
dis_imm:
        lda     #CHAR_HASH
        jsr     dis_COUT
;
; Instruction with a zero page address.
;
dis_zpg:
        lda     #CHAR_DOL
        jsr     dis_COUT
        lda     (REG1L),y
dis_PRBYTE:
        inx
        inx
        jmp     MPRBYTE
;
; Instruction with an absolute operand.
;
dis_abs:
        lda     #CHAR_DOL
        jsr     dis_COUT
        iny
        lda     (REG1L),y
        jsr     dis_PRBYTE
        dey
        lda     (REG1L),y
        jmp     dis_PRBYTE
;
; Instruction with an absolute operand, plus an X offset.
;
dis_abs_X:
        jsr     dis_abs
dis_comma_X:
        jsr     dis_comma
        lda     #CHAR_X
        jmp     dis_COUT
;
; Instruction with an absolute operand, plus a Y offset.
;
dis_abs_Y:
        jsr     dis_abs
dis_comma_Y:
        jsr     dis_comma
        lda     #CHAR_Y
        jmp     dis_COUT
;
; Instruction with a zero page indirect, plus an X offset.
;
dis_X_ind:
        jsr     dis_lparen
dis_comma_X_rparen:
        jsr     dis_zpg
        jsr     dis_comma_X
dis_rparen:
        lda     #CHAR_RPAR
        jmp     dis_COUT
dis_lparen:
        lda     #CHAR_LPAR
        jmp     dis_COUT
;
; Instruction with a zero page indirect, plus a Y offset.
;
dis_ind_Y:
        jsr     dis_lparen
        jsr     dis_zpg
        jsr     dis_rparen
        jmp     dis_comma_Y
;
; Instruction with a zero page address, plus an X offset.
;
dis_zpg_X:
        jsr     dis_zpg
        jmp     dis_comma_X
;
; Instruction with a zero page address, plus a Y offset.
;
dis_zpg_Y:
        jsr     dis_zpg
        jmp     dis_comma_Y
;
; Instruction with a relative branch address.
;
dis_rel:
        lda     #CHAR_DOL
        jsr     dis_COUT
        lda     REG1L
        clc
        adc     OPCODL
        sta     REG4L
        lda     REG1H
        adc     #0
        sta     REG4H
        lda     (REG1L),y
        bmi     dis_rel_backwards
        clc
        adc     REG4L
        pha
        lda     REG4H
        adc     #0
        jsr     dis_PRBYTE
        pla
        jmp     dis_PRBYTE
dis_rel_backwards:
        clc
        adc     REG4L
        pha
        lda     REG4H
        adc     #$FF
        jsr     dis_PRBYTE
        pla
        jmp     dis_PRBYTE
;
; Instruction with an absolute indirect address.
;
dis_ind:
        jsr     dis_lparen
        jsr     dis_abs
        jmp     dis_rparen
    .ifdef CPU_65C02
;
; Instruction with a zero page indirect.
;
dis_ind_zpg:
        jsr     dis_lparen
        jsr     dis_zpg
        jmp     dis_rparen
;
; Instruction with an absolute indirect address, plus an X offset.
;
dis_ind_abs_X:
        jsr     dis_lparen
        jsr     dis_abs
        jmp     dis_comma_X_rparen
;
; Instruction with a bit number and a zero page address.
;
dis_bit_zpg:
        jsr     dis_bit
        jmp     dis_zpg
dis_bit:
        dey
        lda     (REG1L),y
        iny
        and     #$07
        ora     #CHAR_0
        jsr     dis_COUT
dis_comma:
        lda     #CHAR_COMMA
        jmp     dis_COUT
;
; Instruction with a bit number, zero page address, and relative branch offset.
;
dis_zpg_rel:
        jsr     dis_bit
        jsr     dis_zpg
        lda     #CHAR_COMMA
        jsr     dis_COUT
        iny
        jmp     dis_rel
    .else
dis_comma:
        lda     #CHAR_COMMA
        jmp     dis_COUT
    .endif
