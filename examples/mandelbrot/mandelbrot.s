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
; Compute and print a mandelbrot, farming parts of it out to both CPU's.
;
; This implementation uses 24-bit fixed-point with 16 bits after the point.
;

START_WITH_CPU1_LOCKED .equ 1
        .include bios.s
;
; Zero page variables.
;
DONE    .equ    $01             ; Number of jobs done on this CPU.
PRINTED .equ    $02             ; Number of jobs printed so far.
TOPRINT .equ    $03             ; Job to print up to.
TEMP    .equ    $04             ; Temporary 16-bit pointer.
START   .equ    $06             ; Start time on this CPU (24-bit).
VAR_k   .equ    $09             ; Iteration counter for the Mandelbrot loop.
JOB_PTR .equ    $0E             ; Pointer to the next job to execute.
JOB     .equ    $10             ; Job details, copied to local CPU zero page.
VAR_a   .equ    $20             ; Working variable a (24-bit fixed-point).
VAR_b   .equ    $23             ; Working variable b (24-bit fixed-point).
VAR_c   .equ    $26             ; Working variable c (24-bit fixed-point).
VAR_d   .equ    $29             ; Working variable d (24-bit fixed-point).
VAR_e   .equ    $2C             ; Working variable e (24-bit fixed-point).
VAR_r   .equ    $2F             ; Working variable r (24-bit fixed-point).
VAR_i   .equ    $32             ; Working variable i (24-bit fixed-point).
VAR_x   .equ    $35             ; Working variable x (24-bit fixed-point).
VAR_y   .equ    $38             ; Working variable y (24-bit fixed-point).
VAR_t   .equ    $3B             ; Working variable t (24-bit fixed-point)
VAR_u   .equ    $3E             ; Working variable u (24-bit fixed-point)
VAR_sq  .equ    $41             ; Temporary for squaring (48-bit fixed-point).
;
; Location of the job queue in RAM.
;
JOBS    .equ    $0500
;
; Location of the computed mandelbrot data in RAM.  Must be page-aligned.
;
MANDEL  .equ    $1000
;
; Number of jobs.
;
NUMJOBS .equ    23
;
; Maximum number of iterations for each point.
;
MAXITER .equ    32

cold_start:
warm_start:

;
; Initialize the job queue.
;
        stz     DONE
    .if CPU1
        stz     PRINTED
        ldx     #job_list_end-job_list
copy_all_jobs:
        lda     job_list-1,x
        sta     JOBS-1,x
        dex
        bne     copy_all_jobs
        lda     #<JOBS
        sta     JOB_PTR
        lda     #>JOBS
        sta     JOB_PTR+1
        lda     #1
        sta     $8100           ; Indicate that CPU1 is ready.
    .else
        lda     #1
        sta     $8101           ; Indicate that CPU2 is ready.
    .endif
;
; Record the system time in milliseconds when we started processing jobs.
;
        jsr     systick
        stx     START
        sta     START+1
        sty     START+2
    .if CPU2
    .ifdef ONE_CPU_ONLY         ; For testing with only 1 CPU.
        jmp     end_jobs
    .endif
    .endif
;
; Main job loop.  Take a job off the queue, process it,
; then move onto the next job.  CPU1 also prints job progress.
;
loop:
        jsr     mutex_lock
    .if CPU2
        lda     $0200+JOB_PTR
        sta     JOB_PTR
        lda     $0200+JOB_PTR+1
        sta     JOB_PTR+1
    .endif
        ldy     #7
copy_job:
        lda     (JOB_PTR),y
        sta     JOB,y
        dey
        bpl     copy_job
copy_job_done:
        lda     JOB_PTR
        clc
        adc     #8
    .if CPU1
        sta     JOB_PTR
    .else
        sta     $0200+JOB_PTR
    .endif
        lda     JOB_PTR+1
        adc     #0
    .if CPU1
        sta     JOB_PTR+1
    .else
        sta     $0200+JOB_PTR+1
    .endif
        jsr     mutex_unlock
;
; Indicate which CPU is busy on a job.
;
        lda     #1
    .if CPU1
        sta     $8102
    .else
        sta     $8103
    .endif
;
; Stop if the pointer is NULL - we're at the end of the job list.
;
        lda     JOB
        ora     JOB+1
        beq     end_jobs
;
; Process the job.
;
        lda     JOB+4           ; Get the y value for this line.
        sta     VAR_y
        lda     JOB+5
        sta     VAR_y+1
        lda     JOB+6
        sta     VAR_y+2
;
        lda     #0              ; Set x to -2 for the start of the line.
        sta     VAR_x
        sta     VAR_x+1
        lda     #$FE
        sta     VAR_x+2
;
        lda     #"1"+CPU2       ; Number of the CPU that did this job.
        ldy     #0
        sta     (JOB),y
        iny
