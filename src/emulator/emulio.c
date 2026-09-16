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
 * Locations in the I/O space between $CF00 and $CFFF.
 */
#define KEYBRD      0x3C7E0 /* Read keyboard data */
#define KEYRAW      0x3C7E1 /* Read raw 8-bit keyboard data. */
#define KEYSTR      0x3C7E2 /* Clear keyboard strobe */
#define SBANK1      0x3C7E3 /* Select memory bank for memory window 0 (0-15) */
#define SBANK2      0x3C7E4 /* Select memory bank for memory window 1 (0-15) */
#define SBANK3      0x3C7E5 /* Select memory bank for memory window 2 (0-15) */
#define SBANK4      0x3C7E6 /* Select memory bank for memory window 3 (0-15) */
#define KEYBRDW     0x3C7E7 /* Read from the keyboard and wait. */
#define KEYBRDT     0x3C7E8 /* Read from the keyboard with a timeout. */
#define KEYTOUT     0x3C7E9 /* Timeout for KEYBRDT (0-255 ms) */
#define TTYOUT      0x3C7EA /* Pass-through to the system tty */
#define SCRNWID     0x3C7EB /* Read actual screen width */
#define SCRNHT      0x3C7EC /* Read actual screen height */
#define MILLIS      0x3C7ED /* Get the system ms tick counter into A:X. */
#define QUITEMUL    0x3C7EE /* Writing to this will quit the emulator */
#define TAPEOPEN    0x3C7EF /* Open the "tape" for reading or writing */
#define TAPECLOSE   0x3C7F0 /* Close the open "tape" */
#define TAPEDATA    0x3C7F1 /* Read or write a byte of "tape" data */

/*
 * File access modes for the kernel.
 */
#define FO_RDONLY   0x00
#define FO_WRONLY   0x01
#define FO_RDWR     0x02
#define FO_APPEND   0x10
#define FO_TRUNC    0x20
#define FO_CREAT    0x40
#define FO_EXCL     0x80
#define FO_ISREAD(mode) \
    (((mode) & 0x03) == FO_RDONLY || ((mode) & 0x03) == FO_RDWR)
#define FO_ISWRITE(mode) \
    (((mode) & 0x03) == FO_WRONLY || ((mode) & 0x03) == FO_RDWR)

/* I/O locations that trigger a software switch but don't have a value */
static int emulio_switch(emul6502_t *emul, uint32_t addr)
{
    (void)emul;
    switch (addr) {
    case KEYSTR:
        /* Keyboard strobe to clear the most-recently received character */
        if (emul->key_push) {
            ++(emul->key_push);
            if (emul->key_push[0] == '\0')
                emul->key_push = 0; /* Done pushing in keys */
        }
        emul->keybuf &= 0x7F;
        break;

    default:
        /* Allow anything else in the I/O space but ignore */
        if (addr >= 0x3C000 && addr <= 0x3C3FF)
            return 1;
        return 0;
    }
    return 1;
}

/* Get the file descriptor for read/write operations from A:X */
static int emulio_get_fd(emul6502_t *emul)
{
    return emul->A | (((int)(emul->X)) << 8);
}

