
; This is a reverse engineering of the Acorn Electron Plus 1 Expansion
; utility ROM.

; Acorn included the RS423 driver since it made it easier to support
; the serial printer and redirection. The chip the driver is written
; for is the SCN2681 Dual UART with built in clock generation. It was
; to be supplied as a cartridge.

; ROM private space
uart_0d68         = &0d68
uart_0d69         = &0d69
uart_0d6a         = &0d6a
romstb_shad_latch = &0d6b
os_var_start_low  = &0d6c
os_var_start_high = &0d6d
old_insv_ptr_low  = &0d6e
old_insv_ptr_high = &0d6f

	ORG &8000

.start
	jmp lang
	jmp service

	EQUB &c0  ; This should be C2 but the original ROM has it as C0
	EQUB (copystr - start)
.version
	EQUB 0
.titlestr
	EQUS "Electron Expansion"
; Lots of backspace delete characters to erase the title
	EQUD &7f7f7f7f
	EQUD &7f7f7f7f
	EQUD &7f7f7f7f
	EQUD &7f7f7f7f
	EQUW &7f7f
; Up one line (reverse line feed)
	EQUW &0b0b
	EQUB 0
	EQUS "1.00"
.copystr
	EQUB 0
	EQUS "(C)1984 Acorn"
	EQUB 0

; Language entry point
;
; Since this ROM is not a language but this may be seen first it
; selects which ROM should be the language and starts it. It
; completely changes the priority order for the language, looking
; at ROMS 7 to 0 in descring order and then BASIC. This is because
; this is higher than the BASIC ROM and cartridge ROMs should take
; priority over BASIC.

; ROM numbers are:
;
; 0,1   - Cartridge 0
; 2,3   - Cartridge 1
; 4     - Plus 3 ROM
; 5-7   - Further expansion
; 8-9   - Keyboard matrix
; 10    - BASIC duplicate
; 11    - BASIC
; 12    - Plus 1 ROM
; 13    - Cartridge high priority ROM
; 14,15 - Further expansion

.lang
	ldy #ob_var_rom_itable
	jsr read_os_var
IF _NO_BUG_
	stx p0_spare_low
	sty p0_spare_high
ELSE
	stx &00
	sty &01
ENDIF
	ldx p0_rom_num
.lang2
	lda langtbl,x  ; Next ROM to check
	bmi lang4
	tax
	tay
IF _NO_BUG_
	lda (p0_spare_low),y  ; Load ROM type byte
ELSE
	lda (&00),y
ENDIF
	rol a          ; x2
	bpl lang2      ; Not a language, next one.
	lda #ob_enter_lang
	ldy #0
	jsr OSBYTE
.lang3
	jmp lang3      ; loop forever
.langtbl
	EQUB &0b       ; Start with BASIC if X is 0
	EQUB &00
	EQUB &01
	EQUB &02
	EQUB &03
	EQUB &04
	EQUB &05
	EQUB &06
	EQUB &ff       ; Slots 8 and 9 are the keyboard
	EQUB &ff       ;
	EQUB &ff       ; Slot 10 is the BASIC ROM duplicate
	EQUB &0a
	EQUB &07
	EQUB &0c
	EQUB &0d
	EQUB &0e
.lang4
	lda #'?'
	jsr OSWRCH
.lang5
	jmp lang5      ; loop forever

; Service entry point
;
; A jump table is used for all service calls below &16.

.service
	php
	tax
	cpx #&16
	bcs service2
	pha
	asl a
	tax
	lda service_tbl + 1,x
	pha
	lda service_tbl, x
	pha
	rts
.service2
	ldx &F4
	plp
	rts
.service_tbl
	EQUW	return - 1           ; #00 - Service handled
	EQUW	ws_claim - 1         ; #01 - Absolute workspace claim
	EQUW	return - 1           ; #02 - Relative private workspace claim
	EQUW	return - 1           ; #03 - Auto-boot call
IF _ENHANCED_
	EQUW	command - 1          ; #04 - Unrecognised * command
ELSE
	EQUW	return - 1           ; #04 - Unrecognised * command
