
; Compare a command on the command line to a string
;
; This iterates through characters on the command line comparing
; them with the specified string. It is case insensitive. It
; terminates at the first mismatched character, space, '.' or CR.
; If space, '.', or CR are matched the sub routine returns carry
; clear. Otherwise it returns carry set.
;
; Command address:
;    (cmdline),Y
; String address:
;    A - low byte
;    X - high byte
;
; Returns:
;    Carry S - not equal
;    Y - unchanged
;
;    Carry C - equal
;    Old Y in A, (cmdline),Y char after command

.cmp_command
	sty gen_ptr_low    ; Offset in to the command line
	sec
	sbc gen_ptr_low    ; Address address of string to compare
	sta gen_ptr_low    ; to by Y. This is so that the same value
	txa                ; of Y can be used for the offset in to
	sbc #0             ; the compare string and the command line.
	sta gen_ptr_high
	tya
	pha
.cmp_command_2
	lda (cmdline),y
	beq cmp_command_6
	cmp #13	           ; CR
	beq cmp_command_6
	cmp #&20           ; Space
	beq cmp_command_6
	cmp #&2e           ; Can abreviate with a .
	beq cmp_command_7
	and #&df           ; Convert to upper case
.cmp_command_4
	cmp (gen_ptr_low),y
	bne cmp_command_5
	iny                ; If Y loops
	bne cmp_command_2  ; we exit.
.cmp_command_5
	pla
	tay
	sec                ; Match failed
 	rts
.cmp_command_6       ; Check end of command
	lda (gen_ptr_low),y
	bne cmp_command_5
.cmp_command_7
	pla
	clc                ; Matched
	rts
