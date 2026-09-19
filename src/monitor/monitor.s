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
; F8 monitor ROM.  The entry points here are deliberately numbered to
; match those in the original Apple II ROM so that existing code works.
;
; Labels that start with a capital "M" are public entry points.
; All other labels are internal.
;

;
; Shift the origin to a new location while filling with RTS instructions.
; This way, if existing code jumps to a "known" location in the F8 ROM
; that we don't implement, the monitor will simply return.
;
    .ifndef BASE_SHIFT
    .macro ORIGIN
    .if \1 <> *
        .ds     \1-*,$60
    .endif
    .endm
    .else
    .macro ORIGIN
    .if (\1-$F800) <> (*-BASE_SHIFT)
        .ds     (\1-$F800)-(*-BASE_SHIFT),$60
    .endif
    .endm
    .endif

;
; Eater configuration puts the serial receive buffer above RAMTOP ($3F00).
; 256 bytes of memory space are needed for the serial receive buffer.
;
    .ifdef EATER
SERBUF  .equ    RAMTOP
        .include acia.s
    .endif

    .ifdef DSE_CAT
;
; Well-known entry points for the Dick Smith Cat / Laser 3000 ROM.
;
        jmp     FRAM0I
        jmp     FRAM0O
        jmp     TEXT40
        jmp     TEXT80
        jmp     AUDOUT
        jmp     MOUTS1
    .endif

;
; Handler for escape sequences in the input stream.
;
escape_handler:
        jsr     wait_escape     ; Get the next character in the escape sequence.
        bcc     not_escape
    .ifdef DSE_CAT
        cmp     #$C4            ; "ESC D" is the up arrow key.
        beq     up_arrow
        cmp     #$B0            ; 0, 1, and 2 are function key introducers.
        bcc     not_escape
        cmp     #$B3
        bcs     not_escape
        jmp     function_key
up_arrow:
        lda     #$9F            ; Replace up arrow with a control key.
        rts
    .else
    .ifdef ansi_escape
        jmp     ansi_escape
    .endif
    .endif
;
; Escape sequence was not recognised, so this is just an ESC character.
;
not_escape:
        lda     #CHAR_ESC
        rts
    .ifdef DSE_CAT
;
; Handle special control characters on the Dick Smith Cat / Laser 3000.
;
control_handler:
        cmp     #$88            ; May be a backspace or a left arrow.
        beq     backspace_key
        cmp     #$9C            ; TAB key?
        beq     tab_key
        cmp     #$FF            ; BREAK key?
        bne     not_break
        lda     #$83            ; Convert BREAK into CTRL-C.
not_break:
        rts
tab_key:
        lda     #$89            ; Convert $9C for TAB into the proper $89.
        rts
;
; On the Cat, the backspace character may be the start of the sequence
; "88 A0 88" meaning "RUBOUT".  We recognise that and convert it into DEL.
; If the backspace is on its own, then it is a left arrow.
;
backspace_key:
        jsr     wait_escape
        bcc     not_rubout
        cmp     #$A0
        bne     not_rubout
        jsr     wait_escape
        bcc     not_rubout
        cmp     #$88
        bne     not_rubout
        lda     #CHAR_DEL       ; Map the RUBOUT key to DEL.
        rts
not_rubout:
        lda     #KEY_LEFT
        rts
    .endif
;
; Wait for a keypress with a timeout, to handle input escape sequences.
; On exit, A is is the next character with carry set.  Or carry clear if
; the timeout occurred.
;
    .ifdef EMULATOR
wait_escape:
        lda     #50             ; Set the keyboard timeout to 50ms.
        sta     $C7E9
        lda     $C7E8           ; Wait for a key with the timeout.
        bmi     wait_escape_got_key
        clc
        rts
wait_escape_got_key:
        lda     $C7E1           ; Get the raw 8-bit keycode.
        sec
        rts
    .else
wait_escape:
    .ifdef CPU_65C02
        phy
    .else
        sty     SCRATCH1
    .endif
        ldy     #50
wait_escape_loop:
        jsr     MPEEKIN
        bcs     wait_escape_got_key
        dey
        bne     wait_escape_loop
    .ifdef CPU_65C02
        ply
    .else
        ldy     SCRATCH1
    .endif
        rts
wait_escape_got_key:
        jsr     MRDKEY
    .ifdef CPU_65C02
        ply
    .else
        ldy     SCRATCH1
    .endif
        sec
        rts
    .endif
;
; Core of the get line routine MGETLN.
;
get_line:
        jsr     MRDCHR          ; Get the next character with ESC decoding.
    .ifdef HIGH_ASCII
        cmp     #$A0            ; Is it a control character?
        bcc     control_char
    .else
        cmp     #$20
        bcc     control_char
        cmp     #$7F
        beq     control_char
        cmp     #$F8
        bcs     control_char
    .endif
    .ifndef mon_STEP
        cpx     #$FF            ; Are we at the maximum line size?
    .else
        cpx     #$EF            ; Reserve some space for the step buffer.
    .endif
        bcs     get_line        ; Ignore the character if we are.
        sta     KEYBUF,x        ; Add the character to the end of the line.
        jsr     MCOUT           ; Print the character.
        inx
        jmp     get_line
control_char:
        cmp     #CHAR_BS        ; Backspace or DEL are the same as RUBOUT.
        beq     get_line_rubout
        cmp     #CHAR_DEL
        beq     get_line_rubout
        cmp     #CHAR_NAK       ; CTRL-U or CTRL-X?
        beq     get_line_cancel
        cmp     #CHAR_CAN
        beq     get_line_cancel
        cmp     #CHAR_CR        ; ENTER pressed?
        bne     get_line        ; Ignore all other control characters.
        sta     KEYBUF,x        ; Store the CR at the end of the buffer.
        jsr     MCROUT          ; Print CRLF to terminate the line.
        lda     #CHAR_CR        ; Return a CR character to the caller.
        rts
get_line_rubout:
        cpx     #0              ; Cannot backspace if at the start of the line.
        beq     get_line
        jsr     backspace       ; Print BS, SP, BS to erase the last character.
        jmp     get_line
get_line_cancel_2:
        jsr     backspace
get_line_cancel:
        cpx     #0
        bne     get_line_cancel_2
        beq     get_line
;
; Backspace over and erase the last character in the line buffer.
;
backspace:
        dex                     ; Back up one position in the buffer.
        lda     #CHAR_BS
        jsr     MCOUT
        lda     #CHAR_SP
        jsr     MCOUT
        lda     #CHAR_BS
    .ifndef HIGH_ASCII
        jsr     MCOUT
check_utf8:
        lda     KEYBUF,x        ; Was this part of a multi-byte UTF-8 sequence?
        and     #$C0            ; If so, we need to print backspace once, but
        cmp     #$80            ; remove multiple bytes from the buffer.
        bne     not_utf8
        dex
        bne     check_utf8
not_utf8:
        rts
    .else
        jmp     MCOUT
    .endif

;
; Various messages for the monitor routines.
;
messages:
msg_error:
        .db     "ERROR ",$07
        .db     0