mandel_line:
        jsr     mandel_point    ; Compute the value for the (x, y) point.
        sta     (JOB),y
;
        lda     VAR_x           ; Add (3 / 62) to x to increment the point.
        clc
        adc     #$63
        sta     VAR_x
        lda     VAR_x+1
        adc     #$0C
        sta     VAR_x+1
        lda     VAR_x+2
        adc     #0
        sta     VAR_x+2
;
        iny                     ; Move onto the next point on this line.
        cpy     #64
        bcc     mandel_line
;
        lda     JOB+2           ; Record how far through the job list we are.
        sta     DONE
;
    .if CPU1
        stz     $8102
        jsr     print_jobs
    .else
        stz     $8103
    .endif
;
; Go back for the next job.
;
        jmp     loop
;
; All jobs have been done for this CPU.  Print remaining jobs on
; CPU1 and loop forever on CPU2.
;
end_jobs:
        lda     #NUMJOBS
        sta     DONE
end_jobs_loop:
    .if CPU1
        stz     $8102
        jsr     print_jobs
        lda     PRINTED
        cmp     #NUMJOBS
        bcc     end_jobs_loop
    .else
        stz     $8103
        bra     end_jobs_loop
    .endif
;
; Finished printing all jobs.  Print the elapsed time in seconds.
;
    .if CPU1
finished:
;
; Get the 24-bit elapsed time into VAR_x.
;
        jsr     systick
        pha
        txa
        sec
        sbc     START
        sta     VAR_x
        pla
        sbc     START+1
        sta     VAR_x+1
        tya
        sbc     START+2
        sta     VAR_x+2
        ldx     #0
        jsr     print_msg
;
; Convert VAR_x into BCD in VAR_y.
;
        stz     VAR_y
        stz     VAR_y+1
        stz     VAR_y+2
        stz     VAR_y+3
        ldx     #24
        sed
convert_to_bcd:
        asl     VAR_x
        rol     VAR_x+1
        rol     VAR_x+2
        lda     VAR_y
        adc     VAR_y
        sta     VAR_y
        lda     VAR_y+1
        adc     VAR_y+1
        sta     VAR_y+1
        lda     VAR_y+2
        adc     VAR_y+2
        sta     VAR_y+2
        lda     VAR_y+3
        adc     VAR_y+3
        sta     VAR_y+3
        dex
        bne     convert_to_bcd
        cld
;
; Print the BCD value in VAR_y.
;
        lda     VAR_y+3
        jsr     print_nibble_high
        lda     VAR_y+3
        jsr     print_nibble_low
        lda     VAR_y+2
        jsr     print_nibble_high
        lda     VAR_y+2
        jsr     print_nibble_low
        lda     VAR_y+1
        jsr     print_nibble_high
        lda     #"."
        jsr     put_char
        lda     VAR_y+1
        jsr     print_nibble_low
        lda     VAR_y
        jsr     print_nibble_high
        lda     VAR_y
        jsr     print_nibble_low
;
        ldx     #elapsed_msg_2-elapsed_msg
        jsr     print_msg
        jsr     print_crlf
finished_loop:
        bra     finished_loop
;
; Message printing.
;
print_msg:
        lda     elapsed_msg,x
        beq     print_msg_done
        jsr     put_char
        inx
        bne     print_msg
print_msg_done:
        rts
;
elapsed_msg:
        .db     "Elapsed: ",0
elapsed_msg_2:
        .db     "s",$0D,$0A,0
;
; Print the jobs that have been done so far.  If one CPU has
; run ahead of another, print only up to the minimum "done" point.
;
print_jobs:
        lda     $0200+DONE      ; Find minimum of our DONE and other CPU's DONE.
        cmp     DONE
        bcc     print_jobs_2
        lda     DONE
print_jobs_2:
        sta     TOPRINT
;
print_next_job:
        lda     PRINTED
        cmp     TOPRINT
        bcs     print_jobs_done
        inc     PRINTED
;
; Find the address of the job output: MANDEL + PRINTED * 64.
;
        ldy     #0
        sty     TEMP+1
        asl     a
        rol     TEMP+1
        asl     a
        rol     TEMP+1
        asl     a
        rol     TEMP+1
        asl     a
        rol     TEMP+1
        asl     a
        rol     TEMP+1
        asl     a
        rol     TEMP+1
        sta     TEMP
        lda     TEMP+1
        clc
        adc     #>MANDEL
        sta     TEMP+1
;
; Print the CPU that the job was performed on.
;
        lda     (TEMP),y
        jsr     put_char
        lda     #":"
        jsr     put_char
        lda     #" "
        jsr     put_char
        iny
;
; Print the job output characters.
;
print_job_chars:
        lda     (TEMP),y
        jsr     put_char
        iny
        cpy     #64
        bcc     print_job_chars
        jsr     print_crlf
        bra     print_next_job
