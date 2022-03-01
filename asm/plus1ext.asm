
; Print help
;
; This prints help about this ROM on the screen. It skips
; any white space and if it is the end of the line it prints
; the brief help, otherwise it checks the commands on the
; line and displays the appropriate help if they match.
;
; Command address:
;    (cmdline),Y
; Returns:
;    Y - Unchanged

; TODO - Should handle multiple help commands at the same time

.help
	tya              ; Save Y
	pha
	jsr skip_whitespace
	bcs help_3
	ldx #(help_str MOD 256)
	ldy #(help_str DIV 256)
	jsr print_str
.help_ret
	pla
	tay             ; Restore Y
	jmp return
.help_3
	ldx #0
.help_4
	tya             ; Save Y'
	pha
	txa             ; Save X
	pha
	lda help_table,x
	pha             ; Save A
	lda help_table + 1,x
	tax             ; A -> X
	pla             ; Restore A
	bne help_5
	cpx #0
	bne help_5      ; If A and X are 0 then end of table
	pla             ; Throw away X
	pla             ; Throw away Y'
	jmp help_ret
.help_5
	jsr cmp_command ; This command?
	bcc help_6      ; Yes
	pla
	tax             ; Restore X
	inx
	inx             ; X += 2
	pla
	tay             ; Restore Y'
	jmp help_4      ; Next help command
.help_6
	pla
	tax             ; Restore X
	lda help_str_table,x
	pha             ; Save LOW
	lda help_str_table + 1, x
	tay             ; HIGH in to Y
	pla             ; Restore LOW
	tax             ; LOW in to X
	jsr print_str
	pla             ; Throw away Y'
.help_done
	pla
	tay             ; Restore Y
	jmp done

.help_str
	EQUB 13
	EQUS "Expansion 1.00"
	EQUB 13
	EQUS "  ADC/Printer/RS423"
	EQUB 13
	EQUB 13
	EQUS "Extension Utils 1.00"
	EQUB 13
	EQUS "  EXTUTILS"
	EQUB 13
	EQUB "  SRAM"
	EQUB 13
	EQUB 0

.help_sram_cmp_str
	EQUS "SRAM"
	EQUB 0

.help_utils_cmp_str
	EQUS "EXTUTILS"
	EQUB 0

.help_sram
	EQUB 13
	EQUS "Sidewise ROM/RAM commands"
	EQUB 13
	EQUS "  ROMS"
	EQUB 13
	EQUS "  SRLOAD  <filename> <sram address> <id>"
	EQUB 13
	EQUS "  SRREAD  <dest. start> <dest. end> <sram start> <id>"
	EQUB 13
	EQUS "  SRSAVE  <filename> <sram start> <sram end> <id>"
	EQUB 13
	EQUS "  SRWRITE <source start> <source end> <sram start> <id>"
	EQUB 13
	EQUS "End addresses may be replaced by +<length>"
	EQUB 13
	EQUB 0

.help_utils
	EQUB 13
	EQUS "Utility commands"
	EQUB 13
	EQUS "  MDUMP <mem start> <mem end>"
	EQUB 13
	EQUS "End addresses may be replaced by +<length>"
	EQUB 13
	EQUB 0

.help_table
	EQUW help_sram_cmp_str
	EQUW help_utils_cmp_str
	EQUW 0

.help_str_table
	EQUW help_sram
	EQUW help_utils

; Handle the unknown command service entry
;
; This handles an unknown command. cmd_table is a table of
; addresses (LSB first) of NUL terminated command strings and
; cmd_jmp_table is table of addresses of command handler
; functions (LSB first) which are called if the corresponding
; command string matches.
;
; A match causes the appropriate routine to be called and it
; should return by jumping to command_done.
;
; Command address:
;    (cmdline),Y
; Returns:
;    Y - Unchanged

.command
	ldx #0
.command_2
	tya             ; Save Y
	pha
	txa             ; Save X
	pha
	lda cmd_table,x
	pha             ; Save A
	lda cmd_table + 1,x
	tax             ; A -> X
	pla             ; Restore A
	bne command_3
	cpx #0
	beq command_5   ; If A and X are 0 then end of table