msg_break_at:
        EMITCRLF
    .ifdef ANSI_ESCAPES
        .db     $1B, "[31;1m"
    .endif
        .db     "!BREAK "
    .ifdef ANSI_ESCAPES
        .db     $1B, "[0m"
    .endif
        .db     "@ PC="
        .db     0
msg_reg_A:
        .db     ", "
msg_reg_A_no_comma:
        .db     "A="
        .db     0
msg_reg_X:
        .db     ", X="
        .db     0
msg_reg_Y:
        .db     ", Y="
        .db     0
msg_reg_P:
        .db     ", P="
        .db     0
msg_reg_S:
        .db     ", S="
        .db     0
msg_unknown:
        .db     "UNKNOWN COMMAND: "
        .db     0
msg_verify:
        .db     " -> "
        .db     0
;
; Startup banner for the monitor.
;
    .ifndef NO_BANNER
banner:
    .ifdef ANSI_ESCAPES
        .db     $1B, "[H"
        .db     $1B, "[0m"
        .db     $1B, "[J"
        .db     $1B, "[32;1m"
    .else
        .db     CHAR_FF
    .endif
        .db     "Maggot MON v2.1"
        EMITCRLF
    .ifdef ANSI_ESCAPES
        .db     $1B, "[33;1m"
    .endif
        .db     "Copyright (c) 2026 Rhys Weatherley"
    .ifdef ANSI_ESCAPES
        .db     $1B, "[0m"
    .endif
        EMITCRLF
        .db     0
    .endif
;
; Print A:X as a pair of hexadecimal bytes.  Destroys A.
;
        ORIGIN  $F941
MPRNAX:
        jsr     MPRBYTE
        txa
        jmp     MPRBYTE
;
; Print spaces.
;
; $F948 - Print 3 spaces.
; $F94A - Print X spaces (1..256).
;
        ORIGIN  $F948
MPRNSPC:
        ldx     #3
MPRNXSPC:
        lda     #CHAR_SP
prnspc:
        jsr     MCOUT
        dex
        bne     prnspc
        rts
;
; "=" command for the monitor.  Set a register to the value in REG2.
;
; Examples: "FF=A 67=X" (the register name is after the "=").
;
mon_SETREG:
        stx     STOFLG          ; Clear the store flag for the next command.
        ldx     SAVEX           ; Recover the command-line buffer index.
        lda     KEYBUF+1,x
        ldy     #REGX
        cmp     #CHAR_X
        beq     set_register
        cmp     #CHAR_X_L
        beq     set_register
        iny
        cmp     #CHAR_Y
        beq     set_register
        cmp     #CHAR_Y_L
        beq     set_register
        iny
        cmp     #CHAR_P
        beq     set_register
        cmp     #CHAR_P_L
        beq     set_register
        iny
        iny
        cmp     #CHAR_A
        beq     set_register
        cmp     #CHAR_A_L
        bne     invalid_command
set_register:
        inx                     ; Remove the register name from the buffer.
        stx     SAVEX
        lda     REG2L
        sta     $0000,y
        rts
invalid_command:
        pla
        pla
        jsr     MERR
        jmp     MON1
;
; "<" command which copies REG2 into REG4.
;
mon_SHIFT:
        stx     STOFLG          ; Clear the store flag when "<" encountered.
        lda     REG2L
        sta     REG4L
        lda     REG2H
        sta     REG4H
        rts
;
; Print the bytes that differ when verifying memory.
;
print_verify_result:
        lda     REG1H
        ldx     REG1L
        jsr     MPRNAX          ; Print the source address.
        lda     #CHAR_COLON     ; Print a colon.
        jsr     MCOUT
        lda     (REG1L),y
        jsr     MPRBYTE         ; Print the source byte.
        ldx     #msg_verify-messages
        jsr     print_message
        lda     REG4H
        ldx     REG4L
        jsr     MPRNAX          ; Print the destination adress.
        lda     #CHAR_COLON     ; Print a colon.
        jsr     MCOUT
        lda     (REG4L),y
        jsr     MPRBYTE         ; Print the destination byte.
        jmp     MCROUT
;
; Check if CTRL-C / BREAK has been pressed.  Carry set on exit if
; pressed, carry clear to continue.
;
; If any other key is pressed, the output will be paused.
;
; Preserves A, X, and Y.
;
check_ctrl_c:
        jsr     MPEEKIN         ; Is a character pressed on the keyboard?
        bcc     not_ctrl_c
        pha
        jsr     MRDCHR          ; Read the character.
        cmp     #CHAR_ETX       ; Is it CTRL-C?
        beq     is_ctrl_c
        jsr     MRDCHR          ; Output is paused, wait for another character.
        cmp     #CHAR_ETX       ; Do we have CTRL-C now?
        beq     is_ctrl_c
        pla
        clc
not_ctrl_c:
        rts
is_ctrl_c:
        lda     #CHAR_CARET     ; Print ^C and CRLF to the console.
        jsr     MCOUT
        lda     #CHAR_C
        jsr     MCOUT
        jsr     MCROUT
        pla
        sec
        rts
;
    .ifdef DSE_CAT
;
; Function key handling for the Dick Smith Cat / Laser 3000.
;
function_key:
        and     #$0F                ; A is "0", "1", or "2" at this point.
        asl     a
        asl     a
        asl     a
        adc     #KEY_F1
        sta     FKEY
        jsr     wait_escape
        bcc     function_key_unknown
        cmp     #CHAR_0             ; Next character should be "0" to "7".
        bcc     function_key_unknown
        cmp     #CHAR_8
        bcs     function_key_unknown
        and     #$0F
        clc
        adc     FKEY
        sta     FKEY
        lda     #KEY_FESC
        rts
function_key_unknown:
        lda     #KEY_UNKNOWN
        sta     FKEY
        lda     #KEY_FESC
        rts
    .endif
;
    .ifdef EATER
        ORIGIN  $FA10
;
; Handle serial interrupts in the Eater configuration.
;
serial_rx:
        and     #ACIA_RDRF      ; Did we receive a byte?
        beq     done_serial_rx
        lda     ACIA_DATA       ; Get the received byte into A.
        phx
        ldx     SBAS2H          ; Get the serial buffer write pointer.
        sta     SERBUF,x        ; Store A into the serial buffer.
        plx
        inc     SBAS2H          ; Increment the write pointer.
        lda     SBAS2H          ; Is the buffer almost full?
        sec
        sbc     SBAS2L
        cmp     #240
        bcc     done_serial_rx  ; If not, then leave interrupts on for now.
        lda     #ACIA_DTR       ; Disable serial receive interrupts.
        sta     ACIA_CMD
        bne     done_serial_rx
    .endif
;
; IRQBRK handler.
;
; There was a bug in the original Apple II IRQBRK handler, which was copied
; as-is to the Dick Smith Cat / Laser 3000.  On entry to the user's IRQ
; handler, the A register has been destroyed.  The user's handler would have to
; restore the A register manually from "ACCIRQ" prior to the "RTI" instruction.
;
; This is stupid and error-prone and has caused me no end of grief.
; I restore A just before jumping to the user-supplied IRQ handler.
;
; Another issue is the D bit in the status register.  For predictability,
; it should be off when the interrupt handler is called.  So I do that too.
;
        ORIGIN  $FA40
