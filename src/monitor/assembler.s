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
; Extra zero page variables.
;
STKSAVE .equ    SCRATCH1
OPTYPE  .equ    SCRATCH2
OPNAME  .equ    $4B
;
; "!" command for the monitor - assemble instructions.
;
mon_ASSEM:
;
; The address must be within the RAM region of memory.
; Cannot assemble to I/O space or ROM.
;
        lda     CHKSUM
        beq     assem_check_ram
        jsr     mon_DOT_2
assem_check_ram:
        lda     REG1H
        cmp     #>RAMTOP
        bcs     assem_bad_address
;
; Were there characters after the "!" command?  If so, try assembling
; them as the first instruction.
;
        ldx     SAVEX
        inx
        lda     KEYBUF,x
        cmp     #CHAR_CR
        beq     assem_start
assem_copy_line:
        lda     KEYBUF,x        ; Copy the line to position 0 in the buffer.
        sta     KEYBUF,y        ; This makes error reporting work better.
        inx
        iny
        cmp     #CHAR_CR
        bne     assem_copy_line
        beq     assem_cmd_line
;
assem_start:
        pla                     ; Pop the return address to the monitor.
        pla
;
assem_loop:
;
; Print the address that we are assembling instructions to.
;
    .ifdef ANSI_ESCAPES
        jsr     ansi_green
    .endif
        lda     REG1H
        ldx     REG1L
        jsr     MPRNAX
    .ifdef ANSI_ESCAPES
        jsr     ansi_normal
    .endif
;
; Prompt for a line using "!" as the prompt.
;
        lda     #CHAR_EXC
        sta     PROMPT
        jsr     MGETLN
;
; Save the current stack pointer to aid in error recovery.  We can be
; several subroutine layers deep in the parser and quickly pop the
; stack back to this level to recover after the error.
;
        tsx
        stx     STKSAVE
;
; Quit assembler mode if the line is empty.
;
assem_cmd_line:
        ldx     #0
        jsr     assem_skip_spaces
        cmp     #CHAR_CR
        beq     assem_exit
;
; A line that starts with ';' is a comment, so ignore it.
;
        cmp     #CHAR_SEMI
        beq     assem_loop
;
; Parse the line.
;
        jsr     assem_parse
;
; Go back for the next line.
;
        jmp     assem_loop
assem_exit:
        jmp     monitor_prompt
assem_bad_address:
        jsr     MERR
        jmp     MON1
;
; Skip spaces in the command-line.  X is the offset.
;
assem_skip_spaces:
        lda     KEYBUF,x
        cmp     #CHAR_SP
        bne     assem_end_skip_spaces
        inx
        bne     assem_skip_spaces
        lda     #CHAR_CR
assem_end_skip_spaces:
        rts
;
; Parse a "DB" directive.
;
assem_directive_db:
        jsr     assem_skip_spaces
        cmp     #CHAR_CR
        beq     assem_db_done
        cmp     #CHAR_SEMI
        beq     assem_db_done
        cmp     #CHAR_QUOTE
        beq     assem_db_string
        jsr     assem_skip_dollar
        jsr     assem_get_8bit_num
        lda     REG2L
        jsr     assem_store_byte
assem_db_comma:
        jsr     assem_skip_spaces
        cmp     #CHAR_CR
        beq     assem_db_done
        cmp     #CHAR_SEMI
        beq     assem_db_done
        cmp     #CHAR_COMMA
        bne     assem_db_error
        inx
        jmp     assem_directive_db
assem_db_error:
        jmp     assem_error
assem_db_string:
        inx
        lda     KEYBUF,x
        cmp     #CHAR_CR
        beq     assem_db_done
        cmp     #CHAR_QUOTE
        beq     assem_db_end_string
        jsr     assem_store_byte
        jmp     assem_db_string
assem_db_end_string:
        inx
        jmp     assem_db_comma
assem_db_done:
        rts
;
; Parse a "DW" directive.
;
assem_directive_dw:
        jsr     assem_skip_spaces
        cmp     #CHAR_CR
        beq     assem_db_done
        cmp     #CHAR_SEMI
        beq     assem_db_done
        jsr     assem_skip_dollar
        jsr     assem_get_num
        lda     REG2L
        jsr     assem_store_byte
        lda     REG2H
        jsr     assem_store_byte
        jsr     assem_skip_spaces
        cmp     #CHAR_CR
        beq     assem_db_done
        cmp     #CHAR_SEMI
        beq     assem_db_done
        cmp     #CHAR_COMMA
        bne     assem_db_error
        inx
        jmp     assem_directive_dw
