
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

ADC_to_PB:
	orl	P1M1, #0b10100010
	anl	P1M2, #0b01011101
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

	setb upf 
	setb dnf
	setb select_flag
	setb startstop_flag
	setb conf_flag

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
	clr startstop_flag
	ret

; ------------------------------------
; ------------------------------------
; ------------------------------------


	; Check PB3
ADC_to_PB_L3:
	clr c
	mov a, ADCRH
	subb a, #0x70
	jc ADC_to_PB_L2
	clr PB3
	clr conf_flag
	ret

	; Check PB2
ADC_to_PB_L2:
	clr c
	mov a, ADCRH
	subb a, #0x50
	jc ADC_to_PB_L1
	clr PB2
	clr select_flag
	ret

	; Check PB1
ADC_to_PB_L1:
	clr c
	mov a, ADCRH
	subb a, #0x30
	jc ADC_to_PB_L0
	clr PB1
	clr dnf
	ret

	; Check PB0
ADC_to_PB_L0:		
	clr c
	mov a, ADCRH
	subb a, #0x10
	jc ADC_to_PB_Done
	clr PB0
	clr upf
	ret
	
ADC_to_PB_Done:
	; No pusbutton pressed	
	ret





Display_PushButtons_ADC:
	Set_Cursor(2, 1)
	; mov a, #'0'
	; mov c, PB7
	; addc a, #0
    ; lcall ?WriteData	
	; mov a, #'0'
	; mov c, PB6
	; addc a, #0
    ; lcall ?WriteData	
	; mov a, #'0'
	; mov c, PB5
	; addc a, #0
    ; lcall ?WriteData	
	; mov a, #'0'
	; mov c, PB4
	; addc a, #0
    ; lcall ?WriteData	
	mov a, #'0'
	mov c, PB3
	addc a, #0
    lcall ?WriteData	
	mov a, #'0'
	mov c, PB2
	addc a, #0
    lcall ?WriteData	
	mov a, #'0'
	mov c, PB1
	addc a, #0
    lcall ?WriteData	
	mov a, #'0'
	mov c, PB0
	addc a, #0
    lcall ?WriteData	
	ret



Display_Bflags:
	Set_Cursor(1,4)
	Display_Bit(upf)
	Set_Cursor(1,3)
	Display_Bit(dnf)
	Set_Cursor(1,2)
	Display_Bit(select_flag)
	Set_Cursor(1,1)
	Display_Bit(conf_flag)

	Set_Cursor(1,8)
	Display_Bit(half_s_flag)
	Set_Cursor(1,10)
	mov lcd_bin, count10ms
	lcall DisplayByte


	ret

$LIST