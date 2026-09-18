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

#include "emul6502.h"
#include "emulio.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <getopt.h>

#define short_options "thc"
static struct option long_options[] = {
    {"tty",             no_argument,        0,  't'},
    {"cycle-counter",   no_argument,        0,  'c'},
    {"help",            no_argument,        0,  '?'},
    {0,                 0,                  0,    0},
};

static void usage(const char *progname);

static emul6502_mem_t mem;  /* Shared memory */
static emul6502_t emul1;    /* Emulator for CPU1 */
static emul6502_t emul2;    /* Emulator for CPU2 */

int main(int argc, char *argv[])
{
    const char *progname = argv[0];
    const char *rom_file = NULL;

    /* Initialize the emulator */
    emul6502_init(&emul1, &mem, 1);
    emul6502_init(&emul2, &mem, 2);

    /* Parse the command-line options */
    for (;;) {
        int opt = getopt_long(argc, argv, short_options, long_options, 0);
        if (opt < 0)
            break;
        switch (opt) {
        case 't':
            emul1.cls = 0;
            emul2.cls = 0;
            break;
        case 'c':
            emul1.cycle_counter = 1;
            emul2.cycle_counter = 1;
            break;
        default:
            usage(progname);
            return 1;
        }
    }
    if (optind >= argc) {
        usage(progname);
        return 1;
    }
    rom_file = argv[optind];

    /* Load the ROM file, half into each CPU */
    if (!emul6502_load_rom_file(&emul1, rom_file)) {
        perror(rom_file);
        return 1;
    }

    /* Initialise the TTY handling on CPU1 */
    emulio_tty_init(&emul1);

    /* Reset the CPU's and start runnning */
    emul6502_reset(&emul1);
    emul6502_reset(&emul2);
    if (emul1.PC < 0xC000 || emul2.PC < 0xC000 ||
            emul6502_load_byte(&emul1, emul6502_resolve_address(&emul1, emul1.PC)) == 0 ||
            emul6502_load_byte(&emul2, emul6502_resolve_address(&emul2, emul2.PC)) == 0) {
        /* PC does not look like a valid reset address */
        emulio_tty_end(&emul1);
        fprintf(stderr, "ROM file does not have a valid reset vector\n");
        return 1;
    }
    for (;;) {
        emul6502_step(&emul1);
        emul6502_step(&emul2);
    }

    /* Shut the system down */
    emulio_tty_end(&emul1);
    return 0;
}

static void usage(const char *progname)
{
    fprintf(stderr, "Usage: %s [options] rom-file\n\n", progname);

    fprintf(stderr, "    --tty, -t\n");
    fprintf(stderr, "        Directly write to the TTY; do not enter alternate screen mode.\n\n");

    fprintf(stderr, "    --cycle-counter, -c\n");
    fprintf(stderr, "        Print the number of CPU cycles whenever a BRK is seen.\n\n");
}