;
; Parse an "ORG" directive to change the address for assembling.
;
assem_directive_org:
        jsr     assem_skip_spaces
        jsr     assem_get_num
        lda     REG2H
        cmp     #>RAMTOP        ; New origin must be in RAM.
        bcs     assem_db_error
        sta     REG1H
        lda     REG2L
        sta     REG1L
        rts
;
; Parse the current line and assemble the instruction it contains.
;
assem_parse:
;
; Parse the opcode.
;
        jsr     assem_parse_opcode
;
; Is this one of the special directives "DB", "DW", or "ORG"?
;
        cpy     #OP_DB
        bne     assem_check_dw
        jmp     assem_directive_db
assem_check_dw:
        cpy     #OP_DW
        beq     assem_directive_dw
        cpy     #OP_ORG
        beq     assem_directive_org
;
; Parse the operands.
;
        jsr     assem_parse_operands
        sta     OPTYPE
;
; Skip remaining spaces and then we expect end of line or ';'.
;
        jsr     assem_skip_spaces
        lda     KEYBUF,x
        cmp     #CHAR_CR
        beq     assem_parse_2
        cmp     #CHAR_SEMI
        beq     assem_parse_2
        jmp     assem_error
assem_parse_2:
;
; Find an instruction that matches the opcode name and operand type.
;
        ldx     #0
assem_match_insn:
        lda     OPNAMEIDX,x     ; Check for a match on the opcode name.
        cmp     OPNAME
        bne     assem_match_next
        lda     OPMODES,x       ; Check for a match on the operand type.
        and     #$1F
        asl     a
        tay
        lda     assem_matchers+1,y
        pha
        lda     assem_matchers,y
        pha
        lda     OPTYPE
        rts
assem_match_next:
        inx
        bne     assem_match_insn
        ldx     #4              ; Could not find a suitable instruction,
        jmp     assem_error     ; so report an error in the operand.
assem_match_found:
;
; Encode the instruction into memory.  Numeric form of the opcode is in X.
;
        ldy     #0
        txa
        sta     (REG1L),y       ; Store the opcode.
        lda     OPMODES,x       ; Get the actual opcode type as OPTYPE
        and     #$1F            ; may be abs when the opcode is zpg.
        asl     a
        tax
        lda     #>(assem_encode_return-1)
        pha
        lda     #<(assem_encode_return-1)
        pha
        lda     assem_encoders+1,x
        pha
        lda     assem_encoders,x
        pha
        rts
assem_encode_return:
        tya                     ; Opcode length minus 1 is in Y.
        sec
        adc     REG1L           ; Add the opcode length to REG1.
        sta     REG1L
        lda     REG1H
        adc     #0
        sta     REG1H
        rts
;
assem_match_abs:
        cmp     #OP_abs
        beq     assem_match_found
        bne     assem_match_next
assem_match_imp:
        cmp     #OP_imp
        beq     assem_match_found
        bne     assem_match_next
assem_match_zpg:
        cmp     #OP_abs
assem_match_zpg_2:
        bne     assem_match_next
assem_check_zpg:
        lda     REG2H
        bne     assem_match_next
        beq     assem_match_found
assem_match_zpg_X:
        cmp     #OP_abs_X
        bne     assem_match_next
        beq     assem_check_zpg
assem_match_zpg_Y:
        cmp     #OP_abs_Y
assem_match_next_2:
        bne     assem_match_next
        beq     assem_check_zpg
assem_match_rel:
        cmp     #OP_abs
        bne     assem_match_next
        clc
assem_match_rel_2:
        lda     REG1L
        adc     #2
        sta     REG4L
        lda     REG1H
        adc     #0
        sta     REG4H
        lda     REG2L
        sec
        sbc     REG4L
        sta     REG2L
        tay
        lda     REG2H
        sbc     REG4H
        beq     assem_match_rel_fwd
        cmp     #$FF
        bne     assem_match_next
        cpy     #$80
        bcc     assem_match_next
        bcs     assem_match_found
assem_match_rel_fwd:
        cpy     #$80
        bcc     assem_match_found
        jmp     assem_match_next
    .ifdef CPU_65C02
assem_match_ind_X:
        cmp     #OP_ind_abs_X
        jmp     assem_match_zpg_2
