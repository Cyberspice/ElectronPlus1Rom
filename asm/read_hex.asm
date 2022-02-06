
; Reads a hex value from the command line
;
; Command address:
;    (cmdline),y
;
; Returns:
;    parse_hex_low/high - the value
;    (cmdline),y - next character
;    X - unchanged

.read_hex
	txa
	pha             ; Save X
	lda #0
	sta parse_hex_low
	sta parse_hex_high
.read_hex_2
 	lda (cmdline),y
	jsr conv_hex_digit
	bcc read_hex_3
	pla             ; Restore X
	tax
	clc
	rts             ; Return
.read_hex_3
	pha             ; Save A
	ldx #4
.read_hex_4
	asl parse_hex_low
	rol parse_hex_high
	bcc read_hex_6  ; Overflow?
	pla
	pla             ; Restore X
	tax
	sec
	rts             ; Return
.read_hex_6
	dex
	bne read_hex_4  ; Multiply by 16
	pla             ; Restore A
	ora parse_hex_low
	sta parse_hex_low
	iny
	jmp read_hex_2

; Convert an ASCII hex digit to its value
;
; ASCII hex digit:
;    A - digit
;
; Returns:
;    Carry C - valid ASCII hex
;    A - value
;    Carry S - invalid ASCII hex
;    A - undefined
;
;    X - Unchanged
;    Y - Unchanged

.conv_hex_digit
	sec
	sbc #&30		; Carry will be clear if A < &30
	bcc conv_hex_digit_3
	cmp #&0a                ; Carry will be clear if A < 10
	bcc conv_hex_digit_2
	sbc #&07
.conv_hex_digit_2
	cmp #&10                ; Carry will be clear if A < 16
	rts
.conv_hex_digit_3
	sec
	rts

