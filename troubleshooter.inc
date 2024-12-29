$NOLIST
CSEG
;----------------------------------------------------
; Reads whatever values are in the 4 bytes of Val_test 
; and displays it on bcd. Good for troubleshooting
; Example:
	; mov Val_test+0, mV_offset+0          ; store result in temp_mc (for python)
    ; mov Val_test+1, mV_offset+1		
    ; mov Val_test+2, #0
    ; mov Val_test+3, #0
	; lcall Display_Val
;----------------------------------------------------
Troubleshoot_msg:     db 'hex in Val_test:', 0
Xmsg:				  db 'CURRENT VAL IN X', 0

Display_Val:
	push acc
	push psw
	push AR0
	push AR1
	push AR2
	
	clr a
	mov Val_temp+0, a ; Initialize Val_temp to 00-00-00-00
	mov Val_temp+1, a
	mov Val_temp+2, a
	mov Val_temp+3, a
	mov r2, #32  ; Loop counter.

Display_conv_L0:
	; Shift binary left	
	mov a, Val_test+3
	mov c, acc.7 ; This way Val_test remains unchanged!
	mov r1, #4
	mov r0, #(Val_test+0)
Display_conv_L1:
	mov a, @r0
	rlc a
	mov @r0, a
	inc r0
	djnz r1, Display_conv_L1
    
	; Perform Val_temp + Val_temp + carry using Val_temp arithmetic
	mov r1, #5
	mov r0, #(Val_temp+0)
Display_conv_L2:   
	mov a, @r0
	addc a, @r0
	da a
	mov @r0, a
	inc r0
	djnz r1, Display_conv_L2

	djnz r2, Display_conv_L0

    lcall Display_val2

	pop AR2
	pop AR1
	pop AR0
	pop psw
	pop acc
	ret

Display_val2: 
    Set_Cursor(1, 1)
	Send_Constant_String(#Troubleshoot_msg)
	Set_Cursor(2, 1)
    Display_BCD(Val_temp+3)
    Set_Cursor(2, 3)
    Display_BCD(Val_temp+2)
    Set_Cursor(2, 5)
    Display_BCD(Val_temp+1)
    Set_Cursor(2, 7)
    Display_BCD(Val_temp+0)
	ret

; DISPLAY X

Display_x:
	push acc
	push psw
	push AR0
	push AR1
	push AR2
	
	clr a
	mov Val_temp+0, a ; Initialize Val_temp to 00-00-00-00
	mov Val_temp+1, a
	mov Val_temp+2, a
	mov Val_temp+3, a
	mov r2, #32  ; Loop counter.

Display_x_L0:
	; Shift binary left	
	mov a, x+3
	mov c, acc.7 ; This way Val_test remains unchanged!
	mov r1, #4
	mov r0, #(x+0)
Display_x_L1:
	mov a, @r0
	rlc a
	mov @r0, a
	inc r0
	djnz r1, Display_x_L1
    
	; Perform Val_temp + Val_temp + carry using Val_temp arithmetic
	mov r1, #5
	mov r0, #(Val_temp+0)
Display_x_L2:   
	mov a, @r0
	addc a, @r0
	da a
	mov @r0, a
	inc r0
	djnz r1, Display_x_L2

	djnz r2, Display_x_L0

    lcall Display_x2

	pop AR2
	pop AR1
	pop AR0
	pop psw
	pop acc
	ret

Display_x2: 
    Set_Cursor(1, 1)
	Send_Constant_String(#Xmsg)
	Set_Cursor(2, 1)
    Display_BCD(Val_temp+3)
    Set_Cursor(2, 3)
    Display_BCD(Val_temp+2)
    Set_Cursor(2, 5)
    Display_BCD(Val_temp+1)
    Set_Cursor(2, 7)
    Display_BCD(Val_temp+0)
	ret




Display_Buttons:
	Set_Cursor(1,4)
	Display_Bit(upf)
	Set_Cursor(1,3)
	Display_Bit(dnf)
	Set_Cursor(1,2)
	Display_Bit(select_flag)
	Set_Cursor(1,1)
	Display_Bit(conf_flag)

	Set_Cursor(2,4)
	Display_Bit(PB3)
	Set_Cursor(2,3)
	Display_Bit(PB2)
	Set_Cursor(2,2)
	Display_Bit(PB1)
	Set_Cursor(2,1)
	Display_Bit(PB0)

	ret

$LIST