assem_match_zrel:
        cmp     #OP_zpg_rel
        bne     assem_match_next_2
        sec
        jmp     assem_match_rel_2
    .endif
assem_match_exact:
        cmp     OPMODES,x
        bne     assem_match_next_2
        jmp     assem_match_found
;
; Operand type matchers that deal with abs vs zpg and other differences.
;
assem_matchers:
        .dw     assem_match_exact-1 ; OP_ill
        .dw     assem_match_imp-1   ; OP_imp
        .dw     assem_match_exact-1 ; OP_imm
        .dw     assem_match_abs-1   ; OP_abs
        .dw     assem_match_exact-1 ; OP_abs_X
        .dw     assem_match_exact-1 ; OP_abs_Y
    .ifdef CPU_65C02
        .dw     assem_match_ind_X-1 ; OP_X_ind
    .else
        .dw     assem_match_exact-1 ; OP_X_ind
    .endif
        .dw     assem_match_exact-1 ; OP_Y_ind
        .dw     assem_match_zpg-1   ; OP_zpg
        .dw     assem_match_zpg_X-1 ; OP_zpg_X
        .dw     assem_match_zpg_Y-1 ; OP_zpg_Y
        .dw     assem_match_rel-1   ; OP_rel
        .dw     assem_match_exact-1 ; OP_ind
        .dw     assem_match_abs-1   ; OP_jsr
        .dw     assem_match_abs-1   ; OP_jmp
        .dw     assem_match_imp-1   ; OP_rts
        .dw     assem_match_imp-1   ; OP_rti
    .ifdef CPU_65C02
        .dw     assem_match_zpg-1   ; OP_ind_zpg
        .dw     assem_match_exact-1 ; OP_ind_abs_X
        .dw     assem_match_exact-1 ; OP_bit_zpg
        .dw     assem_match_zrel-1  ; OP_zpg_rel
    .endif
;
; Report an error in the current line and then jump back to the
; assembler's main loop.
;
assem_error:
;
; Print "ERROR".
;
    .ifdef ANSI_ESCAPES
        jsr     ansi_red
    .endif
        lda     #CHAR_E
        jsr     MCOUT
        lda     #CHAR_R
        jsr     MCOUT
        jsr     MCOUT
        lda     #CHAR_O
        jsr     MCOUT
        lda     #CHAR_R
        jsr     MCOUT
;
; Show the position of the error with a "^".
;
        cpx     #0
        beq     assem_error_printed
        lda     #CHAR_SP
assem_error_posn:
        jsr     MCOUT
        dex
        bne     assem_error_posn
assem_error_printed:
        lda     #CHAR_CARET
        jsr     MCOUT
    .ifdef ANSI_ESCAPES
        jsr     ansi_normal
    .endif
        jsr     MCROUT
;
; Pop the stack and jump back to the main assembler loop.
;
        ldx     STKSAVE
        txs
        jmp     assem_loop
;
; Parse an opcode name.  On "OPNAME" contains the index of the
; name in the "OPNAMES" table, and X has been advanced to just
; past the opcode in KEYBUF.
;
assem_parse_opcode:
        jsr     assem_read_alpha
        bcc     assem_bad_opcode
        sta     OPNAME
        jsr     assem_read_alpha
        bcc     assem_bad_opcode
        sta     OPNAME+1
        lda     #$20
        sta     OPNAME+2
        lda     KEYBUF,x        ; Third char may be a space for "DB" and "DW".
        cmp     #CHAR_SP
        beq     assem_find_opcode
        jsr     assem_read_alpha
        bcc     assem_bad_opcode
        sta     OPNAME+2
        lda     KEYBUF,x        ; Opcode must be followed by space or comment.
        cmp     #CHAR_SP
        beq     assem_find_opcode
        cmp     #CHAR_CR
        beq     assem_find_opcode
        cmp     #CHAR_SEMI
        bne     assem_bad_opcode
assem_find_opcode:
        ldy     #0
assem_next_opcode:
        lda     OPNAME
        cmp     OPNAMES,y
        bne     assem_find_next
        lda     OPNAME+1
        cmp     OPNAMES+1,y
        bne     assem_find_next
        lda     OPNAME+2
        cmp     OPNAMES+2,y
        beq     assem_found_opcode
assem_find_next:
        iny
        iny
        iny
        cpy     #OP_ORG+3       ; At the end of the opcode name table?
        bcc     assem_next_opcode
        dex                     ; Could not find the opcode.
