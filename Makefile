
ASM = asm
BUILD = build

ELECTRON = 1
ENHANCED = 1

PLUS1FILES = \
	hw_addresses.asm \
	os_addresses.asm \
	osbytes_ops.asm \
	page0_addresses.asm \
	plus1core.asm

ifeq ($(ENHANCED),1)
PLUS1FILES += \
	page0_addr_ext.asm \
	brk_error.asm \
	print_str.asm \
	print_str_ind.asm \
	print_hex.asm \
	skip_whitespace.asm \
	read_hex.asm \
	cmp_command.asm \
	plus1ext.asm
endif

PLUS1FILES += plus1end.asm

PLUS1EXTFILES = \
	hw_addresses.asm \
	os_addresses.asm \
	osbytes_ops.asm \
	page0_addresses.asm \
	page0_addr_ext.asm \
	plus1extstart.asm \
	brk_error.asm \
	print_str.asm \
	print_str_ind.asm \
	print_hex.asm \
	skip_whitespace.asm \
	read_hex.asm \
	cmp_command.asm \
	plus1ext.asm \
	plus1extend.asm

_PLUS1FILES = $(patsubst %,$(ASM)/%,$(PLUS1FILES))
_PLUS1EXTFILES = $(patsubst %,$(ASM)/%,$(PLUS1EXTFILES))

$(BUILD):
	@mkdir -p build

$(BUILD)/plus1rom.asm: $(_PLUS1FILES)
	cat $^ > $@

$(BUILD)/plus1extrom.asm: $(_PLUS1EXTFILES)
	cat $^ > $@

plus1rom.bin: $(BUILD)/plus1rom.asm
	beebasm -D _ELECTRON_=$(ELECTRON) -D _ENHANCED_=$(ENHANCED) -o $@ -i $< -v -d

plus1ext.bin: $(BUILD)/plus1extrom.asm
	beebasm -D _ELECTRON_=$(ELECTRON) -o $@ -i $< -v -d

clean:
	rm $(BUILD)/*
	rmdir $(BUILD)

all: $(BUILD) plus1rom.bin plus1ext.bin

.PHONY: all clean
