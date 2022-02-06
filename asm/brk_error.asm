; Copies an error block in to the bottom of the stack
; and jumps there generating an error.
;
; Error block:
;    X - address low
;    Y - address high
;
; NEVER RETURNS (handled by OS/Language BRK handler)

.brk_error
	stx brk_addr_low
	sty brk_addr_high
	lda #0
	sta stack_start
	tay
.brk_error_2
	lda (brk_addr_low),y
	sta stack_start + 1,y
	beq brk_error_3
	iny
	jmp brk_error_2
.brk_error_3
	jmp stack_start

; Raises a bad command error

.raise_bad_command
  ldx #(bad_command MOD 256)
  ldy #(bad_command DIV 256)
  jmp brk_error

.bad_command
	EQUB &FE
	EQUS "Bad command"
	EQUB 0

; Raises an illegal param error

.raise_illegal_param
  ldx #(illegal_param MOD 256)
  ldy #(illegal_param DIV 256)
  jmp brk_error

.illegal_param
	EQUB &80
	EQUS "Illegal parameter"
	EQUB 0

