
COMMON_DIR = ../../src/common

VASM = vasm6502_oldstyle
VASM_OPTIONS = -quiet -c02 -dotdir -Fbin -I. -I$(COMMON_DIR)

TARGET = $(NAME).rom
TARGET_CPU1 = $(NAME)_cpu1.bin
TARGET_CPU2 = $(NAME)_cpu2.bin

all: $(TARGET)

$(TARGET): $(TARGET_CPU1) $(TARGET_CPU2)
	cat $(TARGET_CPU1) $(TARGET_CPU2) >$(TARGET)

$(TARGET_CPU1): $(NAME).s $(COMMON_DIR)/bios.s
	$(VASM) $(VASM_OPTIONS) -DCPU1=1 -DCPU2=0 -o $(TARGET_CPU1) $(NAME).s

$(TARGET_CPU2): $(NAME).s $(COMMON_DIR)/bios.s
	$(VASM) $(VASM_OPTIONS) -DCPU1=0 -DCPU2=1 -o $(TARGET_CPU2) $(NAME).s

clean:
	rm -f $(TARGET) $(TARGET_CPU1) $(TARGET_CPU2)
