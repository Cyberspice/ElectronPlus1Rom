
ASM = asm
BUILD = build

PLUS1FILES = \
	hw_addresses.asm \
	os_addresses.asm \
	osbytes_ops.asm \
	page0_addresses.asm \
	plus1core.asm

_PLUS1FILES = $(patsubst %,$(ASM)/%,$(PLUS1FILES))

$(BUILD):
	@mkdir -p build

$(BUILD)/plus1rom.asm: $(_PLUS1FILES)
	cat $^  > $@

plus1rom.bin: $(BUILD)/plus1rom.asm
	beebasm -D _ELECTRON_=1 -o $@ -i $< -v -d 

clean:
	rm $(BUILD)/*
	rmdir $(BUILD)

all: $(BUILD) plus1rom.bin

.PHONY: all clean