IRQBRK:
        sta     ACCIRQ          ; Save A.
        cld                     ; Make sure that D is off.
        pla                     ; Copy the status register into A.
        pha
        and     #$10            ; Is the BREAK bit set?
        bne     do_break
    .ifdef EATER
;
; Handle serial port interrupts for the Eater configuration.
;
        lda     ACIA_STATUS     ; Did the serial interrupt fire off?
        bmi     serial_rx       ; Bit 7 will be set if it did.
done_serial_rx:
    .endif
        lda     ACCIRQ          ; Restore A.
        jmp     (IRQVER)        ; Jump to the user-supplied interrupt handler.
do_break:
        plp                     ; Restore the status register.
        jsr     MSAVE2          ; Save all registers in the zero page.
        pla                     ; Copy the BREAK address to the zero page.
        sta     PCL
        pla
        sta     PCH
        cld                     ; Make sure D is off again.
        cli                     ; Re-enable interrupts.
        jmp     (BRKVER)        ; Jump to the user-supplied BREAK handler.
;
; Reset vector for the system.
;
        ORIGIN  $FA62
MRESET:
        cld                     ; Make sure D is off.
        sei                     ; Mask interrupts until we are ready.
;
; Detect cold vs warm start.
;
    .ifdef DSE_CAT
        ldx     #$0F            ; Is PBANK4 set to 15?
        cpx     PBANK4          ; If it is, then we are doing a warm start.
        beq     mon_warm_start
    .else
        lda     RESTVR+1        ; Check the reset vector in page 3.
        eor     #$A5
        cmp     PWRIND
        beq     mon_warm_start
    .endif
;
; Cold start reset handling.
;
; Perform a short delay at startup to let the power rails and
; daughter chips settle into their reset condition.
;
; This delay is approximately 300ms with a 1MHz clock.
;
        ldy     #0
        tya
reset_delay:
    .if SYSCLK > 4000
        nop
        nop
    .endif
    .if SYSCLK > 3000
        nop
        nop
        nop
    .endif
    .if SYSCLK > 2000
        nop
        nop
    .endif
    .if SYSCLK > 1000
        nop
        nop
        nop
    .endif
        adc     #1
        bcc     reset_delay
        dey
        bne     reset_delay
;
; Clear $0000 to $03FF on a cold start before we start using it.
; Zero page, stack, keyboard buffer, and vector page.
;
        tya
clear_low_pages:
        sta     $0000,y
        sta     $0100,y
        sta     $0200,y
        sta     $0300,y
        iny
        bne     clear_low_pages
;
; Set the initial stack pointer on a cold start.
;
        ldx     #$FF
        txs
;
    .ifdef DSE_CAT
;
; Fix the memory configuration for the Dick Smith Cat / Laser 3000.
; Banks 0, 1, 3, and F should be activated by default.
;
        lda     #$0F
        sta     SBANK4
        sta     SYSTEM
        sta     PBANK4
        ldy     #0
        sty     SBANK1
        sty     PBANK1
        iny
        sty     SBANK2
        sty     PBANK2
        iny
        iny
        sty     SBANK3
        sty     SBANK3
;
; Clear the 80 column screen text buffer.
;
        lda     #$10
        ldy     #0
        sta     BSTART+1
        sty     BSTART
        sta     STATUS          ; Initialise saved status to $10.
        lda     #CHAR_SP
clear_80cols:
        sta     (BSTART),y
        iny
        bne     clear_80cols
        inc     BSTART+1
        lda     BSTART+1
        cmp     #$18
        bcc     clear_80cols
    .else
        lda     #$10            ; Initialise saved status to $10.
        sta     STATUS
    .endif
;
; Set the start and end of RAM for BASIC programs (or other languages).
;
; Starts at $1800 for the Dick Smith Cat / Laser 3000, or $0400 for others.
;
    .ifndef DSE_CAT
        lda     #0
        sta     BSTART
        lda     #$04
        sta     BSTART+1
    .endif
        lda     #<(RAMTOP-1)
        sta     BEND
        lda     #>(RAMTOP-1)
        sta     BEND+1
;
; Warm start reset handling.
;
mon_warm_start:
;
; Set the default llvm-mos stack pointer to the end of RAM in case
; we want to run some C code at startup.
;
        lda     BEND
        sta     __rc0
        lda     BEND+1
        sta     __rc1
;
    .ifdef DSE_CAT
;
; Initialise the hardware for the Dick Smith Cat / Laser 3000 at startup.
;
        jsr     TEXT40          ; Activate 40-column text mode.
        jsr     MSETNOR         ; Set normal text.
        lda     TEXTCR          ; Set white text.
        lda     BKGRND          ; Set black background.
        lda     BKDROP          ; Set black border.
        jsr     sound_init      ; Initialise the sound generator chip.
        lda     VZSELF          ; Turn off emulation.
        lda     VZPAG1          ; Select screen page 1.
        lda     VZTEXT          ; Select text mode.
;
; Initialise the screen window to 40x24 and place the cursor at the
; bottom of the screen.
;
        lda     #0
        sta     WNDTOP
        sta     WNDLFT
        sta     CHORZ
        lda     #40
        sta     WNDWTH
        ldy     #24
        sta     WNDBTM
        dey
        sty     CVERT
        jsr     MVTAB
    .endif
    .ifdef EATER
;
; Initialise the serial port for the Eater configuration.
;
        lda     ACIA_STATUS     ; Clear spurious status bits.
        lda     ACIA_DATA       ; Empty the receive buffer.
        stz     ACIA_STATUS     ; Force the ACIA to reset itself.
    .ifdef SERIAL_115200
        ; Need a system clock of at least 2MHz to use 115200bps.
    .if SYSCLK >= 2000
        lda     #(ACIA_BPS_115200 | ACIA_RCS)
    .else
        lda     #(ACIA_BPS_19200 | ACIA_RCS)
    .endif
    .else
        lda     #(ACIA_BPS_19200 | ACIA_RCS)
    .endif
        sta     ACIA_CTRL
        lda     #(ACIA_TIC1 | ACIA_DTR)
        sta     ACIA_CMD
        lda     #0              ; Clear the read/write buffer pointers.
        sta     SBAS2L
        sta     SBAS2H
    .endif
;
; Set the I/O handler addresses to their defaults.
;
        jsr     set_default_output
        jsr     set_default_input
        lda     #<MPEEKKEY
        ldy     #>MPEEKKEY
        sta     PEEKSWL
        sty     PEEKSWH
;
; Is this a cold or warm start?
;
        lda     RESTVR+1        ; Check the reset vector in page 3.
        eor     #$A5
        cmp     PWRIND
        beq     warm_start_launch
;
; Fix up the interrupt handlers and other vectors in page 3.
;
        ldx     #vectors_end-vectors-1
fix_vectors:
        lda     vectors,x
        sta     BRKJMP,x
        dex
        bpl     fix_vectors
;
; It is now safe to turn interrupts on.
;
        cli
;
; Print the startup banner.
;
    .ifndef NO_BANNER
        ldx     #banner-messages
        jsr     print_message
    .else
        jsr     MCROUT
    .endif
;
; Clear the BASIC program area on a cold start.
;
    .ifndef DSE_CAT
        lda     BSTART
        sta     REG4L
        lda     BSTART+1
        sta     REG4H
        lda     #0
        tay