print_jobs_done:
        rts
;
print_crlf:
        lda     #$0D
        jsr     put_char
        lda     #$0A
        jmp     put_char
;
print_nibble_high:
        lsr     a
        lsr     a
        lsr     a
        lsr     a
print_nibble_low:
        and     #$0F
        ora     #$30
        jmp     put_char
    .endif ; CPU1
;
; Initialize the hardware.
;
hw_init:
        rts
;
; Static list of all jobs to perform.  Copied down to RAM at init time.
;
; The fields are:
;
;   Address of the job in the output RAM area (0 at the end of the list).
;   Job number, 1-based.
;   Low 16 bits of the 24-bit fixed-point y value for the job.
;   High 8 bits of the 24-bit fixed-point y value for the job.
;
    .if CPU1
job_list:
        .dw     MANDEL +  0*64,  1, $0000, $FF ; y = -1.000000
        .dw     MANDEL +  1*64,  2, $1746, $FF ; y = -0.909091
        .dw     MANDEL +  2*64,  3, $2E8C, $FF ; y = -0.818182
        .dw     MANDEL +  3*64,  4, $45D1, $FF ; y = -0.727273
        .dw     MANDEL +  4*64,  5, $5D17, $FF ; y = -0.636364
        .dw     MANDEL +  5*64,  6, $745D, $FF ; y = -0.545455
        .dw     MANDEL +  6*64,  7, $8BA3, $FF ; y = -0.454545
        .dw     MANDEL +  7*64,  8, $A2E9, $FF ; y = -0.363636
        .dw     MANDEL +  8*64,  9, $BA2F, $FF ; y = -0.272727
        .dw     MANDEL +  9*64, 10, $D174, $FF ; y = -0.181818
        .dw     MANDEL + 10*64, 11, $E8BA, $FF ; y = -0.090909
        .dw     MANDEL + 11*64, 12, $0000, $00 ; y =  0.000000
        .dw     MANDEL + 12*64, 13, $1746, $00 ; y =  0.090909
        .dw     MANDEL + 13*64, 14, $2E8C, $00 ; y =  0.181818
        .dw     MANDEL + 14*64, 15, $45D1, $00 ; y =  0.272727
        .dw     MANDEL + 15*64, 16, $5D17, $00 ; y =  0.363636
        .dw     MANDEL + 16*64, 17, $745D, $00 ; y =  0.454545
        .dw     MANDEL + 17*64, 18, $8BA3, $00 ; y =  0.545455
        .dw     MANDEL + 18*64, 19, $A2E9, $00 ; y =  0.636364
        .dw     MANDEL + 19*64, 20, $BA2F, $00 ; y =  0.727273
        .dw     MANDEL + 20*64, 21, $D174, $00 ; y =  0.818182
        .dw     MANDEL + 21*64, 22, $E8BA, $00 ; y =  0.909091
        .dw     MANDEL + 22*64, 23, $0000, $01 ; y =  1.000000
        .dw     0, 0, 0, 0
job_list_end:
    .endif
;
; Perform the Mandelbrot calculations on the current point (x, y).
; On exit, A is the ASCII character corresponding to the result.
; Preserves X and Y.
;
;   r = i = 0
;   k = max_iterations
;   repeat
;       a = r^2
;       b = i^2
;       c = (r - i)^2
;       d = a - b
;       e = a + b
;       r = d + x
;       i = e - c + y
;       k = k - 1
;   until e > 4 or k = 0
;
mandel_point:
        phx
        phy
        stz     VAR_r           ; Set r and i to zero.
        stz     VAR_r+1
        stz     VAR_r+2
        stz     VAR_i
        stz     VAR_i+1
        stz     VAR_i+2
        lda     #MAXITER        ; Set k to the maximum number of iterations.
        sta     VAR_k
;
mandel_loop:
        ldx     #VAR_r-VAR_a    ; a = r^2
        ldy     #VAR_a-VAR_a
        jsr     square
;
        ldx     #VAR_i-VAR_a    ; b = i^2
        ldy     #VAR_b-VAR_a
        jsr     square
;
        lda     VAR_r           ; c = (r - i)^2
        sec
        sbc     VAR_i
        sta     VAR_c
        lda     VAR_r+1
        sbc     VAR_i+1
        sta     VAR_c+1
        lda     VAR_r+2
        sbc     VAR_i+2
        sta     VAR_c+2
        ldx     #VAR_c-VAR_a
        ldy     #VAR_c-VAR_a
        jsr     square
;
        lda     VAR_a           ; d = a - b
        sec
        sbc     VAR_b
        sta     VAR_d
        lda     VAR_a+1
        sbc     VAR_b+1
        sta     VAR_d+1
        lda     VAR_a+2
        sbc     VAR_b+2
        sta     VAR_d+2
