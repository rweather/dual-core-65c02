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

#ifndef EMUL6502_H
#define EMUL6502_H

#include <stdint.h>
#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Bits in the processor status register "P" */
#define P_C         0x01    /**< Carry bit */
#define P_Z         0x02    /**< Zero bit */
#define P_I         0x04    /**< Interrupt disable */
#define P_D         0x08    /**< Decimal mode (ignored by the implementation) */
#define P_B         0x10    /**< BREAK command */
#define P_V         0x40    /**< Overflow */
#define P_N         0x80    /**< Negative */

/** Total size of memory */
#define MEMSZ       65536

/** Size of the ROM at the top of memory */
#define ROMSZ       16384

/** CPU errors that may occur while executing instructions */
#define ERR_NONE    0       /**< No error */
#define ERR_ILLEGAL 1       /**< Illegal instruction */
#define ERR_ACCESS  2       /**< Illegal access to memory location */

/**
 * @brief Memory for the system, split across the CPU's.
 */
typedef struct
{
    /** Memory for the computer, plus an extra 256 bytes so that
     *  addresses like MEM,X can be done safely without a range check */
    uint8_t     memory[MEMSZ + 256];

    /** Alternate ROM image for CPU2 */
    uint8_t     rom_alt[ROMSZ];

} emul6502_mem_t;

/**
 * @brief State of the 6502 emulator.
 *
 * @note This is a very big structure, so don't put it on the stack.
 */
typedef struct
{
    /** Memory for the computer */
    emul6502_mem_t *mem;

    /** Number of the CPU performing the memory access, 1 or 2 */
    int cpu_num;

    /* CPU registers */
    uint8_t     A;      /**< Accumulator */
    uint8_t     X;      /**< X index register */
    uint8_t     Y;      /**< Y index register */
    uint8_t     S;      /**< Stack pointer, relative to 0x0100 in memory */
    uint8_t     P;      /**< Processor status register */
    uint16_t    PC;     /**< Program counter */

    /** Cycle counter */
    uint64_t    cycles;

    /* Other system state */
    uint8_t     error;      /**< CPU error that occurred */
    uint8_t     do_break;   /**< Set 1 to cause a system-level BREAK */
    uint8_t     keybuf;     /**< Keyboard buffer, MSB set means key pressed */
    uint8_t     keyraw;     /**< Keyboard buffer, raw byte for last key */
    uint8_t     key_timeout;/**< Keyboard timeout in milliseconds */
    char       *key_push;   /**< Data to push into the buffer at startup */
    uint8_t     lower;      /**< Non-zero to allow lower case input */
    uint8_t     cycle_counter; /**< Non-zero to use BRK for cycle counting */
    uint8_t     cls;        /**< Non-zero to clear the screen on startup */

    /* Tape file */
    FILE        *tape;      /**< Open tape file, or NULL if closed */
    uint8_t     tape_mode;  /**< Mode that the tape file is open with */

} emul6502_t;

/**
 * @brief Initializes the 6502 emulator.
 *
 * @param[out] emul Points to the emulator to be initialized.
 * @param[in] mem Shared memory object to use.
 * @param[in] cpu_num CPU number, 1 or 2.
 */
void emul6502_init(emul6502_t *emul, emul6502_mem_t *mem, int cpu_num);

/**
 * @brief Perform a reset on a 6502 emulator.
 *
 * @param[in,out] emul Points to the emulator.
 */
void emul6502_reset(emul6502_t *emul);

/**
 * @brief Jump to the main interrupt service routine.
 *
 * @param[in,out] emul Points to the emulator.
 *
 * @return Non-zero if the jump happened, or zero if interrupts are blocked.
 */
int emul6502_irq(emul6502_t *emul);

/**
 * @brief Jump to the NMI interrupt service routine.
 *
 * @param[in,out] emul Points to the emulator.
 */
void emul6502_nmi(emul6502_t *emul);

