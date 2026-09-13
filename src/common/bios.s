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
; The startup code in the BIOS assumes that the following labels are present:
;
; hw_init       Subroutine that initializes the hardware.  Interrupts are
;               enabled after this subroutine returns.  On entry, A is
;               zero for a warm start or 1 for a cold start.
; cold_start    Entry point for a cold start.
; warm_start    Entry point for a warm start.
;
; On a cold start, the zero page is cleared to zeroes.  The locations
; $F8 to $FF are reserved for BIOS-related purposes.
;

;
; Definitions.
;
systick_val .equ    $F8     ; 24-bit system millisecond tick counter.
serial_wr   .equ    $FB     ; Write pointer for the serial buffer (CPU1 only).
serial_rd   .equ    $FC     ; Read pointer for the serial buffer (CPU1 only).
startup_vec .equ    $FD     ; Jump address for warm start.
startup_chk .equ    $FF     ; Startup checksum.
serial_buf  .equ    $0400   ; Location of the serial buffer in memory.
;
    .if CPU1
        .include acia.s
    .endif
;
        .org    $C000
;
; Jump table that user programs in RAM can use to access useful features
; without needing to know where they actually are in the ROM.
;
        jmp     get_cpuid       ; $C000: Get the id of the current CPU.
        jmp     mutex_lock      ; $C003: Lock the hardware mutex.
        jmp     mutex_unlock    ; $C006: Unlock the hardware mutex.
        jmp     mutex_try_lock  ; $C009: Try to lock the hardware mutex.
        jmp     put_char        ; $C00C: Print a character on the ACIA (CPU1).
        jmp     get_char        ; $C00F: Get a character from the ACIA (CPU1).
        jmp     systick         ; $C012: Get system millisecond tick counter.
        jmp     reserved        ; $C015: Reserved for future use.
        jmp     reserved        ; $C018: Reserved for future use.
        jmp     reserved        ; $C01B: Reserved for future use.
;
; Reset entry point to the ROM / warm start reset.
;
reset:
        cld                 ; Make sure that D is off.
        sei                 ; Disable interrupts until we are ready.
        ldx     #$FF        ; Set up the initial stack pointer.
        txs
;
; Delay at startup to let the power rails settle.  Otherwise the
; daughter chips may not reset correctly.
;
        ldy     #0
        tya
startup_delay:
        clc
        adc     #1
        bne     startup_delay
        dey
        bne     startup_delay
;
; Release the mutex for this CPU in case we had locked it pre-reset.
; Alternatively, lock the mutex to CPU1 or CPU2 at startup.
;
    .if CPU1
      .ifdef START_WITH_CPU1_LOCKED
        lda     #1
      .else
        lda     #0
      .endif
        sta     $8107
    .else
      .ifdef START_WITH_CPU2_LOCKED
        lda     #1
      .else
        lda     #0
      .endif
        sta     $8106
    .endif
;
; Reset the system millisecond tick counter.  We need to set the low
; byte twice because NMI might fire and increment it while clearing.
;
        stz     systick_val
        stz     systick_val+1
        stz     systick_val+2
        stz     systick_val
;
; Are we doing a cold or warm start of the system?
;
        lda     startup_vec
        eor     startup_vec+1
        eor     #$A5
        cmp     startup_chk
        beq     startup_warm
;
; Clear most of the zero page so it starts in a known state on a cold start.
;
        ldx     #systick_val-1
        lda     #0
startup_clearz:
        sta     0,x
        dex
        bne     startup_clearz
        sta     0,x
;
; Initialize the hardware for the cold start.
;
    .if CPU1
        jsr     acia_init
    .endif
        lda     #1
        jsr     hw_init
;
; Set up the warm start vector for next time.  We do this after
; hardware initialization in case we reset again before we get here.
; Do another cold start if hardware initialization didn't complete.
;
        lda     #<warm_start
        sta     startup_vec
        lda     #>warm_start
        sta     startup_vec+1
        eor     #(<warm_start) ^ $A5
        sta     startup_chk
;
; Enable interrupts and do the cold start.
;
        cli
        jmp     cold_start
;
; Initialize the hardware and do the warm start.
;
startup_warm:
    .if CPU1
        jsr     acia_init
    .endif
        lda     #0
        jsr     hw_init
        cli
        jmp     (startup_vec)
;
; Get the identifier for the current CPU.  Returns A = 0 for CPU1 or
; A = 1 for CPU2.  Preserves X and Y.
;
get_cpuid:
        lda     #CPU2
        rts
;
; Lock the hardware mutex.  Destroys A.  Preserves X and Y.
;
; If the mutex is already locked, this will return immediately.
; Recursive locking is not supported.
;
mutex_lock:
        lda     #1
    .if CPU1
        sta     $8107               ; Request the mutex for CPU1.
mutex_lock_check:
        bit     $8080               ; Wait for it to become available.
        bpl     mutex_lock_check
    .else
        sta     $8106               ; Request the mutex for CPU2.
mutex_lock_check:
        bit     $8080               ; Wait for it to become available.
        bvc     mutex_lock_check
    .endif
        rts
