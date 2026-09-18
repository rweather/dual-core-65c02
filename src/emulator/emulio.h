/*
 * Copyright (C) 2026 Rhys Weatherley
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

#ifndef EMULIO_H
#define EMULIO_H

#include "emul6502.h"

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Loads a byte from I/O memory.
 *
 * @param[in,out] emul Points to the emulator.
 *
 * @return The byte that was loaded.
 *
 * If the I/O address is invalid, then the emulator's "error" state will be set.
 */
uint8_t emulio_load_byte(emul6502_t *emul, uint32_t addr);

/**
 * @brief Stores a byte to I/O memory.
 *
 * @param[in,out] emul Points to the emulator.
 * @param[in] value The byte to be stored.
 *
 * If the I/O address is invalid, then the emulator's "error" state will be set.
 */
void emulio_store_byte(emul6502_t *emul, uint32_t addr, uint8_t value);

/**
 * @brief Initializes the host system's tty.
 *
 * @param[in,out] emul Points to the emulator.
 */
void emulio_tty_init(emul6502_t *emul);

/**
 * @brief Ends access to the host system's tty.
 *
 * @param[in,out] emul Points to the emulator.
 */
void emulio_tty_end(emul6502_t *emul);

/**
 * @brief Writes a character to the host system's tty output.
 *
 * @param[in,out] emul Points to the emulator.
 * @param[in] ch The character to write.
 */
void emulio_tty_out(emul6502_t *emul, uint8_t ch);

/**
 * @brief Wait for a character to be input on the host system's tty.
 *
 * @param[in,out] emul Points to the emulator.
 * @param[in] timeout Timeout in milliseconds, or -1 for infinite.
 *
 * @return The character between 0 and 255, or -1 on timeout.
 */
int emulio_tty_in(emul6502_t *emul, int timeout);

/**
 * @brief Peek at the next character and stuff it into the receive buffer.
 *
 * @param[in,out] emul Points to the emulator.
 */
void emulio_tty_peek(emul6502_t *emul);

#ifdef __cplusplus
}
#endif

#endif
