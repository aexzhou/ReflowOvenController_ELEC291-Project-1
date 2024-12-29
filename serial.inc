$NOLIST
CSEG
; /* Send a character using the serial port */
putchar:
    jnb TI, putchar
    clr TI
    mov SBUF, a
    ret

; Sends binary data to Python via putchar
Send_Serial:
	push acc
	push psw

	; mov data_out+0, 
    ; mov data_out+1, 
    ; mov data_out+2, 
    ; mov data_out+3, 

	clr A					; Sends temp_mc (4) bytes
	mov a, temp_mc+0
	lcall putchar
	clr A
	mov a, temp_mc+1
	lcall putchar
	clr A
	mov a, temp_mc+2
	lcall putchar
	clr A
	mov a, temp_mc+3
	lcall putchar

	clr A 					; Sends temp_lm (4) (cold junc)
	mov a, temp_lm+0
	lcall putchar
	clr A
	mov a, temp_lm+1
	lcall putchar
	clr A
	mov a, temp_lm+2
	lcall putchar
	clr A
	mov a, temp_lm+3
	lcall putchar

	clr A 
	mov a, tempc			; tempc (this is what the system sees)
	lcall putchar

	clr A 
	mov a, temp_lm_c		; temp_lm_c (this is what the system sees)
	lcall putchar

	clr A					; Oven State (1)
	mov a, oven_state
	lcall putchar

	clr A					; Button State (1)
	mov a, button_state
	lcall putchar

	clr A					; Seconds Elapsed (1)
	mov a, seconds
	lcall putchar

	clr A 					; Oven Parameters (4) Total 
	mov a, SoakTime
	lcall putchar
	clr A 
	mov a, SoakTemp
	lcall putchar
	clr A 
	mov a, ReflowTime
	lcall putchar
	clr A 
	mov a, ReflowTemp
	lcall putchar

	clr A					; Sends data_out (4)
	mov a, Band_Gap_Voltage+0
	lcall putchar
	clr A
	mov a, Band_Gap_Voltage+1
	lcall putchar
	clr A					; Sends data_out
	mov a, #0
	lcall putchar
	clr A
	mov a, #0
	lcall putchar

	clr A					; Another 4 byte out(4)
	mov a, Band_Gap_Value+0
	lcall putchar
	clr A
	mov a, Band_Gap_Value+1
	lcall putchar
	clr A					
	mov a, #0
	lcall putchar
	clr A
	mov a, #0
	lcall putchar


	clr a					;(1)
	mov a, lcd_test1
	lcall putchar

	clr a					;(1)
	mov a, lcd_test2
	lcall putchar	

	clr a					;(2)
	mov a, adc1+0
	lcall putchar	
	clr a				
	mov a, adc1+1
	lcall putchar	

	clr a					;(2)
	mov a, adc2+0
	lcall putchar	
	clr a				
	mov a, adc2+1
	lcall putchar	

	clr a
	clr c
	;mov psw, #0x00
	pop psw
	pop acc
	ret

SendString:
; Send a constant-zero-terminated string using the serial port
    clr A
    movc A, @A+DPTR
    jz SendStringDone
    lcall putchar
    inc DPTR
    sjmp SendString
SendStringDone:
    ret
$LIST
