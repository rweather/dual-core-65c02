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
; The startup code assumes that the following labels are present:
;
; hw_init       Subroutine that initializes the hardware.  Interrupts are
;               enabled after this subroutine returns.  On entry, A is
;               zero for a warm start or 1 for a cold start.
; cold_start    Entry point for a cold start.
; warm_start    Entry point for a warm start.
;
; On a cold start, the zero page is cleared to zeroes except for $FC to $FF
; which are reserved for startup-related purposes.
;
; The zero page variable at $FF (cpu_id) will be set to 0 for CPU1 and
; 1 for CPU2 to allow generic code to discover which CPU it is running on
; without using ifdef's.
;

;
; Definitions.
;
startup_vec .equ    $FC     ; Jump address for warm start.
startup_chk .equ    $FE     ; Startup checksum.
cpu_id      .equ    $FF     ; 0 = CPU1, 1 = CPU2
mutex_addr  .equ    $8000   ; Address of the hardware mutex.
;
; Reset entry point to the ROM.
;
        .org    $C000
reset:
        cld                 ; Make sure that D is off.
        sei                 ; Disable interrupts until we are ready.
        ldx     #$FF        ; Set up the initial stack pointer.
        txs
    .if CPU1
        stx     mutex_addr  ; Initialize the hardware mutex.
    .endif
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
; Set the CPU identity into the zero page.
;
        lda     #CPU2
        sta     cpu_id
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
        ldx     #startup_vec-1
        lda     #0
startup_clearz:
        sta     0,x
        dey
        bne     startup_clearz
        sta     0,x
;
; Initialize the hardware for the cold start.
;
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
        lda     #0
        jsr     hw_init
        cli
        jmp     (startup_vec)
;
; Lock the hardware mutex.  Preserves A, X, and Y.
;
; The behaviour is undefined if the CPU already owns the mutex or if
; this subroutine is called from an interrupt handler.
;
mutex_lock:
;
; The mutex value must be negative for us to have a chance of getting it.
; Use a regular memory operation to avoid stalling the other CPU.
;
        bit     mutex_addr
        bpl     mutex_lock
;
; We might be able to get the mutex now.  Stall the other CPU and increment it.
; If the value is zero, then we have obtained the lock.
;
; Do this with interrupts disabled to avoid a race condition on this CPU
; where multiple threads are trying to acquire the mutex.
;
        php
        sei
        inc     mutex_addr
        beq     mutex_locked
;
; Could not get the mutex.  Decrement the value and go back to try again.
;
        dec     mutex_addr
        plp
        bra     mutex_lock
mutex_locked:
        plp
        rts
;
; Unlock the hardware mutex.  Preserves A, X, and Y.
;
; The behaviour is undefined if the CPU doesn't currently own the mutex.
;
mutex_unlock:
        dec     mutex_addr
        rts
