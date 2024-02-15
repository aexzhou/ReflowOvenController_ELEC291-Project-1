$NOLIST
$MODN76E003
$LIST



;  N76E003 pinout:
;                               -------
;       PWM2/IC6/T0/AIN4/P0.5 -|1    20|- P0.4/AIN5/STADC/PWM3/IC3
;               TXD/AIN3/P0.6 -|2    19|- P0.3/PWM5/IC5/AIN6
;               RXD/AIN2/P0.7 -|3    18|- P0.2/ICPCK/OCDCK/RXD_1/[SCL]
;                    RST/P2.0 -|4    17|- P0.1/PWM4/IC4/MISO
;        INT0/OSCIN/AIN1/P3.0 -|5    16|- P0.0/PWM3/IC3/MOSI/T1
;              INT1/AIN0/P1.7 -|6    15|- P1.0/PWM2/IC2/SPCLK
;                         GND -|7    14|- P1.1/PWM1/IC1/AIN7/CLO
;[SDA]/TXD_1/ICPDA/OCDDA/P1.6 -|8    13|- P1.2/PWM0/IC0
;                         VDD -|9    12|- P1.3/SCL/[STADC]
;            PWM5/IC7/SS/P1.5 -|10   11|- P1.4/SDA/FB/PWM1
;                               -------
;
;  N76E003 pinout:
;                               ----
;                 (FREE) P0.5 -|1    20|- P0.4 (FREE)
;      Serial to COM TXD/P0.6 -|2    19|- P0.3 LCD.3
;      Serial to COM RXD/P0.7 -|3    18|- P0.2 LCD.2
;                    RST P2.0 -|4    17|- P0.1 LCD.1
;            LM335 INPUT P3.0 -|5    16|- P0.0 LCD.0
;       PUSHBUTTONS AIN0/P1.7 -|6    15|- P1.0 (FREE)
;                         GND -|7    14|- P1.1 THERMOCOUPLE INPUT
;         SPEAKER OUTPUT P1.6 -|8    13|- P1.2 OVEN CONTROL PIN
;                         VDD -|9    12|- P1.3 LCD RS
;                 (FREE) P1.5 -|10   11|- P1.4 LCD E
;                               -------
;
CLK               EQU 16600000 ; Microcontroller system frequency in Hz
BAUD              EQU 115200 ; Baud rate of UART in bps
TIMER1_RELOAD     EQU (0x100-(CLK/(16*BAUD)))
TIMER0_RELOAD_1MS EQU (0x10000-(CLK/1000))
TIMER2_RATE         EQU 100      ; 100Hz or 10ms
TIMER2_RELOAD       EQU (65536-(CLK/(16*TIMER2_RATE))) ; Need to change timer 2 input divide to 16 in T2MOD
ORG 0x0000
    ljmp main

ORG 002BH
	ljmp Timer2_ISR




; Initialization Messages
temperature_message:     db 'O=       J=     ', 0
comma              :     db ','               , 0
soak_message       :     db 'r'               , 0
reflow_message     :     db 's'               , 0

state0:	   db '0', 0
state1:	   db '1', 0
state2:	   db '2', 0
state3:	   db '3', 0
state4:	   db '4', 0
state5:	   db '5', 0


cseg

Timer2_ISR:
	clr TF2  ; Timer 2 doesn't clear TF2 automatically. Do it in the ISR.  It is bit addressable.
	push psw
	push acc
	
	inc pwm_counter
	clr c
	mov a, pwm
	subb a, pwm_counter ; If pwm_counter <= pwm then c=1
	cpl c
	mov oven_out, c
	
	mov a, pwm_counter
	cjne a, #100, Timer2_ISR_done
	mov pwm_counter, #0
	inc seconds ; It is super easy to keep a seconds count here
	setb s_flag

Timer2_ISR_done:
	pop acc
	pop psw
	reti
; SYMBOLIC CONSTANTS

; INPUTS
tempsensor_in equ P3.0
thermocouple_in equ P1.1

; OUTPUTS
oven_out equ P1.2
speaker_out equ P1.6

