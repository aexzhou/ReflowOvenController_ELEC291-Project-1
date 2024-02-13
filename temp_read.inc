$NOLIST
;----------------------------------------------------
; Contains all functions related to reading thermocouple
; and lm335 data and subsequent conversions.
;
; Copyright 2024 by LX
; https://soundcloud.com/lx778
;
;----------------------------------------------------
Avg_ADC:						; function for ADC noise reduction
    push AR5
    Load_X(0)
    mov R5, #255
sum_loop_avg:
    lcall Read_ADC
    mov y+3, #0
    mov y+2, #0
    mov y+1, R1
    mov y+0, R0
    lcall add32
    djnz R5, sum_loop_avg
    Load_y(255)
    lcall div32
    pop AR5
    ret

TEMP_READ:
    push acc
    push AR0
    push AR1 

	ljmp read_led

read_led:
    anl ADCCON0, #0xf0          ; read led voltage
    orl ADCCON0, #LED_PORT
    lcall Avg_ADC
    mov VLED_ADC+0, R0          ; save reading to VLED_ADC
	mov VLED_ADC+1, R1

read_lm335:
    anl ADCCON0, #0xf0          ; *** LM335 ***
    orl ADCCON0, #LM335_PORT
    lcall Avg_ADC
    mov x+0, R0 			    ; load lm335 reading to x
	mov x+1, R1
	mov x+2, #0 			
	mov x+3, #0
    Load_y(260000)              ; load const vled ref into y      
    lcall mul32
    mov y+0, VLED_ADC+0 	    ; import vled reading into y
	mov y+1, VLED_ADC+1         
	mov y+2, #0 			
	mov y+3, #0
    lcall div32
    Load_y(273000)			    ; adjust to 273.000 C offset
	lcall sub32	                ; result of lm335 temp remains in x
	mov temp_lm+0, x+0          ; store 3 decimal lm335 value for later
    mov temp_lm+1, x+1				
    mov temp_lm+2, x+2
    mov temp_lm+3, x+3

read_opamp:
	anl ADCCON0, #0xf0          ; *** OPAMP ***
    orl ADCCON0, #OPAMP_PORT	; 
	lcall Avg_ADC
	mov x+0, R0 			    ; load opamp reading to x
	mov x+1, R1
	mov x+2, #0 			
	mov x+3, #0
    Load_y(2600)                ; load const vled ref (2070 mV) into y      
    lcall mul32
    mov y+0, VLED_ADC+0 	    ; import led adc reading into y
	mov y+1, VLED_ADC+1      	   
	mov y+2, #0 			
	mov y+3, #0
    lcall div32                 ; x value now stores OPAMP V in mV
	Load_y(1000)				
	lcall mul32					; turn mV to uV
	Load_y(V2C_DIVISOR)
	lcall div32					; deg C reading now in x	
	Load_y(1000)
	lcall mul32					; conv to mV again to add to lm335 data

add_lm335_to_opamp:
    mov y+0, temp_lm+0       	; load lm335 temp to y
    mov y+1, temp_lm+1
    mov y+2, temp_lm+2
    mov y+3, temp_lm+3
    lcall add32                	; lm335 + opamp = real temp
    mov temp_mc+0, x+0          ; store result in temp_mc (for python)
    mov temp_mc+1, x+1				
    mov temp_mc+2, x+2
    mov temp_mc+3, x+3

    mov x+0, #0         
    mov x+1, #0
    mov x+2, #0
    mov x+3, temp_mc+3


	
export_to_main:					; exports temp reading to rest of code
	mov x+0, temp_mc+0          
    mov x+1, temp_mc+1
    mov x+2, temp_mc+2
    mov x+3, temp_mc+3
    Load_y(1000)
    lcall div32
    mov tempc, x+0              ; Both tempc and x now stores temp (C)	




temp_read_exit:
    pop AR1 
    pop AR0 
    pop ACC
    ret

$LIST