ENDIF
	EQUW	unknown_int - 1      ; #05 - Unknown interrupt
	EQUW	handle_brk - 1       ; #06 - BRK
	EQUW	unknown_osbyte - 1   ; #07 - Unrecognised OSBYTE
	EQUW	return - 1           ; #08 - Unrecognised OSWORD
	EQUW	help - 1             ; #09 - Help
	EQUW	return - 1           ; #0a - Claim absolute workspace
	EQUW	return - 1           ; #0b - NMI released
	EQUW	return - 1           ; #0c - NMI claim
	EQUW	return - 1           ; #0d - ROM filing system initialise
	EQUW	return - 1           ; #0e - ROM filsing system get byte
	EQUW	vectors_claimed - 1  ; #0f - Vectors claimed
	EQUW	return - 1           ; #10 - Close any *SPOOL or *EXEC files
	EQUW	return - 1           ; #11 - Font implosion/explosion warning
	EQUW	return - 1           ; #12 - Initialise filing system
	EQUW	rs423_buf_ch_ins - 1 ; #13 - Character placed in RS423 buffer (E)
	EQUW	prt_buf_ch_ins - 1   ; #14 - Character placed in printer buffer (E)
	EQUW	poll100hz - 1        ; #15 - 100Hz poll
.return
	ldx &f4
	pla
	plp
	rts
.done
	pla
	lda #0
	plp
	rts

.ws_claim
	tya
	pha
	lda #0
	sta uart_0d68
	sta romstb_shad_latch
	lda #ob_os_var_start
	ldx #0
	ldy #&ff
	jsr OSBYTE
	stx os_var_start_low
	sty os_var_start_high
	ldx #4
	jsr select_adc_chan
	ldy #ob_var_last_break
	jsr read_os_var
	txa
	and #&03
	cmp #&01
	bcc ws_claim2
	ldx #1
	ldy #ob_var_prnt_dest
	jsr write_os_var
	sec
.ws_claim2
	jsr L8464
	pla
	tay
	jmp return

.unknown_int
	lda #2
	bit uart_0d68
	bne unknown_int2
	lda UART_INT_STATUS
	and uart_0d6a
	bmi unknown_int3
	lsr a
	bcs unknown_int5
	lsr a
	bcs unknown_int10
.unknown_int2
	jmp return
.unknown_int3
	lda #4
	bit UART_INPUT_CHG
	bne unknown_int4
	jsr disable_uart_tx_a
.unknown_int4
	jmp done
.unknown_int5
	lda #4
	bit UART_INPUT_PORTS
	bne unknown_int9
	jsr rem_byte_from_uart_tx_buf
	bcc unknown_int6
	ldy #ob_var_prnt_dest
	jsr read_os_var
	cpx #2
	bne unknown_int7
	jsr rem_byte_from_prnt_buf
	pha
	php
	jsr halve_uart_err_evt
	plp
	pla
	bcs unknown_int7
.unknown_int6
	sta UART_TX_REG_A
	ldx #0
	jmp unknown_int8
.unknown_int7
	jsr enable_uart_tx_a
	jsr uart_set_reset_outs
	ldx #&FF
.unknown_int8
	ldy #ob_var_uart_use
	jsr write_os_var
	jmp done
.unknown_int9
	jsr enable_uart_tx_a
	jmp done
.unknown_int10
	ldx UART_RX_REG_A
	lda UART_STATUS_A
	and #&f0
	bne unknown_int12
	txa
	jsr ins_byte_in_uart_rx_buf
	jsr check_uart_rx_buf_space
	bcs unknown_int11
	lda #1
	sta UART_RESET_OUTS
.unknown_int11
	jmp done
.unknown_int12
	txa
	pha
	ldx UART_STATUS_A
	jsr reset_uart_error_a
	pla
	ldy #evt_uart_err
	jsr OSEVEN
	jmp done

.poll100hz
	tya
	pha
	lda #&40
	bit uart_0d68
	beq poll100hz_2
	jsr ins_ptr_ch_3
.poll100hz_2
	lda #&20
	bit uart_0d68
	beq poll100hz_3
	jsr adc_update
.poll100hz_3
	lda #&10
	bit uart_0d68
	beq poll100hz_4
	jsr uart_set_reset_outs
.poll100hz_4
	pla
	tay
	jmp return

