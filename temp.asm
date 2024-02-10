; /* READS TEMPERATURE */
; Note:     Before converting to be stored tempC, 
;           all values are stored as 32 bit numbers 
;           with 3 decimal points. (in milli-celcius)
;           
; Example:  2.07 V would be represented by the number
;           20700. (The real value * 1000).

TEMP_READ:
    anl ADCCON0, #0xf0          ; read led voltage
    orl ADCCON0, #LED_PORT
    lcall Read_ADC
    mov VLED_ADC+0, R0          ; save reading to VLED_ADC
	mov VLED_ADC+1, R1

read_opamp:
    anl ADCCON0, #0xf0          ; *** OPAMP ***
    orl ADCCON0, #OPAMP_PORT
    lcall Read_ADC
    mov x+0, R0 			    ; load opamp reading to x
	mov x+1, R1
	mov x+2, #0 			
	mov x+3, #0
    Load_y(207000)              ; load const vled ref into y      
    lcall mul32
    mov y+0, VLED_ADC+0 	    ; import vled reading into y
	mov y+1, VLED_ADC+1         
	mov y+2, #0 			
	mov y+3, #0
    lcall div32                 ; x value stores celcius 
    Load_y(1000)                ; celcius -> milli celcius 
    mov OPAMP_temp+0, x+0       ; save calculated opamp temp (mili C)
    mov OPAMP_temp+1, x+1
    mov OPAMP_temp+2, x+2
    mov OPAMP_temp+3, x+3

read_lm335:
    anl ADCCON0, #0xf0          ; *** LM335 ***
    orl ADCCON0, #LM335_PORT
    lcall Read_ADC
    mov x+0, R0 			    ; load lm335 reading to x
	mov x+1, R1
	mov x+2, #0 			
	mov x+3, #0
    Load_y(207000)               ; load const vled ref into y      
    lcall mul32
    mov y+0, VLED_ADC+0 	    ; import vled reading into y
	mov y+1, VLED_ADC+1         
	mov y+2, #0 			
	mov y+3, #0
    lcall div32
    Load_y(10)
    lcall mul32
    Load_y(273000)			    ; adjust to 273.000 C offset
	lcall sub32	                ; result of lm335 temp remains in x

add_lm335_to_opamp:
    mov y+0, OPAMP_temp+0       ; load opamp temp to y
    mov y+1, OPAMP_temp+1
    mov y+2, OPAMP_temp+2
    mov y+3, OPAMP_temp+3
    lcall add32                 ; lm335 + opamp = real temp
    mov temp_mc+0, x+0          ; store result in temp_mc (for python)
    mov temp_mc+1, x+1
    mov temp_mc+2, x+2
    mov temp_mc+3, x+3

export_to_main:
    Load_y(1000)
    lcall div32
    mov tempc, x+0              ; Both tempc and x now stores temp (C)
    







    




