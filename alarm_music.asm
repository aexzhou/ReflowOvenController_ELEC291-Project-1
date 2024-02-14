; ISR_example.asm: a) Increments/decrements a BCD variable every half second using
; an ISR for timer 2; b) Generates a 2kHz square wave at pin P1.7 using
; an ISR for timer 0; and c) in the 'main' loop it displays the variable
; incremented/decremented using the ISR for timer 2 on the LCD.  Also resets it to 
; zero if the 'CLEAR' push button connected to P1.5 is pressed.
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

CLK           EQU 16600000 ; Microcontroller system frequency in Hz
TIMER0_RATE   EQU 4096     ; 2048Hz squarewave (peak amplitude of CEM-1203 speaker)
TIMER0_RELOAD EQU ((65536-(CLK/TIMER0_RATE)))
TIMER2_RATE   EQU 1000     ; 1000Hz, for a timer tick of 1ms
TIMER2_RELOAD EQU ((65536-(CLK/TIMER2_RATE)))
;FREQ_DB EQU 50564 ;((65536-(CLK/(2*554)))) ;2217, 50554.05054
;FREQ_GB EQU 54320 ;((65536-(CLK/(2*740)))) ;2959, 54319.78378
;FREQ_F  EQU 53653 ;((65536-(CLK/(2*698)))) ;2793, 
;FREQ_EB EQU 52197 ;((65536-(CLK/(2*622)))) ;2489
;FREQ_BB EQU 47731 ;((65536-(CLK/(2*466)))) ;1864
FREQ_A4  EQU 46672
FREQ_Bb4 EQU 47731
FREQ_B4  EQU 48730
FREQ_C5  EQU 49674
FREQ_Db5 EQU 50564
FREQ_D5  EQU 51404
FREQ_Eb5 EQU 52197
FREQ_E5  EQU 52946
FREQ_F5  EQU 53653
FREQ_Gb5 EQU 54320
FREQ_G5  EQU 54949
FREQ_Ab5 EQU 55543
FREQ_A5  EQU 56104
FREQ_Bb5 EQU 56634
FREQ_B5  EQU 57133
FREQ_C6  EQU 57605
FREQ_Db6 EQU 58050
FREQ_D6  EQU 58470
FREQ_Eb6 EQU 58867
FREQ_E6  EQU 59241
FREQ_F6  EQU 59594
FREQ_Gb6 EQU 59928
FREQ_G6  EQU 60243
FREQ_Ab6 EQU 60540
FREQ_A6  EQU 60820
FREQ_Bb6 EQU 61085
FREQ_B6  EQU 61335

FREQ_C7  EQU 61570
FREQ_Db7 EQU 61793
FREQ_D7  EQU 62002
FREQ_E7  EQU 62201
FREQ_Eb7 EQU 62388
FREQ_F7  EQU 62564
FREQ_Gb7 EQU 62730
FREQ_G7  EQU 62888
FREQ_Ab7 EQU 63037
FREQ_A7  EQU 63178
FREQ_Bb7 EQU 63310
FREQ_B7  EQU 63435


SOUND_OUT     equ P1.6

; Reset vector
org 0x0000
    ljmp main

; External interrupt 0 vector (not used in this code)
org 0x0003
	reti

; Timer/Counter 0 overflow interrupt vector
org 0x000B
	ljmp Timer0_ISR

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

; In the 8051 we can define direct access variables starting at location 0x30 up to location 0x7F
dseg at 0x30
Count1ms:     ds 2 ; Used to determine when half second has passed

;for sound
notes: ds 1
frequency: ds 2

; In the 8051 we have variables that are 1-bit in size.  We can use the setb, clr, jb, and jnb
; instructions with these variables.  This is how you define a 1-bit variable:
bseg
seconds_flag: dbit 1 ; Set to one in the ISR every time 1000 ms had passed
halfsec_flag: dbit 1

cseg
; These 'equ' must match the hardware wiring
LCD_RS equ P1.3
;LCD_RW equ PX.X ; Not used in this code, connect the pin to GND
LCD_E  equ P1.4
LCD_D4 equ P0.0
LCD_D5 equ P0.1
LCD_D6 equ P0.2
LCD_D7 equ P0.3

$NOLIST
$include(LCD_4bit.inc) ; A library of LCD related functions and utility macros
$LIST

;                     1234567890123456    <- This helps determine the location of the counter

;---------------------------------;
; Routine to initialize the ISR   ;
; for timer 0                     ;
;---------------------------------;
Timer0_Init:
	orl CKCON, #0b00001000 ; Input for timer 0 is sysclk/1
	mov a, TMOD
	anl a, #0xf0 ; 11110000 Clear the bits for timer 0
	orl a, #0x01 ; 00000001 Configure timer 0 as 16-timer
	mov TMOD, a
	mov TH0, #high(65536-(CLK/TIMER0_RATE))
	mov TL0, #low(65536-(CLK/TIMER0_RATE))
	; Enable the timer and interrupts
    setb ET0  ; Enable timer 0 interrupt
    clr TR0  ; Start timer 0
	ret

;---------------------------------;
; ISR for timer 0.  Set to execute;
; every 1/4096Hz to generate a    ;
; 2048 Hz wave at pin SOUND_OUT   ;
;---------------------------------;
Timer0_ISR:
	;clr TF0  ; According to the data sheet this is done for us already.
	; Timer 0 doesn't have 16-bit auto-reload, so
	clr TR0
		
	mov TH0, frequency+0
	mov TH1, frequency+1
	
	setb TR0
	
	cpl SOUND_OUT ; Connect speaker the pin assigned to 'SOUND_OUT'!
	reti

