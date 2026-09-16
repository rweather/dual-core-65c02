/*
 * Copyright (C) 2024 Rhys Weatherley
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

#include "emul6502.h"
#include "emulio.h"
#include <string.h>
#include <stdlib.h>
#include <errno.h>

void emul6502_init(emul6502_t *emul, emul6502_mem_t *mem, int cpu_num)
{
    /* Initialize the emulator */
    memset(emul, 0, sizeof(emul6502_t));
    emul->mem = mem;
    emul->cpu_num = cpu_num;
    if (cpu_num == 1) {
        /* Clear all of memory */
        memset(mem, 0, sizeof(emul6502_mem_t));

        /* Set the spare bytes in memory to an illegal instruction code
         * just in case execution gets that far. */
        memset(emul->mem->memory + MEMSZ, 0xFF, 256);
    }

    /* Initialize various system variables */
    emul->S = 0xFF;
    emul->tape = NULL;
    emul->key_timeout = 50;
    emul->lower = 1;
    emul->cls = 1;
}

void emul6502_reset(emul6502_t *emul)
{
    /* Reset the registers to their defaults */
    emul->A = 0;
    emul->X = 0;
    emul->Y = 0;
    emul->S = 0xFF;
    emul->P = 0;

    /* Load the program counter from the reset vector address */
    emul->PC = emul6502_load_word(emul, 0xFFFC);

    /* Close any open tape files */
    emulio_tape_close(emul);
}

int emul6502_irq(emul6502_t *emul)
{
    if (emul->P & P_I)
        return 0;
    emul6502_push_word(emul, emul->PC);
    emul6502_push_byte(emul, emul->P);
    emul->PC = emul6502_load_word(emul, 0xFFFE);
    emul->P &= ~P_D; /* 65C02 clears D upon IRQ */
    return 1;
}

void emul6502_nmi(emul6502_t *emul)
{
    emul6502_push_word(emul, emul->PC);
    emul6502_push_byte(emul, emul->P);
    emul->PC = emul6502_load_word(emul, 0xFFFA);
    emul->P &= ~P_D; /* 65C02 clears D upon NMI */
}

void emul6502_break(emul6502_t *emul)
{
    /* The byte following the "BRK" instruction is skipped so that
     * we return back to just after that point.  The spare byte can
     * be used to store a break type code or whatever. */
    emul6502_push_word(emul, emul->PC + 2);
    emul6502_push_byte(emul, emul->P | P_B); /* Set the BREAK bit in P */
    emul->PC = emul6502_load_word(emul, 0xFFFE);
    emul->P &= ~P_D; /* 65C02 clears D upon BRK */
}

void emul6502_rti(emul6502_t *emul)
{
    emul->P = emul6502_pop_byte(emul);
    emul->PC = emul6502_pop_word(emul);
}

void emul6502_rts(emul6502_t *emul)
{
    /* Return addresses on the stack are -1 from the true return address */
    emul->PC = emul6502_pop_word(emul) + 1;
}

uint32_t emul6502_resolve_address(const emul6502_t *emul, uint16_t addr)
{
    /* No memory banks, so map the address directly */
    (void)emul;
    return addr;
}

uint8_t emul6502_load_byte(emul6502_t *emul, uint32_t addr)
{
    if (addr >= 0x8000U && addr <= 0x8FFFU) {
        return emulio_load_byte(emul, addr);
    }
    if (emul->cpu_num == 2 && addr >= 0xC000U && addr <= 0xFFFFU) {
        /* Load from the alternate ROM image for CPU2 */
        return emul->mem->rom_alt[addr & (ROMSZ - 1)];
    }
    if (emul->cpu_num == 2 && addr <= 0x03FFU) {
        /* CPU2 inverts A9 in this region of memory to move where
         * its zero page and stack are located. */
        addr ^= 0x0200U;
    }
    return emul->mem->memory[addr & (MEMSZ - 1)];
}

uint16_t emul6502_load_word(emul6502_t *emul, uint32_t addr)
{
    return emul6502_load_byte(emul, addr) |
           (((uint16_t)emul6502_load_byte(emul, addr + 1)) << 8);
}

uint32_t emul6502_load_address(emul6502_t *emul, uint32_t addr)
{
    uint16_t value = emul6502_load_byte(emul, addr) |
                     (((uint16_t)emul6502_load_byte(emul, addr + 1)) << 8);
    return emul6502_resolve_address(emul, value);
}

void emul6502_store_byte(emul6502_t *emul, uint32_t addr, uint8_t value)
{
    uint8_t *ptr;
    if (addr >= 0x8000U && addr <= 0x8FFFU) {
        /* Store to an I/O location */
        emulio_store_byte(emul, addr, value);
        return;
    } else if (addr >= 0xC000U) {
        /* Cannot store to a ROM location */
        emul->error = ERR_ACCESS;
        return;
    } else if (emul->cpu_num == 2 && addr <= 0x03FFU) {
        /* CPU2 inverts A9 in this region of memory to move where
         * its zero page and stack are located. */
        addr ^= 0x0200U;
    }
    ptr = &(emul->mem->memory[addr & (MEMSZ - 1)]);
    *ptr = value;
}

void emul6502_push_byte(emul6502_t *emul, uint8_t value)
{
    uint32_t sp = emul6502_resolve_address(emul, 0x0100U + emul->S);
    emul6502_store_byte(emul, sp, value);
    --(emul->S);
}

void emul6502_push_word(emul6502_t *emul, uint16_t value)
{
    emul6502_push_byte(emul, (uint8_t)(value >> 8));
    emul6502_push_byte(emul, (uint8_t)value);
}

uint8_t emul6502_pop_byte(emul6502_t *emul)
{
    uint32_t sp;
    ++(emul->S);
    sp = emul6502_resolve_address(emul, 0x0100U + emul->S);
    return emul6502_load_byte(emul, sp);
}

uint16_t emul6502_pop_word(emul6502_t *emul)
{
    uint16_t value = emul6502_pop_byte(emul);
    value |= ((uint16_t)emul6502_pop_byte(emul)) << 8;
    return value;
}

/* Adjust the cycle counter */
#define CYCLES(n)   ((emul)->cycles += (n))

/* Fetch a byte from program memory at PC */
#define emul6502_fetch(emul) \
    (emul6502_load_byte(emul, emul6502_resolve_address(emul, emul->PC)))

/* Gets the effective address of a "X,ind" instruction, which adds X
 * to a zero page location and then pulls the word out of the zero page.
 * The addition of X wraps around to the start of the zero page. */
static uint32_t emul6502_ea_x_ind(emul6502_t *emul)
{
    uint32_t ind;
    uint16_t addr;
    ++(emul->PC);
    ind = emul6502_resolve_address
        (emul, (emul6502_fetch(emul) + emul->X) & 0xFFU);
    addr = emul6502_load_byte(emul, ind);
    ind = (ind & 0xFF00U) + ((ind + 1) & 0xFF); /* Wrap-around */
    addr |= ((uint16_t)emul6502_load_byte(emul, ind)) << 8;
    return emul6502_resolve_address(emul, addr);
}
#define EA_X_IND (ea = emul6502_ea_x_ind(emul))

/* Gets the effective address of a "ind,zpg" instruction, which loads an
 * address from the zero page without adding Y (65C02). */
