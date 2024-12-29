$NOLIST 
;ReflowTime
;ReflowTemp
;SoakTime
;SoakTemp
;
cseg 

Soaktxt:    db 'SOAK    ', 0
Peaktxt:    db 'PEAK    ', 0
Reflowtxt:  db 'REFLOW  ', 0         
PreHeattxt: db 'Pre-HEAT', 0       
Coolingtxt: db 'COOLING ', 0
Loadingtxt: db 'LOADING ', 0
Stagetxt:   db 'STAGE   ', 0
Donetxt:    db 'DONE    ', 0
Aborttxt:   db 'ABORT   ', 0

;               1234567890123456
BWelcome1:  db 'Start Selection:', 0
BWelcome2:  db '   Press  [S]   ', 0

; button set texts:
;               1234567890123456
Seltimetxt: db ' seconds  ', 0
Seltemptxt: db ' *C       ', 0
; number bcd: 2-3, 4-5 

Stimetxt:   db 'Set Soak Time   ', 0
Stemptxt:   db 'Set Soak Temp   ', 0
Rtimetxt:   db 'Set Reflow Time ', 0
Rtemptxt:   db 'Set Reflow Temp ', 0

Nexttxt:    db 'Press [S] to set', 0

Conftxt1:   db 'Confirm Settings', 0
Conftxt2:   db '[DOWN]-N  [UP]-Y', 0

Loadingf1:  db '    LOADING     ', 0
Loadingf2:  db '    LOADING.    ', 0
Loadingf3:  db '    LOADING..   ', 0
Loadingf4:  db '    LOADING...  ', 0

Emptytxt:   db '                ', 0
Emptytxt2:  db '        ', 0
Barf1:      db '====            ', 0
Barf2:      db '=======         ', 0
Barf3:      db '===========     ', 0
Barf4:      db '================', 0

; Ovenconst1: db '          t:   s', 0
; Ovenconst2: db 'OV:    C CJ:   C', 0

