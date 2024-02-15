$NOLIST
;----------------------------------------------------
; Retrieves Thermocouple mV data stored in APROM 3000H (flash)
; Contains ADC functions
;----------------------------------------------------
CSEG

PAGE_ERASE_AP   EQU 00100010b
BYTE_PROGRAM_AP EQU 00100001b
BYTE_READ_AP    EQU 00000000b
; later add save variable feature for saving reflow parameters from buttons

; to write each line of data to aprom, must unlock ta, read unafected

; reads temp_offset (ds 2), use lktable, puts it in mV_offset (ds 2)

Load_Thermodata:
    push acc
    push AR0
    push AR1
    mov dptr, #0x3000
    
    mov R0, temp_offset+0
    mov R1, temp_offset+1
    clr a
    mov a, R1
    cjne a, #0x00, highval
    ljmp lowval

highval:
    mov dptr, #0x3200
    sjmp lowval

lowval:
    inc dptr
    inc dptr
    djnz R0, lowval         ; traverse until at target index
    clr a
    movc a, @a+dptr         ; extract data
    mov mV_offset+1, a
    inc dptr
    clr a
    movc a, @a+dptr
    mov mV_offset+0, a

    pop AR1
    pop AR0
    pop acc
    ret


ReadNV:
	mov dptr, #0x3f80
	clr a
	movc a, @a+dptr
	mov SoakTime, a
	
	inc dptr
	clr a
	movc a, @a+dptr
	mov SoakTemp, a
	
	inc dptr
	clr a
	movc a, @a+dptr
	mov ReflowTime, a
	
	inc dptr
	clr a
	movc a, @a+dptr
	mov ReflowTemp, a

	ret











; Get_mV:
;     push ACC
;     push AR0
;     push AR1
;     mov a, temp_offset+1
;     cjne a, #0x00, T16start
;     sjmp T0start
    
; T16start:
;     mov dptr, #Table16 
;     sjmp Row_Col
; T0start:
;     mov dptr, #Table0

; Row_Col:
;     mov a, temp_offset+0
;     anl a, #0x0f
;     mov @r0, a              ; col
;     mov a, temp_offset+0
;     anl a, #0xf0
;     swap a
;     mov @r1, a              ; row
;     cjne a, #0x00, Row_sel  ; if row not 0, proceed to select row
;     ljmp Col_check          ; if row 0, go check col
; Row_sel:
;     mov a, dpl 
;     add a, #0x20
;     mov dpl, a
;     jnc Row_sel_dec
;     inc dph 
; Row_sel_dec:
;     djnz r1, Row_sel
; Col_check:                  ; check if col isnt 0 then select col
;     mov a, @r0
;     cjne a, #0x00, Col_sel
;     sjmp Data_sel
; Col_sel:
;     inc dptr
;     inc dptr
;     djnz r0, Col_sel

; Data_sel:
;     mov a, dpl
;     mov mV_offset+0, a
;     inc dptr 
;     mov a, dpl
;     mov mV_offset+1, a
;     pop AR1 
;     pop AR0 
;     pop ACC
;     ret

$LIST