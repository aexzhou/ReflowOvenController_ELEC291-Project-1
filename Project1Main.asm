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

CLK                 EQU 16600000 						; Microcontroller system frequency in Hz
BAUD                EQU 115200 	
TIMER0_RATE         EQU 4096     ; 2048Hz squarewave (peak amplitude of CEM-1203 speaker)
TIMER0_RELOAD       EQU ((65536-(CLK/TIMER0_RATE)))						; Baud rate of UART in bps
TIMER1_RELOAD       EQU (0x100-(CLK/(16*BAUD)))
TIMER0_RELOAD_1MS   EQU (0x10000-(CLK/1000))
TIMER2_RATE 		EQU 100 							; 1/100 = 10ms
TIMER2_RELOAD   	EQU (65536-(CLK/(16*TIMER2_RATE)))
;GAIN				EQU 25
;V2C_DIVISOR			EQU 1051

; /*** PORT DEFINITIONS ***/
LCD_RS 			equ P1.3
LCD_E  			equ P1.4
LCD_D4 			equ P0.0
LCD_D5 			equ P0.1
LCD_D6 			equ P0.2
LCD_D7 			equ P0.3
PWM_OUT 		equ P1.0
START_BUTTON 	equ P0.4
; Analog Input Port Numbering
; LED_PORT 		equ 0x00			; AIN port numbers
; LM335_PORT 		equ 0x05
; OPAMP_PORT 		equ 0x07
; AINCONFIG		equ 0b10100001		; bits 1 = toggled analog in
; SOUND_OUT       equ P1.6

; /*** DIRECT ACCESS VARIABLES @RAM 0x30 -> 0x7F ***/
DSEG at 30H
x:   			ds 4		; for math
y:   			ds 4
data_out:   	ds 4		; for python
bcd: 			ds 5		; for display

;VLED_ADC: 		ds 2		; for temperature 
dtemp:  		ds 2
tempc: 			ds 1
temp_mc:		ds 4
OPAMP_temp: 	ds 4
temp_lm:   		ds 4
;mV_offset:  	ds 2

FSM1_state:  	ds 1		; fsm states

pwm_counter:	ds 1		; time check and pwm
count10ms: 		ds 1
seconds: 		ds 1
pwm:			ds 1
abort_time:		ds 1

ReflowTemp: 	ds 1		; reflow profile parameters
ReflowTime:		ds 1
SoakTime:		ds 1
SoakTemp:		ds 1


; /*** SINGLE BIT VARIABLES @RAM 0x20 -> 0x2F ***/
BSEG 
mf: 			dbit 1
seconds_flag: 	dbit 1
s_flag: 		dbit 1
PB0: dbit 1
PB1: dbit 1
PB2: dbit 1
PB3: dbit 1
PB4: dbit 1
PB5: dbit 1
PB6: dbit 1
PB7: dbit 1

; /*** CODE SEGMENT ***/
CSEG

; Reset vector
org 0x0000
    ljmp main

; External interrupt 0 vector (not used in this code)
org 0x0003
	reti

; Timer/Counter 0 overflow interrupt vector (not used in this code)
org 0x000B
	reti

; External interrupt 1 vector (not used in this code)
org 0x0013
	reti

; Timer/Counter 1 overflow interrupt vector (not used in this code)
org 0x001B
	reti

; Serial port receive/transmit interrupt vector (not used in this code)
org 0x0023 
	reti
	
; Timer/Counter 2 overflow interrupt vector
org 0x002B
	ljmp Timer2_ISR

;                     1234567890123456    <- This helps determine the location of the counter
test_message:     db '****LOADING*****', 0
value_message:    db 'TEMP:           ', 0
temp_message:	  db 'OVEN TEMP:      ', 0
fah_message:      db 'FARENHET READING', 0
abort_message: 	  db 'ABORTABORTABORT ', 0
state_message:	  db 'Current State:  ', 0
error_message:	  db 'State Error     ', 0
soak_text:     	  db 'Soak:    s    C ', 0
reflow_text:   	  db 'Refl:    s    C ', 0
blank_text:       db '                ', 0

