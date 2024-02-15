; PB0: dbit 1
; PB1: dbit 1
; PB2: dbit 1
; PB3: dbit 1
; PB4: dbit 1
; PB5: dbit 1
; PB6: dbit 1
; PB7: dbit 1

$NOLIST
cseg
; JESUS CODE FOR PUSHBUTTON 7
; ; Check PB7
; ADC_to_PB_L7:
; 	clr c
; 	mov a, ADCRH
; 	subb a, #0xf0
; 	jc ADC_to_PB_L6
; 	clr PB7
; 	ret

; should just work straight up?
ADC_to_PB:
	anl ADCCON0, #0xF0
	orl ADCCON0, #0x00 ; Select AIN0
	
	clr ADCF
	setb ADCS   ; ADC start trigger signal
    jnb ADCF, $ ; Wait for conversion complete

	setb PB7
	setb PB6
	setb PB5
	setb PB4
	setb PB3
	setb PB2
	setb PB1
	setb PB0
	
	; Check PB7
;HOW EACH BLOCK WORKS
; value of ADCRH contains the resistance measured by the ADC
; subtract the measured resistance from the expected resistance at that button
ADC_to_PB_L7:
	clr c
	mov a, ADCRH
	subb a, #0xf0
	jc ADC_to_PB_L6
	clr PB7
	ret

	; Check PB6
ADC_to_PB_L6:
	clr c
	mov a, ADCRH
	subb a, #0xd0
	jc ADC_to_PB_L5
	clr PB6
	ret

	; Check PB5
ADC_to_PB_L5:
	clr c
	mov a, ADCRH
	subb a, #0xb0
	jc ADC_to_PB_L4
	clr PB5
	ret

	; Check PB4
ADC_to_PB_L4:
	clr c
	mov a, ADCRH
	subb a, #0x90
	jc ADC_to_PB_L3
	clr PB4
	ret

	; Check PB3
ADC_to_PB_L3:
	clr c
	mov a, ADCRH
	subb a, #0x70
	jc ADC_to_PB_L2
	clr PB3
	ret

	; Check PB2
ADC_to_PB_L2:
	clr c
	mov a, ADCRH
	subb a, #0x50
	jc ADC_to_PB_L1
	clr PB2
	ret

	; Check PB1
ADC_to_PB_L1:
	clr c
	mov a, ADCRH
	subb a, #0x30
	jc ADC_to_PB_L0
	clr PB1
	ret

	; Check PB0
ADC_to_PB_L0:
	clr c
	mov a, ADCRH
	subb a, #0x10
	jc ADC_to_PB_Done
	clr PB0
	ret
	
ADC_to_PB_Done:
	; No pusbutton pressed	
	ret
$LIST