static uint32_t emul6502_ea_ind_zpg(emul6502_t *emul)
{
    uint32_t addr;
    ++(emul->PC);
    addr = emul6502_resolve_address(emul, emul6502_fetch(emul));
    addr = emul6502_load_address(emul, addr);
    return addr;
}
#define EA_IND_ZPG (ea = emul6502_ea_ind_zpg(emul))

/* Gets the effective address of a "ind,Y" instruction, which loads an
 * address from the zero page and adds Y to it. */
static uint32_t emul6502_ea_ind_y(emul6502_t *emul)
{
    return emul6502_ea_ind_zpg(emul) + emul->Y;
}
#define EA_IND_Y (ea = emul6502_ea_ind_y(emul))

/* Gets the effective address of a "zpg" instruction */
static uint32_t emul6502_ea_zpg(emul6502_t *emul)
{
    ++(emul->PC);
    return emul6502_resolve_address(emul, emul6502_fetch(emul));
}
#define EA_ZPG (ea = emul6502_ea_zpg(emul))

/* Gets the effective address of a "zpg,X" instruction */
static uint32_t emul6502_ea_zpg_x(emul6502_t *emul)
{
    ++(emul->PC);
    return emul6502_resolve_address
        (emul, (emul6502_fetch(emul) + emul->X) & 0xFF);
}
#define EA_ZPG_X (ea = emul6502_ea_zpg_x(emul))

/* Gets the effective address of a "zpg,Y" instruction */
static uint32_t emul6502_ea_zpg_y(emul6502_t *emul)
{
    ++(emul->PC);
    return emul6502_resolve_address
        (emul, (emul6502_fetch(emul) + emul->Y) & 0xFF);
}
#define EA_ZPG_Y (ea = emul6502_ea_zpg_y(emul))

/* Gets the effective address of an "abs" instruction */
static uint32_t emul6502_ea_abs(emul6502_t *emul)
{
    uint16_t addr;
    ++(emul->PC);
    addr = emul6502_fetch(emul);
    ++(emul->PC);
    addr |= ((uint16_t)emul6502_fetch(emul)) << 8;
    return emul6502_resolve_address(emul, addr);
}
#define EA_ABS (ea = emul6502_ea_abs(emul))

/* Gets the effective address of an "abs,X" instruction */
#define EA_ABS_X (ea = emul6502_ea_abs(emul) + emul->X)

/* Gets the effective address of an "abs,Y" instruction */
#define EA_ABS_Y (ea = emul6502_ea_abs(emul) + emul->Y)

/* Gets an absolute jump address for "JMP" or "JSR" */
static uint16_t emul6502_jump_address(emul6502_t *emul)
{
    uint16_t addr;
    ++(emul->PC);
    addr = emul6502_fetch(emul);
    ++(emul->PC);
    addr |= ((uint16_t)emul6502_fetch(emul)) << 8;
    return addr;
}

/* Gets the immediate value for the current instruction */
#define GETIMM \
    do { \
        ++(emul->PC); \
        imm = emul6502_fetch(emul); \
    } while (0)

/* Updates the N and Z flags from the "x" value */
#define UPDATE_NZ(x) \
    do { \
        if ((x) == 0) \
            emul->P |= P_Z; \
        else \
            emul->P &= ~P_Z; \
        if (((x) & 0x80) != 0) \
            emul->P |= P_N; \
        else \
            emul->P &= ~P_N; \
    } while (0)

/* Branch if a condition is true */
static void emul6502_branch(emul6502_t *emul, int cond)
{
    int8_t offset;
    ++(emul->PC);
    offset = (int8_t)emul6502_fetch(emul);
    if (cond) {
        emul->PC += (int16_t)offset;
        CYCLES(3);
    } else {
        CYCLES(2);
    }
}

/* Branch if a condition is true for a BBRm or BBSn instruction */
static void emul6502_bbrs(emul6502_t *emul, int cond)
{
    /* Needs 3 extra cycles to load the value to test the condition */
    CYCLES(3);

    /* Perform a normal branch based on the condition */
    emul6502_branch(emul, cond);
}

/* Perform a BIT operation on an effective address */
static void emul6502_bit(emul6502_t *emul, uint32_t ea)
{
    uint8_t value = emul6502_load_byte(emul, ea);
    emul->P = (emul->P & 0x3F) | (value & 0xC0); /* Set N and V */
    if ((emul->A & value) != 0)
        emul->P &= ~P_Z;
    else
        emul->P |= P_Z;
}

/* Perform a BIT operation on an immediate value */
static void emul6502_bit_imm(emul6502_t *emul, uint8_t value)
{
    emul->P = (emul->P & 0x3F) | (value & 0xC0); /* Set N and V */
    if ((emul->A & value) != 0)
        emul->P &= ~P_Z;
    else
        emul->P |= P_Z;
}

/* Perform a TRB operation on an effective address (65C02) */
static void emul6502_trb(emul6502_t *emul, uint32_t ea)
{
    uint8_t value = emul6502_load_byte(emul, ea);
    if ((emul->A & value) != 0)
        emul->P &= ~P_Z;
    else
        emul->P |= P_Z;
    emul6502_store_byte(emul, ea, value & ~(emul->A));
}

/* Perform a TSB operation on an effective address (65C02) */
static void emul6502_tsb(emul6502_t *emul, uint32_t ea)
{
    uint8_t value = emul6502_load_byte(emul, ea);
    if ((emul->A & value) != 0)
        emul->P &= ~P_Z;
    else
        emul->P |= P_Z;
    emul6502_store_byte(emul, ea, value | emul->A);
}

/* Perform a RMB operation on an effective address */
static void emul6502_rmb(emul6502_t *emul, uint32_t ea, int bit)
{
    uint8_t value = emul6502_load_byte(emul, ea);
    value &= ~(1 << bit);
    emul6502_store_byte(emul, ea, value);
}

/* Perform a SMB operation on an effective address */
static void emul6502_smb(emul6502_t *emul, uint32_t ea, int bit)
{
    uint8_t value = emul6502_load_byte(emul, ea);
    value |= (1 << bit);
    emul6502_store_byte(emul, ea, value);
}

/* Perform an ASL operation on an effective address */
static void emul6502_asl(emul6502_t *emul, uint32_t ea)
{
    uint8_t value = emul6502_load_byte(emul, ea);
    if ((value & 0x80) != 0)
        emul->P |= P_C;
    else
        emul->P &= ~P_C;
    value <<= 1;
    emul6502_store_byte(emul, ea, value);
    UPDATE_NZ(value);
}

/* Perform an ASL operation on A */
static void emul6502_asl_A(emul6502_t *emul)
{
    if ((emul->A & 0x80) != 0)
        emul->P |= P_C;
    else
        emul->P &= ~P_C;
    emul->A <<= 1;
    UPDATE_NZ(emul->A);
}

/* Perform a ROL operation on an effective address */
static void emul6502_rol(emul6502_t *emul, uint32_t ea)
{
    uint8_t prev = emul6502_load_byte(emul, ea);
    uint8_t next = (prev << 1) | ((emul->P & P_C) ? 1 : 0);
    if ((prev & 0x80) != 0)
        emul->P |= P_C;
    else
        emul->P &= ~P_C;
    emul6502_store_byte(emul, ea, next);
    UPDATE_NZ(next);
}

/* Perform a ROL operation on A */
static void emul6502_rol_A(emul6502_t *emul)
{
    uint8_t prev = emul->A;
    emul->A = (prev << 1) | ((emul->P & P_C) ? 1 : 0);
    if ((prev & 0x80) != 0)
        emul->P |= P_C;
    else
        emul->P &= ~P_C;
    UPDATE_NZ(emul->A);
}