uint8_t emulio_load_byte(emul6502_t *emul, uint32_t addr)
{
    int ch;
    switch (addr) {
    case KEYBRD:
        /* Read from the keyboard.  MSB is set for a pressed key,
         * and then cleared by KEYSTR when the key is handled. */
        if (emul->key_push) {
            /* Return the next pushed-in character */
            ch = emul->key_push[0] & 0xFF;
            emul->keybuf = ch | 0x80;
            emul->keyraw = ch;
        } else if ((emul->keybuf & 0x80) == 0) {
            /* We don't have a key in the buffer, so poll for one */
            ch = emulio_tty_in(emul, 0);
            if (ch >= 0) {
                emul->keybuf = ch | 0x80;
                emul->keyraw = ch;
            }
        }
        return emul->keybuf;

    case KEYRAW:
        /* Read the last raw byte that arrived at the keyboard */
        return emul->keyraw;

    case KEYBRDW:
    case KEYBRDT:
        /* This is an extension to avoid hard-locked keyboard polling loops.
         * Waits for a key to be pressed on the keyboard and returns it.
         * Automatically invokes the key strobe when the key arrives. */
        if ((emul->keybuf & 0x80) != 0) {
            /* We already have a key in the buffer, so return that */
            uint8_t key = emul->keybuf;
            emul->keybuf &= 0x7F;
            return key;
        } else if (emul->key_push) {
            /* We are pushing keys into the keyboard buffer at startup */
            ch = emul->key_push[0] & 0xFF;
            ++(emul->key_push);
            if (emul->key_push[0] == '\0')
                emul->key_push = 0; /* Done pushing in keys */
            emul->keybuf = ch & 0x7F;
            emul->keyraw = ch;
            return ch | 0x80;
        } else {
            /* Wait for the key, optionally with a timeout */
            ch = emulio_tty_in
                (emul, (addr == KEYBRDT) ? emul->key_timeout : -1);
            if (ch >= 0) {
                emul->keybuf = ch & 0x7F;
                emul->keyraw = ch;
                return ch | 0x80;
            }
        }
        return emul->keybuf;

    case SCRNWID: {
        /* Get the actual width of the screen */
        struct winsize ws;
        if (ioctl(0, TIOCGWINSZ, &ws) >= 0)
            return ws.ws_col;
        else
            return 80; /* Default to 80 */
        }

    case SCRNHT: {
        /* Get the actual height of the screen */
        struct winsize ws;
        if (ioctl(0, TIOCGWINSZ, &ws) >= 0)
            return ws.ws_row;
        else
            return 25; /* Default to 25 */
        }

    case MILLIS: {
        /* Get the value of the system millisecond tick counter */
        struct timespec tv;
        uint64_t ns;
        uint16_t ms;
        clock_gettime(CLOCK_MONOTONIC, &tv);
        ns = tv.tv_sec * 1000000000L + tv.tv_nsec;
        ms = (uint16_t)(ns / 1000000UL);
        emul->X = ms >> 8; /* Return the high byte in X */
        return (uint8_t)ms;
        }

    case TAPEDATA:
        /* Read data from the open "tape" file */
        if (emulio_get_fd(emul) == 0 &&
                emul->tape != NULL && FO_ISREAD(emul->tape_mode)) {
            int ch = fgetc(emul->tape);
            if (ch < 0) {
                if (feof(emul->tape)) {
                    /* We have reached EOF, so set A:X to -1 */
                    emul->A = 0xFF;
                    emul->X = 0xFF;
                } else {
                    /* An error occurred while reading from the file */
                    emul->A = (-5 & 0xFF); /* -EIO */
                    emul->X = 0xFF;
                }
            } else {
                /* Return the character that was read to the caller */
                emul->A = ch;
                emul->X = 0;
                return ch;
            }
        } else if (emul->tape == NULL) {
            /* File is not open */
            emul->A = (-9 & 0xFF); /* -EBADF */
            emul->X = 0xFF;
        } else {
            /* File is not open for reading */
            emul->A = (-22 & 0xFF); /* -EINVAL */
            emul->X = 0xFF;
        }
        return emul->A;

    default:
        /* Catch-all for software switches that don't have a particular value */
        if (!emulio_switch(emul, addr)) {
            /* Not handled, so read from the ROM's instead */
            return emul->memory[addr];
        }
        break;
    }
    return 0;
}