.rs423_buf_ch_ins
	jsr disable_uart_tx_a
	jsr uart_set_reset_outs_2
	jmp done

.prt_buf_ch_ins
	tya
	pha
	jsr ins_prt_ch
	pla
	tay
	jmp done

.ins_prt_ch
	ldy #ob_var_prnt_dest
	jsr read_os_var
	cpx #1
	beq ins_ptr_ch_3
	cpx #2
	bne ins_ptr_ch_2
	jsr disable_uart_tx_a
	jsr uart_set_reset_outs_2
.ins_ptr_ch_2
	rts
.ins_ptr_ch_3
	bit ADC_PRT_STATUS
	bmi ins_ptr_ch_6
	jsr rem_byte_from_prnt_buf
	bcs ins_ptr_ch_4
	sta PRINTER
	lda #&40
	jsr L84f1
	clc
	jmp ins_ptr_ch_5
.ins_ptr_ch_4
	lda #&40
	jsr L8505
	sec
.ins_ptr_ch_5
	jmp halve_uart_err_evt
.ins_ptr_ch_6
	lda #&40
	jmp L84f1

.adc_update
	bit ADC_PRT_STATUS
	bvs adc_update_ret
	ldy #ob_var_cur_adc_ch
	jsr read_os_var
	txa
	beq adc_update_ret
	lda #0
	sta adc_conv_lsb - 1,x
	lda ADC
	sta adc_conv_msb - 1,x
	stx adc_conv_last
	ldy #evt_adc_conv
	jsr OSEVEN
	ldx adc_conv_last
	dex
	bne adc_update_2
	ldy #ob_var_max_adc_ch
	jsr read_os_var
	txa
	bne adc_update_2
	lda #&20
	jsr L8505
	jmp adc_update_ret
.adc_update_2
	jsr start_adc_conv
.adc_update_ret
	rts

; Start an ADC conversion

.start_adc_conv
	cpx #5
	bcc start_adc_conv_2
	ldx #4
.start_adc_conv_2
	txa
	pha
	ldy #ob_var_cur_adc_ch
	jsr write_os_var
	pla
	tax
	beq start_adc_conv_ret
	lda adc_conv_table - 1,x
	sta ADC
.start_adc_conv_ret
	rts
.adc_conv_table
	EQUB 4
	EQUB 5
	EQUB 6
	EQUB 7

; Set / reset UART output bit 0 (RTS)

.uart_set_reset_outs
	lda uart_0d6a
	and #2
	beq uart_reset_outs
.uart_set_reset_outs_2
	jsr check_uart_rx_buf_space
	bcs uart_set_outs
.uart_reset_outs
	lda #1
	sta UART_RESET_OUTS
	rts
.uart_set_outs
	lda #1
	sta UART_SET_OUTS
	rts

; Enable/disable the printer port and ADC
;
; *FX163,128,1 - Disable
; *FX163,128,0 - Enable

.plus1_enable
	lda p0_osbyte_x
	cmp #&80
	bne plus1_enable_ret
	ldx p0_osbyte_y
	beq printer_adc_enable
	dex
	beq printer_adc_disable
	dex
	beq plus1_enable_x_2
	dex
	beq plus1_enable_x_3
.plus1_enable_ret
	jmp return
.printer_adc_enable  ; X = 0
	lda uart_0d68
	pha
	and #&fe
	sta uart_0d68
	jsr start_100hz_processing
	jmp plus1_enable_done
.printer_adc_disable  ; X = 1
	lda uart_0d68
	pha
	ora #1
	sta uart_0d68
	jsr stop_100hz_processing
.plus1_enable_done
	pla
	and #1
	sta p0_osbyte_x
	jmp done
.plus1_enable_x_2     ; X = 2
	lda uart_0d68
	and #&fd
	sta uart_0d68
	jmp done
.plus1_enable_x_3     ; X = 3
	lda uart_0d68
	ora #2
	sta uart_0d68
	jmp done

; Read a value from an ADC channel.
;
; X contains the channel. Also maintains the printer buffer
; if the printer is ready for the next byte

.read_adc_return
	jmp return