/* Perform a LSR operation on an effective address */
static void emul6502_lsr(emul6502_t *emul, uint32_t ea)
{
    uint8_t value = emul6502_load_byte(emul, ea);
    if ((value & 0x01) != 0)
        emul->P |= P_C;
    else
        emul->P &= ~P_C;
    value >>= 1;
    emul6502_store_byte(emul, ea, value);
    UPDATE_NZ(value);
}

/* Perform a LSR operation on A */
static void emul6502_lsr_A(emul6502_t *emul)
{
    if ((emul->A & 0x01) != 0)
        emul->P |= P_C;
    else
        emul->P &= ~P_C;
    emul->A >>= 1;
    UPDATE_NZ(emul->A);
}

/* Perform a ROR operation on an effective address */
static void emul6502_ror(emul6502_t *emul, uint32_t ea)
{
    uint8_t prev = emul6502_load_byte(emul, ea);
    uint8_t next = (prev >> 1) | ((emul->P & P_C) ? 0x80 : 0x00);
    if ((prev & 0x01) != 0)
        emul->P |= P_C;
    else
        emul->P &= ~P_C;
    emul6502_store_byte(emul, ea, next);
    UPDATE_NZ(next);
}

/* Perform a ROR operation on A */
static void emul6502_ror_A(emul6502_t *emul)
{
    uint8_t prev = emul->A;
    emul->A = (prev >> 1) | ((emul->P & P_C) ? 0x80 : 0x00);
    if ((prev & 0x01) != 0)
        emul->P |= P_C;
    else
        emul->P &= ~P_C;
    UPDATE_NZ(emul->A);
}

/* Perform an ADC operation */
static void emul6502_adc(emul6502_t *emul, uint16_t value)
{
    if (emul->P & P_D) {
        /* Compute the addition in BCD mode */
        /* http://www.6502.org/tutorials/decimal_mode.html */
        uint16_t low = (value & 0x0F) + (emul->A & 0x0F) + (emul->P & P_C);
        if (low >= 10)
            low = ((low + 6) & 0x0F) + 0x10;
        value = (value & 0xF0) + (emul->A & 0xF0) + low;
        if (value >= 0xA0)
            value += 0x60;
    } else {
        /* Compute the addition in binary mode */
        value += emul->A;
        value += (emul->P & P_C);
    }
    emul->A = (uint8_t)value;
    emul->P = (emul->P & 0x3F) | (value & 0xC0); /* Set N and V */
    if ((value & 0xFF00) != 0)
        emul->P |= P_C;
    else
        emul->P &= ~P_C;
    if ((value & 0x00FF) != 0)
        emul->P &= ~P_Z;
    else
        emul->P |= P_Z;
}

/* Perform a SBC operation */
static void emul6502_sbc(emul6502_t *emul, uint8_t value)
{
    int result = ((int)(emul->A)) - ((int)value);
    if ((emul->P & P_C) == 0)
        --result; /* Account for input borrow */
    if (emul->P & P_D) {
        /* Correct the result of the subtraction in BCD mode */
        /* http://www.6502.org/tutorials/decimal_mode.html */
        int low = ((int)(emul->A & 0x0F)) - ((int)(value & 0x0F));
        if ((emul->P & P_C) == 0)
            --low; /* Account for input borrow */
        if (result < 0)
            result -= 0x60;
        if (low < 0)
            result -= 6;
    }
    emul->A = (uint8_t)result;
    emul->P = (emul->P & 0x3F) | (result & 0xC0); /* Set N and V */
    if (result >= 0) /* Set output borrow */
        emul->P |= P_C;
    else
        emul->P &= ~P_C;
    if ((result & 0x00FF) != 0)
        emul->P &= ~P_Z;
    else
        emul->P |= P_Z;
}

/* Compare two values and update the flags */
static void emul6502_compare(emul6502_t *emul, uint8_t x, uint8_t y)
{
    int cmp = ((int)x) - ((int)y);
    if (cmp < 0)
        emul->P &= ~P_C;    /* CMP result is a borrow, not a carry */
    else
        emul->P |= P_C;
    UPDATE_NZ(cmp);
}

/* Mark an instruction as 65C02 only */
#define MCU_65C02       do { ; } while (0)

/* Mark an instruction as WDC65C02 only */
#define MCU_WDC65C02    do { ; } while (0)

