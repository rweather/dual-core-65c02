
.PHONY: all clean

CFLAGS = -Wall -Wextra -g

OBJECTS = \
	main.o \
	emul6502.o \
	emulio.o
TARGET = emulator

all: $(TARGET)

$(TARGET): $(OBJECTS)
	$(CC) $(LDFLAGS) -o $(TARGET) $(OBJECTS)

main.o: main.c emul6502.h emulio.h
	$(CC) $(CFLAGS) -o main.o -c main.c

emul6502.o: emul6502.c emul6502.h emulio.h
	$(CC) $(CFLAGS) -o emul6502.o -c emul6502.c

emulio.o: emulio.c emul6502.h emulio.h
	$(CC) $(CFLAGS) -o emulio.o -c emulio.c

clean:
	rm -f $(TARGET) $(OBJECTS)