$NOLIST
$include(LCD_4bit.inc) ; A library of LCD related functions and utility macros
$include(adc_flash.inc)
$include(math32.inc)
$include(troubleshooter.inc) 
;$include(temp_read.inc)
$LIST
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Send_BCD mac
	push ar0
	mov r0, %0
	lcall ?Send_BCD
	pop ar0
	endmac
?Send_BCD:
	push acc
	; Write most significant digit
	mov a, r0
	swap a
	anl a, #0fh
	orl a, #30h
	lcall putchar
	; write least significant digit
	mov a, r0
	anl a, #0fh
	orl a, #30h
	lcall putchar
	pop acc
	ret
	
putchar:
	jnb TI, putchar
	clr TI
	mov SBUF, a
	ret

waitms:
	lcall wait_1ms
	djnz R2, waitms
	ret

wait_1ms:
	clr	TR0 ; Stop timer 0
	clr	TF0 ; Clear overflow flag
	mov	TH0, #high(TIMER0_RELOAD_1MS)
	mov	TL0,#low(TIMER0_RELOAD_1MS)
	setb TR0
	jnb	TF0, $ ; Wait for overflow
	ret

Read_ADC:
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
	ret
	
	
	Avg_ADC:						; function for ADC noise reduction
    Load_X(0)
    mov R5, #100

	sum_loop_avg:
    lcall Read_ADC
    mov y+3, #0
    mov y+2, #0
    mov y+1, R1
    mov y+0, R0
    lcall add32
    djnz R5, sum_loop_avg
    Load_y(100)
    lcall div32
    ret




