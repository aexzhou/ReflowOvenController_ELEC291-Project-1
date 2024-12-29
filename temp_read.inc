$NOLIST
cseg

;temp_lm    4
;temp_mc    4
;tempc      1

TEMP_READ:
    push acc 
    push psw
    push AR0
    push AR1

    orl	P1M1, #0b10100010
	anl	P1M2, #0b01011101
lcall Read_Band_Gap		

    ;mov AINDIDS, #AINCONFIG

; lm335 must be in at most 3 dig precision or else the reading goes beyond 4 bytes	
read_lm335:
    anl ADCCON0, #0xf0          ; *** LM335 *** AIN port = 5
    orl ADCCON0, #0x05
    lcall Avg_ADC
    mov adc1+0, adc_out+0       ; to serial
    mov adc1+1, adc_out+1
    mov x+0, adc_out+0 			    ; load lm335 reading to x
	mov x+1, adc_out+1
	mov x+2, #0 			
	mov x+3, #0
	mov y+0, Band_Gap_Voltage+0    
	mov y+1, Band_Gap_Voltage+1
	mov y+2, #0
	mov y+3, #0
    lcall mul32
    
    mov y+0, Band_Gap_Value+0	   
	mov y+1, Band_Gap_Value+1        
	mov y+2, #0 			
	mov y+3, #0
    lcall div32
    Load_y(100)
    lcall div32
    Load_y(273)			        ; adjust to 273 offset
	lcall sub32	                ; result of lm335 temp remains in x
    mov temp_lm_c, x+0          ; for the display
    ; lcall mul32
	; mov temp_lm+0, x+0          ; mV val store in temp_lm        
    ; mov temp_lm+1, x+1				
    ; mov temp_lm+2, x+2
    ; mov temp_lm+3, x+3

	mov temp_lm+0, temp_lm_c          ; mV val store in temp_lm        
    mov temp_lm+1, #0				
    mov temp_lm+2, #0
    mov temp_lm+3, #0
;
    ; hard code 5208h = 21000d

	; mov temp_lm+0, #08h          ; 3 DECIMALS 
    ; mov temp_lm+1, #52h			
    ; mov temp_lm+2, #0
    ; mov temp_lm+3, #0

read_opamp:
	anl ADCCON0, #0xf0          ; *** OPAMP *** AIN port = 7
    orl ADCCON0, #0x07	 
	lcall Avg_ADC
    mov adc2+0, adc_out+0       ; to serial
    mov adc2+1, adc_out+1
	mov x+0, adc_out+0 			; load opamp reading to x
	mov x+1, adc_out+1
	mov x+2, #0 			
	mov x+3, #0
    mov y+0, Band_Gap_Voltage+0
	mov y+1, Band_Gap_Voltage+1
	mov y+2, #0
	mov y+3, #0
	lcall mul32
    mov y+0, Band_Gap_Value+0 	    
	mov y+1, Band_Gap_Value+1         
	mov y+2, #0 			
	mov y+3, #0
    lcall div32                 ; x value now stores OPAMP V, 4 DECIMALS

	Load_y(100)				
	lcall mul32					; turn 0.1mV to uV
	Load_y(V2C_DIVISOR)
	lcall div32					; deg C reading now in x	
	mov temp_op_c, x+0

	Load_y(1000)
	lcall mul32					; conv to 1 mV again to add to lm335 data

add_lm335_to_opamp:
    mov a, temp_op_c
    add a, temp_lm_c 
    ;add a, #24
    mov tempc, a

    ; mov y+0, temp_lm+0       	; load lm335 temp to y
    ; mov y+1, temp_lm+1
    ; mov y+2, temp_lm+2
    ; mov y+3, temp_lm+3
    ; lcall add32                	; lm335 + opamp = real temp
    ; mov temp_mc+0, x+0          ; store result in temp_mc (for python)
    ; mov temp_mc+1, x+1				
    ; mov temp_mc+2, x+2
    ; mov temp_mc+3, x+3
	
export_to_main:
	; mov x+0, temp_mc+0          
    ; mov x+1, temp_mc+1
    ; mov x+2, temp_mc+2
    ; mov x+3, temp_mc+3
    ; Load_y(1000)
    ; lcall div32
    ; mov tempc, x+0              ; Both tempc and x now stores temp (C)

    pop AR1
    pop AR0
    pop psw
    pop acc
    ret
$LIST