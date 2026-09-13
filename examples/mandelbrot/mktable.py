#!/usr/bin/python3
#
# Make the table of jobs for mandelbrot.s
#

import sys

for i in range(0, 23):
    if i == 11:
        y = 0
    else:
        y = float(i) * (2.0 / 22) - 1.0
    z = int(round(y * 65536.0))
    if z < 0:
        z = 4294967296 + z
        space = ''
    else:
        space = ' '
    print('        .dw     MANDEL + %2d*64, %2d, $%04X, $%02X ; y = %s%f' % (i, i+1, int(z % 65536), int(z / 65536) & 255, space, y))
print('        .dw     0, 0, 0, 0')
print('')

# Compute the x increment for points between -2 and +1.
inc = 3.0 / 62
z = int(round(inc * 65536.0))
if z < 0:
    z = 4294967296 + z
print('$%06X' % z)