CSEG
; LCD
LCD_RS equ P1.3
LCD_E equ P1.4
LCD_D4 equ P0.0
LCD_D5 equ P0.1
LCD_D6 equ P0.2
LCD_D7 equ P0.3

$NOLIST
$include(LCD_4BIT.inc)
$LIST

; Flash instructions
PAGE_ERASE_AP   EQU 00100010b
BYTE_PROGRAM_AP EQU 00100001b

; These register definitions needed by 'math32.inc'
DSEG at 30H
x:   ds 4
y:   ds 4
amb_temp: ds 4 ; ambient temperature read by LM335
bcd: ds 5

DSEG
state: ds 1
temp_soak: ds 1
Time_soak: ds 1
Temp_refl: ds 1
Time_refl: ds 1
pwm_counter:  ds 1 ; Free running counter 0, 1, 2, ..., 100, 0
pwm:          ds 1 ; pwm percentage
seconds:      ds 1 ; a seconds counter attached to Timer 2 ISR
sec: ds 1
temp: ds 2


FSM1_state: ds 1

BSEG
reflow_flag: dbit 1
soak_flag: dbit 1
mf: dbit 1
s_flag: dbit 1 ; set to 1 every time a second has passed
; These eight bit variables store the value of the pushbuttons after calling 'ADC_to_PB' below
PB0: dbit 1
PB1: dbit 1
PB2: dbit 1
PB3: dbit 1
PB4: dbit 1
PB5: dbit 1
PB6: dbit 1
PB7: dbit 1

; MATH32
$NOLIST
$include(math32.inc)
$LIST

; Blank Macro
Left_blank mac
	mov a, %0
	anl a, #0xf0
	swap a
	jz Left_blank_%M_a
	ljmp %1
