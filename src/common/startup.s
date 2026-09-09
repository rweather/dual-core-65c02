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
; On a cold start, the zero page is cleared to zeroes except for $FD to $FF
; which are reserved for startup-related purposes.
;

;
; Definitions.
;
startup_vec .equ    $FD     ; Jump address for warm start.
startup_chk .equ    $FF     ; Startup checksum.
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
        jmp     reserved        ; $C00C: Reserved for future use.
        jmp     reserved        ; $C00F: Reserved for future use.
        jmp     reserved        ; $C012: Reserved for future use.
        jmp     reserved        ; $C015: Reserved for future use.
        jmp     reserved        ; $C018: Reserved for future use.
        jmp     reset_cold      ; $C01B: Cold start reset of the system.
;
; $C01E: Reset entry point to the ROM.
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
;
        jsr     mutex_unlock
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
        dex
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
; Force a cold start reset.
;
reset_cold:
        stz     startup_vec
        stz     startup_vec+1
        stz     startup_chk
        jmp     reset
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
