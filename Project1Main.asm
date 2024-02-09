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

CLK                 EQU 16600000 ; Microcontroller system frequency in Hz
BAUD                EQU 115200 ; Baud rate of UART in bps
TIMER1_RELOAD       EQU (0x100-(CLK/(16*BAUD)))
TIMER0_RELOAD_1MS   EQU (0x10000-(CLK/1000))

org 0000H
   ljmp Main
;                     1234567890123456    <- This helps determine the location of the counter
test_message:     db '****LOADING*****', 0
value_message:    db 'TEMP:      ', 0
cel_message:	  db 'CELCIUS  READING',0
fah_message:      db 'FARENHET READING',0
CSEG

; /* PORT DEFINITIONS */
LCD_RS equ P1.3
LCD_E  equ P1.4
LCD_D4 equ P0.0
LCD_D5 equ P0.1
LCD_D6 equ P0.2
LCD_D7 equ P0.3
OPAMP  equ P1.4			; Port 20 

$NOLIST
$include(LCD_4bit.inc) ; A library of LCD related functions and utility macros
$LIST

; /* MATH.INC STUFFS */
DSEG at 30H
x:   		ds 4
y:   		ds 4
data_out:   ds 1

bcd: 		ds 5
temp_out: 	ds 4

VLED_ADC: 	ds 2
dtemp:  	ds 2
temp1: 		ds 1

BSEG
mf: dbit 1

$NOLIST
$include(math32.inc)
$LIST



; /* Configure the serial port and baud rate */

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

	orl	CKCON, #0x10 			; CLK is the input for timer 1
	orl	PCON, #0x80 			; Bit SMOD=1, double baud rate
	mov	SCON, #0x52
	anl	T3CON, #0b11011111
	anl	TMOD, #0x0F 			; Clear the configuration bits for timer 1
	orl	TMOD, #0x20 			; Timer 1 Mode 2
	mov	TH1, #TIMER1_RELOAD 	; TH1=TIMER1_RELOAD;
	setb TR1
	
	; Using timer 0 for delay functions.  Initialize here:
	clr	TR0 					; Stop timer 0
	orl	CKCON,#0x08 			; CLK is the input for timer 0
	anl	TMOD,#0xF0				; Clear the configuration bits for timer 0
	orl	TMOD,#0x01 				; Timer 0 in Mode 1: 16-bit timer
	
	; Initialize the pin used by the ADC (P1.1) as input.
	orl	P1M1, #0b00000010
	anl	P1M2, #0b11111101
	
	; Initialize and start the ADC:
	anl ADCCON0, #0xF0
	orl ADCCON0, #0x07 			; Select channel 7
	; AINDIDS select if some pins are analog inputs or digital I/O:
	mov AINDIDS, #0x00 			; Disable all analog inputs
	orl AINDIDS, #0b10000000 	; P1.1 is analog input
	orl ADCCON1, #0x01 			; Enable ADC

    ret

; /* Send a character using the serial port */
putchar:
    jnb TI, putchar
    clr TI
    mov SBUF, a
    ret


; Send a constant-zero-terminated string using the serial port
SendString:
    clr A
    movc A, @A+DPTR
    jz SendStringDone
    lcall putchar
    inc DPTR
    sjmp SendString
SendStringDone:
    ret

; Sends binary data to Python via putchar
SendBin:					
	clr A					; Sends temp_out
	mov a, temp_out+0
	lcall putchar
	clr A
	mov a, temp_out+1
	lcall putchar
	clr A
	mov a, temp_out+2
	lcall putchar
	clr A
	mov a, temp_out+3
	lcall putchar

	clr A					; Sends data_out
	mov a, data_out 
	lcall putchar
	ret

ASCII_CHAR: 
	db '0123456789ABCDEF'

Hello_World:
    DB  'Hello, World!', '\r', '\n', 0
New_Line:
	DB '\r', '\n', 0

; /* 1ms DELAY FUNCTIONS */
wait_1ms:
	clr	TR0 ; Stop timer 0
	clr	TF0 ; Clear overflow flag
	mov	TH0, #high(TIMER0_RELOAD_1MS)
	mov	TL0,#low(TIMER0_RELOAD_1MS)
	setb TR0
	jnb	TF0, $ ; Wait for overflow
	ret
