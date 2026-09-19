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
; We use 16 bytes at the end of the keyboard buffer to assist with stepping.
; The monitor code reserves this space for our use by reducing the maximum
; command-line size from 256 bytes to 240 bytes.
;
STEPBUF .equ    KEYBUF+240
REG5L   .equ    STEPBUF         ; Address that is currently being stepped.
REG5H   .equ    STEPBUF+1
TRACING .equ    STEPBUF+2       ; 0 for single-step, 1 for tracing.
LENGTH  .equ    STEPBUF+3       ; Length of the current opcode.
MONRTNL .equ    STEPBUF+4       ; Monitor return address.
MONRTNH .equ    STEPBUF+5
INSNBUF .equ    STEPBUF+6       ; Instruction that is being stepped (9 bytes).
;
; "T" command for the monitor - trace instructions until the next BRK.
;
mon_TRACE:
        inx                     ; Set X to 1.
        ; Fall through to mon_STEP.
;
; "S" command for the monitor - single-step an instruction.
;
mon_STEP:
        stx     TRACING         ; Set the TRACING flag to 0 or 1.
;
; Get the address to start stepping/tracing from into REG5.
;
        lda     CHKSUM          ; Do we have a new starting address?
        beq     step_ready      ; If not, continue from the last REG5 value.
        lda     REG2L           ; If yes, copy it to REG5.
        sta     REG5L
        lda     REG2H
        sta     REG5H
;
; Pop two levels of return addresses for mon_STEP and MON.  We preserve
; the MON return address to push back onto the stack later.
;
step_ready:
        pla
        pla
        pla
        sta     MONRTNL
        pla
        sta     MONRTNH
;
; Check for CTRL-C / BREAK to stop the tracing process.  This will also
; pause tracing if any other key is pressed.  Ignored in single-step mode.
;
step_one:
        lda     TRACING
        beq     step_disassemble
        jsr     check_ctrl_c
        bcc     step_disassemble
        lda     MONRTNH         ; Restore the MON return address to the stack.
        pha
        lda     MONRTNL
        pha
        jmp     monitor_prompt  ; Jump back into the monitor.
;
; Disassemble the instruction.
;
step_disassemble:
        lda     REG5L
        sta     REG1L
        lda     REG5H
        sta     REG1H
    .ifdef disassemble
        jsr     disassemble
    .else
;
; Disassembler code is not included; print the address and instruction bytes.
;
    .ifdef ANSI_ESCAPES
        jsr     ansi_green
    .endif
        lda     REG1H           ; Print the instruction address.
        ldx     REG1L
        jsr     MPRNAX
        lda     #CHAR_COLON
        jsr     MCOUT
    .ifdef ANSI_ESCAPES
        jsr     ansi_normal
    .endif
        ldy     #0              ; Get the length of the opcode.
        lda     (REG1L),y
        tax
        lda     OPMODES,x
        asl     a
        rol     a
        rol     a
        and     #$03
        sta     OPCODL
step_print_bytes:
        lda     #CHAR_SP        ; Print the bytes of the instruction.
        jsr     MCOUT
        lda     (REG1L),y
        jsr     MPRBYTE
        iny
        cpy     OPCODL
        bcc     step_print_bytes
step_align:
        jsr     MPRNSPC         ; Align the output on the right.
        iny
        cpy     #4
        bcc     step_align
    .endif
;
; Copy the instruction to the step buffer so that we can execute
; it in isolation from where it originally came from.  This also
; makes it possible to single-step through ROM.
;
        ldy     #0
step_copy:
        lda     (REG1L),y
        sta     INSNBUF,y
        iny
        cpy     OPCODL
        bcc     step_copy
        sty     LENGTH          ; Save OPCODL outside the zero page.
;
; Follow the instruction with JMP instructions for "continue" and
; "branch taken".
;
        lda     #$4C
        sta     INSNBUF,y
        sta     INSNBUF+3,y
        lda     #<step_continue
        sta     INSNBUF+1,y
        lda     #>step_continue
        sta     INSNBUF+2,y
        lda     #<step_branch
        sta     INSNBUF+4,y
        lda     #>step_branch
        sta     INSNBUF+5,y
;
; Determine how to single-step this instruction.
;
        lda     INSNBUF
        beq     step_break      ; Zero opcode = BRK.
        tax
        lda     OPMODES,x
        and     #$1F
        asl     a
        tax
        lda     step_handler,x  ; Get the address of the step handler.
        sta     REG4L
        lda     step_handler+1,x
        sta     REG4H
        lda     #0              ; Set A to zero before jumping to the handler.
        jmp     (REG4L)         ; Jump to the step handler.
;
; Step into a "JSR" instruction.
;
; If the JSR is to a monitor routine in the block $F800..$FFFF, then we
; just do it.  This is easier than trying to single-step screen output and
; keyboard input routines.
;
step_jsr:
        lda     INSNBUF+2       ; Is this a monitor routine?
        cmp     #$F8
        bcs     step_do         ; If yes, then execute the instruction as-is.
        lda     REG5L           ; Push the return address on the stack.
        clc
        adc     #2
        tax
        lda     REG5H
        adc     #0
        pha
    .ifdef CPU_65C02
        phx
    .else
        txa
        pha
    .endif
        ; Fall through to the "JMP" case.
;
; Step into a "JMP" instruction.
;
step_jmp:
        lda     INSNBUF+1
        sta     REG5L
        lda     INSNBUF+2
        sta     REG5H
        jmp     step_end