;
; Unlock the hardware mutex.  Preserves A, X, and Y.
;
; If the mutex is already unlocked, this will do nothing.
;
mutex_unlock:
    .if CPU1
        stz     $8107               ; Release the mutex for CPU1.
    .else
        stz     $8106               ; Release the mutex for CPU2.
    .endif
        rts
;
; Try to lock the hardware mutex.  Destroys A.  Preserves X and Y.
;
; On exit, Z will be set if the mutex was obtained, Z will be clear if the
; mutex could not be obtained.
;
; If the mutex is already locked, this will return success immediately.
; Recursive locking is not supported.
;
mutex_try_lock:
        lda     #1
    .if CPU1
        sta     $8107               ; Request the mutex for CPU1.
        nop                         ; Deley to let the request settle.
        bit     $8080               ; Check if it is available.
        bmi     mutex_locked
        lda     #0
        sta     $8107               ; Could not get the mutex, so release it.
    .else
        sta     $8106               ; Request the mutex for CPU2.
        nop                         ; Deley to let the request settle.
        bit     $8080               ; Check if it is available.
        bvs     mutex_locked
        lda     #0
        sta     $8106               ; Could not get the mutex, so release it.
    .endif
mutex_locked:
        eor     #1                  ; Set Z based on the result.
reserved:
        rts
;
; ACIA serial is on CPU1 only.
;
    .if CPU1
;
; Initialize the ACIA.
;
acia_init:
        stz     serial_wr   ; Reset the serial buffer write and read pointers.
        stz     serial_rd
        lda     ACIA_STATUS ; Clear spurious status bits.
        lda     ACIA_DATA   ; Empty the receive buffer.
        stz     ACIA_STATUS ; Force the ACIA to reset itself.
        lda     #(ACIA_BPS_19200 | ACIA_RCS)
        sta     ACIA_CTRL
        lda     #(ACIA_TIC1 | ACIA_DTR)
        sta     ACIA_CMD
        lda     #1          ; Assert RTS to allow the connected peer to send.
        sta     ACIA_RTS
        rts
;
; Print the character in A to the ACIA.  Preserves A, X, and Y.
;
put_char:
        phx
        sta     ACIA_DATA   ; Write the character to the serial port.
        ldx     #$FF        ; Delay to wait for the character to be sent.
put_char_delay:
        dex
        bne     put_char_delay
        plx
        rts
;
; Get a character from the ACIA into A.  Preserves X and Y.
; Carry is set if a character was received, or carry is cleared if no
; character is currently available.
;
get_char:
        phx
        ldx     serial_rd       ; Is there a character in the serial buffer?
        cpx     serial_wr
        beq     get_char_none   ; If not, then return "no character".
        lda     serial_buf,x    ; Get the character.
        tax
        inc     serial_rd       ; Increment the buffer's read pointer.
        lda     serial_wr
        sec
        sbc     serial_rd
        cmp     #224            ; Are we below the low water mark?
        bge     get_char_done
        lda     #1              ; If yes, assert RTS to re-enable receive.
        sta     ACIA_RTS
get_char_done:
        txa
        plx
        sec                     ; Set carry to indicate an available character.
        rts
get_char_none:
        plx
        lda     #0              ; No character available, so return NUL
        clc                     ; and clear the carry.
        rts
;
    .else ; CPU2
;
; Stub the put_char and get_char subroutines because CPU2 cannot
; directly access the ACIA.
;
get_char:
        clc
put_char:
        rts
;
    .endif ; CPU2
;
; IRQBRK handler for the system.
;
irqbrk:
        pha                     ; Save the A and X registers on the stack.
        phx
    .if CPU1
        lda     ACIA_STATUS     ; Did we receive a character via the ACIA?
        and     #ACIA_RDRF
        beq     irq_acia_done
        lda     ACIA_DATA       ; Get the received byte into A.
        ldx     serial_wr       ; Get the serial buffer write pointer.
        sta     serial_buf,x    ; Store A into the serial buffer.
        inc     serial_wr       ; Increment the write pointer.
        lda     serial_wr       ; Is the buffer almost full?
        sec
        sbc     serial_rd
        cmp     #240
        blt     irq_acia_done   ; If not, then leave RTS asserted for now.
        lda     #0              ; De-assert RTS to stop the peer talking to us.
        sta     ACIA_RTS
irq_acia_done:
    .endif ; CPU1
        plx                     ; Restore the registers and return.
        pla
        rti
;
; Get the value of the system millisecond tick counter into Y:A:X
; where Y is the high byte.
;
; The returned 24-bit value can time events up to about 4.66 hours.
;
systick:
        ldx     systick_val     ; Fetch the low byte.
        lda     systick_val+1   ; Fetch the middle byte.
        ldy     systick_val+2   ; Fetch the high byte.
        cpx     systick_val     ; Did the low byte change while doing this?
        bne     systick         ; If it did, fetch the value again.
        rts
;
; NMI handler for the system which handles the millisecond tick counter.
;
nmi:
        inc     systick_val
        bne     nmi_done
        inc     systick_val+1
        bne     nmi_done
        inc     systick_val+2
nmi_done:
        rti