.command_3
	jsr cmp_command ; This command?
	bcc command_4   ; Yes
	pla
	tax             ; Restore X
	inx
	inx             ; X += 2
	pla
	tay             ; Restore Y
	jmp command_2   ; Next command
.command_4
	pla
	tax             ; Restore X
	lda cmd_jump_table + 1,x
	pha
	lda cmd_jump_table, x
	pha
	rts             ; Jump to command handler (it must jump back to command_done).
.command_done
	pla
	tay             ; Restore Y
	jmp done        ; Handled command
.command_5
	pla             ; Throw away X
.command_ret
	pla
	tay             ; Restore Y
	jmp return      ; Not handled

; Command strings

.cmd_roms
	EQUS "ROMS"
	EQUB 0

.cmd_mdump
	EQUS "MDUMP"
	EQUB 0

.cmd_srread
	EQUS "SRREAD"
	EQUB 0

.cmd_srwrite
	EQUS "SRWRITE"
	EQUB 0

; Command tables

.cmd_table
	EQUW cmd_roms
	EQUW cmd_mdump
	EQUW cmd_srread
	EQUW cmd_srwrite
	EQUW 0

.cmd_jump_table
	EQUW do_roms - 1
	EQUW do_mdump - 1
	EQUW do_srread - 1
	EQUW do_srwrite - 1
; Commands

; Print out the sideways ROM table highest prioirty first

.do_roms
	lda #ob_var_rom_itable
	ldx #0
	ldy #&FF
	jsr OSBYTE              ; Get the address of the ROM table
	stx temp_ws_low         ; And save it
	sty temp_ws_high
	ldy #16                 ; 16 sideways roms
.do_roms_2
	jsr print_rom_str
	dey                     ; Zero index
	tya
	pha                     ; Save ROM number
	jsr print_hex_digit     ; Print ROM number
	lda #&20                ; Print a space
	jsr OSASCI
; In the Electron basic is at slot 10 and 11 and the keyboard is at
; slots 8 and 9. So skip them and print the Basic string explicitly.
IF _ELECTRON_
	cpy #12
	bcs do_roms_3
	cpy #8
	bcc do_roms_3
	cpy #11
	bne do_roms_6
	jsr print_basic_str
	jmp do_roms_7
ENDIF
.do_roms_3
	lda (temp_ws_low),y     ; Read ROM type byte
	beq do_roms_6           ; 0 means no ROM
	lda #(titlestr MOD 256) ; The address of the ROM title string in the ROM
	sta rom_ptr_low
	lda #(titlestr DIV 256)
	sta rom_ptr_high
 .do_roms_4
	tya
	pha                     ; Save ROM number
	jsr OSRDRM              ; Read character from ROM string
	beq do_roms_5           ; End of string
	cmp #&7F
	beq do_roms_5           ; No deletes or top bit characters
	bcs do_roms_5           ; NUL or DEL or top bit ends string
	jsr OSASCI
	inc rom_ptr_low         ; Next byte
	pla                     ; Restore ROM number
	tay
	jmp do_roms_4
.do_roms_5
	lda #&20                ; Print a space
	jsr OSASCI
	pla                     ; Restore ROM number
	tay
	lda #(version MOD 256)  ; The version byte
	sta rom_ptr_low
	lda #(version DIV 256)
	sta rom_ptr_high
	jsr OSRDRM
	jsr print_hex           ; Print it
	jmp do_roms_7
.do_roms_6
	lda #'?'                ; No ROM
	jsr OSASCI
.do_roms_7
	lda #&0d                ; End of line
	jsr OSASCI
	pla                     ; Restore ROM number
	tay
	bne do_roms_2           ; Next ROM
	jmp command_done

.print_rom_str
	txa
	pha
	tya
	pha
	ldx #(rom_str MOD 256)
	ldy #(rom_str DIV 256)
	jsr print_str
	pla
	tay
	pla
	tax
	rts

.rom_str
	EQUS "ROM "
	EQUB 0

.print_basic_str
	txa
	pha
	tya
	pha
	ldx #(basic_str MOD 256)
	ldy #(basic_str DIV 256)
	jsr print_str
	pla
	tay
	pla
	tax
	rts

.basic_str
	EQUS "Basic"
	EQUB 0

; Jumping off points as further than 128 bytes