.read_adc
	lda p0_osbyte_x
	bne read_adc_return
	lda ADC_PRT_STATUS
	pha
	bpl read_adc_2
	jsr ins_prt_ch
.read_adc_2
	pla
	lsr a
	lsr a
	lsr a
	lsr a
	and #3
	eor #3
	sta p0_osbyte_x
	jmp done

; Select an ADC channel
;
; X is the channel

.select_adc
	ldx p0_osbyte_x
	jsr select_adc_chan
	stx p0_osbyte_x
	jmp done

.select_adc_chan
	txa
	beq select_adc_chan_2
	pha
	jsr start_adc_conv
	lda #&20
	jsr L84f1
	pla
.select_adc_chan_2
	tax
	ldy #ob_var_max_adc_ch
	jmp write_os_var

; Force an ADC conversion
;
; X is the channel

.force_adc
	lda #0
	sta adc_conv_last
	ldx p0_osbyte_x
	jsr start_adc_conv
	lda #&20
	jsr L84f1
	jmp done

; Write the ROMSTB latch that is provided by an Electron cartridge.
;
; The nROMSTB line goes low when &FC73 is addresses. This writes to that
; address storing the value writting in the shadow location. It returns
; the old value.
;
; *FX 110, X where X is the latch value

.romstb_rw
	ldx p0_osbyte_x
	lda romstb_shad_latch
	stx romstb_shad_latch
	stx ROMSTB_LATCH
	sta p0_osbyte_x
	jmp done

; Handle the unknown OSBYTE service call

.unknown_osbyte
	lda p0_osbyte_a
	cmp #ob_read_adc
	beq read_adc
	cmp #ob_sel_adc
	beq select_adc
	cmp #ob_force_adc
	beq force_adc
	cmp #ob_set_rx_bps
	beq set_uart_rx_rate
	cmp #ob_set_tx_bps
	beq set_uart_tx_rate
	cmp #ob_set_uart_sts
	beq set_uart_status
	cmp #ob_set_input
	beq set_input_stream
	cmp #ob_romstb_rw
	beq romstb_rw
	cmp #ob_plus1_enable
	bne unknown_osbyte_ret
	jmp plus1_enable
.unknown_osbyte_ret
	jmp return

; Set the UART data rates for RX and TX
;
; *FX 7, X
; *FX 8, X

.set_uart_rx_rate
	lda #&f0
	sta p0_osbyte_y
	jmp set_uart_rate
.set_uart_tx_rate
	lda #&0f
	sta p0_osbyte_y
.set_uart_rate
	ldx p0_osbyte_x
	cpx #&0c
	bcs set_uart_rate_done
	lda p0_osbyte_y
	eor #&ff
	and uart_0d69
	sta p0_osbyte_x
	lda bps_rate_tbl,x
	and p0_osbyte_y
	ora p0_osbyte_x
	sta uart_0d69
	sta UART_CLOCK_A
.set_uart_rate_done
	jmp done

.set_input_stream
	lda p0_osbyte_x
	pha
	and #1
	tax
	ldy #ob_var_input_src
	jsr write_os_var
	pla
	beq L83d6
	lda #1
	sta UART_COMMAND_A
	lda uart_0d6a
	ora #2
	sta uart_0d6a
	sta UART_INT_MASK
	jsr uart_set_reset_outs
	lda #&10
	jsr L84f1
	jmp done

; Set the UART status.
;
; The UART in BBC micros and BBC Masters is a Motorola 6850 however the
; Electron uses a SCN2681 so this emulates the 6850 status register.

.set_uart_status
	lda #&e3
	cmp p0_osbyte_y
	bne L83f7
	bit p0_osbyte_x
	bne set_uart_status_done
	lda p0_osbyte_x
	lsr a
	lsr a
	nop  ; ???
	tax
	jsr reset_uart_mr_a
	lda UART_MODE_A
	and #&e0
	sta p0_osbyte_y
	jsr reset_uart_mr_a
	lda uart_status_tbl,x
	and #&1f
	ora p0_osbyte_y
	sta UART_MODE_A
	lda UART_MODE_A
	and #&f0
	ldy uart_status_tbl,x
	bmi set_uart_status_2
	ora #&0f
.set_uart_status_2
	ora #&07
	sta UART_MODE_A
