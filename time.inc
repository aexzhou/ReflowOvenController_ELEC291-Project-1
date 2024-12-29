$NOLIST
cseg 
; /*** CODE SEGMENT ***/
; /* 1ms DELAY FUNCTIONS */
wait_1ms:
	clr	TR0 ; Stop timer 0
	clr	TF0 ; Clear overflow flag
	mov	TH0, #high(TIMER0_RELOAD_1MS)
	mov	TL0,#low(TIMER0_RELOAD_1MS)
	setb TR0
	jnb	TF0, $ ; Wait for overflow
	ret
waitms:
	lcall wait_1ms
	djnz R7, waitms
	ret
$LIST