InitAll:
	; /*** SERIAL PORT INITIALIZATION ***/
	mov	P3M1,#0x00  			; Configure all the pins for biderectional I/O
	mov	P3M2,#0x00
	mov	P1M1,#0x00
	mov	P1M2,#0x00
	mov	P0M1,#0x00
	mov	P0M2,#0x00
    ; Since the reset button bounces, we need to wait a bit before
    ; sending messages, otherwise we risk displaying gibberish!
    ;mov R1, #200
    ;mov R0, #104
    ;djnz R0, $   				; 4 cycles->4*60.285ns*104=25us
    ;djnz R1, $-4 				; 25us*200=5.0ms
    mov R2, #5
    lcall waitms
    ; Now we can proceed with the configuration of the serial port
	orl	CKCON, #0x10 			; CLK is the input for timer 1
	orl	PCON, #0x80 			; Bit SMOD=1, double baud rate
	mov	SCON, #0x52
	anl	T3CON, #0b11011111
	anl	TMOD, #0x0F			 	; Clear the configuration bits for timer 1
	orl	TMOD, #0x20 			; Timer 1 Mode 2
	mov	TH1, #TIMER1_RELOAD
	setb TR1
	; /*** INITIALIZE THE REST ***/
	; Using timer 0 for delay functions.  Initialize here:
	clr	TR0 					; Stop timer 0
	orl	CKCON,#0x08 			; CLK is the input for timer 0
	anl	TMOD,#0xF0				; Clear the configuration bits for timer 0
	orl	TMOD,#0x01 				; Timer 0 in Mode 1: 16-bit timer
	; Initialize the pin used by the ADC (P1.1) as input.
	orl	P1M1, #0b00000010	;	Mode 1 select for the pin must be 1, 
	anl	P1M2, #0b11111101	;	Mode 2 select for the pin should be 0, keeping the rest the same
	; Initialize the pin used by the ADC (P1.7, AIN 0)
	orl P1M2, #0b10000000
	anl P1M2, #0b01111111

	orl P1M1, #0b01000000
	anl P1M2, #0b01000000

	; Initialize and start the ADC:
	anl ADCCON0, #0xF0
	orl ADCCON0, #0x07 			; Select channel 7
	anl ADCCON0, #0xF0
	orl ADCCON0, #0x00 			; Select channel 0
	anl ADCCON0, #0xF0
	anl ADCCON0, #0x01 			; Select chanel 1 for lm335 analog input 
	; AINDIDS select if some pins are analog inputs or digital I/O:
	mov AINDIDS, #0x00 			; Disable all analog inputs
	orl AINDIDS, #0b10000000	; P1.1 is analog input
	orl AINDIDS, #0b00000001	; P1.7 AIN0
	orl AINDIDS, #0b01000000
	orl ADCCON1, #0x01 			; Enable ADC
	; /* TIMER 2 INIT * /
	mov T2CON, #0 ; Stop timer/counter.  Autoreload mode.
	mov TH2, #high(TIMER2_RELOAD)
	mov TL2, #low(TIMER2_RELOAD)
	; Set the reload value
	mov T2MOD, #0b10100000 ; Enable timer 2 autoreload, and clock divider is 16
	mov RCMP2H, #high(TIMER2_RELOAD)
	mov RCMP2L, #low(TIMER2_RELOAD)
	; Init the free running 10 ms counter to zero
	mov pwm_counter, #0
	; Enable the timer and interrupts
	orl EIE, #0x80 ; Enable timer 2 interrupt ET2=1
    setb TR2  ; Enable timer 2
	setb EA ; Enable global interrupts
	orl CKCON, #0b00001000 ; Input for timer 0 is sysclk/1
	mov a, TMOD
	anl a, #0xf0 ; 11110000 Clear the bits for timer 0
	orl a, #0x01 ; 00000001 Configure timer 0 as 16-timer
	mov TMOD, a
	mov TH0, #high(65536-(CLK/TIMER0_RATE))
	mov TL0, #low(65536-(CLK/TIMER0_RATE))
	; Enable the timer and interrupts
    setb ET0  ; Enable timer 0 interrupt
    setb TR0  ; Start timer 0
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ALL OF OUR RETURNING FUNCTIONS TO AVOID LOOP ISSUES 

;---------------------------------;
; ISR for Timer 2                 ;
;---------------------------------;
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


;line1:
;	DB 'PWM Example     '
;	DB 0
;line2:
;	DB 'Chk pin 15:P1.0 '
;	DB 0


; Send a constant-zero-terminated string using the serial port

; Sends binary data to Python via putchar
;SendBin:					
;	clr A					; Sends temp_mc
;	mov a, temp_mc+0
;	lcall putchar
;	clr A
;	mov a, temp_mc+1
;	lcall putchar
;	clr A
;	mov a, temp_mc+2
;	lcall putchar
;	clr A
;	mov a, temp_mc+3
;	lcall putchar
;
;	clr A
;	mov a, FSM1_state
;	lcall putchar
;
;	clr A					; Sends data_out
;	mov a, data_out+0
;	lcall putchar
;	clr A
;	mov a, data_out+1
;	lcall putchar
;	clr A					; Sends data_out
;	mov a, data_out+2
;	lcall putchar
;	clr A
;	mov a, data_out+3
;	lcall putchar
;	ret

ASCII_CHAR: 
	db '0123456789ABCDEF'

Hello_World:
    DB  'Hello, World!', '\r', '\n', 0
New_Line:
	DB '\r', '\n', 0


Main:
    mov SP, #0x7F 	; Set the stack pointer to the begining of idata
    
    lcall InitAll	; Initializes timers, analog inputs.
    lcall LCD_4BIT	; Configures our LCD for 4 bit mode 

	; Initialize all variables
	Load_y(0)
	mov data_out,  #0
	mov dtemp,  #0
	mov temp_mc,  #0
	mov OPAMP_temp,  #0
	mov temp_lm,  #0
	mov FSM1_state, #0
	mov seconds, #0
	mov ReflowTemp, #0
	mov ReflowTime, #0
	mov SoakTime, #0
	mov abort_time, #0
	mov SoakTemp, #0
	mov data_out, #0 
	mov tempc, #0
	mov pwm, #0
	clr mf
	clr seconds_flag
	clr s_flag
	clr PB0
	clr PB1
	clr PB2
	clr PB3
	clr PB4
	clr PB5
	clr PB6
	clr PB7


	;initial messages in LCD
	Set_Cursor(1, 1)
    Send_Constant_String(#soak_text)
	Set_Cursor(2, 1)
    Send_Constant_String(#reflow_text)

    Set_Cursor(1,8)
    mov x+0, SoakTemp
	mov x+1, #0
	mov x+2, #0
	mov x+3, #0
    lcall hex2bcd
	Display_BCD(bcd)

    Set_Cursor(1,13)
	mov x+0, SoakTime
	mov x+1, #0
	mov x+2, #0
	mov x+3, #0
    lcall hex2bcd
	Display_BCD(bcd)

    Set_Cursor(2,8)
	mov x+0, ReflowTime
	mov x+1, #0
	mov x+2, #0
	mov x+3, #0
    lcall hex2bcd
	Display_BCD(bcd)

    mov x+0, ReflowTemp
	mov x+1, #0
	mov x+2, #0
	mov x+3, #0
    Set_Cursor(2,13)
    lcall hex2bcd
	Display_BCD(bcd)

;Forever: ;avaliable: r2, r3
FSM_sys:
; /* TEMP_READ: READS TEMPERATURE */
; Note:     Before converting to be stored tempC, 
;           all values are stored as 32 bit numbers 
;           with 3 decimal points. (in milli-celcius)
;           
; Example:  2.07 V would be represented by the number
;           20700. (The real value * 1000).
TEMP_READ:

