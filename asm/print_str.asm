
; Prints a NUL terminated string
;
; String:
;    (gen_ptr_low),y
;
; Returns
;    (gen_ptr_low),y - the NUL char

.print_str_loop
	lda (gen_ptr_low),y
	beq print_str_loop_2
	jsr OSASCI
	iny
	bne print_str_loop   ; If Y loops increment the MSB
	inc gen_ptr_high
	jmp print_str_loop
.print_str_loop_2
	rts

; Prints a NUL byte terminated string
;
; X - low byte of address
; Y - high byte of address
;
; A - unchanged

.print_str
	pha
	lda gen_ptr_low
	pha
	lda gen_ptr_high
	pha
	stx gen_ptr_low
	sty gen_ptr_high
	ldy #0
	jsr print_str_loop
	pla
	sta gen_ptr_high
	pla
	sta gen_ptr_low
	pla
	rts