.set_uart_status_done
	jmp done

.L83d6
	lda #2
	sta UART_COMMAND_A
	jsr reset_uart_chan_a
	jsr reset_uart_error_a
	lda uart_0d6a
	and #&fd
	sta uart_0d6a
	sta UART_INT_MASK
	jsr uart_set_reset_outs
	lda #&10
	jsr L8505
	jmp done

.L83f7
	lda #&9f
	cmp p0_osbyte_y
	bne set_uart_status_done
	bit p0_osbyte_x
	bne set_uart_status_done
	lda p0_osbyte_x
	cmp #&60
	beq L840f
	lda #&70
	sta UART_COMMAND_A
	jmp set_uart_status_done
.L840f
	lda #&64
	sta UART_COMMAND_A
	jmp set_uart_status_done

.bps_rate_tbl
	EQUB &bb  ; 9600
	EQUB &00  ; 150
	EQUB &33  ; 300
	EQUB &44  ; 600
	EQUB &66  ; 1200
	EQUB &88  ; 2400
	EQUB &99  ; 4800
	EQUB &bb  ; 9600
	EQUB &cc  ; 19200
	EQUB &11  ;
	EQUB &55  ;
	EQUB &aa  ;

.uart_status_tbl
	EQUB &02
	EQUB &06
	EQUB &82
	EQUB &86
	EQUB &13
	EQUB &93
	EQUB &83
	EQUB &87

IF NOT(_ENHANCED_)
.help
	tya
	pha
	ldx #0
.help_2
	lda help_str,x
	beq help_3
	jsr OSASCI
	inx
	jmp help_2
.help_3
	pla
	tay
.help_ret
	jmp return
.help_str
	EQUS "Expansion 1.00"
	EQUB 13
	EQUS "  ADC/Printer/RS423"
	EQUB 13
	EQUB 0
ENDIF

.L8464
	jsr reset_uart_mr_a
	lda #&93
	sta UART_MODE_A
	lda #7
	sta UART_MODE_A
	lda #&8f
	sta UART_AUX_CONTROL
	lda uart_0d69
	bcc L847d
	lda #&bb
.L847d
	sta uart_0d69
	sta UART_CLOCK_A
	jsr reset_uart_chan_a
	jsr reset_uart_tx_a
	jsr reset_uart_error_a
	lda #&80
	sta uart_0d6a
	sta UART_INT_MASK
	rts

.reset_uart_chan_a
	lda #&20
	sta UART_COMMAND_A
	rts

.reset_uart_tx_a
	lda #&30
	sta UART_COMMAND_A
	rts

.reset_uart_error_a
	lda #&40
	sta UART_COMMAND_A
	rts

.reset_uart_mr_a
	lda #&10
	sta UART_COMMAND_A
	rts

.disable_uart_tx_a
	lda uart_0d6a
	ora #1
	sta uart_0d6a
	sta UART_INT_MASK
	lda #4
	sta UART_COMMAND_A
	rts

.enable_uart_tx_a
	lda uart_0d6a
	and #&fe
	sta uart_0d6a
	sta UART_INT_MASK
	lda #8
	sta UART_COMMAND_A
	rts

.ins_byte_in_uart_rx_buf
	ldx #1
	jmp (INSV)

.rem_byte_from_uart_tx_buf
	clv
	ldx #2
	jmp (REMV)

.rem_byte_from_prnt_buf
	clv
	ldx #3
	jmp (REMV)

.check_uart_rx_buf_space
	jsr get_uart_rx_buf_space
	cpy #1
	bcs check_uart_rx_buf_space_2
	cpx #9
.check_uart_rx_buf_space_2
	rts

.get_uart_rx_buf_space
	sec
	clv
	ldx #1
	jmp (CNPV)

.L84f1
	ora uart_0d68
	ldx uart_0d68
	sta uart_0d68
	txa
	and #&f0
	bne L8504
.inc_poll_semaphore
	lda #ob_inc_poll_sem
	jsr OSBYTE
.L8504
	rts

.L8505
	tax
	lda #&f0
	bit uart_0d68
	beq L851f
	txa
	eor #&ff
	and uart_0d68
	sta uart_0d68
	and #&f0
	bne L851f