Left_blank_%M_a:
	Display_char(#' ')
	mov a, %0
	anl a, #0x0f
	jz Left_blank_%M_b
	ljmp %1
Left_blank_%M_b:
	Display_char(#' ')
endmac


putchar:
    jnb TI, putchar
    clr TI
    mov SBUF, a
    ret

;binary to display 3 digits on lcd screen

SendToLCD:
	mov b, #100
	div ab
	orl a, #0x30
	lcall ?WriteData
	mov a,b
	mov b,#10
	div ab
	orl a, #0x30
	lcall ?WriteData
	mov a, b
	orl a, #0x30
	lcall ?WriteData
	ret


; Formatting to display thermocouple temperature
; Display: 0000.00
Display_formated_BCD_To:
	Display_BCD(bcd+3)
	Display_BCD(bcd+2)
	Display_char(#'.')
	Display_BCD(bcd+1)


	ret
	
; Formatting to display ambient temperature
; Display: 00.00
Display_formated_BCD_Tj:
	Display_BCD(bcd+2)
	Display_char(#'.')
	Display_BCD(bcd+1)
	ret


; INITIALIZATION SUBROUTINES
Init_All:
	; Configure all the pins for biderectional I/O
	mov	P3M1, #0x00
	mov	P3M2, #0x00
	mov	P1M1, #0x00
	mov	P1M2, #0x00
	mov	P0M1, #0x00
	mov	P0M2, #0x00

	orl	CKCON, #0x10 ; CLK is the input for timer 1
	orl	PCON, #0x80 ; Bit SMOD=1, double baud rate
	mov	SCON, #0x52
	anl	T3CON, #0b11011111
	anl	TMOD, #0x0F ; Clear the configuration bits for timer 1
	orl	TMOD, #0x20 ; Timer 1 Mode 2
	mov	TH1, #TIMER1_RELOAD ; TH1=TIMER1_RELOAD;
	setb TR1
	
	; Using timer 0 for delay functions.  Initialize here:
	clr	TR0 ; Stop timer 0
	orl	CKCON,#0x08 ; CLK is the input for timer 0
	anl	TMOD,#0xF0 ; Clear the configuration bits for timer 0
	orl	TMOD,#0x01 ; Timer 0 in Mode 1: 16-bit timer
	
	; Initialize the pin used by the ADC (P1.1) as input.
	orl	P1M1, #0b00000010
	anl	P1M2, #0b11111101

	; Initialize the pin used by the ADC (P3.0) as input.
	orl	P3M1, #0b00000001
	anl	P3M2, #0b11111110
	
	; Initialize and start the ADC:
	anl ADCCON0, #0xF0
	orl ADCCON0, #0x07 ; Select channel 7

	anl ADCCON2, #0xF0
	orl ADCCON2, #0x01 ; Select channel 1

	; AINDIDS select if some pins are analog inputs or digital I/O:
	mov AINDIDS, #0x00 ; Disable all analog inputs
	orl AINDIDS, #0b10000000 ; P1.1 is analog input
	orl AINDIDS, #0b00000001 ; P3.0 is analog input
	orl ADCCON1, #0x01 ; Enable ADC

	mov T2CON, #0
	mov TH2, #high(TIMER2_RELOAD)
	mov TL2, #low(TIMER2_RELOAD)
	mov T2MOD, #0b10100000
	mov RCMP2H, #high(TIMER2_RELOAD)
	mov RCMP2L, #low(TIMER2_RELOAD)
	mov pwm_counter, #0
	orl EIE, #0x80
	setb TR2

	
	ret

; Flash Memory Subroutines
;******************************************************************************
; This code illustrates how to use IAP to make APROM 3f80h as a byte of
; Data Flash when user code is executed in APROM.
; (The base of this code is listed in the N76E003 user manual)
;******************************************************************************

Save_Variables:
	CLR EA  ; MUST disable interrupts for this to work!
	
	MOV TA, #0aah ; CHPCON is TA protected
	MOV TA, #55h
	ORL CHPCON, #00000001b ; IAPEN = 1, enable IAP mode
	
	MOV TA, #0aah ; IAPUEN is TA protected
	MOV TA, #55h
	ORL IAPUEN, #00000001b ; APUEN = 1, enable APROM update
	
	MOV IAPCN, #PAGE_ERASE_AP ; Erase page 3f80h~3f7Fh
	MOV IAPAH, #3fh ; Address high byte
	MOV IAPAL, #80h ; Address low byte
	MOV IAPFD, #0FFh ; Data to load into the address byte
	MOV TA, #0aah ; IAPTRG is TA protected
	MOV TA, #55h
	ORL IAPTRG, #00000001b ; write ?1? to IAPGO to trigger IAP process
	
	MOV IAPCN, #BYTE_PROGRAM_AP
	MOV IAPAH, #3fh
	
	;Load 3f80h with temp_soak
	MOV IAPAL, #80h
	MOV IAPFD, temp_soak
	MOV TA, #0aah
	MOV TA, #55h
	ORL IAPTRG,#00000001b ; Basically, this executes the write to flash memory
	
	;Load 3f81h with Time_soak
	MOV IAPAL, #81h
	MOV IAPFD, Time_soak
	MOV TA, #0aah
	MOV TA, #55h
	ORL IAPTRG,#00000001b
	
	;Load 3f82h with Temp_refl
	MOV IAPAL, #82h
	MOV IAPFD, Temp_refl
	MOV TA, #0aah
	MOV TA, #55h
	ORL IAPTRG,#00000001b
	
	;Load 3f83h with Time_refl
	MOV IAPAL, #83h
	MOV IAPFD, Time_refl
	MOV TA, #0aah
	MOV TA, #55h
	ORL IAPTRG,#00000001b

	;Load 3f84h with 55h
	MOV IAPAL,#84h
	MOV IAPFD, #55h
	MOV TA, #0aah
	MOV TA, #55h
	ORL IAPTRG, #00000001b

	;Load 3f85h with aah (spacer value indicating EOF, will load if something funny happens)
	MOV IAPAL, #85h
	MOV IAPFD, #0aah
	MOV TA, #0aah
	MOV TA, #55h
	ORL IAPTRG, #00000001b

	MOV TA, #0aah
	MOV TA, #55h
	ANL IAPUEN, #11111110b ; APUEN = 0, disable APROM update
	MOV TA, #0aah
	MOV TA, #55h
	ANL CHPCON, #11111110b ; IAPEN = 0, disable IAP mode
	
	setb EA  ; Re-enable interrupts

	ret

Load_Variables:
	mov dptr, #0x3f84  ; First key value location.  Must be 0x55
	clr a
	movc a, @a+dptr
	cjne a, #0x55, Load_Defaults
	inc dptr      ; Second key value location.  Must be 0xaa
	clr a
	movc a, @a+dptr
	cjne a, #0xaa, Load_Defaults
	
	mov dptr, #0x3f80
	clr a
	movc a, @a+dptr
	mov temp_soak, a
	
	inc dptr
	clr a
	movc a, @a+dptr
	mov Time_soak, a
	
	inc dptr
	clr a
	movc a, @a+dptr
	mov Temp_refl, a
	
	inc dptr
	clr a
	movc a, @a+dptr
	mov Time_refl, a
	ret

Load_Defaults:
	mov temp_soak, #1
	mov Time_soak, #2
	mov Temp_refl, #3
	mov Time_refl, #4
	ret

wait_1ms:
	clr	TR0 ; Stop timer 0
	clr	TF0 ; Clear overflow flag
	mov	TH0, #high(TIMER0_RELOAD_1MS)
	mov	TL0,#low(TIMER0_RELOAD_1MS)
	setb TR0
	jnb	TF0, $ ; Wait for overflow
	ret

; Wait the number of miliseconds in R2
waitms:
	lcall wait_1ms
	djnz R2, waitms
	ret

ADC_to_PB:
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
	
	; Check PB7
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
	ret

	; Check PB3
ADC_to_PB_L3:
	clr c
	mov a, ADCRH
	subb a, #0x70
	jc ADC_to_PB_L2
	clr PB3
	ret

	; Check PB2
ADC_to_PB_L2:
	clr c
	mov a, ADCRH
	subb a, #0x50
	jc ADC_to_PB_L1
	clr PB2
	ret

	; Check PB1
ADC_to_PB_L1:
	clr c
	mov a, ADCRH
	subb a, #0x30
	jc ADC_to_PB_L0
	clr PB1
	ret

	; Check PB0
ADC_to_PB_L0:
	clr c
	mov a, ADCRH
	subb a, #0x10
	jc ADC_to_PB_Done
	clr PB0
	ret
	
ADC_to_PB_Done:
	; No puhsbutton pressed	
	ret

; MAIN 
main:
	mov sp, #0x7f
    lcall Init_All
    lcall LCD_4BIT
    ; initial messages in LCD
    Set_Cursor(1, 1)
    Send_Constant_String(#temperature_message)
	Set_Cursor(2,1)
	Send_Constant_String(#soak_message)
	Set_Cursor(2,5)
	Send_Constant_String(#comma)
	Set_Cursor(2,8)
	Send_Constant_String(#reflow_message)
	Set_Cursor(2,12)
	Send_Constant_String(#comma)

	mov FSM1_state, #0
    mov Temp_soak, #200
	mov Time_soak, #0x60
	mov Temp_refl, #200
	mov Time_refl, #0x45
	mov sec, #0

	clr reflow_flag ; start on temp
	clr soak_flag ; start on temp

Forever:


; Example branch for decreasing any given value 
; This set of code will increase the ones columnn of any given 
; variable. ie. reflow_temp_ones, reflow_time_ones
; the 10s and 100s column will update in response to increasing 
; the ones column beyond 9.

; REFLOW ;
reflow_toggle:
	jb PB7, check_reflow_toggle
	cpl reflow_flag ; if button is pressed, change flag

check_reflow_toggle: 
	jb reflow_flag, turn_reflow_to_time

turn_reflow_to_temp:
	; will use the same logic for the other pushbuttons
; This example will use temp_soak for this example

	decrease_reflow_temp:
	jb PB6, increase_reflow_temp
    dec Temp_refl
	ljmp soak_toggle
	
	increase_reflow_temp:
	jb PB5, soak_toggle 
	inc Temp_refl
	ljmp soak_toggle


turn_reflow_to_time:
	
	decrease_reflow_time:
	jb PB6, increase_reflow_time
	mov a, Time_refl
    add a, #0x99
	da a
    mov Time_refl, a
	ljmp soak_toggle
	
	increase_reflow_time:
	jb PB5, soak_toggle 
	mov a, Time_refl
	add a, #1
	da a 
	mov Time_refl, a
	ljmp soak_toggle

; SOAK ;
soak_toggle:
	jb PB4, check_soak_toggle
	cpl soak_flag ; if button is pressed, change flag

check_soak_toggle: 
	jb soak_flag, turn_soak_to_time

turn_soak_to_temp:
	; will use the same logic for the other pushbuttons
; This example will use temp_soak for this example

	decrease_soak_temp:
	jb PB3, increase_soak_temp
    dec Temp_soak
	ljmp start_stop
	
	increase_soak_temp:
	jb PB2, start_stop 
	inc Temp_soak
	ljmp start_stop

turn_soak_to_time:
	
	decrease_soak_time:
	jb PB3, increase_soak_time
	mov a, Time_soak
    add a, #0x99
	da a
    mov Time_soak, a
	ljmp start_stop
	
	increase_soak_time:
	jb PB2, soak_toggle 
	mov a, Time_soak
	add a, #1
	da a 
	mov Time_soak, a
	ljmp start_stop

start_stop:
	mov a, Temp_refl
	Set_cursor(2,2)
	lcall SendToLCD
	clr a
	mov a, Time_soak
	Set_cursor(2,9)
	lcall SendToLCD
	clr a
	Set_Cursor(2,6)
	Display_BCD(Time_refl)
	Set_Cursor(2,13)
	Display_BCD(Time_soak)
	jb PB0, continue

turn_on:
	mov a, FSM1_state
	cjne a, #0, turn_off
	mov FSM1_state, #1
	sjmp continue

turn_off:
	mov FSM1_state, #0
	sjmp continue


continue:
	lcall ADC_to_PB
	;lcall Display_PushButtons_ADC
	
	mov ADCCON0, #0x07 ; Select channel 7 (P1.1)
	clr ADCF
	setb ADCS ;  ADC start trigger signal
    jnb ADCF, $ ; Wait for conversion complete
    
    ; Read the ADC result and store in [R1, R0]
    mov a, ADCRH   
    swap a
    push acc
    anl a, #0x0f
    mov R1, a
    pop acc
    anl a, #0xf0
    orl a, ADCRL
    mov R0, A
    
    mov ADCCON0, #0x01 ; Select channel 1 (P3.0)
	clr ADCF
	setb ADCS ;  ADC start trigger signal
    jnb ADCF, $ ; Wait for conversion complete
    
    ; Read the ADC result and store in [R4, R3]
    mov a, ADCRH   
    swap a
    push acc
    anl a, #0x0f
    mov R4, a
    pop acc
    anl a, #0xf0
    orl a, ADCRL
    mov R3, A
    
	; Convert to LM335 temperature to voltage
	mov x+0, R3
	mov x+1, R4
	mov x+2, #0
	mov x+3, #0
	Load_y(53800) ; VCC voltage measured
	lcall mul32
	Load_y(4095) ; 2^12-1
	lcall div32
	Load_y(27600)
	lcall sub32
	Load_y(100)
	lcall mul32
	
	; Convert to BCD and display
	lcall hex2bcd
	Set_Cursor(1, 12)
	lcall Display_formated_BCD_Tj

	; Convert value back to hex to use for calculations
	lcall bcd2hex

	; Storing the ambient temperature
	mov amb_temp+0, x+0
	mov amb_temp+1, x+1
	mov amb_temp+2, x+2
	mov amb_temp+3, x+3

	; Convert to thermocouple voltage to temperature
	mov x+0, R0
	mov x+1, R1
	mov x+2, #0
	mov x+3, #0
	Load_y(50300) ; VCC voltage measured
	lcall mul32
	Load_y(4095) ; 2^12-1
	lcall div32
	Load_y(100)
	lcall div32
	Load_y(5189)
	lcall mul32

	; Adding the ambient temperature to oven temperature
	mov y+0, amb_temp+0
	mov y+1, amb_temp+1
	mov y+2, amb_temp+2
	mov y+3, amb_temp+3
	lcall add32
	
	
	; Convert to BCD and display
	lcall hex2bcd
	Set_Cursor(1, 3)
	lcall Display_formated_BCD_To
	
?Send_BCD:	
	push acc
; Write most significant digit
	mov a, bcd+2
	swap a
	anl a, #0fh
	orl a, #30h
	lcall putchar
; write least significant digit
	mov a, bcd+2
	anl a, #0fh
	orl a, #30h
	lcall putchar
	mov a, bcd+1
	swap a
	anl a, #0fh
	orl a, #30h
	lcall putchar
	mov a, bcd+1
	anl a, #0fh
	orl a, #30h
	lcall putchar
	pop acc

	; Storing the thermocouple temperature into var temp 
	Load_y(10000)
	lcall div32
	mov temp+0, x+0
	mov temp+1, x+1
	
	; Wait 100 ms between readings
	mov R2, #100
	lcall waitms
	
; STATE MACHINE	
FSM1:
	mov a, FSM1_state

; off state. Should go to state 1 when start button is pressed (Button 8 right now)
FSM1_state0:
	cjne a, #0, FSM1_state1
	Set_Cursor(2, 16)
	Send_Constant_String(#state0)
	mov pwm, #0
	;jb PB0, FSM1_state0_done
	;mov FSM1_state, #1
FSM1_state0_done:
	ljmp Forever

; pre-heat state. Should go to state two when temp reaches temp_soak	
FSM1_state1:
	cjne a, #1, FSM1_state2
	Set_Cursor(2, 16)
	Send_Constant_String(#state1)
	
	clr P1.6
	
	mov pwm, #100
	mov sec, #0
	
	; These two lines are temporary. temp should be read from the thermocouple wire
	mov temp_soak, #100
	
	mov a, temp_soak
	setb c
	subb a, temp
	jnc FSM1_state1_done
	mov FSM1_state, #2
FSM1_state1_done:
	ljmp Forever

; State 2
FSM1_state2:
	setb P1.6 ;speaker
	cjne a, #2, FSM1_state3
	Set_Cursor(2, 16)
	Send_Constant_String(#state2)
	mov pwm, #20
	
	mov a, sec
	add a, #1
	mov sec, a

	mov R2, #50
	lcall waitms

	mov a, Time_soak
	clr c
	subb a, sec
	jnc FSM1_state2_done
	mov FSM1_state, #3
FSM1_state2_done:
	ljmp Forever

;DELETE
jump:
ljmp FSM1_state0	

;State 3
FSM1_state3:
	cjne a, #3, FSM1_state4
	Set_Cursor(2, 16)
	Send_Constant_String(#state3)
	mov pwm, #100
	mov sec, #0
	
	
	mov a, Temp_refl
	clr c
	subb a, temp
	jnc FSM1_state3_done
	mov FSM1_state, #4
FSM1_state3_done:
	ljmp Forever


;State 4
FSM1_state4:
	cjne a, #4, FSM1_state5
	Set_Cursor(2, 16)
	Send_Constant_String(#state4)
	mov pwm, #20
	
	mov a, sec
	add a, #1
	mov sec, a

	mov R2, #50
	lcall waitms
	
	mov a, Time_refl
	clr c
	subb a,sec
	jnc FSM1_state4_done
	mov FSM1_state, #5
FSM1_state4_done:
	ljmp Forever
	
FSM1_state5:
	cjne a, #5, jump
	Set_Cursor(2, 16)
	Send_Constant_String(#state5)
	mov pwm, #0
	
	
	mov a, #60
	clr c
	subb a, temp
	jc FSM1_state5_done
	mov FSM1_state,#0
FSM1_state5_done:
	lcall Save_Variables ; Save variables in flash memory
	ljmp Forever
	
Send_BCD mac
	push ar0
	mov r0, %0
	lcall ?Send_BCD
	pop ar0
endmac

;Any additions to be checked
END