clear_program_area:
        sta     (REG4L),y
        iny
        bne     clear_program_area
        inc     REG4H
        ldx     REG4H
        cpx     BEND+1
        bcc     clear_program_area
        beq     clear_program_area
    .endif
;
; Check to see if we have a bootable disk controller.
;
    .ifdef DSE_CAT
        jsr     check_disk
    .endif
;
; Perform a cold start on BASIC, or jump into the kernel monitor.
;
; It is possible that we have some language other than BASIC at $E000,
; but as long as the entry point looks like BASIC we will jump to it.
;
        lda     $E000           ; Does it look like we have BASIC?
        cmp     #$4C            ; We expect a JMP or JSR instruction at $E000.
        beq     cold_start_basic
        cmp     #$20
        beq     cold_start_basic
;
; We don't have BASIC available, so change the reset vector to point
; at the kernel monitor instead.  And then jump to the monitor.
;
start_monitor:
        lda     #<MON1          ; MON1 is "Enter monitor with no beep".
        sta     RESTVR
        lda     #>MON1
        sta     RESTVR+1
        eor     #$A5
        sta     PWRIND
        jsr     MON             ; MON is "Enter monitor with beep".
;
; Perform a warm start on BASIC, or jump into the kernel monitor.
;
warm_start_launch:
        cli                     ; Enable interrupts.
        lda     RESTVR+1        ; Do we have a non-BASIC warm start vector?
        cmp     #$E0
        bne     warm_start_jump
        lda     RESTVR
        bne     warm_start_jump
;
; If we get here, then the reset vector is $E000 which indicates that
; we need to force a cold start of BASIC.  Switch the reset vector to the
; warm start location for the next boot and then do the cold start.
;
cold_start_basic:
        lda     #$03
        sta     RESTVR
        lda     #$E0
        sta     RESTVR+1
        eor     #$A5
        sta     PWRIND
        jmp     $E000
warm_start_jump:
        lda     #>(MON1-1)      ; Push the monitor address on the stack
        pha                     ; in case the user's reset vector returns.
        lda     #<(MON1-1)
        pha
        jmp     (RESTVR)        ; Call the user-supplied reset vector.
;
; Set the default video output routine.
;
set_default_output:
        lda     #>MCOUT1
        ldy     #<MCOUT1
        sta     OUTSWH
        sty     OUTSWL
        rts
;
; Set the default keyboard input routine.
;
set_default_input:
        lda     #>MINKEY
        ldy     #<MINKEY
        sta     INSWH
        sty     INSWL
        rts
    .ifdef DSE_CAT
;
; Initialise the 76489 sound generator chip.
;
sound_init:
        ldy     #3
sound_init_loop:
        lda     sound_off,y
        jsr     AUDOUT
        dey
        bpl     sound_init_loop
no_disk:
        rts
sound_off:
        .db     $9F, $BF, $DF, $FF
;
; Check for a bootable disk controller at $C600 or $C500.
;
check_disk:
        lda     $C607
        cmp     #$3C
        bne     check_disk_5
        lda     $C603
        bne     check_disk_5
        pla
        pla
        jmp     $C600
check_disk_5:
        lda     $C507
        cmp     #$3C
        bne     no_disk
        lda     $C503
        bne     no_disk
        pla
        pla
        jmp     $C500
    .endif

;
; Data to initialise the break/reset/irq/etc vectors in page 3.
;
vectors:
        jmp     break_handler   ; $3EF - Handler for BREAK.
        .dw     $E000           ; $3F2 - Warm start reset handler.
        .db     $45             ; $3F4 - Power on indicator.
        jmp     MRETURN         ; $3F5 - Default "&" subroutine for BASIC.
        jmp     MRETURN         ; $3F8 - Default "USR" subroutine for BASIC.
        jmp     nmi_default     ; $3FB - NMI handler.
        .dw     irq_default     ; $3FE - IRQ handler.
vectors_end:
;
; Default IRQ and NMI handlers.
;
irq_default:
        lda     ACCIRQ          ; Restore the A register.
nmi_default:
        rti
;
; Print the prompt character in A, including ANSI colour escapes if appropriate.
;
print_prompt:
    .ifdef ANSI_ESCAPES
        jsr     ansi_yellow
        jsr     MCOUT
        jmp     ansi_normal
    .else
        jmp     MCOUT
    .endif
;
; Print some useful ANSI escape sequences.
;
    .ifdef ANSI_ESCAPES
ansi_green:
        phx
        ldx     #esc_ansi_green-ansi_escapes
        jsr     print_ansi
        plx
        rts
ansi_yellow:
        phx
        ldx     #esc_ansi_yellow-ansi_escapes
        jsr     print_ansi
        plx
        rts
ansi_red:
        phx
        ldx     #esc_ansi_red-ansi_escapes
        jsr     print_ansi
        plx
        rts
ansi_normal:
        phx
        ldx     #esc_ansi_normal-ansi_escapes
        jsr     print_ansi
        plx
        rts
ansi_inverse:
        phx
        ldx     #esc_ansi_inverse-ansi_escapes
        jsr     print_ansi
        plx
        rts
print_ansi:
        pha
print_ansi_next:
        lda     ansi_escapes,x
        beq     print_ansi_done
        jsr     MCOUT
        inx
        bne     print_ansi_next
print_ansi_done:
        pla
        rts
ansi_escapes:
esc_ansi_green:
        .db     $1B, "[32;1m", 0
esc_ansi_yellow:
        .db     $1B, "[33;1m", 0
esc_ansi_red:
        .db     $1B, "[31;1m", 0
esc_ansi_normal:
        .db     $1B, "[0m", 0
esc_ansi_inverse:
        .db     $1B, "[7m", 0
    .endif
;
; Ring the terminal bell for the actual video screen.  Use MBELL to ring the
; terminal bell on the default output stream.
;
        ORIGIN  $FBDD
MBELLVID:
    .ifdef DSE_CAT
        jsr     C800IN
        jmp     $CA2E
    .else
        lda     #CHAR_BEL
        jmp     MCOUT1
    .endif
;
; Find a monitor command in the "commands" table.
;
find_command:
        ldy     #0
        lda     KEYBUF,x        ; Get the command from the keyboard buffer.
        cmp     #CHAR_A_L
        bcc     find_command_loop
        cmp     #CHAR_LCURLY
        bcs     find_command_loop
        and     #$DF            ; Convert the command to upper case.
find_command_loop:
        cmp     commands,y
        beq     found_command
        iny
        cpy     #commands_end-commands
        bcc     find_command_loop
        clc
        rts
found_command:
        sec
        rts
;
; Print a message from the "messages" table.  X is the offset into the table.
;
print_message:
        lda     messages,x
        beq     done_message
    .ifdef HIGH_ASCII
        ora     #$80
    .endif
        jsr     MCOUT
        inx
        bne     print_message
done_message:
        rts
;
; Print a message followed by a register value.
;
print_reg:
        pha
        jsr     print_message
        pla
        jmp     MPRBYTE

;
; Re-calculate the screen address because of a manual change to CHORZ/CVERT.
;
        ORIGIN  $FC22