void emulio_store_byte(emul6502_t *emul, uint32_t addr, uint8_t value)
{
    switch (addr) {
    case KEYBRDW:
        /* Put a key back into the keyboard buffer */
        emul->keybuf = value | 0x80;
        emul->keyraw = value;
        break;

    case SBANK1:
        /* Set the physical page for memory bank 1 */
        emul6502_set_bank(emul, 0, value);
        break;

    case SBANK2:
        /* Set the physical page for memory bank 2 */
        emul6502_set_bank(emul, 1, value);
        break;

    case SBANK3:
        /* Set the physical page for memory bank 3 */
        emul6502_set_bank(emul, 2, value);
        break;

    case SBANK4:
        /* Set the physical page for memory bank 4 */
        emul6502_set_bank(emul, 3, value);
        break;

    case KEYTOUT:
        /* Set the timeout for keyboard polling */
        emul->key_timeout = value;
        break;

    case TTYOUT:
        /* Write to the host system's tty */
        emulio_tty_out(emul, value);
        break;

    case QUITEMUL:
        /* Request to quit the emulator */
        emulio_tty_end(emul);
        exit(value);
        break;

    case TAPEOPEN:
        /* Open the "tape" file for reading or writing */
        if (emulio_tape_open(emul, value)) {
            /* File is open, so return a file descriptor for it in A:X.
             * We only support one file at a time, so it is always zero. */
            emul->A = 0;
            emul->X = 0;
        } else {
            /* File could not be opened, so report -ENOENT (-2) */
            emul->A = (-2 & 0xFF);
            emul->X = 0xFF;
        }
        break;

    case TAPECLOSE:
        /* Close the "tape" file if the file descriptor is 0 */
        if (emulio_get_fd(emul) == 0)
            emulio_tape_close(emul);
        break;

    case TAPEDATA:
        /* Write data to the open "tape" file */
        if (emulio_get_fd(emul) == 0 &&
                emul->tape != NULL && FO_ISWRITE(emul->tape_mode)) {
            if (fputc(value, emul->tape) < 0) {
                /* An error occurred while writing to the tape */
                emul->A = (-5 & 0xFF); /* -EIO */
                emul->X = 0xFF;
            } else {
                /* Byte was written successfully */
                emul->A = 0;
                emul->X = 0;
            }
        } else if (emul->tape == NULL) {
            /* File is not open */
            emul->A = (-9 & 0xFF); /* -EBADF */
            emul->X = 0xFF;
        } else {
            /* File is not open for writing */
            emul->A = (-22 & 0xFF); /* -EINVAL */
            emul->X = 0xFF;
        }
        break;

    default:
        /* Catch-all for software switches */
        if (!emulio_switch(emul, addr)) {
            /* Invalid write to ROM's */
            emul->error = ERR_ACCESS;
        }
        break;
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

int emulio_tape_open(emul6502_t *emul, uint8_t mode)
{
    char filename[256];
    uint32_t addr;
    const char *fmode;
    int len;

    /* Close the file if it is already open */
    emulio_tape_close(emul);

    /* Convert the file mode into a stdio open mode.  We only handle a
     * subset of the full set of POSIX-style file modes at the moment. */
    switch (mode) {
    case FO_RDONLY:
        fmode = "rb";
        break;

    case FO_WRONLY | FO_CREAT:
    case FO_WRONLY:
    case FO_RDWR | FO_CREAT:
    case FO_RDWR:
        fmode = "r+b";
        break;

    case FO_WRONLY | FO_APPEND:
        fmode = "ab";
        break;

    case FO_RDWR | FO_APPEND:
        fmode = "a+b";
        break;

    case FO_WRONLY | FO_CREAT | FO_TRUNC:
        fmode = "wb";
        break;

    default:
        return 0;
    }
    emul->tape_mode = mode;

    /* The address of the filename is in A:X, so copy the data out */
    addr = emul6502_resolve_address
        (emul, (((uint16_t)(emul->X)) << 8) | emul->A);
    for (len = 0; len < 255; ++len, ++addr) {
        char ch = emul6502_load_byte(emul, addr);
        if (ch == '\0')
            break;
        filename[len] = ch;
    }
    filename[len] = '\0';
    if (len == 0) {
        /* No filename supplied, so error out */
        return 0;
    }

    /* Now try to open the file */
    emul->tape = fopen(filename, fmode);
    return emul->tape != NULL;
}

void emulio_tape_close(emul6502_t *emul)
{
    if (emul->tape != NULL) {
        fclose(emul->tape);
        emul->tape = NULL;
    }
}