waitms:
	lcall wait_1ms
	djnz R2, waitms
	ret

Display_formated_BCD: ;4 dig 
	Set_Cursor(1, 1)
    Send_Constant_String(#cel_message)
	Set_Cursor(2, 7)
	Display_BCD(bcd+2)
	Set_Cursor(2, 9)
	Display_BCD(bcd+1)
	Set_Cursor(2, 10)
	Display_BCD(bcd+1)
	
	Set_Cursor(2, 12)
	Display_BCD(bcd+0)
	Set_Cursor(2, 10)
	Display_char(#'.')
	Set_Cursor(2, 7)
	Display_char(#0x20)
	Set_Cursor(2, 15)
	Display_char(#0xDF)
	Set_Cursor(2, 16)
	Display_char(#'C')

	ret

Display_formated_BCD_F: ;4 dig 
	Set_Cursor(1, 1)
    Send_Constant_String(#fah_message)
	Set_Cursor(2, 7)
	Display_BCD(bcd+2)
	Set_Cursor(2, 9)
	Display_BCD(bcd+1)
	Set_Cursor(2, 10)
	Display_BCD(bcd+1)
	
	Set_Cursor(2, 12)
	Display_BCD(bcd+0)
	Set_Cursor(2, 10)
	Display_char(#'.')
	Set_Cursor(2, 7)
	;Display_char(#0x20)
	Set_Cursor(2, 15)
	Display_char(#0xDF)
	Set_Cursor(2, 16)
	Display_char(#'F')

	ret


; /* READ ADC */
Read_ADC:
	clr ADCF
	setb ADCS ;  ADC start trigger signal
    jnb ADCF, $ ; Wait for conversion complete
    
    ; Read the ADC result and store in [R1, R0]
    mov a, ADCRL
    anl a, #0x0f
    mov R0, a
    mov a, ADCRH   
    swap a
    push acc
    anl a, #0x0f
    mov R1, a
    pop acc
    anl a, #0xf0
    orl a, R0
    mov R0, A
	ret

Main:
    mov SP, #0x7F ; Set the stack pointer to the begining of idata
    
    lcall InitAll
    lcall LCD_4BIT

    ; initial messages in LCD
	Set_Cursor(1, 1)
    Send_Constant_String(#test_message)
	Set_Cursor(2, 1)
    Send_Constant_String(#value_message)
	setb cel

	mov data_out, #0b00000001

Forever: ;avaliable: r2, r3

	; /* CALIBRATE */ 
	anl ADCCON0, #0xF0 ; Read the 2.08V LED voltage connected to AIN0 on pin 6
	orl ADCCON0, #0x00 ; Select channel 0
    lcall Read_ADC
    
	mov VLED_ADC+0, R0 ; Save result for later use
	mov VLED_ADC+1, R1

	anl ADCCON0, #0xF0 ; Read the signal connected to AIN7
	orl ADCCON0, #0x07 ; Select channel 7
	lcall Read_ADC

	jb cel, Celcius
	ljmp Fah

Celcius: 
	mov x+0, R0 			; x <- adc(ch) 
	mov x+1, R1
	mov x+2, #0 			; pad w/0
	mov x+3, #0
	Load_y(207000) 			; y <- (x.xxx (vled) * 1000) * 100
	lcall mul32				
    mov y+0, VLED_ADC+0 	; y <- adc(led)
	mov y+1, VLED_ADC+1
	mov y+2, #0 			
	mov y+3, #0 
	lcall div32				; x <- adc(ch) * vled * 100 / adc(led)
	Load_y(273150)			; y <- (2.7315 * 1000) * 100
	lcall sub32	

	lcall hex2bcd 			; Convert to BCD and display
	lcall Display_formated_BCD
    lcall bcd2hex 			;hex number now stored in x

	ljmp Export	 			

Export:							; Data export to python
	mov R2, #250 				; Wait 500 ms between conversions
	lcall waitms
	mov R2, #250
	lcall waitms

	mov temp_out+0, x+0			; Store Computed temperture results 
	mov temp_out+1, x+1			; from x(4) to temp_out (4)
	mov temp_out+2, x+2
	mov temp_out+3, x+3

    lcall SendBin				; Sends 5 Bytes to python, temp_out(4) + data_out(1)	
	
    ljmp Forever

END


