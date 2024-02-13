
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

CLK EQU 16600000 ; Microcontroller system frequency in Hz
BAUD EQU 115200 ; Baud rate of UART in bps
TIMER1_RELOAD EQU (0x100-(CLK/(16*BAUD)))
TIMER0_RELOAD_1MS EQU (0x10000-(CLK/1000))

PAGE_ERASE_AP   EQU 00100010b
BYTE_PROGRAM_AP EQU 00100001b

ORG 0x0000
        ljmp main

;                 1234567890123456    <-This helps determine the location of the counter
soak_text:     db 'Soak: xxxs xxxC ', 0
reflow_text:   db 'Refl: xxxs xxxC ', 0
blank_text:    db '                ', 0


DSEG at 0x30
SoakTime: ds 1
SoakTemp: ds 1
ReflowTime: ds 1
ReflowTemp: ds 1
x:   ds 4
y:   ds 4
bcd: ds 5

cseg
; These 'equ' must match the hardware wiring
LCD_RS equ P1.3
LCD_E equ P1.4
LCD_D4 equ P0.0
LCD_D5 equ P0.1
LCD_D6 equ P0.2
LCD_D7 equ P0.3

$NOLIST
$include(LCD_4bit.inc) ; A library of LCD related functions and utility macros
$include(math32.inc)
$LIST


BSEG
; These five bit variables store the value of the pushbuttons after calling 'LCD_PB' below
PB0: dbit 1
PB1: dbit 1
PB2: dbit 1
PB3: dbit 1
PB4: dbit 1
;systemstate is 1 if oven is on, 0 if oven is off 
SystemState: dbit 1
mf: dbit 1


CSEG
Init_All:
; Configure all the pins for biderectional I/O
mov P3M1, #0x00
mov P3M2, #0x00
mov P1M1, #0x00
mov P1M2, #0x00
mov P0M1, #0x00
mov P0M2, #0x00


orl CKCON, #0x10 ; CLK is the input for timer 1
orl PCON, #0x80 ; Bit SMOD=1, double baud rate
mov SCON, #0x52
anl T3CON, #0b11011111
anl TMOD, #0x0F ; Clear the configuration bits for timer 1
orl TMOD, #0x20 ; Timer 1 Mode 2
mov TH1, #TIMER1_RELOAD ; TH1=TIMER1_RELOAD;
setb TR1

; Using timer 0 for delay functions. Initialize here:
clr TR0 ; Stop timer 0
orl CKCON,#0x08 ; CLK is the input for timer 0
anl TMOD,#0xF0 ; Clear the configuration bits for timer 0
orl TMOD,#0x01 ; Timer 0 in Mode 1: 16-bit timer

ret
wait_1ms:
    clr TR0 ; Stop timer 0
    clr TF0 ; Clear overflow flag
    mov TH0, #high(TIMER0_RELOAD_1MS)
    mov TL0,#low(TIMER0_RELOAD_1MS)
    setb TR0
    jnb TF0, $ ; Wait for overflow
ret
; Wait the number of miliseconds in R2
waitms:
    lcall wait_1ms
    djnz R2, waitms
ret
LCD_PB:
; Set variables to 1: 'no push button pressed'
    setb PB0
    setb PB1
    setb PB2
    setb PB3
    setb PB4
    ; The input pin used to check set to '1'
    setb P1.5

    ; Check if any push button is pressed
    clr P0.0
    clr P0.1
    clr P0.2
    clr P0.3
    clr P1.3

    jb P1.5, LCD_PB_Done

    ; Debounce
    mov R2, #50
    lcall waitms

    jb P1.5, LCD_PB_Done
    ; Set the LCD data pins to logic 1
    setb P0.0
    setb P0.1
    setb P0.2
    setb P0.3
    setb P1.3

    ; Check the push buttons one by one
    clr P1.3
    mov c, P1.5
    mov PB4, c
    setb P1.3
    
    clr P0.0
    mov c, P1.5
    mov PB3, c
    setb P0.0
    
    clr P0.1
    mov c, P1.5
    mov PB2, c
    setb P0.1
    
    clr P0.2
    mov c, P1.5
    mov PB1, c
    setb P0.2
    
    clr P0.3
    mov c, P1.5
    mov PB0, c
    setb P0.3
    