Display_Oven_Constants:
    Set_Cursor(1,9)
    Display_char(#0x20)
    Display_char(#0x20)
    Display_char(#'t')
    Display_char(#':')
    Set_Cursor(2,1)
    Display_char(#'O')
    Display_char(#'V')
    Display_char(#':')
    Set_Cursor(2,9)
    Display_char(#0x20)
    Display_char(#'C')
    Display_char(#'J')
    Display_char(#':')
    ret

Display_Junction_Readings:
    mov lcd_bin, temp_lm_c
    lcall ?Convert_to_bcd 
    Set_Cursor(2,13)
    mov lcd_test1, lcd_bcd+0 ;;;;; test
    Display_BCD(lcd_bcd+0)
    Set_Cursor(2,15)
    Display_char(#0xDF) ;deg symbol
    Display_char(#'C')

    Set_Cursor(2,3)
    mov lcd_bin, tempc 
    lcall DisplayByte
    mov lcd_test2, lcd_bcd+0 ;;;; test
    Set_Cursor(2,7)
    Display_char(#0xDF)
    Display_char(#'C')
    ret

Display_DegC:
    Display_char(#0xDF)
    Display_char(#'C') 

; /* FUNCTIONS BELOW UPDATES THE LCD */
; *** Called from ISr2, updates every 10 ms ***
; oven_states: 
; 0   go to button fsm    
; 1   Soaktemp stage (temp condition) 
; 2   SoakTime stage (time condition)
; 3   ReflowTemp  (temp condition) 
; 4   ReflowTime  (time condition)
; 5   Cooling stage (temp condition)
; 6   Done state, just to display done after cooling 
; 15  Abort State, display abort message

; button states:
; 0   welcome Screen
; 1   Set SoakTime
; 2   Set SoakTemp 
; 3   Set ReflowTime 
; 4   Set ReflowTemp
; 5   Confirm Screen

; lcall from Main.asm's ISr2
Oven_Display:
    push acc
    push psw
    clr a

; Only lcalls 
    mov a, oven_state       
    ; move the current oven state to the accumulator to compare each  
    ; state and figure out which segment of code to execute
    ; Comparison to oven_state works via cascading over here.
    ; basically check if the oven state matches a specific state.
    ; If it matches, run the code specific for this state. If not,
    ; then keep checking one by one, cascading downwards.
ovs_case0:
    cjne a, #0, ovs_case1   ; jumps to the next state if oven_state != 0
    ; ALL DISPLAY IN THIS STATE HANDLED BY Button_Display
    pop psw 
    pop acc
    ret                     ; returns to caller (ISr2)

; ---- oven_state = 1 (Soak to Temp) ----
; Since the code for the other cases are similar,
; Only this portion will be heavily commented to explain the logic.
ovs_case1:
    cjne a, #1, ovs_case2   ; if oven_state != 1, check the next state
    ; The code that executes below this line (before the ret) 
    ; are for if we have entered the Soak to Temp Stage
    ; (oven_state = 1). The LCD must get displayed
    jnb s2_clk, ovs_ld1   ; this is what enables the switching between the top text
    Set_Cursor(1,1)
    Send_Constant_String(#PreHeattxt)
    sjmp ovs_t1
    ovs_ld1:
    Set_Cursor(1,1)
    Send_Constant_String(#Loadingtxt)
    ovs_t1: ; pos 1, 13
    
    

    lcall Display_Junction_Readings

    lcall Display_Oven_Constants
    Set_Cursor(1,13)
    mov lcd_bin+0, tempc
    lcall DisplayByte

    pop psw 
    pop acc    
    ret

; ---- oven_state = 2 (Soak till Time) ----
ovs_case2:
    cjne a, #2, ovs_case3

    jnb s2_clk, ovs_ld2   
    Set_Cursor(1,1)
    Send_Constant_String(#Soaktxt)
    sjmp ovs_t2
    ovs_ld2:
    Set_Cursor(1,1)
    Send_Constant_String(#Stagetxt)
    ovs_t2: ; pos 1, 13
    Set_Cursor(1,13)
    mov lcd_bin, seconds
    lcall DisplayByte

    lcall Display_Junction_Readings

    lcall Display_Oven_Constants

    pop psw 
    pop acc
    ret

; ---- oven_state = 3 (Reflow to Temp) ----
ovs_case3:
    cjne a, #3, ovs_case4

    lcall Display_Oven_Constants
    jnb s2_clk, ovs_ld3  
    Set_Cursor(1,1)
    Send_Constant_String(#Peaktxt)
    sjmp ovs_t3
    ovs_ld3:
    Set_Cursor(1,1)
    Send_Constant_String(#Loadingtxt)
    ovs_t3: ; pos 1, 13
    Set_Cursor(1,13)
    mov lcd_bin, tempc
    lcall DisplayByte

    lcall Display_Junction_Readings

    lcall Display_Oven_Constants

    pop psw 
    pop acc
    ret

; ---- oven_state = 4 (Reflow till Time) ----
ovs_case4:
    cjne a, #4, ovs_case5
    
    lcall Display_Oven_Constants
    jnb s2_clk, ovs_ld4  
    Set_Cursor(1,1)
    Send_Constant_String(#Reflowtxt)
    sjmp ovs_t4
    ovs_ld4:
    Set_Cursor(1,1)
    Send_Constant_String(#Stagetxt)
    ovs_t4: ; pos 1, 13
    Set_Cursor(1,13)
    mov lcd_bin, seconds
    lcall DisplayByte

    lcall Display_Junction_Readings
    
    lcall Display_Oven_Constants

    pop psw 
    pop acc
    ret

; ---- oven_state = 5 (Cooldown) ----
ovs_case5:
    cjne a, #5, ovs_case6

    lcall Display_Oven_Constants
    jnb s2_clk, ovs_ld5  
    Set_Cursor(1,1)
    Send_Constant_String(#Coolingtxt)
    sjmp ovs_t5
    ovs_ld5:
    Set_Cursor(1,1)
    Send_Constant_String(#Stagetxt)
    ovs_t5: ; pos 1, 13
    Set_Cursor(1,13)
    mov lcd_bin, tempc
    lcall DisplayByte

    lcall Display_Junction_Readings

    lcall Display_Oven_Constants

    pop psw 
    pop acc
    ret

; ---- oven_state = 6 (Done State) ----
ovs_case6:
    cjne a, #6, ovs_case15

    Set_Cursor(1,1)
    Send_Constant_String(#Donetxt)

    pop psw 
    pop acc
    ret

; ---- oven_state = 15 (Abort) ----
ovs_case15:
    cjne a, #15, ovs_t15

    lcall Display_Oven_Constants
    jnb s2_clk, ovs_ld15  
    Send_Constant_String(#Aborttxt)
    sjmp ovs_t15
    ovs_ld15:
    Send_Constant_String(#Stagetxt)
    ovs_t15: 
    
    pop psw 
    pop acc
    ret


; button states:
; 0   welcome Screen
; 1   Set SoakTime
; 2   Set SoakTemp 
; 3   Set ReflowTime 
; 4   Set ReflowTemp
; 5   Confirm Screen

Button_Display:
    clr a
    mov a, button_state
bs0:
    cjne a, #0, bs1

    Set_Cursor(1,1)
    Send_Constant_String(#BWelcome1)
    Set_Cursor(2,1)
    Send_Constant_String(#BWelcome2)
    ret

bs1:
    cjne a, #1, bs2
    
    Set_Cursor(1,1)
    Send_Constant_String(#Stimetxt)
    Set_Cursor(2,7)
    Send_Constant_String(#Seltimetxt)
    Set_Cursor(2,3)
    mov lcd_bin, SoakTime
    lcall DisplayByte
    ret

bs2:
    cjne a, #2, bs3
    
    Set_Cursor(1,1)
    Send_Constant_String(#Stemptxt)
    Set_Cursor(2,7)
    lcall Display_DegC
    Send_Constant_String(#Emptytxt2)
    Set_Cursor(2,3)
    mov lcd_bin, SoakTemp
    lcall DisplayByte
    ret

bs3:
    cjne a, #3, bs4
    
    Set_Cursor(1,1)
    Send_Constant_String(#Rtimetxt)
    Set_Cursor(2,7)
    Send_Constant_String(#Seltimetxt)
    Set_Cursor(2,3)
    mov lcd_bin, ReflowTime
    lcall DisplayByte
    ret

bs4: 
    cjne a, #4, bs5
    
    Set_Cursor(1,1)
    Send_Constant_String(#Rtemptxt)
    Set_Cursor(2,7)
    lcall Display_DegC
    Send_Constant_String(#Emptytxt2)
    Set_Cursor(2,3)
    mov lcd_bin, ReflowTemp
    lcall DisplayByte
    ret 

bs5:
    cjne a, #5, bs6

    Set_Cursor(1,1)
    Send_Constant_String(#Conftxt1)
    Set_Cursor(2,1)
    Send_Constant_String(#Conftxt2)
    ret 

bs6:
    cjne a, #6, bs7
    Set_Cursor(1,1)
    Send_Constant_String(#Loadingf1)
    Set_Cursor(2,1)
    Send_Constant_String(#Barf1)
    ret 
bs7:
    cjne a, #7, bs8
    Set_Cursor(1,1)
    Send_Constant_String(#Loadingf2)
    Set_Cursor(2,1)
    Send_Constant_String(#Barf2)
    ret 
bs8:
    cjne a, #8, bs9
    Set_Cursor(1,1)
    Send_Constant_String(#Loadingf3)
    Set_Cursor(2,1)
    Send_Constant_String(#Barf3)
    ret 
bs9:
    cjne a, #9, bs_done
    Set_Cursor(1,1)
    Send_Constant_String(#Loadingf4)
    Set_Cursor(2,1)
    Send_Constant_String(#Barf4)
    ret 
bs_done:
    ret


; display 2-3 digits of bcd, must preset cursor to pos of ms-digit 
DisplayByte:
	
    ; lcall ?Convert_bin
    ; WriteCommand(#0x14) ; shift cursor right
    ; Display_BCD(lcd_bcd+0)
    ; WriteCommand(#0x10) ; shift cursor left x2
    ; WriteCommand(#0x10)
    ; Display_BCD(lcd_bcd+1)
    ; Display_char(#':')

    lcall ?Convert_to_bcd
    Display_BCD(lcd_bcd+1)
    Display_BCD(lcd_bcd+0)
; check_no_hundreds?:
;     mov a, lcd_bcd+1 
;     cjne a, #0, display_all_dig
;     Display_char(#0x20)
;     Display_char(#0x20)
;     Display_BCD(lcd_bcd+0)
;     ret

; display_all_dig:
;     Display_BCD(lcd_bcd+1)
;     Display_BCD(lcd_bcd+0)
    ; WriteCommand(#0x10) ; shift cursor left x4
    ; WriteCommand(#0x10)
    ; WriteCommand(#0x10)
    ; WriteCommand(#0x10)
    ; Display_char(#0x20)
    ret


?Convert_to_bcd:
    push acc
    push psw
    push AR0
    push AR1
    push AR2

    clr a
    mov R0, a
    mov R1, a
    mov R2, a
    mov lcd_bcd+0, a   ; Clear ones place
    mov lcd_bcd+1, a   ; Clear tens place
    mov r2, #8         ; Loop counter for 8 bits of the binary number

?Convert_to_bcd_L0:
    mov a, lcd_bin     ; Get the binary value to shift
    rlc a              ; Rotate left through carry, preparing to add this bit as LSB
    mov lcd_bin, a     ; Store the shifted binary value back

    ; Double the BCD value, simulating a shift left in binary, but for BCD
    mov r0, #2         ; Counter for doubling both BCD digits
    mov r1, #(lcd_bcd+0) ; Start with the ones place

?Double_BCD:
    mov a, @r1         ; Get the BCD digit
    addc a, @r1        ; Add it to itself, including the carry from the binary shift
    da a               ; Adjust if needed to keep it in BCD
    mov @r1, a         ; Store the result back
    inc r1            ; Move to the next BCD digit
    djnz r0, ?Double_BCD ; Repeat for the next digit

    djnz r2, ?Convert_to_bcd_L0 ; Repeat for all bits of the binary value

    pop AR2
    pop AR1
    pop AR0
    pop psw
    pop acc
    ret


; ?Convert_to_bcd:
; 	push acc
; 	push psw
; 	push AR0
; 	push AR1
; 	push AR2
	
; 	clr a
; 	mov lcd_bcd+0, a 
; 	mov lcd_bcd+1, a
; 	mov r2, #8              ; Loop counter.

; ?Convert_to_bcd_L0:

; 	mov a, lcd_bin          ; shift left
;     rlc a
;     mov lcd_bin, a
; 	mov r0, #2
; 	mov r1, #(lcd_bcd+0)

; ?Double_BCD:
; 	mov a, @r1
;     addc a, @r1
;     da a
;     mov @r1, a
;     inc r1
;     djnz r0, ?Double_BCD

; 	djnz r2, ?Convert_to_bcd_L0

; 	pop AR2
; 	pop AR1
; 	pop AR0
; 	pop psw
; 	pop acc
; 	ret







; ?Convert_to_bcd:
;     push acc 
;     push psw
;     push aR5
    
;     mov lcd_bcd+0, #0 
;     mov lcd_bcd+1, #0

;     mov a, lcd_bin
;     mov b, #10 
;     div ab 
;     mov R5, b           ; store the ones digit
;     mov b, #10      
;     div ab 
;     mov lcd_bcd+1, a    ; store the hundreds digit into nibble 2
;     mov a, b            
;     swap a              ; move the tens digit to nibble 1
;     add a, R5           ; add the ones to nibble 0
;     mov lcd_bcd+0, a    ; finish the bcd conversion

;     pop aR5 
;     pop psw
;     pop acc
;     ret



















$LIST












; display lm335 temp


; display buttons:

; display different settings screens

; pertaining oto state 0
; plesae display the readings
; dispaly yhr modes


; welcome screen