MVTAB:
    .ifdef DSE_CAT
        lda     CVERT
        jsr     C800IN
        jmp     $CB41
    .else
    .ifdef move_cursor
        jmp     move_cursor
    .else
        rts
    .endif
    .endif

;
; "G" command for the kernel monitor.
;
; This one is slightly better than the standard one in that it will
; save the registers after the subroutine returns.
;
; We also force "G" to be the last command by ignoring any later commands.
; This is needed because the subroutine that we jump to may destroy the
; contents of the keyboard buffer.
;
mon_GO:
    .ifdef mon_STEP
;
; "G" on its own in step mode causes the code to start running from the
; point we got up to in the step sequence.
;
        lda     CHKSUM
        bne     mon_GO_GO
        lda     STOFLG
        cmp     #STOSTEP
        bne     mon_GO_GO
        lda     REG5L           ; Copy REG5 into REG2.
        sta     REG2L
        lda     REG5H
        sta     REG2H
mon_GO_GO:
    .endif
        pla
        pla
        lda     #>(monitor_restart-1)
        pha
        lda     #<(monitor_restart-1)
        pha
        lda     REG2L
        sta     PCL
        lda     REG2H
        sta     PCH
        jsr     MRESTORE
        jmp     (PCL)
monitor_restart:
        jsr     MSAVE
        cld                     ; Fix up the D and I bits in the P register.
        cli
        jmp     monitor_prompt
;
; Get the range to use for the current command.  Carry is clear on
; exit if the range is ready to use.  Carry is set for a continuation.
;
get_range:
        lda     STOFLG
        cmp     #STODOT         ; Did we have a "." for an explicit range?
        beq     dot_range       ; If so, range is already in REG1..REG2.
        lda     CHKSUM          ; Did we have a value before the command?
        beq     continue_range  ; If not, continue the previous range.
        jsr     mon_DOT_2       ; Range is REG2..REG2; copy REG2 into REG1.
dot_range:
        clc
        rts
continue_range:
        lda     REG1L           ; Copy REG1 back into REG2.
        sta     REG2L
        lda     REG1H
        sta     REG2H
        sec                     ; Indicate a continuation.
        rts
;
; "M" command for the monitor.  Move a region of memory.
;
mon_MOVE:
        jsr     get_range       ; Get the range to be moved.
        stx     STOFLG          ; Clear the store flag for the next command.
move_byte:
        lda     (REG1L),y       ; Move a byte from (REG1) to (REG4).
        sta     (REG4L),y
        jsr     inc_REG4        ; Increment REG4 and REG1; compare REG1 > REG2.
        bcc     move_byte
        rts
;
; "V" command for the monitor.  Verify a region of memory.
;
mon_VERIFY:
        jsr     get_range       ; Get the range to be verified.
        stx     STOFLG          ; Clear the store flag for the next command.
verify_byte:
        lda     (REG1L),y       ; Compare (REG1) with (REG4).
        cmp     (REG4L),y
        beq     bytes_same
        jsr     print_verify_result
bytes_same:
        jsr     inc_REG4        ; Increment REG4 and REG1; compare REG1 > REG2.
        bcc     verify_byte
        rts
;
; " " command for the monitor.  Examine or set.
;
mon_SPACE:
        lda     STOFLG          ; Are we in store mode?
        cmp     #STOSET
        beq     store_mode
        jsr     get_range       ; Get the range of addresses to examine.
        php
        lda     #15             ; Figure out the screen width.
    .ifdef DSE_CAT
        ldx     WNDWTH          ; Are we in 80 column mode?
        cmp     #80
        bcs     wide_examine
        lsr     a               ; 40-column mode, so replace 15 with 7.
wide_examine:
    .endif
        sta     CHKSUM
        plp
        bcc     examine_range
;
; We are continuing the previous examine.  Set up to show the next
; line of bytes, up to the next multiple of 8 or 16.
;
        ora     REG1L
        sta     REG2L
        lda     REG1H
        sta     REG2H
examine_range:
    .ifdef ANSI_ESCAPES
        jsr     ansi_green
    .endif
        ldx     REG1L           ; Print the starting address for the line.
        lda     REG1H
        jsr     MPRNAX
        lda     #CHAR_COLON     ; Print a ":" after the address.
        jsr     MCOUT
    .ifdef ANSI_ESCAPES
        jsr     ansi_normal
    .endif
examine_byte:
        lda     #CHAR_SP        ; Print a space before the byte.
        jsr     MCOUT
        lda     (REG1L),y       ; Get the next byte and print it.
        jsr     MPRBYTE
        jsr     inc_REG1        ; Increment REG1 and compare with REG2.
        bcs     examine_done
        lda     REG1L
        and     CHKSUM
        bne     examine_byte
        jsr     MCROUT          ; End the current line of 8 or 16 bytes.
        jsr     check_ctrl_c    ; Check for CTRL-C / BREAK.
        bcs     examine_done
        jmp     examine_range   ; Go back for the next line to output.
examine_done:
        jmp     MCROUT
store_mode:
        lda     REG2L           ; Store REG2L into (REG1).
        sta     (REG1L),y
        jmp     inc_REG1_now    ; Increment REG1 for the next store.
;
; CR command for the monitor.  Examine or set and then end the line.
;
mon_RETURN:
    .ifdef mon_STEP
;
; Check if we need to repeat the last "S" command.
;
        lda     CHKSUM
        bne     mon_RETURN_2
        lda     STOFLG
        cmp     #STOSTEP
        bne     mon_RETURN_2
        jmp     mon_STEP
mon_RETURN_2:
    .endif
        jsr     mon_SPACE
end_line:
        pla                     ; Pop the return address and jump back
        pla                     ; to the start of the monitor code.
        jmp     monitor_prompt
;
; "X" command which exits from the monitor back to BASIC (or whatever
; language we are using instead of BASIC).
;
mon_EXIT:
    .ifdef EMULATOR
        lda     #0              ; Tell the emulator to quit with exit code 0.
        sta     $C7EE
    .endif
        pla
        pla
        rts
;
; Read a key from the standard input device.
;
        ORIGIN  $FD0C
MRDKEY:
    .ifdef DSE_CAT
        jsr     C800IN          ; Swap in the C800 ROM for slot 3.
        jsr     $CBA0           ; Enable the cursor.
        lda     TEMPA           ; Set A to the character under the cursor.
    .endif
        jmp     (INSWL)
    .ifdef EATER
;
; Increment the random number value while waiting for serial input.
;
serial_rand:
        inc     RNDNOL
        bne     serial_wait
        inc     RNDNOH
        jmp     serial_wait
    .endif
;
; Read a key from the actual keyboard.
;
        ORIGIN  $FD1B
MINKEY:
    .ifdef DSE_CAT
        jsr     C800IN          ; Swap in the C800 ROM for slot 3.
        sty     SAVEY
        jsr     $C84D           ; Wait for the next key.
        jsr     $CBDF           ; Disable the cursor.
        ldy     SAVEY
        rts
    .else
    .ifdef EATER
;
; Wait for the next character on the serial port.
;
        phx
serial_wait:
        ldx     SBAS2L          ; Wait for the read and write pointers
        cpx     SBAS2H          ; to be different.
        beq     serial_rand     ; Generate random numbers while we wait.
