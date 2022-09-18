
ASM = asm

plus1rom.bin:
	cd asm ; beebasm -i plus1rom.asm -v -d ; cd ..

clean:
	rm plus1rom.bin

all: plus1rom.bin

.PHONY: all clean plus1rom.bin