.raise_bad_command_j
	jmp raise_bad_command

.raise_illegal_param_j
	jmp raise_illegal_param

; Reads a start and end address from the command line
;
; Command address:
;    (cmdline),Y
;
; Returns:
;    Last char - (cmdline),Y
;    rom_ptr - start
;    gen_count - length

.parse_start_and_len
	jsr skip_whitespace     ; Skip whitespace
	bcc raise_bad_command_j ; Premature end of line
	jsr read_hex            ; Read the start address
	bcs raise_illegal_param_j  ; Overflow - jump to error
	lda (cmdline),y         ; Test following char is whitespace
	beq raise_bad_command_j
	cmp #&20
	beq parse_start_and_len_2
	jmp raise_bad_command_j ; Not whitespace so error
.parse_start_and_len_2
	lda parse_hex_low       ; Store the value in the ROM ptr
	sta rom_ptr_low
	lda parse_hex_high
	sta rom_ptr_high
	jsr skip_whitespace     ; Skip whitespace
	bcc raise_bad_command_j ; Premature end of line
	lda (cmdline),y         ; + means the following value is a length
	cmp #'+'
	pha
	bne parse_start_and_len_3
	iny                     ; Next char
.parse_start_and_len_3
	jsr read_hex            ; Read the end address / length
	bcs raise_illegal_param_j  ; Overflow - jump to error
	pla
	cmp #'+'                ; Is it a length?
	beq parse_start_and_len_4
	sec                     ; Length is end address - start address
	lda parse_hex_low
	sbc rom_ptr_low
	sta parse_hex_low
	lda parse_hex_high
	sbc rom_ptr_high
	sta parse_hex_high
.parse_start_and_len_4
	lda parse_hex_low       ; Store the length
	sta gen_count_low
	lda parse_hex_high
	sta gen_count_high
	rts

; Do the MDUMP command
;
; Rest of command address:
;    (cmdline),Y

.do_mdump
	tya                     ; Save Y
	pha
	lda #ob_current_mode    ; Read current character and mode
	jsr OSBYTE
	tya
	tax                     ; Move the mode, Y, to X
	pla
	tay                     ; Restore Y
	jsr parse_start_and_len
	lda (cmdline),y	        ; Test following char is whitespace
	beq do_mdump_3          ; End of line
	cmp #&0d
	beq do_mdump_3          ; End of line
	cmp #&20
	beq do_mdump_2
	jmp raise_bad_command   ; Not a space so error
.do_mdump_2
	jsr skip_whitespace     ; Skip whitespace
	jmp raise_bad_command   ; More characters is an error
.do_mdump_3
	txa
	asl a
	tax
	lda do_mdump_tbl + 1,x
	pha
	lda do_mdump_tbl,x
	pha
	rts

.do_mdump_tbl
	EQUW mdump_80_col - 1
	EQUW mdump_40_col - 1
	EQUW mdump_40_col - 1
	EQUW mdump_80_col - 1
	EQUW mdump_40_col - 1
	EQUW mdump_40_col - 1
	EQUW mdump_40_col - 1
	EQUW mdump_40_col - 1

.mdump_prt_addr
	lda rom_ptr_high
	jsr print_hex
	lda rom_ptr_low
	jmp print_hex

.mdump_prt_bytes
	lda #&20
	jsr OSASCI
	lda (rom_ptr_low),y
	jsr print_hex
	iny
	dex
	bne mdump_prt_bytes
	rts

.mdump_prt_pad_bytes
	lda #&20
	jsr OSASCI
	jsr OSASCI
	jsr OSASCI
	dex
	bne mdump_prt_pad_bytes
	rts

.mdump_prt_chars
	lda (rom_ptr_low),y
	cmp #&20
	bmi mdump_prt_chars_2
	cmp #&7F
	bcc mdump_prt_chars_3
.mdump_prt_chars_2
	lda #'.'
.mdump_prt_chars_3
	jsr OSASCI
	iny
	dex
	bne mdump_prt_chars
	rts

.mdump_prt_lines
	stx temp_ws_high        ; Bytes per line

; Print a line of the memory dump
.mdump_prt_line
	lda escape_flag
	beq mdump_ptr_line_1    ; No escape
	jmp command_done
