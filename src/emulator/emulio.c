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

#include "emulio.h"
#include <sys/ioctl.h>
#include <termios.h>
#include <unistd.h>
#include <poll.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <time.h>

/*
 * Locations in the I/O space between $8000 and $8FFF.
 */
#define INPUT_FLAGS 0x8080  /* Input flags */
#define RS232_RTS   0x8105  /* RTS signal to the RS-232 port */
#define MUTEX_WANT2 0x8106  /* Want the mutex on CPU2 */
#define MUTEX_WANT1 0x8107  /* Want the mutex on CPU1 */
#define ACIA_DATA   0x8410  /* ACIA data register */
#define ACIA_STATUS 0x8411  /* ACIA status register */
#define ACIA_CMD    0x8412  /* ACIA command register */
#define ACIA_CTRL   0x8413  /* ACIA control register */

/*
 * Input flags.
 */
#define FLAG_CTS    0x20    /* CTS signal from the RS-232 port */
#define FLAG_ACQ2   0x40    /* Acquired the mutex on CPU2 */
#define FLAG_ACQ1   0x80    /* Acquired the mutex on CPU1 */

/*
 * I/O flags in the emul6502_mem_t structure.
 */
#define IO_WANT1    0x0001  /* Want the mutex on CPU1 */
#define IO_WANT2    0x0002  /* Want the mutex on CPU2 */
#define IO_ACQ1     0x0004  /* Acquired the mutex on CPU1 */
#define IO_ACQ2     0x0008  /* Acquired the mutex on CPU2 */
#define IO_RTS      0x0010  /* RTS signal is raised, ACIA comms allowed */
#define IO_CTS      0x0020  /* CTS signal is lowered */

/*
 * Memory locations for the serial buffer in CPU1.
 */
#define SER_RD      0x00FC  /* Read pointer */
#define SER_WR      0x00FB  /* Write pointer */
#define SER_BUF     0x0400  /* Serial receive buffer */

uint8_t emulio_load_byte(emul6502_t *emul, uint32_t addr)
{
    uint8_t result = 0;
    switch (addr) {
    case INPUT_FLAGS:
        if (emul->mem->io_flags & IO_ACQ1) {
            result |= FLAG_ACQ1;
        }
        if (emul->mem->io_flags & IO_ACQ2) {
            result |= FLAG_ACQ2;
        }
        if (emul->mem->io_flags & IO_CTS) {
            result |= FLAG_CTS;
        }
#if 0
        if (emul->cpu_num == 1) {
            /* Probably polling for the mutex on CPU1.  If we don't have it,
             * perform a small delay to avoid pegging the host CPU at 100% */
            if (!(emul->mem->io_flags & IO_ACQ1)) {
                usleep(1000);
            }
        } else {
            /* Same, but for CPU2 this time */
            if (!(emul->mem->io_flags & IO_ACQ2)) {
                usleep(1000);
            }
        }
#endif
        return result;

    default: break;
    }
    return 0;
}

void emulio_store_byte(emul6502_t *emul, uint32_t addr, uint8_t value)
{
    switch (addr) {
    case RS232_RTS:
        /* Raise or lower the RTS signal on the RS-232 port */
        if (value & 0x01) {
            emul->mem->io_flags |= IO_RTS;
        } else {
            emul->mem->io_flags &= ~IO_RTS;
        }
        break;

    case MUTEX_WANT1:
        /* CPU1 either wants the mutex or is releasing the mutex */
        if (value & 0x01) {
            emul->mem->io_flags |= IO_WANT1;
            if (!(emul->mem->io_flags & IO_ACQ2)) {
                emul->mem->io_flags |= IO_ACQ1;
            }
        } else {
            emul->mem->io_flags &= ~(IO_WANT1 | IO_ACQ1);
            if (emul->mem->io_flags & IO_WANT2) {
                emul->mem->io_flags |= IO_ACQ2;
            }
        }
        break;

    case MUTEX_WANT2:
        /* CPU2 either wants the mutex or is releasing the mutex */
        if (value & 0x01) {
            emul->mem->io_flags |= IO_WANT2;
            if (!(emul->mem->io_flags & IO_ACQ1)) {
                emul->mem->io_flags |= IO_ACQ2;
            }
        } else {
            emul->mem->io_flags &= ~(IO_WANT2 | IO_ACQ2);
            if (emul->mem->io_flags & IO_WANT1) {
                emul->mem->io_flags |= IO_ACQ1;
            }
        }
        break;

    case ACIA_DATA:
        /* Write to the serial port */
        emulio_tty_out(emul, value);
        break;

    case ACIA_STATUS:
    case ACIA_CMD:
    case ACIA_CTRL:
        /* Ignore ACIA setup as we assume we're running at full speed */
        break;

    default: break;
    }
}

