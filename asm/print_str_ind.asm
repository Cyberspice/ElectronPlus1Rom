
; Prints a NUL terminate string that follows the call
;
; String:
;    Directly follow the JSR statement
;
; Returns:
;    X - Unchanged
;    Y - Unchanged
;    A - Undefined

.print_str_ind
	pla
	sta gen_ptr_low
	pla
	sta gen_ptr_high
	tya
	pha
	ldy #1
	jsr print_str_loop
	tya
	clc
	adc gen_ptr_low
	sta gen_ptr_low
	lda gen_ptr_high
	adc #0
	sta gen_ptr_high
	pla
	tay
	lda gen_ptr_high
	pha
	lda gen_ptr_low
	pha
	rts