serial_read:
        lda     SERBUF,x        ; Get the next character from the buffer.
        plx
        pha
        inc     SBAS2L          ; Advance the read pointer.
        lda     SBAS2H          ; Should we turn receive interrupts back on?
        sec
        sbc     SBAS2L
        cmp     #224
        bcs     serial_rx_done
        bcc     serial_rx_restart
    .else
    .ifdef EMULATOR
        lda     $C7E7           ; Wait for a key to be pressed.
        lda     $C7E1           ; Get the raw 8-bit keycode.
        rts
    .else
    .ifdef DUAL_CORE_65C02
        jsr     get_char
        bcc     MINKEY
    .else
;
; Don't know how to read from the keyboard on this platform!
;
        lda     #0
        rts
    .endif
    .endif
    .endif
    .endif
;
; Read a character and convert escape codes.
;
        ORIGIN  $FD35
MRDCHR:
        jsr     MRDKEY
        cmp     #CHAR_ESC       ; ESC key?
        beq     escape_key
    .ifdef DSE_CAT
        cmp     #$A0            ; Control character?
        bcc     control_key
        rts
control_key:
        jmp     control_handler
    .else
        rts
    .endif
escape_key:
        jmp     escape_handler
;
; Rest of the Eater serial input routine after skipping over MRDCHR.
;
    .ifdef EATER
serial_rx_restart:
        lda     #(ACIA_TIC1 | ACIA_DTR)
        sta     ACIA_CMD
serial_rx_done:
        pla
        sec
        rts
    .endif
;
; Peek for a character.  If the keyboard buffer contains a character,
; then the carry flag will be set.  Otherwise carry will be cleared.
; Preserves A, X, and Y.
;
; This is a custom addition for this monitor.  Not present in Apple II or
; other traditional systems.
;
        ORIGIN  $FD50
MPEEKIN:
        jmp     (PEEKSWL)
MPEEKKEY:
        inc     RNDNOL          ; Increment the random number while peeking.
        bne     peek_key
        inc     RNDNOH
peek_key:
    .ifdef DSE_CAT
        pha
        lda     $C000           ; Read from the keyboard buffer.
        asl     a               ; Shift the top bit into the carry flag.
        pla
        rts
    .else
    .ifdef EATER
        pha
        lda     SBAS2L          ; Is there a character in the serial buffer?
        cmp     SBAS2H
        beq     no_key
        pla
        sec
        rts
no_key:
        pla
        clc
        rts
    .else
    .ifdef EMULATOR
        pha
        lda     $C7E0           ; Is there something in the keyboard buffer?
        bpl     no_key
        pla
        sec
        rts
no_key:
        pla
        clc
        rts
    .else
        clc                     ; Don't know how to peek for a key.
        rts
    .endif
    .endif
    .endif
;
; Line input routines.  Read a line into the buffer at $0200, terminated
; with a carriage return character.
;
; $FD67 - Print a CRLF and then prompt for a line.
; $FD6A - Print the prompt character and then get the line.
; $FD6F - Do not print a CRLF or a prompt; just get the line.
;
; On exit, X is the length of the line excluding the CR.  The line
; will be in KEYBUF, terminated with a CR.
;
; Destroys A and X.  Preserves Y.
;
        ORIGIN  $FD67
MGETLZ:
        jsr     MCROUT          ; Print a CRLF sequence first.
MGETLN:
        lda     PROMPT          ; Print the prompt character.
        jsr     print_prompt
MGETLN2:
        ldx     #0              ; Current position in the keyboard buffer.
        jmp     get_line        ; Get the line.
;
; Print a carriage return and line feed to the standard output device.
;
        ORIGIN  $FD8E
MCROUT:
    .ifdef HIGH_ASCII
        lda     #$8D            ; Apple II style system - output CR only.
        jmp     MCOUT
    .else
        lda     #CHAR_CR        ; Regular system; output a proper CRLF sequence.
        jsr     MCOUT
        lda     #CHAR_LF
        jmp     MCOUT
    .endif
;
    .ifdef DSE_CAT
;
; Bring RAM0 into BANK2 for text screen access.
;
FRAM0I:
        jsr     C800IN
        jmp     $CC0D
;
; Restore the prevous BANK2 configuration.
;
FRAM0O:
        jsr     C800IN
        jmp     $CC17
;
; Activate 40-column text mode.
;
TEXT40:
        lda     #$04
        jsr     text_mode
        bit     VZTX40
        rts
;
; Activate 80-column text mode.
;
TEXT80:
        lda     #$10
        jsr     text_mode
        bit     VZTX80
        rts
text_mode:
        sta     TXTMOD
text_mode_vsync:
        bit     VERTSC          ; Wait for VSYNC before switching modes.
        bmi     text_mode_vsync
        bit     VZSELF
        bit     VZTEXT
        rts
;
; Output A to the 76489 sound generator chip.
;
AUDOUT:
        sta     SONGEN          ; Write A to the sound generator.
AUDOUT_2:
        bit     HORZSC          ; Wait for horizontal redrace.
        bmi     AUDOUT_2
AUDOUT_3:
        bit     HORZSC
        bpl     AUDOUT_3
        rts
;
; Output A to the screen and then activate the $C100 ROM for the printer driver.
;
MOUTS1:
        jsr     MCOUT1
        sta     $CFFF
        sta     $C100
        rts
    .endif
;
; Print the byte value in A in hexadecimal.  Destroys A.
;
        ORIGIN  $FDDA
MPRBYTE:
        pha
        lsr     a               ; Extract the high nibble.
        lsr     a
        lsr     a
        lsr     a
        jsr     print_hex
        pla                     ; Restore the low nibble and fall through.
;
; Print the nibble value in the low 4 bits of A in hexadecimal.  Destroys A.
;
MPRNHEX:
        jmp     print_hex
    .ifdef DSE_CAT
;
; Switch in the 80-column ROM on the Dick Smith Cat / Laser 3000.
; Need this to access the standard keyboard and screen routines.
;
        ORIGIN  $FDE6
C800IN:
        sta     $CFFF
        sta     $C300
        rts
    .endif
;
; Print A to the standard output device.  Preserves A, X, and Y.
;
        ORIGIN  $FDED
MCOUT:
        jmp     (OUTSWL)
;
; Print A to the screen.  Preserves A, X, and Y.
;
        ORIGIN  $FDF0
MCOUT1:
    .ifdef DSE_CAT
        jsr     C800IN
        pha
        sty     SAVEY
        ora     #0
        bpl     out_plain_ascii
        cmp     #$A0
        bcc     out_ctrl
        and     INVFLG
out_plain_ascii:
        jsr     $CA18
        jmp     out_char_end
out_ctrl:
        and     #$7F
        cmp     #$0D            ; Expand CR to CRLF.
        bne     out_ctrl_2
        jsr     $CA01
        lda     #$0A
out_ctrl_2:
        jsr     $CA01
out_char_end:
        ldy     SAVEY
        pla
        rts
    .else
    .ifdef EATER