static inline int emulio_tty_write_str(const char *str)
{
    int len = write(1, str, strlen(str));
    tcdrain(1);
    return len;
}

static inline int emulio_tty_write_ch(char ch)
{
    int len = write(1, &ch, 1);
    tcdrain(1);
    return len;
}

static struct termios orig_tio1, orig_tio2;

void emulio_tty_init(emul6502_t *emul)
{
    struct termios tio1, tio2;
    (void)emul;
    cfmakeraw(&orig_tio1);
    cfmakeraw(&orig_tio2);
    if (tcgetattr(0, &tio1) < 0 || tcgetattr(1, &tio2) < 0) {
        fprintf(stderr, "stdin and stdout must be a tty\n");
        exit(1);
    }
    orig_tio1 = tio1;
    orig_tio2 = tio2;
    cfmakeraw(&tio1);
    cfmakeraw(&tio2);
    tcsetattr(0, TCSANOW, &tio1);
    tcsetattr(1, TCSANOW, &tio2);

    /* Do we need to clear the screen at startup? */
    if (emul->cls) {
        /* Enter the alternate screen mode in xterm */
        emulio_tty_write_str("\x1B[?1047h");

        /* Set normal text mode by default and clear the screen */
        emulio_tty_write_str("\x1B[m\x1B[H\x1B[J");
    }
}

void emulio_tty_end(emul6502_t *emul)
{
    /* Return to normal text mode on shutdown */
    emulio_tty_write_str("\x1B[m");
    if (emul->cls) {
        /* Exit from the alternate screen mode */
        emulio_tty_write_str("\x1B[?1047l");
    }
    tcsetattr(0, TCSANOW, &orig_tio1);
    tcsetattr(1, TCSANOW, &orig_tio2);
}

void emulio_tty_out(emul6502_t *emul, uint8_t ch)
{
    (void)emul;
    /* Determine what to do with the character.  The only special
     * one we need to handle is CTRL-L / 0x0C for "clear screen". */
    if (ch == 0x0C)
        emulio_tty_write_str("\x1B[H\x1B[J");
    else
        emulio_tty_write_ch((char)ch);
}

int emulio_tty_in(emul6502_t *emul, int timeout)
{
    for (;;) {
        struct pollfd pfd = {
            .fd = 0,
            .events = POLLIN
        };
        int ret = poll(&pfd, 1, timeout);
        if (ret == 0) {
            return -1;
        } else if (ret > 0) {
            char ch = 0;
            if (read(0, &ch, 1) != 1)
                continue;
            if (ch == 0x11) {
                /* CTRL-Q - quit the emulator */
                emulio_tty_end(emul);
                if (!emul->cls)
                    printf("\n<QUIT>\n");
                exit(0);
            }
            if (ch >= 'a' && ch <= 'z' && !emul->lower) {
                /* Convert lower case to upper case on input */
                ch = ch - 'a' + 'A';
            }
            return ch & 0xFF;
        } else {
            if (errno != EAGAIN && errno != EINTR) {
                emulio_tty_end(emul);
                fprintf(stderr, "I/O failure\n");
                exit(1);
            }
        }
    }
    return -1;
}

void emulio_tty_peek(emul6502_t *emul)
{
    uint8_t write = emul->mem->memory[SER_RD];
    if (emul->mem->memory[SER_RD] == write) {
        /* Serial buffer is empty, so poll for keyboard input */
        int ch = emulio_tty_in(emul, 10);
        if (ch >= 0) {
            emul->mem->memory[SER_BUF + write] = (uint8_t)ch;
            emul->mem->memory[SER_WR] = (uint8_t)(write + 1);
        }
    }
}