read_lm335:
    anl ADCCON0, #0xf0          ; *** LM335 ***
    orl ADCCON0, #0x01			; AIN1 
    lcall Avg_ADC
    mov x+0, R0 			    ; load lm335 reading to x
	mov x+1, R1
	mov x+2, #0 			
	mov x+3, #0
	Load_y(50300) ; VCC voltage measured
	lcall mul32	  ; VCC measured (50.3) * 4095
	Load_y(4095) ; 2^12-1
	lcall div32
	Load_y(27300) ; / 27.3
	lcall sub32
	Load_y(100)
	lcall mul32	; * 100			; Code from lab 3, (((x * 50300)/4095)-27300) * 100 
	mov temp_lm+0, x+0          ; store 3 decimal lm335 value for later in degrees celcius
    mov temp_lm+1, x+1				
    mov temp_lm+2, x+2
    mov temp_lm+3, x+3

read_opamp:
	anl ADCCON0, #0xf0          ; *** OPAMP ***
    orl ADCCON0, #0x07	; 
	lcall Avg_ADC
	mov x+0, R0 			    ; load opamp reading to x
	mov x+1, R1
	mov x+2, #0 			
	mov x+3, #0
    Load_y(503)                ; load const vled ref (2070 mV) into y      
    lcall mul32
	Load_y(4095)
    lcall div32                 
	Load_y(1000000)				
	lcall mul32					
	Load_y(213)
	lcall div32
	Load_y(41)
	lcall div32 
	Load_y(2200)
	lcall add32					

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
	
export_to_main:					; exports temp reading to rest of code
	mov x+0, temp_mc+0          
    mov x+1, temp_mc+1
    mov x+2, temp_mc+2
    mov x+3, temp_mc+3
    mov tempc, x+0              ; Both tempc and x now stores temp (C)

;lcall TEMP_READ

;Export:							; Data export to python
;	mov R2, #250 				; Wait 500 ms between conversions
;	lcall waitms
;	mov R2, #250
;	lcall waitms				; Sends binary contents of 
;
;    lcall SendBin				; temp_mc and data_out to python
;
;	; /* FSM1 STATE CHANGE CONTROLS */
;	ljmp FSM1

; REQUIREMENTS
; Start/Stop button, to do this, make routine which displays "stopped" for a little bit
; Temperature display, implemented already
; Running time display, implement in main
; 

FSM1:
	mov a, FSM1_state
	cjne a, #0, contd	; When not in state 0 we need to get tempc and display
	ljmp FSM1_state0
