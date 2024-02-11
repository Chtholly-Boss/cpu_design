ifndef CROSS_COMPILE
CROSS_COMPILE = mips-linux-gnu-
endif
CC = $(CROSS_COMPILE)as
LD = $(CROSS_COMPILE)ld
OBJCOPY = $(CROSS_COMPILE)objcopy
OBJDUMP = $(CROSS_COMPILE)objdump

OBJECTS = inst_rom.o

export CROSS_COMPILE

# ********************
# Rules of Compilation
# ********************

all: inst_rom.data inst_rom.asm inst_rom.data inst_rom.bin

%.o: %.S
	$(CC) -mips32 $< -o $@

inst_rom.om: ram.ld $(OBJECTS)
	$(LD) -T ram.ld $(OBJECTS) -o $@

inst_rom.bin: inst_rom.om
	$(OBJCOPY) -O binary $< $@

inst_rom.data: inst_rom.bin
	./Bin2Mem.exe -f $< -o $@

inst_rom.asm: inst_rom.om
	$(OBJDUMP) -D $< > $@

clean:
	rm -f *.o *.om *.bin *.data *.asm