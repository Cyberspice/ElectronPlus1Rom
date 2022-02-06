
	ORG &8000

.start
	EQUB 0
	EQUB 0
	EQUB 0
	jmp service

	EQUB &82
	EQUB (copystr - start)
.version
	EQUB 1
.titlestr
	EQUS "Electron Extension Utilities"
	EQUB 0
	EQUS "1.00"
.copystr
	EQUB 0
	EQUS "(C) 2022 Cyberspice"
	EQUB 0

.service
	php
	tax
	cpx #&0a
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
	EQUW    return - 1	   ; #00 - Service handled
	EQUW    return - 1	   ; #01 - Absolute workspace claim
	EQUW    return - 1	   ; #02 - Relative private workspace claim
	EQUW    return - 1	   ; #03 - Auto-boot call
	EQUW    command - 1	   ; #04 - Unrecognised * command
	EQUW    return - 1	   ; #05 - Unknown interrupt
	EQUW    return - 1	   ; #06 - BRK
	EQUW    return - 1	   ; #07 - Unrecognised OSBYTE
	EQUW    return - 1	   ; #08 - Unrecognised OSWORD
	EQUW    help - 1	   ; #09 - Help
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