assem_bad_opcode:
        jmp     assem_error
assem_found_opcode:
        sty     OPNAME
        rts
;
; Read a character from the line and check that it is alphabetic.
; Also converts the character to lower case for comparing against
; the opcode table.  Carry is set if character in A is alphabetic.
; Carry clear if not alphabetic.
;
assem_read_alpha:
        lda     KEYBUF,x
        inx
        cmp     #CHAR_A
        bcc     assem_not_alpha
        cmp     #CHAR_Z+1
        bcc     assem_upper_case
        cmp     #CHAR_A_L
        bcc     assem_not_alpha
        cmp     #CHAR_Z_L+1
        bcs     assem_not_alpha
    .ifdef HIGH_ASCII
        and     #$7F
    .endif
        sec
        rts
assem_upper_case:
        ora     #$20
    .ifdef HIGH_ASCII
        and     #$7F
    .endif
        sec
        rts
assem_not_alpha:
        dex
        clc
        rts
;
; Parse an immediate operand.
;
assem_parse_imm:
        inx
        jsr     assem_skip_dollar
        jsr     assem_get_8bit_num
        lda     #OP_imm
        rts
;
; Parse the operand to an instruction and determine the type of operand.
;
;       <nothing>
;       #$nn
;       $nnnn
;       ($nnnn)
;       ($nnnn,X)
;       ($nn),Y
;       $nnnn,X
;       $nnnn,Y
;       b,$nn
;       b,$nn,$nnnn
;
; The "$" is optional.  Zero page instructions will be selected by
; preference if "nnnn" is between 0000 and 00FF.
;
; The "nnnn" value is put into REG2.  The "nn" value for "b,$nn,$nnnn"
; will be put into REG4L.  The "b" value will be put into REG4H.
; The operand type will be returned in A.
;
assem_parse_operands:
        jsr     assem_skip_spaces
        lda     KEYBUF,x
        cmp     #CHAR_SEMI
        beq     assem_parse_imp
        cmp     #CHAR_CR
        beq     assem_parse_imp
        cmp     #CHAR_DOL
        beq     assem_parse_abs
        cmp     #CHAR_HASH
        beq     assem_parse_imm
        cmp     #CHAR_LPAR
        bne     assem_parse_abs_2
;
; Parse an indirect reference: (nn) or (nn,X) or (nn),Y.
;
assem_parse_ind:
        inx
        lda     KEYBUF,x
        jsr     assem_skip_dollar
        jsr     assem_get_num
        lda     KEYBUF,x
        cmp     #CHAR_RPAR
        beq     assem_parse_ind_maybe_Y
        cmp     #CHAR_COMMA
        bne     assem_operand_error
        inx
        lda     KEYBUF,x
        cmp     #CHAR_X
        beq     assem_parse_ind_X
        cmp     #CHAR_X_L
        bne     assem_operand_error
assem_parse_ind_X:
        inx
        lda     KEYBUF,x
        cmp     #CHAR_RPAR
        bne     assem_operand_error
    .ifdef CPU_65C02
        lda     #OP_ind_abs_X
    .else
        lda     #OP_X_ind
        lda     REG2H
        bne     assem_operand_error
    .endif
        rts
assem_parse_ind_maybe_Y:
        inx
        lda     KEYBUF,x
        cmp     #CHAR_COMMA
        beq     assem_parse_ind_Y
        lda     #OP_ind
        rts
assem_parse_ind_Y:
        inx
        lda     KEYBUF,x
        cmp     #CHAR_Y
        beq     assem_parse_ind_Y_2
        cmp     #CHAR_Y_L
        bne     assem_operand_error
assem_parse_ind_Y_2:
        inx
        lda     #OP_ind_Y
        rts
;
; Parse an implied operand; i.e. no operand.
;
assem_parse_imp:
        lda     #OP_imp
        rts
;
assem_operand_error:
        jmp     assem_error
;
; Parse an absolute value, optionally suffixed with ",X" or ",Y".
;
assem_parse_abs:
        inx
assem_parse_abs_2:
        jsr     assem_get_num
        lda     KEYBUF,x
        cmp     #CHAR_COMMA
        bne     assem_parse_abs_3
        inx
        lda     KEYBUF,x
        cmp     #CHAR_X
        beq     assem_parse_abs_X
        cmp     #CHAR_X_L
        beq     assem_parse_abs_X
        cmp     #CHAR_Y
        beq     assem_parse_abs_Y
        cmp     #CHAR_Y_L
    .ifdef CPU_65C02
        bne     assem_parse_bit
    .else
        bne     assem_operand_error
    .endif