;
        lda     VAR_a           ; e = a + b
        clc
        adc     VAR_b
        sta     VAR_e
        lda     VAR_a+1
        adc     VAR_b+1
        sta     VAR_e+1
        lda     VAR_a+2
        adc     VAR_b+2
        sta     VAR_e+2
;
        lda     VAR_d           ; r = d + x
        clc
        adc     VAR_x
        sta     VAR_r
        lda     VAR_d+1
        adc     VAR_x+1
        sta     VAR_r+1
        lda     VAR_d+2
        adc     VAR_x+2
        sta     VAR_r+2
;
        lda     VAR_c           ; i = e - c + y
        clc
        adc     VAR_y
        sta     VAR_c
        lda     VAR_c+1
        adc     VAR_y+1
        sta     VAR_c+1
        lda     VAR_c+2
        adc     VAR_y+2
        sta     VAR_c+2
        lda     VAR_e
        sec
        sbc     VAR_c
        sta     VAR_i
        lda     VAR_e+1
        sbc     VAR_c+1
        sta     VAR_i+1
        lda     VAR_e+2
        sbc     VAR_c+2
        sta     VAR_i+2
;
        dec     VAR_k           ; Decrement k and check for the end.
        beq     mandel_done
;
        lda     VAR_e+2         ; Is e > 4?
        cmp     #4
        bcc     mandel_next
        bne     mandel_done
        lda     VAR_e+1
        bne     mandel_done
        lda     VAR_e
        bne     mandel_done
mandel_next:
        jmp     mandel_loop
mandel_done:
        ldy     VAR_k           ; Fetch the character to show for k.
        lda     mandel_chars,y
        ply
        plx
        rts
mandel_chars:
        .db     " .,-*/$&#@ABCDEFGHIJKL0123456789"
;
; Square a 24-bit fixed-point value.  On entry, X is the offset from
; VAR_a of the variable to be squared, and Y is the offset from VAR_a of
; where to put the 24-bit result.  X may be the same as Y.  Destroys A and X.
;
square:
        stz     VAR_sq          ; Zero the 48-bit intermediate result.
        stz     VAR_sq+1
        stz     VAR_sq+2
        stz     VAR_sq+3
        stz     VAR_sq+4
        stz     VAR_sq+5
        stz     VAR_sq+6
;
        lda     VAR_a,x         ; Copy the input argument to "t".
        sta     VAR_t
        lda     VAR_a+1,x
        sta     VAR_t+1
        lda     VAR_a+2,x
        sta     VAR_t+2
        bpl     square_pos      ; Is "t" negative?
        lda     VAR_t           ; Negate it if so.
        eor     #$FF
        clc
        adc     #1
        sta     VAR_t
        lda     VAR_t+1
        eor     #$FF
        adc     #0
        sta     VAR_t+1
        lda     VAR_t+2
        eor     #$FF
        adc     #0
        sta     VAR_t+2
square_pos:
        sta     VAR_u+2         ; Copy "t" to "u".
        lda     VAR_t
        sta     VAR_u
        lda     VAR_t+1
        sta     VAR_u+1
;
        ldx     #24
square_loop:
        asl     VAR_sq          ; Shift the intermediate result left by 1 bit.
        rol     VAR_sq+1
        rol     VAR_sq+2
        rol     VAR_sq+3
        rol     VAR_sq+4
        rol     VAR_sq+5
;
        asl     VAR_u           ; Shift "u" left by 1 bit and check the top bit.
        rol     VAR_u+1
        rol     VAR_u+2
        bcc     square_next
;
        lda     VAR_t           ; Add "t" to the intermediate result.
        clc
        adc     VAR_sq
        sta     VAR_sq
        lda     VAR_t+1
        adc     VAR_sq+1
        sta     VAR_sq+1
        lda     VAR_t+2
        adc     VAR_sq+2
        sta     VAR_sq+2
        bcc     square_next
        inc     VAR_sq+3        ; Propagate the carries to the high bytes.
        bne     square_next
        inc     VAR_sq+4
        bne     square_next
        inc     VAR_sq+5
square_next:
        dex
        bne     square_loop
;
        lda     VAR_sq+2        ; Copy the result to VAR_a+y.
        sta     VAR_a,y
        lda     VAR_sq+3
        sta     VAR_a+1,y
        lda     VAR_sq+4
        sta     VAR_a+2,y
        bmi     square_max      ; Did we overflow the signed 24-bit range?
        lda     VAR_sq+5
        beq     square_done
square_max:
        lda     #$7F            ; Max out the signed 24-bit result.
        sta     VAR_a+2,y
        lda     #$FF
        sta     VAR_a,y
        sta     VAR_a+1,y
square_done:
        rts
;
; Interrupt and reset vectors.
;
        .org    $FFFA
        .dw     nmi
        .dw     reset
        .dw     irqbrk
