; /* READS TEMPERATURE */
; Note:     Before converting to be stored tempC, 
;           all values are stored as 32 bit numbers 
;           with 3 decimal points. (in milli-celcius)
;           
; Example:  2.07 V would be represented by the number
;           20700. (The real value * 1000).

TEMP_READ:
ljmp read_led

Avg_ADC:
    Load_X(0)
    mov R5, #100
sum_loop_avg:
    lcall Read_ADC
    mov y+3, #0
    mov y+2, #0
    mov y+1, R1
    mov y+0, R0
    lcall add32
    djnz R5, sum_loop_avg:
    Load_y(0)
    lcall div32
    ret

read_led:
    anl ADCCON0, #0xf0          ; read led voltage
    orl ADCCON0, #LED_PORT
    lcall Avg_ADC
    mov VLED_ADC+0, R0          ; save reading to VLED_ADC
	mov VLED_ADC+1, R1

read_opamp:
    anl ADCCON0, #0xf0          ; *** OPAMP ***
    orl ADCCON0, #OPAMP_PORT
    lcall Avg_ADC
    mov x+0, R0 			    ; load opamp reading to x
	mov x+1, R1
	mov x+2, #0 			
	mov x+3, #0
    Load_y(2070)              ; load const vled ref into y      
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
    lcall Avg_ADC
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
    








Table:
    DW 0, 39, 79, 119, 158, 198, 238, 277, 317, 357,
    397, 437, 477, 517, 557, 597, 637, 677, 718, 758,
    798, 838, 879, 919, 960, 1000, 1041, 1081, 1122, 1163,
    1203, 1244, 1285, 1326, 1366, 1407, 1448, 1489, 1530, 1571,
    1612, 1653, 1694, 1735, 1776, 1817, 1858, 1899, 1941, 1982,
    2023, 2064, 2106, 2147, 2188, 2230, 2271, 2312, 2354, 2395,
    2436, 2478, 2519, 2561, 2602, 2644, 2685, 2727, 2768, 2810,
    2851, 2893, 2934, 2976, 3017, 3059, 3100, 3142, 3184, 3225,
    3267, 3308, 3350, 3391, 3433, 3474, 3516, 3557, 3599, 3640,
    3682, 3723, 3765, 3806, 3848, 3889, 3931, 3972, 4013, 4055,
    4096, 4138, 4179, 4220, 4262, 4303, 4344, 4385, 4427, 4468,
    4509, 4550, 4591, 4633, 4674, 4715, 4756, 4797, 4838, 4879,
    4920, 4961, 5002, 5043, 5084, 5124, 5165, 5206, 5247, 5288,
    5328, 5369, 5410, 5450, 5491, 5532, 5572, 5613, 5653, 5694,
    5735, 5775, 5815, 5856, 5896, 5937, 5977, 6017, 6058, 6098,
    6138, 6179, 6219, 6259, 6299, 6339, 6380, 6420, 6460, 6500,
    6540, 6580, 6620, 6660, 6701, 6741, 6781, 6821, 6861, 6901,
    6941, 6981, 7021, 7060, 7100, 7140, 7180, 7220, 7260, 7300,
    7340, 7380, 7420, 7460, 7500, 7540, 7579, 7619, 7659, 7699,
    7739, 7779, 7819, 7859, 7899, 7939, 7979, 8019, 8059, 8099,
    8138, 8178, 8218, 8258, 8298, 8338, 8378, 8418, 8458, 8499,
    8539, 8579, 8619, 8659, 8699, 8739, 8779, 8819, 8860, 8900,
    8940, 8980, 9020, 9061, 9101, 9141, 9181, 9222, 9262, 9302,
    9343, 9383, 9423, 9464, 9504, 9545, 9585, 9626, 9666, 9707,
    9747, 9788, 9828, 9869, 9909, 9950, 9991, 10031, 10072, 10113,
    10153, 10194, 10235, 10276, 10316, 10357, 10398, 10439, 10480, 10520,
    10561, 10602, 10643, 10684, 10725, 10766, 10807, 10848, 10889, 10930,
    10971, 11012, 11053, 11094, 11135, 11176, 11217, 11259, 11300, 11341,
    11382, 11423, 11465, 11506, 11547, 11588, 11630, 11671, 11712, 11753,
    11795, 11836, 11877, 11919, 11960, 12001, 12043, 12084, 12126, 12167,
    12209, 12250, 12291, 12333, 12374, 12416, 12457, 12499, 12540, 12582, 12624

$LIST



    