;
; Step into a relative branch instruction.
;
step_rel:
        ldy     LENGTH
        dey
        lda     #$03            ; Skip forward by 3 if the branch is taken.
        sta     INSNBUF,y
;
; Step the current instruction by directly executing it.
;
step_do:
        jsr     MRESTORE        ; Restore the registers.
        jmp     INSNBUF         ; Do the instruction.
;
; Step into a "BRK" instruction.  We abort the step/trace process and
; jump back into the monitor with a "!BREAK AT ..." message.
;
; Illegal instructions also come here as we don't know what to do with them.
;
step_ill:
step_break:
        lda     REG5L
        clc
        adc     #2
        sta     PCL
        lda     REG5H
        adc     #0
        sta     PCH
        jmp     break_handler
    .ifdef CPU_65C02
;
; Step into a "JMP" instruction with indirect X addressing.
;
step_jmp_ind_X:
        lda     REGX            ; Get the offset into A.
        ; Fall through to the next case.
    .endif
;
; Step into a "JMP" instruction with indirect addressing.
;
; Older versions of the 6502 had a bug where if the indirect address
; crossed a 256-byte page boundary, the wrong address would be loaded.
; We don't handle this case, as it is pretty rare.  Programmers were
; aware of this bug and made sure not to trigger it by accident.
;
step_jmp_ind:
        clc                     ; Add A (normally 0) to the indirect address.
        adc     INSNBUF+1
        sta     REG1L
        lda     INSNBUF+2
        adc     #0
        sta     REG1H
        ldy     #0              ; Fetch the address via the indirect.
        lda     (REG1L),y
        sta     REG5L
        iny
        lda     (REG1L),y
        sta     REG5H
        jmp     step_end
;
; Step into a "RTS" instruction.
;
step_rts:
        pla
        clc
        adc     #1
        sta     REG5L
        pla
        adc     #0
        sta     REG5H
        jmp     step_end
;
; Step into a "RTI" instruction.
;
step_rti:
        pla                     ; Pop the status value from the stack.
        ora     #$30            ; P always sets these bits when read.
        sta     STATUS 
        pla                     ; Pop the interrupt return address.
        sta     REG5L
        pla
        sta     REG5H
        jmp     step_end
;
; Called when the stepped instruction falls through to continue on.
;
step_continue:
        jsr     MSAVE           ; Save the registers when we get here.
        lda     REG5L
        clc
        adc     LENGTH
        sta     REG5L
        lda     REG5H
        adc     #0
        sta     REG5H
step_end:
        lda     REG5L           ; Copy REG5 into PCL/PCH for the "I" command.
        sta     PCL
        lda     REG5H
        sta     PCH
    .ifndef DSE_CAT
        ldx     #msg_reg_A_no_comma-messages
        jsr     print_regs_2
    .endif
        jsr     MCROUT
        lda     TRACING         ; Are we tracing?
        bne     step_trace_next
        lda     MONRTNH         ; Restore the MON return address to the stack.
        pha
        lda     MONRTNL
        pha
;
; Re-enter the monitor, but arrange for STOFLG to be set to STOSTEP.
; If the user presses RETURN without an address, we will step again.
;
        lda     #CHAR_STAR      ; Monitor prompt character is '*'.
        sta     PROMPT
        jsr     MGETLN          ; Get a line from the user.
        lda     #STOSTEP
        sta     STOFLG
        ldx     #$FF            ; Set up to parse the commands on the line.
        jmp     monitor_next_command
;
step_trace_next:
        jmp     step_one        ; Step the next instruction in the trace.
;
; Called when the stepped instruction takes a branch.
;
step_branch:
        jsr     MSAVE           ; Save the registers when we get here.
        dec     LENGTH          ; Branch offset at the end of the instruction.
        lda     REG5L
        clc
        adc     LENGTH
        sta     REG1L
        lda     REG5H
        adc     #0
        sta     REG1H
        ldy     #0
        lda     (REG1L),y       ; Load the relative branch offset.
        bmi     step_branch_reverse
        sec
        adc     REG1L
        sta     REG5L
        lda     REG1H
        adc     REG5H
        jmp     step_end
step_branch_reverse:
        clc
        adc     REG1L
        sta     REG5L
        lda     REG1H
        adc     #$FF
        sta     REG5H
        jmp     step_end
;
; Single-stepping handlers for the operand types.
;
step_handler:
        .dw     step_ill        ; OP_ill
        .dw     step_do         ; OP_imp
        .dw     step_do         ; OP_imm
        .dw     step_do         ; OP_abs
        .dw     step_do         ; OP_abs_X
        .dw     step_do         ; OP_abs_Y
        .dw     step_do         ; OP_X_ind
        .dw     step_do         ; OP_ind_Y
        .dw     step_do         ; OP_zpg
        .dw     step_do         ; OP_zpg_X
        .dw     step_do         ; OP_zpg_Y
        .dw     step_rel        ; OP_rel
        .dw     step_jmp_ind    ; OP_ind
        .dw     step_jsr        ; OP_jsr
        .dw     step_jmp        ; OP_jmp
        .dw     step_rts        ; OP_rts
        .dw     step_rti        ; OP_rti
    .ifdef CPU_65C02
        .dw     step_do         ; OP_ind_zpg
        .dw     step_do         ; OP_ind_abs_X
        .dw     step_do         ; OP_bit_zpg
        .dw     step_rel        ; OP_zpg_rel
    .endif