;
; Write the character to the serial port.
;
        sta     ACIA_DATA
        phx
    .ifdef SERIAL_115200
        ; Need a system clock of at least 2MHz to use 115200bps.
    .if SYSCLK >= 2000
        ldx     #20             ; Wait ~100us for the byte to be transmitted.
    .else
        ldx     #$70            ; Wait ~560us for the byte to be transmitted.
    .endif
    .else
        ldx     #$70            ; Wait ~560us for the byte to be transmitted.
    .endif
    .if SYSCLK > 1000
        jsr     serial_tx_wait
    .else
serial_tx_wait:
        dex
        bne     serial_tx_wait
    .endif
        plx
        rts
    .else
    .ifdef EMULATOR
;
; Write the character using the emulator.
;
        sta     $C7EA
        rts
    .else
    .ifdef DUAL_CORE_65C02
        jmp     put_char
    .else
;
; Don't know how to output characters on this platform.
;
        rts
    .endif
    .endif
    .endif
    .endif
;
; Characters for all monitor commands.
;
commands:
        .db     CHAR_PERIOD     ; Copy REG2 into REG1 for a range.
        .db     CHAR_COLON      ; Switch to store mode.
        .db     CHAR_LT         ; Copy REG2 into REG4 for a move/verify.
        .db     CHAR_EQ         ; Set register.
    .ifdef mon_ASSEM
        .db     CHAR_EXC        ; Enter assembler mode.
    .endif
    .ifdef mon_HELP
        .db     CHAR_QUEST      ; Print help for the monitor.
    .endif
        .db     CHAR_G          ; Go to a subroutine.
        .db     CHAR_I          ; Inspect registers.
    .ifdef mon_LIST
        .db     CHAR_L          ; Disassembly listing.
    .endif
        .db     CHAR_M          ; Move memory.
    .ifdef mon_STEP
        .db     CHAR_S          ; Step one instruction.
    .endif
    .ifdef mon_TRACE
        .db     CHAR_T          ; Trace instructions until BRK.
    .endif
        .db     CHAR_V          ; Verify memory.
        .db     CHAR_X          ; Exit back to BASIC.
        .db     CHAR_SP         ; Examine or set.
        .db     CHAR_CR         ; Examine or set, plus end of line.
commands_end:
;
; Addresses of the command handlers, split into high and low bytes.
; Minus 1 so we can push the address onto the stack and "RTS" to it.
;
handler_high:
        .db     >(mon_DOT-1)
        .db     >(mon_COLON-1)
        .db     >(mon_SHIFT-1)
        .db     >(mon_SETREG-1)
    .ifdef mon_ASSEM
        .db     >(mon_ASSEM-1)
    .endif
    .ifdef mon_HELP
        .db     >(mon_HELP-1)
    .endif
        .db     >(mon_GO-1)
        .db     >(mon_INSPECT-1)
    .ifdef mon_LIST
        .db     >(mon_LIST-1)
    .endif
        .db     >(mon_MOVE-1)
    .ifdef mon_STEP
        .db     >(mon_STEP-1)
    .endif
    .ifdef mon_TRACE
        .db     >(mon_TRACE-1)
    .endif
        .db     >(mon_VERIFY-1)
        .db     >(mon_EXIT-1)
        .db     >(mon_SPACE-1)
        .db     >(mon_RETURN-1)
handler_low:
        .db     <(mon_DOT-1)
        .db     <(mon_COLON-1)
        .db     <(mon_SHIFT-1)
        .db     <(mon_SETREG-1)
    .ifdef mon_ASSEM
        .db     <(mon_ASSEM-1)
    .endif
    .ifdef mon_HELP
        .db     <(mon_HELP-1)
    .endif
        .db     <(mon_GO-1)
        .db     <(mon_INSPECT-1)
    .ifdef mon_LIST
        .db     <(mon_LIST-1)
    .endif
        .db     <(mon_MOVE-1)
    .ifdef mon_STEP
        .db     <(mon_STEP-1)
    .endif
    .ifdef mon_TRACE
        .db     <(mon_TRACE-1)
    .endif
        .db     <(mon_VERIFY-1)
        .db     <(mon_EXIT-1)
        .db     <(mon_SPACE-1)
        .db     <(mon_RETURN-1)
;
; Perform a monitor command.  Index of the command is in Y.
;
do_command:
        lda     handler_high,y  ; Push the handler address onto the stack.
        pha
        lda     handler_low,y
        pha
        ldx     #0              ; X and Y should be zero for command handlers.
        ldy     #0
        rts                     ; Jump to the command handler.
;
; Increment REG4 and REG1.
;
inc_REG4:
        inc     REG4L
        bne     inc_REG1
        inc     REG4H
;
; Increment REG1 and compare with REG2.  Carry is set when REG1 >= REG2
; before REG1 was incremented.
;
inc_REG1:
        lda     REG1H
        cmp     REG2H
        bne     inc_REG1_now
        lda     REG1L
        cmp     REG2L
inc_REG1_now:                   ; Carry is now set for the comparison result.
        inc     REG1L
        bne     inc_REG1_done
        inc     REG1H
inc_REG1_done:
        rts
;
; ":" command for the monitor, which switches to store mode and copies
; REG2 into REG1.
;
mon_COLON:
        lda     #STOSET
        sta     STOFLG
        bne     mon_DOT_2
;
; "." command which copies REG2 into REG1.
;
mon_DOT:
        lda     #STODOT         ; Switch into dot mode.
        sta     STOFLG
mon_DOT_2:
        lda     REG2L           ; Copy REG2 into REG1.
        sta     REG1L
        lda     REG2H
        sta     REG1H
        rts
    .ifdef DSE_CAT
;
; MSETINV - Set inverse text mode.
; MSETNOR - Set normal text mode.
;
        ORIGIN  $FE80
MSETINV:
        lda     #$3F
        nop
        .db     $2C
MSETNOR:
        lda     #$FF
        sta     INVFLG
        rts
    .else
    .ifdef  ANSI_ESCAPES
        ORIGIN  $FE80
MSETINV:
        jmp     ansi_inverse
        ORIGIN  $FE84
MSETNOR:
        jmp     ansi_normal
    .else
;
; Don't know how to set inverse or normal text mode on this platform.
;
        ORIGIN  $FE80
MSETINV:
        rts
        ORIGIN  $FE84
MSETNOR:
        rts
    .endif
    .endif
;
; Set the input device for MRDKEY.
;
        ORIGIN  $FE89
MSETIN0:
        lda     #0              ; Restore the default input device.
MSETIN:                         ; Select the input device in A.
        sta     REG2L
MSETINL:                        ; Select the input device in REG2L.
        lda     REG2L
        beq     set_keyboard
        bne     set_in
;
; Set the output device for MCOUT.
;
        ORIGIN  $FE93
MSETOUT0:
        lda     #0              ; Restore the default output device.
MSETOUT:                        ; Select the output device in A.
        sta     REG2L
MSETOUTL:                       ; Select the output device in REG2L.
        lda     REG2L
        beq     set_screen
        and     #$07
        ora     #$C0
        sta     OUTSWH
        ldy     #0
        sty     OUTSWL
        rts
set_screen:
        jmp     set_default_output
;
set_keyboard:
        jmp     set_default_input
set_in:
        and     #$07
        ora     #$C0
        sta     INSWH
        ldy     #0
        sty     INSWL
        rts