LCD_PB_Done:
    ret

main:
	mov sp, #0x7f
	lcall Init_All
    lcall LCD_4BIT
	clr SystemState

	clr a
	mov SoakTemp, a
    mov SoakTime, a
    mov ReflowTemp, a   
    mov ReflowTime, a
    mov x+0, a
    mov x+1, a
    mov x+2, a
    mov x+3, a
    mov y+0, a
    mov y+1, a
    mov y+2, a
    mov y+3, a

    ; initial messages in LCD
	Set_Cursor(1, 1)
    Send_Constant_String(#soak_text)
	Set_Cursor(2, 1)
    Send_Constant_String(#reflow_text)

    Set_Cursor(1,8)
    mov x, SoakTemp
    lcall hex2bcd
	Display_BCD(bcd)

    Set_Cursor(1,13)
	mov x, SoakTime
    lcall hex2bcd
	Display_BCD(bcd)

    Set_Cursor(2,8)
	mov x, ReflowTime
    lcall hex2bcd
	Display_BCD(bcd)

    mov x, ReflowTemp
    Set_Cursor(2,13)
    lcall hex2bcd
	Display_BCD(bcd)
	
Forever:
	lcall LCD_PB
	;lcall Display_PushButtons_ADC	

	; If the oven is on, skip over param adjustments
	jnb SystemState, Soak_Temp
    ljmp Start_Stop


Soak_Temp:
	; If PB1 is pressed, increase soak temp
	jb PB1, Soak_Time
	mov a, SoakTemp
	add a, #0x01
	mov SoakTemp, a
	Set_Cursor(1,8)
	mov x, SoakTemp
    lcall hex2bcd
	Display_BCD(bcd)
	
Soak_Time:
	; If PB2 is pressed, increase soak time
	jb PB2, Reflow_Time
	mov a, SoakTime
	add a, #0x01
	mov SoakTime, a
	Set_Cursor(1,13)
	mov x, SoakTime
    lcall hex2bcd
	Display_BCD(bcd)

Reflow_Time:
	; If PB3 is pressed, increase reflow time
	jb PB3, Reflow_Temp
	mov a, ReflowTime
	add a, #0x01
	mov ReflowTime, a
	Set_Cursor(2,8)
	mov x, ReflowTime
    lcall hex2bcd
	Display_BCD(bcd)

Reflow_Temp:
	; If PB4 is pressed, increase reflow temp
	jb PB4, Start_Stop
	mov a, ReflowTemp
	add a, #0x01
	mov ReflowTemp, a
    mov x, ReflowTemp
    Set_Cursor(2,13)
    lcall hex2bcd
	Display_BCD(bcd)
	
	; If PB0 is pressed, start/stop
Start_Stop:
	jb PB0, wait_50ms
	cpl SystemState
	jb SystemState, SystemStarted
    ljmp SystemStopped

SystemStarted:
    ; Code to start or continue the system operation
    ; non-volatile storage
	Set_Cursor(1,1)
	Send_Constant_String(#blank_text)
	Set_Cursor(2,1)
	Send_Constant_String(#blank_text)
	mov FSM1_state, #0
    ljmp Save_Parameters

wait_50ms:
	; Wait 50 ms between readings
	mov R2, #50
	lcall waitms
	
	ljmp Forever

SystemStopped:
    ; Code to stop the system operation
    Set_Cursor(1, 1)
    Send_Constant_String(#soak_text)
	Set_Cursor(2, 1)
    Send_Constant_String(#reflow_text)

    Set_Cursor(1,8)
    mov x, SoakTemp
    lcall hex2bcd
	Display_BCD(bcd)

    Set_Cursor(1,13)
	mov x, SoakTime
    lcall hex2bcd
	Display_BCD(bcd)

    Set_Cursor(2,8)
	mov x, ReflowTime
    lcall hex2bcd
	Display_BCD(bcd)

    mov x, ReflowTemp
    Set_Cursor(2,13)
    lcall hex2bcd
	Display_BCD(bcd)
	mov FSM1_state, #10
	ljmp wait_50ms


Save_Parameters:  ;Saves the values that were set by the user for the FSM
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
	ORL IAPTRG, #00000001b ; write �1� to IAPGO to trigger IAP process
	
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
    
    ljmp wait_50ms

END