assem_parse_abs_Y:
        inx
        lda     #OP_abs_Y
        rts
assem_parse_abs_X:
        inx
        lda     #OP_abs_X
        rts
assem_parse_abs_3:
        lda     #OP_abs
        rts
    .ifdef CPU_65C02
;
; Parse an operand that includes a bit number (0-7): b,nn or b,nn,nnnn
;
assem_parse_bit:
        lda     REG2H
        bne     assem_operand_error
        lda     REG2L
        cmp     #8
        bcs     assem_operand_error
        sta     REG4H
        jsr     assem_skip_dollar
        jsr     assem_get_8bit_num
        lda     REG2L
        sta     REG4L
        lda     KEYBUF,x
        cmp     #CHAR_COMMA
        bne     assem_parse_bit_zpg
        inx
        jsr     assem_skip_dollar
        jsr     assem_get_num
        lda     #OP_zpg_rel
        rts
assem_parse_bit_zpg:
        lda     #OP_bit_zpg
        rts
    .endif
;
; Get a hexadecimal number into REG2 from offset X in the
; command-line buffer.  Raises an error if no number found.
;
assem_get_num:
        dex
        jsr     MGETNUM
        lda     CHKSUM
        beq     assem_operand_error
assem_got_num:
        rts
;
; Get a hexadecimal number and check that it is 8 bits in size.
;
assem_get_8bit_num:
        jsr     assem_get_num
        lda     REG2H
        beq     assem_got_num
        dex
        jmp     assem_error
;
; Skip an optional "$" before a hexadecimal number.
;
assem_skip_dollar:
        lda     KEYBUF,x
        cmp     #CHAR_DOL
        bne     assem_skip_dollar_2
        inx
assem_skip_dollar_2:
        rts
;
; Instruction operand encoders.
;
assem_encoders:
        .dw     assem_encode_none-1   ; OP_ill
        .dw     assem_encode_none-1   ; OP_imp
        .dw     assem_encode_single-1 ; OP_imm
        .dw     assem_encode_double-1 ; OP_abs
        .dw     assem_encode_double-1 ; OP_abs_X
        .dw     assem_encode_double-1 ; OP_abs_Y
        .dw     assem_encode_single-1 ; OP_X_ind
        .dw     assem_encode_single-1 ; OP_Y_ind
        .dw     assem_encode_single-1 ; OP_zpg
        .dw     assem_encode_single-1 ; OP_zpg_X
        .dw     assem_encode_single-1 ; OP_zpg_Y
        .dw     assem_encode_single-1 ; OP_rel
        .dw     assem_encode_double-1 ; OP_ind
        .dw     assem_encode_double-1 ; OP_jsr
        .dw     assem_encode_double-1 ; OP_jmp
        .dw     assem_encode_none-1   ; OP_rts
        .dw     assem_encode_none-1   ; OP_rti
    .ifdef CPU_65C02
        .dw     assem_encode_single-1 ; OP_ind_zpg
        .dw     assem_encode_double-1 ; OP_ind_abs_X
        .dw     assem_encode_zbit-1   ; OP_bit_zpg
        .dw     assem_encode_zrel-1   ; OP_zpg_rel
    .endif
;
; Encode operands for instructions.
;
assem_encode_double:
        jsr     assem_encode_single
        iny
        lda     REG2H
        sta     (REG1L),y
assem_encode_none:
        rts
;
    .ifdef CPU_65C02
assem_encode_zbit:
        lda     (REG1L),y       ; Add the bit number to the opcode.
        ora     REG4H
        sta     (REG1L),y
    .endif
;
assem_encode_single:
        iny
        lda     REG2L
        sta     (REG1L),y
        rts
;
    .ifdef CPU_65C02
assem_encode_zrel:
        lda     (REG1L),y       ; Add the bit number to the opcode.
        ora     REG4H
        sta     (REG1L),y
        iny
        lda     REG4L
        sta     (REG1L),y
        iny
        lda     REG2L
        sta     (REG1L),y
        rts
    .endif
;
; Store a single byte at REG1L and increment REG1L.
;
assem_store_byte:
        ldy     #0
        sta     (REG1L),y
        jmp     inc_REG1_now