.mdump_ptr_line_1
	jsr mdump_prt_addr      ; Print the address
	lda gen_count_high      ; Is there a whole line to print?
	bne mdump_prt_line_2
	ldx gen_count_low       ; Number of bytes remaining
	cpx temp_ws_high        ; Number of bytes per line
	bcs mdump_prt_line_2    ; More than a line, print a whole line

; Print the remainder of the bytes and chars
.mdump_prt_pad_bytes_and_chars
	ldy #0
	jsr mdump_prt_bytes     ; Print the remaining bytes
	sec
	lda temp_ws_high
	sbc gen_count_low       ; How much padding?
	jsr mdump_prt_pad_bytes ; Print the padding bytes to complete the bytes
	lda #&20
	jsr OSASCI
	ldx gen_count_low       ; Number of bytes remaining
	ldy #0
	txa
	jsr mdump_prt_chars     ; Print the remaining chars
	lda #13
	jsr OSASCI
	jmp command_done

; Print a line of bytes and chars
.mdump_prt_line_2
	ldx temp_ws_high
	ldy #0
	jsr mdump_prt_bytes     ; Print the bytes
	lda #&20
	jsr OSASCI
	ldx temp_ws_high
	ldy #0
	jsr mdump_prt_chars     ; Print the chars
	lda #13
	jsr OSASCI

; Update and move to the next line
	clc
	lda rom_ptr_low         ; Address = Address + Bytes per line
	adc temp_ws_high
	sta rom_ptr_low
	lda rom_ptr_high
	adc #0
	sta rom_ptr_high
	sec
	lda gen_count_low       ; Count = Count - Bytes per line
	sbc temp_ws_high
	sta gen_count_low
	lda gen_count_high
	sbc #0
	sta gen_count_high

; Still check as range may be (more than likely)a multiple of bytes per line
	beq mdump_prt_line_3    ; High count is zero
	bpl mdump_prt_line      ; High count is positive
.mdump_prt_line_3
	lda gen_count_low
	bne mdump_prt_line      ; Low count is not zero
	jmp command_done

.mdump_80_col
	ldx #16
	jmp mdump_prt_lines

.mdump_40_col
	ldx #8
	jmp mdump_prt_lines

workspace = stack_start

; Routine that copies a block from main RAM to
; sideways RAM. Do not use directly but copy to
; main RAM first

.copy_block_to_sram_loop
	lda (gen_ptr_low),y
	sta (rom_ptr_low),y
	iny
	dex
	bne copy_block_to_sram_loop
.copy_block_to_sram_loop_end

; Routine that copies a block from sideways RAM to
; main RAM. Do not use directly but copy to main
; RAM first

.copy_block_from_sram_loop
	lda (rom_ptr_low),y
	sta (gen_ptr_low),y
	iny
	dex
	bne copy_block_from_sram_loop
.copy_block_from_sram_loop_end

; Routine that selects a sideways ROM/RAM. Do not use
; directly but copy to main RAM first

.select_rom_lower
IF _ELECTRON_
	lda #&0c
	sta rom_num
	sta ULA_ROM_LATCH
ENDIF
.select_rom_lower_rom_num
	lda #0
	sta rom_num
	sta ULA_ROM_LATCH
.select_rom_lower_end

; Routine that selects a sideways ROM/RAM. Do not use
; directly but copy to main RAM first

.select_rom_upper
.select_rom_upper_rom_num
	lda #&0c
	sta rom_num
	sta ULA_ROM_LATCH
.select_rom_upper_end

; Sub routine that builds the appropriate select rom routine
; for a specific ROM in workspace RAM.

; On the Electron you need to deselect BASIC first if you're
; selecting a ROM in banks below 8. You do this by writing
; the BASIC ROM number to the ULA before selecting the ROM
; you want

.build_select_rom
	ldx #0
	pha
IF _ELECTRON_
	cmp #8
	bcc build_select_rom_3
ENDIF
.build_select_rom_2
	lda select_rom_upper,x
	sta workspace,y
	iny
	inx
	cpx #(select_rom_upper_end - select_rom_upper)
	bne build_select_rom_2
	pla
	sta workspace - (select_rom_upper_end - select_rom_upper_rom_num) + 1,y
	rts