void emul6502_run(emul6502_t *emul)
{
    uint16_t start; /* PC at the start of the instruction fetch */
    uint32_t ea; /* Effective address for current instruction */
    uint8_t imm; /* Immediate value for current instruction */
    for (;;) {
        /* 6502:  https://www.masswerk.at/6502/6502_instruction_set.html */
        /* 65C02: http://6502.org/tutorials/65c02opcodes.html */
        start = emul->PC;
        switch (emul6502_fetch(emul)) {
        case 0x00:      /* BRK */
            /* BRK can be used to print the cycle counter for testing */
            if (emul->cycle_counter) {
                fprintf(stderr, "cycle counter = %d\r\n", (int)(emul->cycles));
            } else {
                emul->PC = start;
                emul6502_break(emul);
                CYCLES(7);
                continue;
            }
            break;

        case 0x01:      /* ORA X,ind */
            EA_X_IND;
            emul->A |= emul6502_load_byte(emul, ea);
            UPDATE_NZ(emul->A);
            CYCLES(6);
            break;

        case 0x04:      /* TSB zpg */
            MCU_65C02;
            EA_ZPG;
            emul6502_tsb(emul, ea);
            CYCLES(5);
            break;

        case 0x05:      /* ORA zpg */
            EA_ZPG;
            emul->A |= emul6502_load_byte(emul, ea);
            UPDATE_NZ(emul->A);
            CYCLES(3);
            break;

        case 0x06:      /* ASL zpg */
            EA_ZPG;
            emul6502_asl(emul, ea);
            CYCLES(5);
            break;

        case 0x07:      /* RMB0 zpg */
            MCU_WDC65C02;
            EA_ZPG;
            emul6502_rmb(emul, ea, 0);
            CYCLES(5);
            break;

        case 0x08:      /* PHP */
            emul6502_push_byte(emul, emul->P);
            CYCLES(3);
            break;

        case 0x09:      /* ORA # */
            GETIMM;
            emul->A |= imm;
            UPDATE_NZ(emul->A);
            CYCLES(2);
            break;

        case 0x0A:      /* ASL A */
            emul6502_asl_A(emul);
            CYCLES(2);
            break;

        case 0x0C:      /* TSB abs */
            MCU_65C02;
            EA_ABS;
            emul6502_tsb(emul, ea);
            CYCLES(6);
            break;

        case 0x0D:      /* ORA abs */
            EA_ABS;
            emul->A |= emul6502_load_byte(emul, ea);
            UPDATE_NZ(emul->A);
            CYCLES(4);
            break;

        case 0x0E:      /* ASL abs */
            EA_ABS;
            emul6502_asl(emul, ea);
            CYCLES(6);
            break;

        case 0x0F:      /* BBR0 zpg,rel */
            MCU_WDC65C02;
            EA_ZPG;
            emul6502_bbrs(emul, (emul6502_load_byte(emul, ea) & 0x01) == 0);
            break;

        case 0x10:      /* BPL rel */
            emul6502_branch(emul, (emul->P & P_N) == 0);
            break;

        case 0x11:      /* ORA ind,Y */
            EA_IND_Y;
            emul->A |= emul6502_load_byte(emul, ea);
            UPDATE_NZ(emul->A);
            CYCLES(5);
            break;

        case 0x12:      /* ORA (zpg) */
            MCU_65C02;
            EA_IND_ZPG;
            emul->A |= emul6502_load_byte(emul, ea);
            UPDATE_NZ(emul->A);
            CYCLES(5);
            break;

        case 0x14:      /* TRB zpg */
            MCU_65C02;
            EA_ZPG;
            emul6502_trb(emul, ea);
            CYCLES(5);
            break;

        case 0x15:      /* ORA zpg,X */
            EA_ZPG_X;
            emul->A |= emul6502_load_byte(emul, ea);
            UPDATE_NZ(emul->A);
            CYCLES(4);
            break;

        case 0x16:      /* ASL zpg,X */
            EA_ZPG_X;
            emul6502_asl(emul, ea);
            CYCLES(6);
            break;

        case 0x17:      /* RMB1 zpg */
            MCU_WDC65C02;
            EA_ZPG;
            emul6502_rmb(emul, ea, 1);
            CYCLES(5);
            break;

        case 0x18:      /* CLC */
            emul->P &= ~P_C;
            CYCLES(2);
            break;

        case 0x1A:      /* INC A */
            MCU_65C02;
            emul->A = emul->A + 1;
            UPDATE_NZ(emul->A);
            CYCLES(2);
            break;

        case 0x19:      /* ORA abs,Y */
            EA_ABS_Y;
            emul->A |= emul6502_load_byte(emul, ea);
            UPDATE_NZ(emul->A);
            CYCLES(4);
            break;

        case 0x1C:      /* TRB abs */
            MCU_65C02;
            EA_ABS;
            emul6502_trb(emul, ea);
            CYCLES(6);
            break;

        case 0x1D:      /* ORA abs,X */
            EA_ABS_X;
            emul->A |= emul6502_load_byte(emul, ea);
            UPDATE_NZ(emul->A);
            CYCLES(4);
            break;

        case 0x1E:      /* ASL abs,X */
            EA_ABS_X;
            emul6502_asl(emul, ea);
            CYCLES(7);
            break;

        case 0x1F:      /* BBR1 zpg,rel */
            MCU_WDC65C02;
            EA_ZPG;
            emul6502_bbrs(emul, (emul6502_load_byte(emul, ea) & 0x02) == 0);
            break;

        case 0x20:      /* JSR abs */
            emul6502_push_word(emul, emul->PC + 2);
            emul->PC = emul6502_jump_address(emul);
            CYCLES(6);
            continue;

        case 0x21:      /* AND X,ind */
            EA_X_IND;
            emul->A &= emul6502_load_byte(emul, ea);
            UPDATE_NZ(emul->A);
            CYCLES(6);
            break;

        case 0x24:      /* BIT zpg */
            EA_ZPG;
            emul6502_bit(emul, ea);
            CYCLES(3);
            break;

        case 0x25:      /* AND zpg */
            EA_ZPG;
            emul->A &= emul6502_load_byte(emul, ea);
            UPDATE_NZ(emul->A);
            CYCLES(3);
            break;

        case 0x26:      /* ROL zpg */
            EA_ZPG;
            emul6502_rol(emul, ea);
            CYCLES(5);
            break;

        case 0x27:      /* RMB2 zpg */
            MCU_WDC65C02;
            EA_ZPG;
            emul6502_rmb(emul, ea, 2);
            CYCLES(5);
            break;

        case 0x28:      /* PLP */
            emul->P = emul6502_pop_byte(emul);
            CYCLES(4);
            break;

        case 0x29:      /* AND # */
            GETIMM;
            emul->A &= imm;
            UPDATE_NZ(emul->A);
            CYCLES(2);
            break;

        case 0x2A:      /* ROL A */
            emul6502_rol_A(emul);
            CYCLES(2);
            break;

        case 0x2C:      /* BIT abs */
            EA_ABS;
            emul6502_bit(emul, ea);
            CYCLES(4);
            break;

        case 0x2D:      /* AND abs */
            EA_ABS;
            emul->A &= emul6502_load_byte(emul, ea);
            UPDATE_NZ(emul->A);
            CYCLES(4);
            break;

        case 0x2E:      /* ROL abs */
            EA_ABS;
            emul6502_rol(emul, ea);
            CYCLES(6);
            break;

        case 0x2F:      /* BBR2 zpg,rel */
            MCU_WDC65C02;
            EA_ZPG;
            emul6502_bbrs(emul, (emul6502_load_byte(emul, ea) & 0x04) == 0);
            break;

        case 0x30:      /* BMI rel */
            emul6502_branch(emul, (emul->P & P_N) != 0);
            break;

        case 0x31:      /* AND ind,Y */
            EA_IND_Y;
            emul->A &= emul6502_load_byte(emul, ea);
            UPDATE_NZ(emul->A);
            CYCLES(5);
            break;

        case 0x32:      /* AND (zpg) */
            MCU_65C02;
            EA_IND_ZPG;
            emul->A &= emul6502_load_byte(emul, ea);
            UPDATE_NZ(emul->A);
            CYCLES(5);
            break;

        case 0x34:      /* BIT zpg,X */
            MCU_65C02;
            EA_ZPG_X;
            emul6502_bit(emul, ea);
            CYCLES(4);
            break;

        case 0x35:      /* AND zpg,X */
            EA_ZPG_X;
            emul->A &= emul6502_load_byte(emul, ea);
            UPDATE_NZ(emul->A);
            CYCLES(4);
            break;

        case 0x36:      /* ROL zpg,X */
            EA_ZPG_X;
            emul6502_rol(emul, ea);
            CYCLES(6);
            break;

        case 0x37:      /* RMB3 zpg */
            MCU_WDC65C02;
            EA_ZPG;
            emul6502_rmb(emul, ea, 3);
            CYCLES(5);
            break;

        case 0x38:      /* SEC */
            emul->P |= P_C;
            CYCLES(2);
            break;

        case 0x39:      /* AND abs,Y */
            EA_ABS_Y;
            emul->A &= emul6502_load_byte(emul, ea);
            UPDATE_NZ(emul->A);
            CYCLES(4);
            break;

        case 0x3A:      /* DEC A */
            MCU_65C02;
            emul->A = emul->A - 1;
            UPDATE_NZ(emul->A);
            CYCLES(2);
            break;

        case 0x3C:      /* BIT abs,X */
            MCU_65C02;
            EA_ABS_X;
            emul6502_bit(emul, ea);
            CYCLES(4);
            break;

        case 0x3D:      /* AND abs,X */
            EA_ABS_X;
            emul->A &= emul6502_load_byte(emul, ea);
            UPDATE_NZ(emul->A);
            CYCLES(4);
            break;

        case 0x3E:      /* ROL abs,X */
            EA_ABS_X;
            emul6502_rol(emul, ea);
            CYCLES(7);
            break;

        case 0x3F:      /* BBR3 zpg,rel */
            MCU_WDC65C02;
            EA_ZPG;
            emul6502_bbrs(emul, (emul6502_load_byte(emul, ea) & 0x08) == 0);
            break;

        case 0x40:      /* RTI */
            emul6502_rti(emul);
            CYCLES(6);
            continue;

        case 0x41:      /* EOR X,ind */
            EA_X_IND;
            emul->A ^= emul6502_load_byte(emul, ea);
            UPDATE_NZ(emul->A);
            CYCLES(6);
            break;

        case 0x45:      /* EOR zpg */
            EA_ZPG;
            emul->A ^= emul6502_load_byte(emul, ea);
            UPDATE_NZ(emul->A);
            CYCLES(3);
            break;

        case 0x46:      /* LSR zpg */
            EA_ZPG;
            emul6502_lsr(emul, ea);
            CYCLES(5);
            break;

        case 0x47:      /* RMB4 zpg */
            MCU_WDC65C02;
            EA_ZPG;
            emul6502_rmb(emul, ea, 4);
            CYCLES(5);
            break;

        case 0x48:      /* PHA */
            emul6502_push_byte(emul, emul->A);
            CYCLES(3);
            break;

        case 0x49:      /* EOR # */
            GETIMM;
            emul->A ^= imm;
            UPDATE_NZ(emul->A);
            CYCLES(2);
            break;

        case 0x4A:      /* LSR A */
            emul6502_lsr_A(emul);
            CYCLES(2);
            break;

        case 0x4C:      /* JMP abs */
            emul->PC = emul6502_jump_address(emul);
            CYCLES(3);
            continue;

        case 0x4D:      /* EOR abs */
            EA_ABS;
            emul->A ^= emul6502_load_byte(emul, ea);
            UPDATE_NZ(emul->A);
            CYCLES(4);
            break;

        case 0x4E:      /* LSR abs */
            EA_ABS;
            emul6502_lsr(emul, ea);
            CYCLES(6);
            break;

        case 0x4F:      /* BBR4 zpg,rel */
            MCU_WDC65C02;
            EA_ZPG;
            emul6502_bbrs(emul, (emul6502_load_byte(emul, ea) & 0x10) == 0);
            break;

        case 0x50:      /* BVC rel */
            emul6502_branch(emul, (emul->P & P_V) == 0);
            break;

        case 0x51:      /* EOR ind,Y */
            EA_IND_Y;
            emul->A ^= emul6502_load_byte(emul, ea);
            UPDATE_NZ(emul->A);
            CYCLES(5);
            break;

        case 0x52:      /* EOR (zpg) */
            MCU_65C02;
            EA_IND_ZPG;
            emul->A ^= emul6502_load_byte(emul, ea);
            UPDATE_NZ(emul->A);
            CYCLES(5);
            break;

        case 0x55:      /* EOR zpg,X */
            EA_ZPG_X;
            emul->A ^= emul6502_load_byte(emul, ea);
            UPDATE_NZ(emul->A);
            CYCLES(4);
            break;

        case 0x56:      /* LSR zpg,X */
            EA_ZPG_X;
            emul6502_lsr(emul, ea);
            CYCLES(6);
            break;

        case 0x57:      /* RMB5 zpg */
            MCU_WDC65C02;
            EA_ZPG;
            emul6502_rmb(emul, ea, 5);
            CYCLES(5);
            break;

        case 0x58:      /* CLI */
            emul->P &= ~P_I;
            CYCLES(2);
            break;

        case 0x59:      /* EOR abs,Y */
            EA_ABS_Y;
            emul->A ^= emul6502_load_byte(emul, ea);
            UPDATE_NZ(emul->A);
            CYCLES(4);
            break;

        case 0x5A:      /* PHY */
            MCU_65C02;
            emul6502_push_byte(emul, emul->Y);
            CYCLES(3);
            break;

        case 0x5D:      /* EOR abs,X */
            EA_ABS_X;
            emul->A ^= emul6502_load_byte(emul, ea);
            UPDATE_NZ(emul->A);
            CYCLES(4);
            break;

        case 0x5E:      /* LSR abs,X */
            EA_ABS_X;
            emul6502_lsr(emul, ea);
            CYCLES(7);
            break;

        case 0x5F:      /* BBR5 zpg,rel */
            MCU_WDC65C02;
            EA_ZPG;
            emul6502_bbrs(emul, (emul6502_load_byte(emul, ea) & 0x20) == 0);
            break;

        case 0x60:      /* RTS */
            emul6502_rts(emul);
            CYCLES(6);
            continue;

        case 0x61:      /* ADC X,ind */
            EA_X_IND;
            emul6502_adc(emul, emul6502_load_byte(emul, ea));
            CYCLES(6);
            break;

        case 0x64:      /* STZ zpg */
            MCU_65C02;
            EA_ZPG;
            emul6502_store_byte(emul, ea, 0);
            CYCLES(3);
            break;

        case 0x65:      /* ADC zpg */
            EA_ZPG;
            emul6502_adc(emul, emul6502_load_byte(emul, ea));
            CYCLES(3);
            break;

        case 0x66:      /* ROR zpg */
            EA_ZPG;
            emul6502_ror(emul, ea);
            CYCLES(5);
            break;

        case 0x67:      /* RMB6 zpg */
            MCU_WDC65C02;
            EA_ZPG;
            emul6502_rmb(emul, ea, 6);
            CYCLES(5);
            break;

        case 0x68:      /* PLA */
            emul->A = emul6502_pop_byte(emul);
            UPDATE_NZ(emul->A);
            CYCLES(4);
            break;

        case 0x69:      /* ADC # */
            GETIMM;
            emul6502_adc(emul, imm);
            CYCLES(2);
            break;

        case 0x6A:      /* ROR A */
            emul6502_ror_A(emul);
            CYCLES(2);
            break;

        case 0x6C:      /* JMP ind */
            EA_ABS;
            emul->PC = emul6502_load_word(emul, ea);
            CYCLES(5);
            continue;

        case 0x6D:      /* ADC abs */
            EA_ABS;
            emul6502_adc(emul, emul6502_load_byte(emul, ea));
            CYCLES(4);
            break;

        case 0x6E:      /* ROR abs */
            EA_ABS;
            emul6502_ror(emul, ea);
            CYCLES(6);
            break;

        case 0x6F:      /* BBR6 zpg,rel */
            MCU_WDC65C02;
            EA_ZPG;
            emul6502_bbrs(emul, (emul6502_load_byte(emul, ea) & 0x40) == 0);
            break;

        case 0x70:      /* BVS rel */
            emul6502_branch(emul, (emul->P & P_V) != 0);
            break;

        case 0x71:      /* ADC ind,Y */
            EA_IND_Y;
            emul6502_adc(emul, emul6502_load_byte(emul, ea));
            CYCLES(5);
            break;

        case 0x72:      /* ADC (zpg) */
            MCU_65C02;
            EA_IND_ZPG;
            emul6502_adc(emul, emul6502_load_byte(emul, ea));
            CYCLES(5);
            break;

        case 0x74:      /* STZ zpg,X */
            MCU_65C02;
            EA_ZPG_X;
            emul6502_store_byte(emul, ea, 0);
            CYCLES(4);
            break;

        case 0x75:      /* ADC zpg,X */
            EA_ZPG_X;
            emul6502_adc(emul, emul6502_load_byte(emul, ea));
            CYCLES(4);
            break;

        case 0x76:      /* ROR zpg,X */
            EA_ZPG_X;
            emul6502_ror(emul, ea);
            CYCLES(6);
            break;

        case 0x77:      /* RMB7 zpg */
            MCU_WDC65C02;
            EA_ZPG;
            emul6502_rmb(emul, ea, 7);
            CYCLES(5);
            break;

        case 0x78:      /* SEI */
            emul->P |= P_I;
            CYCLES(2);
            break;

        case 0x79:      /* ADC abs,Y */
            EA_ABS_Y;
            emul6502_adc(emul, emul6502_load_byte(emul, ea));
            CYCLES(4);
            break;

        case 0x7A:      /* PLY */
            MCU_65C02;
            emul->Y = emul6502_pop_byte(emul);
            UPDATE_NZ(emul->Y);
            CYCLES(4);
            break;

        case 0x7C:      /* JMP (abs,X) */
            MCU_65C02;
            EA_ABS_X;
            emul->PC = emul6502_load_word(emul, ea);
            CYCLES(6);
            continue;

        case 0x7D:      /* ADC abs,X */
            EA_ABS_X;
            emul6502_adc(emul, emul6502_load_byte(emul, ea));
            CYCLES(4);
            break;

        case 0x7E:      /* ROR abs,X */
            EA_ABS_X;
            emul6502_ror(emul, ea);
            CYCLES(7);
            break;

        case 0x7F:      /* BBR7 zpg,rel */
            MCU_WDC65C02;
            EA_ZPG;
            emul6502_bbrs(emul, (emul6502_load_byte(emul, ea) & 0x80) == 0);
            break;

        case 0x80:      /* BRA rel */
            MCU_65C02;
            emul6502_branch(emul, 1);
            break;

        case 0x81:      /* STA X,ind */
            EA_X_IND;
            emul6502_store_byte(emul, ea, emul->A);
            CYCLES(6);
            break;

        case 0x84:      /* STY zpg */
            EA_ZPG;
            emul6502_store_byte(emul, ea, emul->Y);
            CYCLES(3);
            break;

        case 0x85:      /* STA zpg */
            EA_ZPG;
            emul6502_store_byte(emul, ea, emul->A);
            CYCLES(3);
            break;

        case 0x86:      /* STX zpg */
            EA_ZPG;
            emul6502_store_byte(emul, ea, emul->X);
            CYCLES(3);
            break;

        case 0x87:      /* SMB0 zpg */
            MCU_WDC65C02;
            EA_ZPG;
            emul6502_smb(emul, ea, 0);
            CYCLES(5);
            break;

        case 0x88:      /* DEY */
            emul->Y = emul->Y - 1;
            UPDATE_NZ(emul->Y);
            CYCLES(2);
            break;

        case 0x89:      /* BIT imm */
            MCU_65C02;
            GETIMM;
            emul6502_bit_imm(emul, imm);
            CYCLES(2);
            break;

        case 0x8A:      /* TXA */
            emul->A = emul->X;
            UPDATE_NZ(emul->A);
            CYCLES(2);
            break;

        case 0x8C:      /* STY abs */
            EA_ABS;
            emul6502_store_byte(emul, ea, emul->Y);
            CYCLES(4);
            break;

        case 0x8D:      /* STA abs */
            EA_ABS;
            emul6502_store_byte(emul, ea, emul->A);
            CYCLES(4);
            break;

        case 0x8E:      /* STX abs */
            EA_ABS;
            emul6502_store_byte(emul, ea, emul->X);
            CYCLES(4);
            break;

        case 0x8F:      /* BBS0 zpg,rel */
            MCU_WDC65C02;
            EA_ZPG;
            emul6502_bbrs(emul, (emul6502_load_byte(emul, ea) & 0x01) != 0);
            break;

        case 0x90:      /* BCC rel */
            emul6502_branch(emul, (emul->P & P_C) == 0);
            break;

        case 0x91:      /* STA ind,Y */
            EA_IND_Y;
            emul6502_store_byte(emul, ea, emul->A);
            CYCLES(6);
            break;

        case 0x92:      /* STA (zpg) */
            MCU_65C02;
            EA_IND_ZPG;
            emul6502_store_byte(emul, ea, 0);
            CYCLES(6);
            break;

        case 0x94:      /* STY zpg,X */
            EA_ZPG_X;
            emul6502_store_byte(emul, ea, emul->Y);
            CYCLES(4);
            break;

        case 0x95:      /* STA zpg,X */
            EA_ZPG_X;
            emul6502_store_byte(emul, ea, emul->A);
            CYCLES(4);
            break;

        case 0x96:      /* STX zpg,Y */
            EA_ZPG_Y;
            emul6502_store_byte(emul, ea, emul->X);
            CYCLES(4);
            break;

        case 0x97:      /* SMB1 zpg */
            MCU_WDC65C02;
            EA_ZPG;
            emul6502_smb(emul, ea, 1);
            CYCLES(5);
            break;

        case 0x98:      /* TYA */
            emul->A = emul->Y;
            UPDATE_NZ(emul->A);
            CYCLES(2);
            break;

        case 0x99:      /* STA abs,Y */
            EA_ABS_Y;
            emul6502_store_byte(emul, ea, emul->A);
            CYCLES(5);
            break;

        case 0x9A:      /* TXS */
            emul->S = emul->X;
            CYCLES(2);
            break;

        case 0x9C:      /* STZ abs */
            MCU_65C02;
            EA_ABS;
            emul6502_store_byte(emul, ea, 0);
            CYCLES(4);
            break;

        case 0x9D:      /* STA abs,X */
            EA_ABS_X;
            emul6502_store_byte(emul, ea, emul->A);
            CYCLES(5);
            break;

        case 0x9E:      /* STZ abs,X */
            MCU_65C02;
            EA_ABS_X;
            emul6502_store_byte(emul, ea, 0);
            CYCLES(5);
            break;

        case 0x9F:      /* BBS1 zpg,rel */
            MCU_WDC65C02;
            EA_ZPG;
            emul6502_bbrs(emul, (emul6502_load_byte(emul, ea) & 0x02) != 0);
            break;

        case 0xA0:      /* LDY imm */
            GETIMM;
            emul->Y = imm;
            UPDATE_NZ(imm);
            CYCLES(2);
            break;

        case 0xA1:      /* LDA X,ind */
            EA_X_IND;
            emul->A = emul6502_load_byte(emul, ea);
            UPDATE_NZ(emul->A);
            CYCLES(6);
            break;

        case 0xA2:      /* LDX imm */
            GETIMM;
            emul->X = imm;
            UPDATE_NZ(imm);
            CYCLES(2);
            break;

        case 0xA4:      /* LDY zpg */
            EA_ZPG;
            emul->Y = emul6502_load_byte(emul, ea);
            UPDATE_NZ(emul->Y);
            CYCLES(3);
            break;

        case 0xA5:      /* LDA zpg */
            EA_ZPG;
            emul->A = emul6502_load_byte(emul, ea);
            UPDATE_NZ(emul->A);
            CYCLES(3);
            break;

        case 0xA6:      /* LDX zpg */
            EA_ZPG;
            emul->X = emul6502_load_byte(emul, ea);
            UPDATE_NZ(emul->X);
            CYCLES(3);
            break;

        case 0xA7:      /* SMB2 zpg */
            MCU_WDC65C02;
            EA_ZPG;
            emul6502_smb(emul, ea, 2);
            CYCLES(5);
            break;

        case 0xA8:      /* TAY */
            emul->Y = emul->A;
            UPDATE_NZ(emul->Y);
            CYCLES(2);
            break;

        case 0xA9:      /* LDA imm */
            GETIMM;
            emul->A = imm;
            UPDATE_NZ(imm);
            CYCLES(2);
            break;

        case 0xAA:      /* TAX */
            emul->X = emul->A;
            UPDATE_NZ(emul->X);
            CYCLES(2);
            break;

        case 0xAC:      /* LDY abs */
            EA_ABS;
            emul->Y = emul6502_load_byte(emul, ea);
            UPDATE_NZ(emul->Y);
            CYCLES(4);
            break;

        case 0xAD:      /* LDA abs */
            EA_ABS;
            emul->A = emul6502_load_byte(emul, ea);
            UPDATE_NZ(emul->A);
            CYCLES(4);
            break;

        case 0xAE:      /* LDX abs */
            EA_ABS;
            emul->X = emul6502_load_byte(emul, ea);
            UPDATE_NZ(emul->X);
            CYCLES(4);
            break;

        case 0xAF:      /* BBS2 zpg,rel */
            MCU_WDC65C02;
            EA_ZPG;
            emul6502_bbrs(emul, (emul6502_load_byte(emul, ea) & 0x04) != 0);
            break;

        case 0xB0:      /* BCS rel */
            emul6502_branch(emul, (emul->P & P_C) != 0);
            break;

        case 0xB1:      /* LDA ind,Y */
            EA_IND_Y;
            emul->A = emul6502_load_byte(emul, ea);
            UPDATE_NZ(emul->A);
            CYCLES(5);
            break;

        case 0xB2:      /* LDA (zpg) */
            MCU_65C02;
            EA_IND_ZPG;
            emul->A = emul6502_load_byte(emul, ea);
            UPDATE_NZ(emul->A);
            CYCLES(5);
            break;

        case 0xB4:      /* LDY zpg,X */
            EA_ZPG_X;
            emul->Y = emul6502_load_byte(emul, ea);
            UPDATE_NZ(emul->Y);
            CYCLES(4);
            break;

        case 0xB5:      /* LDA zpg,X */
            EA_ZPG_X;
            emul->A = emul6502_load_byte(emul, ea);
            UPDATE_NZ(emul->A);
            CYCLES(4);
            break;

        case 0xB6:      /* LDX zpg,Y */
            EA_ZPG_Y;
            emul->X = emul6502_load_byte(emul, ea);
            UPDATE_NZ(emul->X);
            CYCLES(4);
            break;

        case 0xB7:      /* SMB3 zpg */
            MCU_WDC65C02;
            EA_ZPG;
            emul6502_smb(emul, ea, 3);
            CYCLES(5);
            break;

        case 0xB8:      /* CLV */
            emul->P &= ~P_V;
            CYCLES(2);
            break;

        case 0xB9:      /* LDA abs,Y */
            EA_ABS_Y;
            emul->A = emul6502_load_byte(emul, ea);
            UPDATE_NZ(emul->A);
            CYCLES(4);
            break;

        case 0xBA:      /* TSX */
            emul->X = emul->S;
            UPDATE_NZ(emul->X);
            CYCLES(2);
            break;

        case 0xBC:      /* LDY abs,X */
            EA_ABS_X;
            emul->Y = emul6502_load_byte(emul, ea);
            UPDATE_NZ(emul->Y);
            CYCLES(4);
            break;

        case 0xBD:      /* LDA abs,X */
            EA_ABS_X;
            emul->A = emul6502_load_byte(emul, ea);
            UPDATE_NZ(emul->A);
            CYCLES(4);
            break;

        case 0xBE:      /* LDX abs,Y */
            EA_ABS_Y;
            emul->X = emul6502_load_byte(emul, ea);
            UPDATE_NZ(emul->X);
            CYCLES(4);
            break;

        case 0xBF:      /* BBS3 zpg,rel */
            MCU_WDC65C02;
            EA_ZPG;
            emul6502_bbrs(emul, (emul6502_load_byte(emul, ea) & 0x08) != 0);
            break;

        case 0xC0:      /* CPY imm */
            GETIMM;
            emul6502_compare(emul, emul->Y, imm);
            CYCLES(2);
            break;

        case 0xC1:      /* CMP X,ind */
            EA_X_IND;
            emul6502_compare(emul, emul->A, emul6502_load_byte(emul, ea));
            CYCLES(6);
            break;

        case 0xC4:      /* CPY zpg */
            EA_ZPG;
            emul6502_compare(emul, emul->Y, emul6502_load_byte(emul, ea));
            CYCLES(3);
            break;

        case 0xC5:      /* CMP zpg */
            EA_ZPG;
            emul6502_compare(emul, emul->A, emul6502_load_byte(emul, ea));
            CYCLES(3);
            break;

        case 0xC6:      /* DEC zpg */
            EA_ZPG;
            imm = emul6502_load_byte(emul, ea) - 1;
            emul6502_store_byte(emul, ea, imm);
            UPDATE_NZ(imm);
            CYCLES(5);
            break;

        case 0xC7:      /* SMB4 zpg */
            MCU_WDC65C02;
            EA_ZPG;
            emul6502_smb(emul, ea, 4);
            CYCLES(5);
            break;

        case 0xC8:      /* INY */
            emul->Y = emul->Y + 1;
            UPDATE_NZ(emul->Y);
            CYCLES(2);
            break;

        case 0xC9:      /* CMP imm */
            GETIMM;
            emul6502_compare(emul, emul->A, imm);
            CYCLES(2);
            break;

        case 0xCA:      /* DEX */
            emul->X = emul->X - 1;
            UPDATE_NZ(emul->X);
            CYCLES(2);
            break;

        case 0xCB:      /* WAI */
            /* Wait for interrupt - does nothing in this implementation */
            MCU_WDC65C02;
            CYCLES(2);
            break;

        case 0xCC:      /* CPY abs */
            EA_ABS;
            emul6502_compare(emul, emul->Y, emul6502_load_byte(emul, ea));
            CYCLES(4);
            break;

        case 0xCD:      /* CMP abs */
            EA_ABS;
            emul6502_compare(emul, emul->A, emul6502_load_byte(emul, ea));
            CYCLES(4);
            break;

        case 0xCE:      /* DEC abs */
            EA_ABS;
            imm = emul6502_load_byte(emul, ea) - 1;
            emul6502_store_byte(emul, ea, imm);
            UPDATE_NZ(imm);
            CYCLES(6);
            break;

        case 0xCF:      /* BBS4 zpg,rel */
            MCU_WDC65C02;
            EA_ZPG;
            emul6502_bbrs(emul, (emul6502_load_byte(emul, ea) & 0x10) != 0);
            break;

        case 0xD0:      /* BNE rel */
            emul6502_branch(emul, (emul->P & P_Z) == 0);
            break;

        case 0xD1:      /* CMP ind,Y */
            EA_IND_Y;
            emul6502_compare(emul, emul->A, emul6502_load_byte(emul, ea));
            CYCLES(5);
            break;

        case 0xD2:      /* CMP (zpg) */
            EA_IND_ZPG;
            emul6502_compare(emul, emul->A, emul6502_load_byte(emul, ea));
            CYCLES(5);
            break;

        case 0xD5:      /* CMP zpg,X */
            EA_ZPG_X;
            emul6502_compare(emul, emul->A, emul6502_load_byte(emul, ea));
            CYCLES(4);
            break;

        case 0xD6:      /* DEC zpg,X */
            EA_ZPG_X;
            imm = emul6502_load_byte(emul, ea) - 1;
            emul6502_store_byte(emul, ea, imm);
            UPDATE_NZ(imm);
            CYCLES(6);
            break;

        case 0xD7:      /* SMB5 zpg */
            MCU_WDC65C02;
            EA_ZPG;
            emul6502_smb(emul, ea, 5);
            CYCLES(5);
            break;

        case 0xD8:      /* CLD */
            emul->P &= ~P_D;
            CYCLES(2);
            break;

        case 0xD9:      /* CMP abs,Y */
            EA_ABS_Y;
            emul6502_compare(emul, emul->A, emul6502_load_byte(emul, ea));
            CYCLES(4);
            break;

        case 0xDA:      /* PHX */
            MCU_65C02;
            emul6502_push_byte(emul, emul->X);
            CYCLES(3);
            break;

        case 0xDB:      /* STP */
            /* Stop the processor - does nothing in this implementation */
            MCU_WDC65C02;
            CYCLES(2);
            break;

        case 0xDD:      /* CMP abs,X */
            EA_ABS_X;
            emul6502_compare(emul, emul->A, emul6502_load_byte(emul, ea));
            CYCLES(4);
            break;

        case 0xDE:      /* DEC abs,X */
            EA_ABS_X;
            imm = emul6502_load_byte(emul, ea) - 1;
            emul6502_store_byte(emul, ea, imm);
            UPDATE_NZ(imm);
            CYCLES(7);
            break;

        case 0xDF:      /* BBS5 zpg,rel */
            MCU_WDC65C02;
            EA_ZPG;
            emul6502_bbrs(emul, (emul6502_load_byte(emul, ea) & 0x20) != 0);
            break;

        case 0xE0:      /* CPX imm */
            GETIMM;
            emul6502_compare(emul, emul->X, imm);
            CYCLES(2);
            break;

        case 0xE1:      /* SBC X,ind */
            EA_X_IND;
            emul6502_sbc(emul, emul6502_load_byte(emul, ea));
            CYCLES(6);
            break;

        case 0xE4:      /* CPX zpg */
            EA_ZPG;
            emul6502_compare(emul, emul->X, emul6502_load_byte(emul, ea));
            CYCLES(3);
            break;

        case 0xE5:      /* SBC zpg */
            EA_ZPG;
            emul6502_sbc(emul, emul6502_load_byte(emul, ea));
            CYCLES(3);
            break;

        case 0xE6:      /* INC zpg */
            EA_ZPG;
            imm = emul6502_load_byte(emul, ea) + 1;
            emul6502_store_byte(emul, ea, imm);
            UPDATE_NZ(imm);
            CYCLES(5);
            break;

        case 0xE7:      /* SMB6 zpg */
            MCU_WDC65C02;
            EA_ZPG;
            emul6502_smb(emul, ea, 6);
            CYCLES(5);
            break;

        case 0xE8:      /* INX */
            emul->X = emul->X + 1;
            UPDATE_NZ(emul->X);
            CYCLES(2);
            break;

        case 0xE9:      /* SBC imm */
            GETIMM;
            emul6502_sbc(emul, imm);
            CYCLES(2);
            break;

        case 0xEA:      /* NOP */
            CYCLES(2);
            break;

        case 0xEC:      /* CPX abs */
            EA_ABS;
            emul6502_compare(emul, emul->X, emul6502_load_byte(emul, ea));
            CYCLES(4);
            break;

        case 0xED:      /* SBC abs */
            EA_ABS;
            emul6502_sbc(emul, emul6502_load_byte(emul, ea));
            CYCLES(4);
            break;

        case 0xEE:      /* INC abs */
            EA_ABS;
            imm = emul6502_load_byte(emul, ea) + 1;
            emul6502_store_byte(emul, ea, imm);
            UPDATE_NZ(imm);
            CYCLES(6);
            break;

        case 0xEF:      /* BBS6 zpg,rel */
            MCU_WDC65C02;
            EA_ZPG;
            emul6502_bbrs(emul, (emul6502_load_byte(emul, ea) & 0x40) != 0);
            break;

        case 0xF0:      /* BEQ rel */
            emul6502_branch(emul, (emul->P & P_Z) != 0);
            break;

        case 0xF1:      /* SBC ind,Y */
            EA_IND_Y;
            emul6502_sbc(emul, emul6502_load_byte(emul, ea));
            CYCLES(5);
            break;

        case 0xF2:      /* SBC (zpg) */
            MCU_65C02;
            EA_IND_ZPG;
            emul6502_sbc(emul, emul6502_load_byte(emul, ea));
            CYCLES(5);
            break;

        case 0xF5:      /* SBC zpg,X */
            EA_ZPG_X;
            emul6502_sbc(emul, emul6502_load_byte(emul, ea));
            CYCLES(4);
            break;

        case 0xF6:      /* INC zpg,X */
            EA_ZPG_Y;
            imm = emul6502_load_byte(emul, ea) + 1;
            emul6502_store_byte(emul, ea, imm);
            UPDATE_NZ(imm);
            CYCLES(6);
            break;

        case 0xF7:      /* SMB7 zpg */
            MCU_WDC65C02;
            EA_ZPG;
            emul6502_smb(emul, ea, 7);
            CYCLES(5);
            break;

        case 0xF8:      /* SED */
            emul->P |= P_D;
            CYCLES(2);
            break;

        case 0xF9:      /* SBC abs,Y */
            EA_ABS_Y;
            emul6502_sbc(emul, emul6502_load_byte(emul, ea));
            CYCLES(4);
            break;

        case 0xFA:      /* PLX */
            MCU_65C02;
            emul->X = emul6502_pop_byte(emul);
            UPDATE_NZ(emul->X);
            CYCLES(4);
            break;

        case 0xFD:      /* SBC abs,X */
            EA_ABS_X;
            emul6502_sbc(emul, emul6502_load_byte(emul, ea));
            CYCLES(4);
            break;

        case 0xFE:      /* INC abs,X */
            EA_ABS_X;
            imm = emul6502_load_byte(emul, ea) + 1;
            emul6502_store_byte(emul, ea, imm);
            UPDATE_NZ(imm);
            CYCLES(7);
            break;

        case 0xFF:      /* BBS7 zpg,rel */
            MCU_WDC65C02;
            EA_ZPG;
            emul6502_bbrs(emul, (emul6502_load_byte(emul, ea) & 0x80) != 0);
            break;

        default:
            /* Illegal instruction */
            emul->error = ERR_ILLEGAL;
            break;
        }
        ++(emul->PC);
        if (emul->error != ERR_NONE) {
            /* CPU error has occurred.  Force a BREAK at the original PC */
            emul->error = 0;
            emul->PC = start;
            emul6502_break(emul);
        }
        if (emul->do_break) {
            /* System level BREAK has been requested */
            emul->do_break = 0;
            emul6502_break(emul);
        }
    }
}

int emul6502_load_rom_file(emul6502_t *emul, const char *filename)
{
    FILE *file;
    long size;
    if ((file = fopen(filename, "rb")) == NULL) {
        return 0;
    }
    if (fseek(file, 0, SEEK_END) < 0) {
        fclose(file);
        return 0;
    }
    size = ftell(file);
    if (fseek(file, 0, SEEK_SET) < 0) {
        fclose(file);
        return 0;
    }
    if (size > (2 * ROMSZ)) {
        errno = E2BIG;
        return 0;
    }
    /* Split the ROM file in half for CPU1 and CPU2 */
    fread(emul->mem->memory + (size_t)(MEMSZ - size / 2), 1, size / 2, file);
    fread(emul->mem->rom_alt + (size_t)(ROMSZ - size / 2), 1, size / 2, file);
    fclose(file);
    return 1;
}