;---------------------------------;
; Routine to initialize the ISR   ;
; for timer 2                     ;
;---------------------------------;
Timer2_Init:
	mov T2CON, #0 ; Stop timer/counter.  Autoreload mode.
	mov TH2, #high(TIMER2_RELOAD)
	mov TL2, #low(TIMER2_RELOAD)
	; Set the reload value
	orl T2MOD, #0x80 ; Enable timer 2 autoreload
	mov RCMP2H, #high(TIMER2_RELOAD)
	mov RCMP2L, #low(TIMER2_RELOAD)
	; Init One millisecond interrupt counter.  It is a 16-bit variable made with two 8-bit parts
	clr a
	mov Count1ms+0, a
	mov Count1ms+1, a
	; Enable the timer and interrupts
	orl EIE, #0x80 ; Enable timer 2 interrupt ET2=1
    setb TR2  ; Enable timer 2
	ret

;---------------------------------;
; ISR for timer 2                 ;
;---------------------------------;
Timer2_ISR:
	clr TF2  ; Timer 2 doesn't clear TF2 automatically. Do it in the ISR.  It is bit addressable.
	cpl P0.4 ; To check the interrupt rate with oscilloscope. It must be precisely a 1 ms pulse.
	
	; The two registers used in the ISR must be saved in the stack
	push acc
	push psw
	
	; Increment the 16-bit one mili second counter
	inc Count1ms+0    ; Increment the low 8-bits first
	mov a, Count1ms+0 ; If the low 8-bits overflow, then increment high 8-bits
	jnz Inc_Done
	inc Count1ms+1 

Inc_Done:
    ; Check if a halfsecond has passed
    mov a, Count1ms+0
	cjne a, #low(500), seconds_check ; Warning: this instruction changes the carry flag!
	mov a, Count1ms+1
	cjne a, #high(500), seconds_check

    setb halfsec_flag

seconds_check:
	; Check if a second has passed
	mov a, Count1ms+0
	cjne a, #low(1000), Timer2_ISR_done ; Warning: this instruction changes the carry flag!
	mov a, Count1ms+1
	cjne a, #high(1000), Timer2_ISR_done
    
	; 1000 milliseconds have passed.  Set a flag so the main program knows
	setb seconds_flag ; Let the main program know half second had passed
    setb halfsec_flag
	
	; Reset to zero the milli-seconds counter, it is a 16-bit variable
	clr a
	mov Count1ms+0, a
	mov Count1ms+1, a
Timer2_ISR_done:
	pop psw
	pop acc
	reti
	

;---------------------------------;
; Main program. Includes hardware ;
; initialization and 'forever'    ;
; loop.                           ;
;---------------------------------;
main:
	; Initialization
    mov SP, #0x7F
    mov P0M1, #0x00
    mov P0M2, #0x00
    mov P1M1, #0x00
    mov P1M2, #0x00
    mov P3M2, #0x00
    mov P3M2, #0x00
          
    lcall Timer0_Init
    lcall Timer2_Init
    setb EA   ; Enable Global interrupts
    lcall LCD_4BIT

    clr halfsec_flag
    clr seconds_flag

forever:
    ;first dadada
    clr TR0
    mov frequency+0,#low(FREQ_D7) 
    mov frequency+1,#high(FREQ_D7)
    setb TR0 
    clr seconds_flag
    clr halfsec_flag

    jnb halfsec_flag, $
    clr TR0
    clr seconds_flag
    clr halfsec_flag

    jnb seconds_flag, $
    clr TR0
    mov frequency+0,#low(FREQ_Bb7) 
    mov frequency+1,#high(FREQ_Bb7)
    setb TR0 
    clr seconds_flag
    clr halfsec_flag

    jnb halfsec_flag, $
    clr TR0
    clr seconds_flag
    clr halfsec_flag

    jnb seconds_flag, $
    clr TR0
    mov frequency+0,#low(FREQ_F7) 
    mov frequency+1,#high(FREQ_F7)
    setb TR0 
    clr seconds_flag
    clr halfsec_flag

    jnb seconds_flag, $
    clr TR0
    clr seconds_flag
    clr halfsec_flag

    ;second dadada
    jnb seconds_flag, $
    clr TR0
    mov frequency+0,#low(FREQ_D7) 
    mov frequency+1,#high(FREQ_D7)
    setb TR0 
    clr seconds_flag
    clr halfsec_flag

    jnb halfsec_flag, $
    clr TR0
    clr seconds_flag
    clr halfsec_flag

    jnb seconds_flag, $
    clr TR0
    mov frequency+0,#low(FREQ_Bb7) 
    mov frequency+1,#high(FREQ_Bb7)
    setb TR0 
    clr seconds_flag
    clr halfsec_flag

    jnb halfsec_flag, $
    clr TR0
    clr seconds_flag
    clr halfsec_flag

    jnb seconds_flag, $
    clr TR0
    mov frequency+0,#low(FREQ_F7) 
    mov frequency+1,#high(FREQ_F7)
    setb TR0 
    clr seconds_flag
    clr halfsec_flag

    jnb seconds_flag, $
    clr TR0
    clr seconds_flag
    clr halfsec_flag

    jnb seconds_flag, $
    clr seconds_flag
    clr halfsec_flag
    
    ljmp forever

END



FREQ_C7  EQU 61570
FREQ_Db7 EQU 61793
FREQ_D7  EQU 62002
FREQ_E7  EQU 62201
FREQ_Eb7 EQU 62388
FREQ_F7  EQU 62564
FREQ_Gb7 EQU 62730
FREQ_G7  EQU 62888
FREQ_Ab7 EQU 63037
FREQ_A7  EQU 63178
FREQ_Bb7 EQU 63310
FREQ_B7  EQU 63435
