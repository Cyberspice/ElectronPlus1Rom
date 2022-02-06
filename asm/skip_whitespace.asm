
; Skip whitespace until end of command line or non whitespace
; character
;
; Command line:
;    (cmdline),y
;
; Returns:
;    Carry S - non whitespace char reached
;    Carry C - end of line
;    (cmdline),y - last character tested
;    X - unchanged

.skip_whitespace
	lda (cmdline),y
	beq skip_whitespace_2
	cmp #&0d
	beq skip_whitespace_2
	cmp #&20
	bne skip_whitespace_3
	iny
	bne skip_whitespace
.skip_whitespace_2
	clc
	rts
.skip_whitespace_3
	sec
	rts