contd:
	mov x+0, tempc
	mov x+1, #0
	mov x+2, #0
	mov x+3, #0
    lcall hex2bcd
	Set_Cursor(1,1)
	Send_Constant_String(#value_message)
	Set_Cursor(2,1)
	Send_Constant_String(#temp_message)
	Set_Cursor(2,12)
    Display_BCD(bcd+1)
    Set_Cursor(2,12)
    Display_char(#0x20)
    Set_Cursor(2,14)
	Display_BCD(bcd+0)

    mov x+0, temp_lm+0       	; load lm335 temp to y
    mov x+1, temp_lm+1
    mov x+2, temp_lm+2
    mov x+3, temp_lm+3
	Load_y(1000)
	lcall div32
	lcall hex2bcd
    Set_Cursor(1,12)
	Display_BCD(bcd+0)


FSM1_state0:
	cjne a, #0, FSM1_state1 ; if FSM1_state (currently stored in a) is not equal to zero (ie. state zero), go to state 1
	mov pwm, #0
	Set_Cursor(1,16)
	Display_BCD(#0x00)
	clr seconds_flag
	; Wait 50 ms between readings
	mov R2, #50
	lcall waitms
	lcall ADC_to_PB
	ljmp paraminput
	
paramindone:
	; check for push button input, PB0 is start/stop
	jb PB0, FSM1_state0_done
	mov FSM1_state, #1

FSM1_state0_done:
	ljmp FSM_sys
	;ljmp FSM1

FSM1_state1:
	cjne a, #1, FSM1_state2
	mov pwm, #100
	Set_Cursor(1,15)
	Display_BCD(#0x01)
	mov seconds, #0
	mov a, #150
	clr c
	subb a, tempc
	jnc FSM1_state1_done
	mov FSM1_state, #2

FSM1_state1_done:
	ljmp FSM_sys

FSM1_state2:
	cjne a, #2, FSM1_state3
	mov pwm, #20
	Set_Cursor(1,15)
	Display_BCD(#0x02)
	jnb seconds_flag, FSM_state2_funk
	;mov a, #60
	mov a, SoakTime
	clr c
	subb a, seconds	 	; Want time to be greater than 60 seconds
	jc FSM1_state2_done
	mov FSM1_state, #3

FSM_state2_funk:
	mov seconds, #0 	; Set seconds so we can count up to the required time 
	setb seconds_flag	; seconds flag so we don't reset seconds_flag multiple times
	ljmp FSM1_state2	

FSM1_state2_done:
	ljmp FSM_sys

FSM1_state3:
	cjne a, #3, FSM1_state4
	mov pwm, #100
	Set_Cursor(1,15)
	Display_BCD(#0x03)
	;mov a, #220
	mov a, ReflowTemp
	clr seconds_flag
	clr c
	subb a, tempc
	jnc FSM1_state3_done
	mov FSM1_state, #4

FSM1_state3_done:
	ljmp FSM_sys

FSM1_state4:
	cjne a, #4, FSM1_state5
	mov pwm, #20 
	Set_Cursor(1,15)
	Display_BCD(#0x04)
	jnb seconds_flag, FSM1_state4_funk
	;mov a, #45
	mov a, ReflowTime
	clr c 
	subb a, seconds ; when seconds is greater than 45, there will be a carry bit
	jc FSM1_state4_done
	mov FSM1_state, #5

FSM1_state4_funk:
	mov seconds, #0
	setb seconds_flag
	ljmp FSM1_state4

FSM1_state4_done:
	ljmp FSM_sys

FSM1_state5:
	cjne a, #5, FSM1_state6		; if the state is not in 0-5, then it must be 10 (aka the abort state)
	mov pwm, #0
	Set_Cursor(1,15)
	Display_BCD(#0x05)
	mov a, #60
	clr c
	subb a, tempc
	jc FSM1_state5_done
	mov FSM1_state, #6

FSM1_state5_done:
	ljmp FSM_sys

FSM1_abort_state_im:
	mov FSM1_state, #10
    ljmp FSM1_abort_state

;;;

FSM1_state6:
	cjne a, #6, FSM1_abort_state_im
	Set_Cursor(1,15)
	Display_BCD(#0x06)

;alarm sound 
;first dadada

	jb PB0, FSM1_state6_done
	mov FSM1_state, #0

FSM1_state6_done:
	ljmp FSM_sys


	;;;;;

FSM1_abort_state:						; When the abort state is triggered, turn everything off and remain in this state utill you reset
	cjne a, #10, FSM1_error				; if state is somehow neither 0-5 or 10, go to state error
	mov pwm, #0
	Set_Cursor(1,1)
	Send_Constant_String(#abort_message)

	ljmp FSM1_abort_state

FSM1_error:
	mov pwm, #0
	Set_Cursor(1,1)
	Send_Constant_String(#error_message)
	ljmp FSM1_error
	

paraminput:
;--------------------------------------------;
;			OVEN PARAMETER INPUTS			 ;
;--------------------------------------------;

Soak_Temp:
	; If PB1 is pressed, increase soak temp
	jb PB1, Soak_Time
	mov a, SoakTemp
	add a, #0x01
	mov SoakTemp, a
	mov x+0, SoakTemp
	mov x+1, #0
	mov x+2, #0
	mov x+3, #0
    lcall hex2bcd
    Set_Cursor(1,6)
    Display_BCD(bcd+1)
    Set_Cursor(1,6)
    Display_char(#0x20)
    Set_Cursor(1,8)
	Display_BCD(bcd+0)
	ljmp saveit


Soak_Time:
	; If PB2 is pressed, increase soak time
	jb PB2, Reflow_Time	
	mov a, SoakTime
	add a, #0x01
	mov SoakTime, a
	mov x+0, SoakTime
	mov x+1, #0
	mov x+2, #0
	mov x+3, #0
    lcall hex2bcd
	Set_Cursor(1,11)
    Display_BCD(bcd+1)
    Set_Cursor(1,11)
    Display_char(#0x20)
    Set_Cursor(1,13)
	Display_BCD(bcd+0)
	ljmp saveit

Reflow_Time:
	; If PB3 is pressed, increase reflow time
	jb PB3, Reflow_Temp
	mov a, ReflowTime
	add a, #0x01
	mov ReflowTime, a
	mov x+0, ReflowTime
	mov x+1, #0
	mov x+2, #0
	mov x+3, #0
    lcall hex2bcd
	Set_Cursor(2,6)
    Display_BCD(bcd+1)
    Set_Cursor(2,6)
    Display_char(#0x20)
    Set_Cursor(2,8)
	Display_BCD(bcd+0)
	ljmp saveit

Reflow_Temp:
	; If PB4 is pressed, increase reflow temp
	jb PB4, saveit
	mov a, ReflowTemp
	add a, #0x01
	mov ReflowTemp, a
	mov x+0, ReflowTemp
	mov x+1, #0
	mov x+2, #0
	mov x+3, #0
    lcall hex2bcd
	Set_Cursor(2,11)
    Display_BCD(bcd+1)
    Set_Cursor(2,11)
    Display_char(#0x20)
    Set_Cursor(2,13)
	Display_BCD(bcd+0)

saveit:
	ljmp save_parameters

ADC_to_PB:
	anl ADCCON0, #0xF0
	orl ADCCON0, #0x00 ; Select AIN0
	
	clr ADCF
	setb ADCS   ; ADC start trigger signal
    jnb ADCF, $ ; Wait for conversion complete

	setb PB4
	setb PB3
	setb PB2
	setb PB1
	setb PB0

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
	; No pusbutton pressed	
	ret

save_parameters:
	CLR EA  ; MUST disable interrupts for this to work!

	MOV TA, #0aah ; CHPCON is TA protected
	MOV TA, #55h
	ORL CHPCON, #00000001b ; IAPEN = 1, enable IAP mode

	MOV TA, #0aah ; IAPUEN is TA protected
	MOV TA, #55h
	ORL IAPUEN, #00000001b ; APUEN = 1, enable APROM update

	MOV IAPCN, #PAGE_ERASE_AP ; Erase page 3f80h~3f7Fh
	MOV IAPAH, #3fh
	MOV IAPAL, #80h
	MOV IAPFD, #0FFh
	MOV TA, #0aah ; IAPTRG is TA protected
	MOV TA, #55h
	ORL IAPTRG, #00000001b ; write ?1? to IAPGO to trigger IAP process

	MOV IAPCN, #BYTE_PROGRAM_AP
	MOV IAPAH, #0x28h

	;Load 3f80h with SoakTime
	MOV IAPAL, #00h
	MOV IAPFD, SoakTime
	MOV TA, #0aah
	MOV TA, #55h
	ORL IAPTRG,#00000001b

	;Load 3f81h with SoakTemp
	MOV IAPAL, #01h
	MOV IAPFD, SoakTemp
	MOV TA, #0aah
	MOV TA, #55h
	ORL IAPTRG,#00000001b

	;Load 3f82h with ReflowTime
	MOV IAPAL, #02h
	MOV IAPFD, ReflowTime
	MOV TA, #0aah
	MOV TA, #55h
	ORL IAPTRG,#00000001b

	;Load 3f83h with ReflowTemp
	MOV IAPAL, #03h
	MOV IAPFD, ReflowTemp
	MOV TA, #0aah
	MOV TA, #55h
	ORL IAPTRG,#00000001b

	setb EA
	ljmp paramindone

END