/**
 * @brief Perform a BREAK and jump to the NMI interrupt service routine.
 *
 * @param[in,out] emul Points to the emulator.
 */
void emul6502_break(emul6502_t *emul);

/**
 * @brief Return from interrupt (RTI instruction).
 *
 * @param[in,out] emul Points to the emulator.
 */
void emul6502_rti(emul6502_t *emul);

/**
 * @brief Return from subroutine (RTS instruction).
 *
 * @param[in,out] emul Points to the emulator.
 */
void emul6502_rts(emul6502_t *emul);

/**
 * @brief Resolves a virtual 16-bit address to a physical address.
 *
 * @param[in] emul Points to the emulator.
 * @param[in] addr Virtual 16-bit address to be resolved.
 *
 * @return The resolved address.
 */
uint32_t emul6502_resolve_address(const emul6502_t *emul, uint16_t addr);

/**
 * @brief Loads a byte from memory.
 *
 * @param[in,out] emul Points to the emulator.
 * @param[in] addr Physical 18-bit address.
 *
 * @return The byte that was loaded.
 *
 * If @a addr corresponds to an I/O address, then the I/O operation
 * will be performed.
 */
uint8_t emul6502_load_byte(emul6502_t *emul, uint32_t addr);

/**
 * @brief Loads a 16-bit word from memory.
 *
 * @param[in,out] emul Points to the emulator.
 * @param[in] addr Physical 18-bit address.
 *
 * @return The word that was loaded.
 *
 * If @a addr corresponds to an I/O address, then the I/O operation
 * will be performed.
 */
uint16_t emul6502_load_word(emul6502_t *emul, uint32_t addr);

/**
 * @brief Loads a 16-bit value from memory and resolve it to physical address.
 *
 * @param[in,out] emul Points to the emulator.
 * @param[in] addr Physical 18-bit address of where to load the value from.
 *
 * @return The physical address for the value that was loaded.
 *
 * If @a addr corresponds to an I/O address, then the I/O operation
 * will be performed.
 */
uint32_t emul6502_load_address(emul6502_t *emul, uint32_t addr);

/**
 * @brief Stores a byte to memory.
 *
 * @param[in,out] emul Points to the emulator.
 * @param[in] addr Physical 18-bit address.
 * @param[in] value The value to be stored.
 *
 * If @a addr corresponds to an I/O address, then the I/O operation
 * will be performed.
 */
void emul6502_store_byte(emul6502_t *emul, uint32_t addr, uint8_t value);

/**
 * @brief Pushes a byte onto the stack.
 *
 * @param[in,out] emul Points to the emulator.
 * @param[in] value The value to be pushed.
 */
void emul6502_push_byte(emul6502_t *emul, uint8_t value);

/**
 * @brief Pushes a word onto the stack.
 *
 * @param[in,out] emul Points to the emulator.
 * @param[in] value The value to be pushed.
 */
void emul6502_push_word(emul6502_t *emul, uint16_t value);

/**
 * @brief Pops a byte off the stack.
 *
 * @param[in,out] emul Points to the emulator.
 *
 * @return The byte that was popped.
 */
uint8_t emul6502_pop_byte(emul6502_t *emul);

/**
 * @brief Pops a word off the stack.
 *
 * @param[in,out] emul Points to the emulator.
 *
 * @return The word that was popped.
 */
uint16_t emul6502_pop_word(emul6502_t *emul);

/**
 * @brief Runs the 6502 emulator.
 *
 * @param[in,out] emul Points to the emulator.
 */
void emul6502_run(emul6502_t *emul);

/**
 * @brief Loads a file into memory and positions it as the main ROM
 * at the top of the 64K memory space.
 *
 * @param[in,out] emul Points to the emulator.
 * @param[in] filename Name of the ROM file to load.
 *
 * @return Non-zero if the file was loaded, zero on error (in errno).
 */
int emul6502_load_rom_file(emul6502_t *emul, const char *filename);

#ifdef __cplusplus
}
#endif

#endif