;
; "I" command for the monitor.  Inspect all registers that will be
; used for the next "GO" command.
;
mon_INSPECT:
        tsx
        inx
        inx
        stx     STACKP
        ldx     #msg_reg_A_no_comma-messages
        jsr     print_regs_2
        jmp     MCROUT
print_regs_2:
        lda     REGA
        jsr     print_reg
;
        ldx     #msg_reg_X-messages
        lda     REGX
        jsr     print_reg
;
        ldx     #msg_reg_Y-messages
        lda     REGY
        jsr     print_reg
;
        ldx     #msg_reg_S-messages
        lda     STACKP
        jsr     print_reg
;
        ldx     #msg_reg_P-messages
        lda     STATUS
        jsr     print_reg
;
        lda     #CHAR_LSQ
        jsr     MCOUT
        lda     STATUS
        sta     SCRATCH1
        ldx     #0
print_status:
        lda     #CHAR_MINUS
        asl     SCRATCH1
        bcc     no_status_bit
        lda     status_flags,x
no_status_bit:
        jsr     MCOUT
        inx
        cpx     #8
        bne     print_status
        lda     #CHAR_RSQ
        jmp     MCOUT
status_flags:
        .db     "NV?BDIZC"
;
; Default handler for BREAK.  Dump the registers and jump into the monitor.
;
break_handler:
        ldx     #msg_break_at-messages
        jsr     print_message
;
        lda     PCL             ; Print the break address which is
        sec                     ; 2 bytes back from PCL/PCH.
        sbc     #2
        tax
        lda     PCH
        sbc     #0
        jsr     MPRNAX
;
        ldx     #msg_reg_A-messages
        jsr     print_regs_2
;
; Jump into the monitor.  If it returns, we do a warm start on BASIC.
; If there is no BASIC, then we go right back into the monitor.
;
        jsr     MON
        jmp     warm_start_launch
;
; MERR - Print "ERROR " followed by a bell.  Destroys A.
;
        ORIGIN  $FF2D
MERR:
        txa
        pha
        ldx     #msg_error-messages
        jsr     print_message
        pla
        tax
        rts
;
; Ring the terminal bell.
;
        ORIGIN  $FF3A
MBELL:
        lda     #CHAR_BEL
        jmp     MCOUT
;
; Restore registers prior to jumping to code from the machine code monitor.
;
        ORIGIN  $FF3F
MRESTORE:
        ldx     REGX
        ldy     REGY
        lda     STATUS
        pha
        lda     REGA
        plp
        rts
;
; Save registers prior to entering the machine code monitor.
;
        ORIGIN  $FF4A
MSAVE:
        sta     REGA
        stx     REGX
        sty     REGY
        php
        pla
        sta     STATUS
        tsx
        stx     STACKP
        cld                     ; Fix up the D flag just in case.
;
; Lots of Apple II software assumes that $FF58 is a RTS instruction.
;
        ORIGIN  $FF58
MRETURN:
        rts
;
; Apple II original F8 ROM: Reset vector.
; Apple II auto-start F8 ROM: Re-initialise the screen and enter the monitor.
; Dick Smith Cat / Laser 3000: Enter the kernel monitor, no re-init.
;
        ORIGIN  $FF59
MONENT:
        jmp     MON
;
; Public entry points to the machine code monitor:
;
; $FF65 - "CALL -155" - Beep and enter the machine code monitor.
; $FF69 - "CALL -151" - Enter the machine code monitor with no beep.
;
        ORIGIN  $FF65
MON:
        cld                     ; Apple II monitor clears D here.
        jsr     MBELL
MON1:
        jsr     MCROUT          ; Print a CRLF prior to entering the monitor.
monitor_prompt:
    .ifdef DSE_CAT
        lda     #CHAR_GT        ; Use a different prompt than the system one.
    .else
        lda     #CHAR_STAR      ; Monitor prompt character is '*'.
    .endif
        sta     PROMPT
        jsr     MGETLN          ; Get a line from the user.
        ldx     #0
        stx     STOFLG          ; Clear the store flag.
        dex                     ; Set up to parse the commands on the line.
monitor_next_command:
        jsr     MGETNUM         ; Parse a hexadecimal number.
        jsr     find_command    ; Find the command from the next character.
        bcc     unknown_command ; Was it recognised by the command table?
        stx     SAVEX           ; Preserve X.
        jsr     do_command      ; Perform the command.
        ldx     SAVEX           ; Restore the index into the keyboard buffer.
skip_spaces:
        lda     KEYBUF+1,x      ; Skip spurious whitespace between commands.
        cmp     #CHAR_CR        ; Carriage return after previous command
        beq     monitor_prompt  ; means that the previous command is the last.
        cmp     #CHAR_SP
        bne     monitor_next_command
        inx
        jmp     skip_spaces
unknown_command:
        lda     KEYBUF,x
        pha
        ldx     #msg_unknown-messages
        jsr     print_message
        pla
        jsr     MCOUT
        jmp     MON1
;
; Get a hexadecimal number from the input key buffer.
;
; The Apple II monitor uses the Y register as the index into the key buffer.
; The Dick Smith Cat / Laser 3000 uses X.  So they aren't 100% compatible.
;
        ORIGIN  $FFA7
MGETNUM:
        lda     #0
        sta     CHKSUM          ; Non-zero if we get at least one digit.
        sta     REG2L
        sta     REG2H
get_hex_num:
        inx
        lda     KEYBUF,x        ; Is this a hexadecimal character?
        cmp     #CHAR_0         ; Check for digits 0-9.
        bcc     not_digit
        cmp     #CHAR_COLON
        bcc     is_digit
        cmp     #CHAR_A         ; Check for upper case letters A-F.
        bcc     not_digit
        cmp     #CHAR_G
        bcc     is_alpha_digit
        cmp     #CHAR_A_L       ; Check for lower case letters a-f.
        bcc     not_digit
        cmp     #CHAR_G_L
        bcs     not_digit
is_alpha_digit:
        sbc     #6
is_digit:
        inc     CHKSUM          ; We have a hexadecimal digit.
        asl     a
        asl     a
        asl     a
        asl     a
        ldy     #4
rotate_hex:                     ; Rotate the new digit into place.
        asl     a
        rol     REG2L
        rol     REG2H
        dey
        bne     rotate_hex
        beq     get_hex_num
not_digit:
        rts
;
; Print the nibble value in the low 4 bits of A in hexadecimal.  Destroys A.
;
print_hex:
        and     #$0F
        ora     #CHAR_0
        cmp     #CHAR_COLON
        bcc     print_hex_2
        adc     #6
print_hex_2:
        jmp     MCOUT
;
; Save all registers from the BREAK handler.  The A register
; needs to be restored from "ACCIRQ" first.
;
MSAVE2:
        php
        lda     ACCIRQ
        plp
        jmp     MSAVE
;
; Handle special TTY operations.
;
        ORIGIN  $FFF7
MTTYOP:
    .ifdef tty_operation
        jmp     tty_operation
    .else
        rts
    .endif
;
; Reset and interrupt vectors.
;
    .ifndef DUAL_CORE_65C02
        ORIGIN  $FFFA
        .dw     NMIADR
        .dw     MRESET
        .dw     IRQBRK
    .endif
