$NOLIST
;----------------------------------------------------
; Retrieves Thermocouple mV data stored in APROM 3000H (flash)
; Contains ADC functions
;----------------------------------------------------
CSEG

PAGE_ERASE_AP   EQU 00100010b
BYTE_PROGRAM_AP EQU 00100001b
BYTE_READ_AP    EQU 00000000b



Read_ADC:       ; UPDATE, this now exports to adc_out [15:0]
    mov adc_temp0, #0
    mov adc_temp1, #0
    push psw
    push acc
    clr a
	clr ADCF
	setb ADCS ;  ADC start trigger signal
    jnb ADCF, $ ; Wait for conversion complete
    
    ; Read the ADC result and store in [adc_temp1, adc_temp0]
    mov a, ADCRL
    anl a, #0x0f
    mov adc_temp0, a
    mov a, ADCRH   
    swap a
    push acc
    anl a, #0x0f
    mov adc_temp1, a
    pop acc
    anl a, #0xf0
    orl a, adc_temp0
    mov adc_temp0, A
    mov adc_out+0, adc_temp0 
    mov adc_out+1, adc_temp1

    mov data_out+0, adc_temp0
    mov data_out+1, adc_temp1

    pop acc
    pop psw
    mov adc_temp0, #0
    mov adc_temp1, #0
    
	ret

Avg_ADC:						; function for ADC noise reduction
	push AR5
    Load_X(0)
    mov R5, #20
sum_loop_avg:
    lcall Read_ADC
    mov y+3, #0
    mov y+2, #0
    mov y+1, adc_out+1
    mov y+0, adc_out+0
    lcall add32
    djnz R5, sum_loop_avg
    Load_y(20)
    lcall div32
    mov adc_out+0, x+0
    mov adc_out+1, x+1 
	pop AR5
    ret

Read_Band_Gap:
    push ACC
    push PSW
    push AR5 
    push AR6
    push AR7
    ; Read from ROM the factory measure voltage of the band-gap reference
    ; following the instructions in section 18.1.4 of the N76E003 manual.
    ; Also reads the current value of the band-gap.  The results are stored
    ; and used to convert ADC channel values to voltage later on using
    ; this formula:
    ;
    ; Channel_Voltage=(Channel_Value*Band_Gap_Voltage)/Band_Gap_Value
    ;
    
    ; Enable IAPEN
    mov TA, #0Xaa
    mov TA, #0x55
    orl CHPCON, #0x01
    
    mov IAPAL, #0x0c
	mov IAPAH, #0x00
	mov IAPCN, #0x04
	
    ; Trig set IAPGO
    mov TA, #0Xaa
    mov TA, #0x55
    orl IAPTRG, #0x01
    
    mov R6, IAPFD ; BandgapHigh stored in R1
	
    mov IAPAL, #0x0d
	mov IAPAH, #0x00
	mov IAPCN, #0x04
	
    ; Trig set IAPGO
    mov TA, #0Xaa
    mov TA, #0x55
    orl IAPTRG, #0x01
    
    mov a, IAPFD 
    anl a, #0x0f
    mov R5, a ; BandgapLow stored in R0
    
    ; Disable IAPEN
    mov TA, #0Xaa
    mov TA, #0x55
    anl CHPCON, #0xfe

	; Re-arrange so the read values forms a 12-bit right aligned contigous number:
    mov a, R6   
    swap a
    push acc
    anl a, #0x0f
    mov R6, a
    pop acc
    anl a, #0xf0
    orl a, R5
    mov R5, a
    ; [R1,R0] now contains the stored band gap reference value
    
    ; Band-gap voltage in milivolts is (x*3072)/4096 according to the manual:
    mov x+0, R5
    mov x+1, R6
    mov x+2, #0
    mov x+3, #0
    Load_y(30720) ; Need 4 decimal places: multiply 3072 by 10
    lcall mul32
    Load_y(4096)
    lcall div32
    
    ; Save the factory measured voltage of the band-gap:
    mov Band_Gap_Voltage+0, x+0
    mov Band_Gap_Voltage+1, x+1
	
	; Read the band-gap value with the ADC
	anl ADCCON0, #0xF0
	orl ADCCON0, #0x08 ; Select band-gap
	
	; Bypass the first three measuraments with a 20ms delay in between:
	mov R5, #3
Read_Band_Gap_1:
	clr ADCF
	setb ADCS   ; ADC start trigger signal
    jnb ADCF, $ ; Wait for conversion complete
    mov R7, #20 ; Delay 20ms
    lcall waitms
    djnz R5, Read_Band_Gap_1
	
	lcall Read_ADC
	
	; Save the measured value of the band-gap:
	mov Band_Gap_Value+0, adc_out+0
	mov Band_Gap_Value+1, adc_out+1
	
    pop AR7
    pop AR6
    pop AR5
    pop PSW
    pop ACC

	ret


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
;     mov @adc_temp0, a              ; col
;     mov a, temp_offset+0
;     anl a, #0xf0
;     swap a
;     mov @adc_temp1, a              ; row
;     cjne a, #0x00, Row_sel  ; if row not 0, proceed to select row
;     ljmp Col_check          ; if row 0, go check col
; Row_sel:
;     mov a, dpl 
;     add a, #0x20
;     mov dpl, a
;     jnc Row_sel_dec
;     inc dph 
; Row_sel_dec:
;     djnz adc_temp1, Row_sel
; Col_check:                  ; check if col isnt 0 then select col
;     mov a, @adc_temp0
;     cjne a, #0x00, Col_sel
;     sjmp Data_sel
; Col_sel:
;     inc dptr
;     inc dptr
;     djnz adc_temp0, Col_sel

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