
COMMON_DIR = ../common

VASM = vasm6502_oldstyle
VASM_OPTIONS = -quiet -c02 -dotdir -Fbin -I. -I$(COMMON_DIR)

NAME = monitor
TARGET = $(NAME).rom
TARGET_CPU1 = $(NAME)_cpu1.bin
TARGET_CPU2 = $(NAME)_cpu2.bin
TARGET_CPU1_LIST = $(NAME)_cpu1.lst
TARGET_CPU2_LIST = $(NAME)_cpu2.lst

SOURCE_DEPS = \
	ascii.s \
	assembler.s \
	disassembler.s \
	escapes.s \
	help.s \
	memmap.s \
	monitor.s \
	opcodes-6502.s \
	opcodes-65c02.s \
	opcodes.s \
	tracing.s \
	tty.s \
	zeropage.s

all: $(TARGET)

$(TARGET): $(TARGET_CPU1) $(TARGET_CPU2)
	cat $(TARGET_CPU1) $(TARGET_CPU2) >$(TARGET)

$(TARGET_CPU1): main.s $(COMMON_DIR)/bios.s $(SOURCE_DEPS)
	$(VASM) $(VASM_OPTIONS) -DCPU1=1 -DCPU2=0 -L $(TARGET_CPU1_LIST) -o $(TARGET_CPU1) main.s

$(TARGET_CPU2): main.s $(COMMON_DIR)/bios.s $(SOURCE_DEPS)
	$(VASM) $(VASM_OPTIONS) -DCPU1=0 -DCPU2=1 -L $(TARGET_CPU2_LIST) -o $(TARGET_CPU2) main.s

clean:
	rm -f $(TARGET) $(TARGET_CPU1) $(TARGET_CPU2) $(TARGET_CPU1_LIST) $(TARGET_CPU2_LIST)