.dec_poll_semaphore
	lda #ob_dec_poll_sem
	jsr OSBYTE
.L851f
	rts

.handle_brk
	lda #1
	bit uart_0d68
	bne handle_brk_2
	lda p0_osbyte_a
	pha
	lda p0_osbyte_x
	pha
	lda p0_osbyte_y
	pha
	jsr start_100hz_processing
	pla
	sta p0_osbyte_y
	pla
	sta p0_osbyte_x
	pla
	sta p0_osbyte_a
.handle_brk_2
	jmp return

.stop_100hz_processing
	pha
	txa
	pha
	tya
	pha
	lda uart_0d68
	bmi stop_100hz_proc_ret
	pha
	ora #&80
	sta uart_0d68
	pla
	beq stop_100hz_proc_ret
	jsr dec_poll_semaphore
	lda #1
	sta UART_STOP_COUNT
.stop_100hz_proc_ret
	pla
	tay
	pla
	tax
	pla
	rts

.start_100hz_processing
	pha
	txa
	pha
	tya
	pha
	lda uart_0d68
	bpl start_100hz_proc_ret
	and #&7f
	sta uart_0d68
	beq start_100hz_proc_ret
	jsr inc_poll_semaphore
	jsr uart_set_reset_outs
.start_100hz_proc_ret
	pla
	tay
	pla
	tax
	pla
	rts

.vectors_claimed
	lda #oa_get_fs_number
	tay
	jsr OSARGS
	cmp #fs_number_rom
	bcs vectors_claimed_ret
	cmp #fs_number_none
	beq vectors_claimed_ret
	lda FILEV
	sta old_insv_ptr_low
	lda FILEV + 1
	sta old_insv_ptr_high
	cmp #&ff
	beq vectors_claimed_ret
	ldy #ob_var_rom_ptable
	jsr read_os_var
	php
	sei
	lda p0_brk_addr_low
	pha
	lda p0_brk_addr_high
	pha
	stx p0_brk_addr_low
	sty p0_brk_addr_high
	ldy #&1b
	sty FILEV
	lda #&ff
	sta FILEV + 1
	lda #(guarded_call_old_insv MOD 256)
	sta (p0_brk_addr_low),y
	iny
	lda #(guarded_call_old_insv DIV 256)
	sta (p0_brk_addr_low),y
	iny
	lda p0_rom_num
	sta (p0_brk_addr_low),y
	pla
	sta p0_brk_addr_high
	pla
	sta p0_brk_addr_low
	plp
.vectors_claimed_ret
	jmp return

.guarded_call_old_insv
	jsr stop_100hz_processing
	jsr call_old_insv
	jmp start_100hz_processing

.call_old_insv
	jmp (old_insv_ptr_low)

; Read/Write a value from the OS variables

; The OS variabls are the values of OSBYTE &a6 to &ff. To read a value
; Y is set to the OSBYTE. os_var_start_low and os_var_start_high are
; populated with the output of OSBYTE &A6 (Read start of OS variables).
; The value returned is set such that the value plus &A6 results in an
; address of &236. I.e. &190 is returned.

; If carry is set then X contains a value to set. If carry is clear
; then the value of the address and the following address are returned
; in X and Y.

.write_os_var
	sec
	bcs rw_os_var_2
.read_os_var
	clc
.rw_os_var_2
	lda p0_brk_addr_low     ; Save the BRK address on the stack
	pha
	lda p0_brk_addr_high
	pha
	lda os_var_start_low
	sta p0_brk_addr_low
	lda os_var_start_high
	sta p0_brk_addr_high
	bcc rw_os_var_3
	txa                  ; Write X in to the var address
	sta (p0_brk_addr_low),y
	bcs rw_os_var_4
.rw_os_var_3                 ; Read two bytes from var address in to X and Y
	lda (p0_brk_addr_low),y
	tax
	iny
	lda (p0_brk_addr_low),y
	tay
.rw_os_var_4
	pla                   ; Restore the BRK address
	sta p0_brk_addr_high
	pla
	sta p0_brk_addr_low
	rts

; Divide RS423 error event by 2

.halve_uart_err_evt
	ror uart_evt_flg
	rts