IF _ELECTRON_
.build_select_rom_3
	lda select_rom_lower,x
	sta workspace,y
	iny
	inx
	cpx #(select_rom_lower_end - select_rom_lower)
	bne build_select_rom_3
	pla
	sta workspace - (select_rom_lower_end - select_rom_lower_rom_num) + 1,y
	rts
ENDIF

; Sub routine that builds the copy block to sram routine
; in workspace
;
; A - ROM to select

.build_copy_block_to_sram
	ldy #0
	jsr build_select_rom
	ldx #0
.build_copy_block_to_sram_2
	lda copy_block_to_sram_loop,x
	sta workspace,y
	iny
	inx
	cpx #(copy_block_to_sram_loop_end - copy_block_to_sram_loop)
	bne build_copy_block_to_sram_2
	lda rom_num
	jsr build_select_rom
; and the RTS
	lda #&60
	sta workspace,y
	rts

; Sub routine that builds the copy block from sram routine
; in workspace
;
; A - ROM to select

.build_copy_block_from_sram
	ldy #0
	jsr build_select_rom
	ldx #0
.build_copy_block_from_sram_2
	lda copy_block_from_sram_loop,x
	sta workspace,y
	iny
	inx
	cpx #(copy_block_from_sram_loop_end - copy_block_from_sram_loop)
	bne build_copy_block_from_sram_2
; Basic is already deselected
	ldx #0
.build_copy_block_from_sram_3
	lda select_rom_upper,x
	sta workspace,y
	iny
	inx
	cpx #(select_rom_upper_end - select_rom_upper)
	bne build_copy_block_from_sram_3
	lda rom_num
	sta workspace - (select_rom_upper_end - select_rom_upper) + 1,y
; and the RTS
	lda #&60
	sta workspace,y
	rts

; Do srread and srwrite argument parsing

.parse_sr_args
	jsr parse_start_and_len
	lda rom_ptr_low
	pha
	lda rom_ptr_high
	pha
	lda (cmdline),y
	cmp #&20
	beq parse_sr_args_2
	jmp raise_bad_command
.parse_sr_args_2
	jsr skip_whitespace
	bcs parse_sr_args_3
	jmp raise_bad_command
.parse_sr_args_3
	jsr read_hex
	lda parse_hex_low
	sta rom_ptr_low
	lda parse_hex_high
	sta rom_ptr_high
	bcc parse_sr_args_4
	jmp raise_illegal_param
.parse_sr_args_4
	lda (cmdline),y
	beq parse_sr_args_5
	cmp #&20
	beq parse_sr_args_6
.parse_sr_args_5
	jmp raise_bad_command
.parse_sr_args_6
	jsr skip_whitespace
	bcs parse_sr_args_7
	jmp raise_bad_command
.parse_sr_args_7
	lda (cmdline),y
	jsr conv_hex_digit
	bcc parse_sr_args_8
	jmp raise_illegal_param
.parse_sr_args_8
	pha
	iny
	jsr skip_whitespace
	bcc parse_sr_args_9
	jmp raise_bad_command
.parse_sr_args_9
	pla
	tax
	pla
	sta gen_ptr_high
	pla
	sta gen_ptr_low
	txa
	rts

; Command that reads a block of memory from sideways RAM

.do_srread
	jsr parse_sr_args
	jsr build_copy_block_from_sram
.do_srread_2
	lda gen_count_high
	bne do_srread_4
	ldx gen_count_low
	beq do_srread_3
	ldy #0
	jsr workspace
.do_srread_3
	jmp command_done
.do_srread_4
	ldx #0
	ldy #0
	jsr workspace
	dec gen_count_high
	inc rom_ptr_high
	inc gen_ptr_high
	jmp do_srread_2

; Command that writes a block of memory to sideways RAM

.do_srwrite
	jsr parse_sr_args
	jsr build_copy_block_to_sram
.do_srwrite_2
	lda gen_count_high
	bne do_srwrite_4
	ldx gen_count_low
	beq do_srwrite_3
	ldy #0
	jsr workspace
.do_srwrite_3
	jmp command_done
.do_srwrite_4
	ldx #0
	ldy #0
	jsr workspace
	dec gen_count_high
	inc rom_ptr_high
	inc gen_ptr_high
	jmp do_srwrite_2

