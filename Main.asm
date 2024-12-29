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
BAUD                EQU 115200 							; Baud rate of UART in bps
TIMER1_RELOAD       EQU (0x100-(CLK/(16*BAUD)))
TIMER0_RELOAD_1MS   EQU (0x10000-(CLK/1000))
TIMER2_RATE 		EQU 100 							; 1/100 = 10ms
TIMER2_RELOAD   	EQU (65536-(CLK/(16*TIMER2_RATE)))
GAIN				EQU 25
;V2C_DIVISOR			EQU (GAIN*41)
V2C_DIVISOR			EQU 8723

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
BUTTON_PORT     equ 0x00			; AIN port numbers
LM335_PORT 		equ 0x05
OPAMP_PORT 		equ 0x07
AINCONFIG		equ 0b10100001		; bits 1 = toggled analog in

; /*** VECTORS ***/
org 0000H
   	ljmp Main

org 002BH					; timer 2 enable
	ljmp Timer2_ISR


; /*** DIRECT ACCESS VARIABLES @RAM 0x30 -> 0x7F ***/
DSEG at 30H
x:   			ds 4		; for math
y:   			ds 4
data_out:   	ds 4		; for python
bcd: 			ds 5		; for display
			
tempc: 			    ds 1
temp_lm_c:          ds 1
temp_op_c:          ds 1
temp_mc:		    ds 4
OPAMP_temp: 	    ds 4
temp_lm:   		    ds 4
temp_offset:	    ds 2
mV_offset:  	    ds 2
Band_Gap_Voltage:   ds 2
Band_Gap_Value:     ds 2
Band_Gap_Voltage_div10:     ds 2
Band_Gap_Value_div10:       ds 2
adc_out:            ds 2
adc_temp0:          ds 1
adc_temp1:          ds 1

adc1: ds 2
adc2: ds 2

oven_state:  	    ds 1		; fsm states
button_state:       ds 1

pwm_counter:	ds 1		; time check and pwm
count10ms: 		ds 1
seconds: 		ds 1
pwm:			ds 1
abort_time:		ds 1

ReflowTemp: 	ds 1		; reflow profile parameters
ReflowTime:		ds 1
SoakTemp:		ds 1
SoakTime:		ds 1

Val_test:		ds 4
Val_temp:		ds 4

lcd_bin:        ds 1
lcd_bcd:        ds 2
lcd_bcd0:       ds 1
lcd_bcd1:       ds 1
lcd_bcd2:       ds 1
lcd_test1:      ds 1
lcd_test2:      ds 1

; /*** SINGLE BIT VARIABLES @RAM 0x20 -> 0x2F ***/
BSEG 
mf: 			dbit 1
ms20_flag:      dbit 1
ms40_flag:      dbit 1 
ms80_flag:      dbit 1
ms160_flag:     dbit 1
ms320_flag:     dbit 1
half_s_flag:	dbit 1
s_flag: 		dbit 1
s_rst_flag:		dbit 1
s_clk:          dbit 1
s2_clk:         dbit 1
abort_flag:		dbit 1
conf_flag:      dbit 1

upf:            dbit 1
dnf:            dbit 1
select_flag:    dbit 1
startstop_flag: dbit 1

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

abort_message: 	  db 'ABORTABORTABORT ', 0

$NOLIST
$include(math32.inc)
$include(lcd.inc) ; A library of LCD related functions and utility macros
$include(adc.inc)
$include(troubleshooter.inc) 
$include(serial.inc)
$include(time.inc)
$include(temp_read.inc)
$include(button.inc)
$include(display.inc)
$LIST


InitAll:
	; /*** SERIAL PORT INITIALIZATION ***/
	mov	P3M1,#0b10000000  			; Configure all the pins for biderectional I/O
	mov	P3M2,#0b00000000
	mov	P1M1,#0b10000000
	mov	P1M2,#0b00000000
	mov	P0M1,#0b10000000
	mov	P0M2,#0b00000000
    ; Since the reset button bounces, we need to wait a bit before
    ; sending messages, otherwise we risk displaying gibberish!
    ;mov R1, #200
    ;mov R0, #104
    ;djnz R0, $   				; 4 cycles->4*60.285ns*104=25us
    ;djnz R1, $-4 				; 25us*200=5.0ms
    mov R7, #5
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

	clr abort_flag
    clr s_clk

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
	
	; Initialize the pin used by the ADC (P1.1) as input. P1.7 initialized for ADC pins input
    ; AIN5: LM335, AIN7: adc pints, AIN1: OPAMP
	orl	P1M1, #0b10100010
	anl	P1M2, #0b01011101
	
	; Initialize and start the ADC:
	anl ADCCON0, #0xF0
	orl ADCCON0, #0x07 			; Select channel 7
	; AINDIDS select if some pins are analog inputs or digital I/O:
	mov AINDIDS, #0x00 			; Disable all analog inputs
	orl AINDIDS, #AINCONFIG		
	orl ADCCON1, #0x01 			; Enable ADC
	mov temp_offset, #0x00

	; ISR 2 ---
	mov T2CON, #0 ; Stop timer/counter.  Autoreload mode.
	mov TH2, #high(TIMER2_RELOAD)
	mov TL2, #low(TIMER2_RELOAD)
	; Set the reload value
	mov T2MOD, #0b1010_0000 ; Enable timer 2 autoreload, and clock divider is 16
	mov RCMP2H, #high(TIMER2_RELOAD)
	mov RCMP2L, #low(TIMER2_RELOAD)
	; Init the free running 10 ms counter to zero
	mov pwm_counter, #0
	; Enable the timer and interrupts
	orl EIE, #0x80 ; Enable timer 2 interrupt ET2=1
    setb TR2  ; Enable timer 2


	setb EA ; Enable global interrupts
    ret


;---------------------------------------------------;
;---------------------------------------------------;
;---------------------------------------------------;
; ISR for Timer 2 (Code here Executes every 10ms)   ;
;---------------------------------------------------;
Timer2_ISR:
;  **** 10ms ZONE **** 
	clr TF2  ; Timer 2 doesn't clear TF2 automatically. Do it in the ISR.  It is bit addressable.
	push acc
	push psw
	
	; inc pwm_counter
	; clr c
	; mov a, pwm
	; subb a, pwm_counter ; If pwm_counter <= pwm then c=1
	; cpl c
	; mov PWM_OUT, c
	
    
    


	
	inc count10ms               
	mov a, count10ms

    cpl ms20_flag       ; this would only be 1 every 20 ms

Runs_every_20ms:
    jnb ms20_flag, Check_Half_Second
    cpl ms40_flag
    lcall ADC_to_PB ;;;; -
    clr a
    clr c

Runs_every_40ms:
    jnb ms40_flag, Check_Half_Second
    cpl ms80_flag

    ; mov a, oven_state
    ; cjne a, #0, Runs_every_80ms
    ; lcall Button_Display ;;;; -
    ; clr a 
    ; clr c
    

Runs_every_80ms:
    jnb ms80_flag, Check_Half_Second
    cpl ms160_flag

    mov a, oven_state
    cjne a, #0, Runs_every_160ms
    lcall Button_Display
    clr a 
    clr c
    
Runs_every_160ms:
    jnb ms160_flag, Check_Half_Second
    cpl ms320_flag

    

    lcall Send_Serial ;;;; -      
    ; ^^ Sends data to Python  (reference: "serial.inc")
    lcall Oven_Display ;;;;-
    clr a ; clean up after Oven_Display
    clr c

Runs_every_320ms:
    jnb ms320_flag, Check_Half_Second
    
    ;lcall TEMP_READ
 

Check_Half_Second:
    mov a, count10ms
	cjne a, #50, Check_Second
	setb half_s_flag
    
    lcall TEMP_READ
    

 
Check_Second:                   ; Check if count10ms has accumulated
	mov a, count10ms            ; 100 times since 100*10ms = 1s
	cjne a, #100, Timer2_ISR_done

; **** 1 second ZONE ****
	mov count10ms, #0
	setb s_flag
	setb half_s_flag
	inc seconds
	clr a 
	mov psw, a

	;lcall OvenAbortRoutine      ; Check for Oven Abort Conditions

Timer2_ISR_done:
	pop acc
	pop psw
	reti
; ^^^^ End of Timer 2 ISR ^^^^



; ------ THIS CODE ONLY EXECUTES ONCE ON START-UP ------ ;
Main:
    mov SP, #0x7F 	; Set the stack pointer to the begining of idata
    mov tempc, #0
	
    lcall InitAll
    lcall LCD_4BIT
   
	clr s_flag              ; Initialize all variables
    clr s2_clk
    setb ms20_flag
    setb ms40_flag
    setb ms80_flag
    setb ms160_flag
    setb ms320_flag
	setb half_s_flag
	clr abort_flag
    clr upf 
    clr dnf
    clr conf_flag
    clr select_flag
    clr startstop_flag
	mov oven_state, #0
 

    ;mov button_state, #0
	mov seconds, #0
	mov ReflowTemp, #180
	mov ReflowTime, #5
	mov SoakTime, #5
	mov SoakTemp, #100

    ; mov data_out+0, #0
    mov data_out+1, #0
    mov data_out+2, #0
    mov data_out+3, #0

    clr a
    mov temp_mc+0, a 
    mov temp_mc+1, a 
    mov temp_mc+2, a 
    mov temp_mc+3, a
    mov temp_lm+0, a 
    mov temp_lm+1, a 
    mov temp_lm+2, a 
    mov temp_lm+3, a 

    ; mov data_out+0, #9
	
	; Set_Cursor(1, 1)                        ; Default LCD msg
    ; Send_Constant_String(#test_message)
	; Set_Cursor(2, 1)
    ; Send_Constant_String(#value_message)


; -------- FOREVER LOOP, REPEATS EVERY 1/2 SECOND --------- ;
Forever:

             ; Checks ADC temperature reading
                            ; (reference: "temp_read.inc")



;lcall TEMP_READ






; Checks the state of which the Oven is in 
; To assign that state to the Oven FSM
; This must be in this part since it itself contains
; infinite loops, so this way ISRs can still run properly
; since they "interupt" the Main code independently
	ljmp OvenFSM              ; Checks Oven State
OvenFSMReturn:                ; return label for Oven State
	


Forever_End:
	; mov R2, #250 				; Wait 500 ms between conversions
	; lcall waitms
	; mov R2, #200
	; lcall waitms
	
	jnb half_s_flag, $ 			; synchronize Main Forever loop with ISR 2
	clr half_s_flag

    
    cpl s_clk                  ; pos/neg edge every 1/2 second
    jnb s_clk, Forever_End_Return
    cpl s2_clk                ; pos/neg edge every 1 second

Forever_End_Return:
	ljmp Forever

; ^^^^ END OF FOREVER LOOP CODE SEGMENT ^^^^ ;


; **************************************************************** ;
;  
;      / \__
;    (    @\___
;    /         O  ↓↓↓ [BELOW ARE JUST FSM FUNCTIONS] ↓↓↓  & Abort routine 
;   /   (_____/
;  /_____/   U
;  
; **************************************************************** ;

; ============================== ;
; ========== OVEN FSM ========== ;
; ============================== ;
OvenFSM:                  ; Checks current OVEN FSM state
    mov a, oven_state 

Oven0: ;allow user input
    cjne a, #0, Oven1       ; check if this is the right state to be in rn
    ; if state is 0, the purpose of this state is to go to button fsm
    mov button_state, #0
    ljmp ButtonFSM_Start    ; Jumps to Button FSM
    ButtonFSMret:           ; Button FSM jumps back here once its done             
    
    mov oven_state, #1
    mov seconds, #0         ; rst seconds before going to next state
    ;sjmp Oven1b
    ljmp OvenFSMReturn

Oven1:                      ; oven processe really only begins here 
    cjne a, #1, Oven2
; Oven1b:
;     mov x+0, tempc
;     mov y+0, SoakTemp
;     clr mf                  
;     ; ^^ clear mf before operation to eliminate any possible values within mf that remains from before
;     lcall x_gteq_y          ; tempc >= SoakTemp, mf = 1
;     jnb mf, o1ret           ; if mf = 0, then temp is still lower than SoakTemp, so just go back to main loop
;     mov oven_state, #2      ; here, tempc >= SoakTemp is True, mf = 1
;                               ; therefore, transition to oven state 2
;     mov seconds, #0        ; rst seconds btw state trans
    mov pwm, #100
    mov seconds, #0
    mov a, SoakTemp
    clr c
    subb a, tempc
    jnc o1ret
    mov oven_state, #2
    o1ret:
    ljmp OvenFSMReturn
    
Oven2:
    cjne a, #2, Oven3
    ; mov x+0, seconds
    ; mov y+0, SoakTime
    ; clr mf
    ; lcall x_gteq_y          ; check seconds >= SoakTime
    ; jnb mf, o2ret
    ; mov oven_state, #3      ; time cond met -> 3 
    ; mov seconds, #0
    mov pwm, #20
    mov a, SoakTime
    clr c
    subb a, seconds
    jnc o2ret
    mov oven_state, #3
    o2ret:
    ljmp OvenFSMReturn

Oven3:
    cjne a, #3, Oven4
    ; mov x+0, tempc
    ; mov y+0, ReflowTemp     ; check tempc >= Reflow Temp
    ; clr mf
    ; lcall x_gteq_y          
    ; jnb mf, o3ret
    ; mov oven_state, #4      ; temp cond met -> 4
    ; mov seconds, #0
    mov pwm, #100
    mov seconds, #0
    mov a, ReflowTemp
    clr c
    subb a, tempc
    jnc o3ret
    mov oven_state, #4
    o3ret:
    ljmp OvenFSMReturn

Oven4:
    cjne a, #4, Oven5
    ; mov x+0, seconds
    ; mov y+0, ReflowTime
    ; clr mf
    ; lcall x_gteq_y          ; check seconds >= ReflowTime
    ; jnb mf, o4ret
    ; mov oven_state, #5      ; time cond met -> 5
    ; mov seconds, #0
    mov pwm, #20
    mov a, ReflowTime
    clr c
    subb a, seconds
    jnc o4ret
    mov oven_state, #5
    o4ret:
    ljmp OvenFSMReturn

Oven5:
    cjne a, #5, Oven6
    ; mov x+0, #60
    ; mov y+0, tempc
    ; clr mf
    ; lcall x_gteq_y          ; check 60 >= tempc
    ; jnb mf, o5ret
    ; mov oven_state, #6      ; temp cond met -> 6, temp now below 60.
    ; mov seconds, #0
    mov pwm, #0
    mov seconds, #0
    mov a, tempc
    clr c
    subb a, #60
    jnc o5ret
    mov oven_state, #6
    o5ret:
    ljmp OvenFSMReturn

Oven6: ; done state
    cjne a, #6, OvenAbort
    mov x+0, seconds
    mov y+0, #5
    lcall x_gteq_y
    jnb mf, o6ret
    clr mf
    ;mov oven_state, #0  ; time cond met -> 0
    mov seconds, #0
    o6ret:
    ljmp OvenFSMReturn

OvenAbort:
    cjne a, #15, OvenReturn
    Set_Cursor(1,1)
    Send_Constant_String(#abort_message)
    ljmp OvenFSMReturn

OvenReturn:
    ljmp OvenFSMReturn

; ^^^^ END of Oven FSM ^^^^



; ================================ ;
; ========== BUTTON FSM ========== ;
; ================================ ;

ButtonFSM_Start: ; button_state = 0 
    mov button_state, #0 ;lcd controls rely on this
    ; Welcome Message is displayed to user in this state
    ; waits for user input to press button 3. will stay here as long as button 3 is not pressed
    ; note that conf_flag gets set in an interrupt, so this does not cause an infinite loop >:^)
    jb select_flag, ButtonFSM_Start
    Wait_Milli_Seconds(#50) ; <----- debounce mitigation
    jb select_flag, ButtonFSM_Start
    jnb select_flag, $

    
; ----- button_state = 1 -----
ButtonFSM_Stime:                
    mov button_state, #1
   
    jb upf, check_pressed_down1     ; upf = up flag: 
    Wait_Milli_Seconds(#50)
    jb upf, check_pressed_down1
    jnb upf, $
    inc SoakTime

check_pressed_down1:
    jb dnf, check_pressed_sel1
    Wait_Milli_Seconds(#50)
    jb dnf, check_pressed_sel1
    jnb dnf, $
    dec SoakTime

check_pressed_sel1:
    jb select_flag, ButtonFSM_Stime
    Wait_Milli_Seconds(#50)
    jb select_flag, ButtonFSM_Stime
    jnb select_flag, $

; ----- button_state = 2 -----
ButtonFSM_Stemp:                
    mov button_state, #2        ; again, to indicate the current state of ButtonFSM for different displays

    jb upf, check_pressed_down2
    Wait_Milli_Seconds(#50)
    jb upf, check_pressed_down2
    jnb upf, $
    inc SoakTemp

check_pressed_down2:
    jb dnf, check_pressed_sel2
    Wait_Milli_Seconds(#50)
    jb dnf, check_pressed_sel2
    jnb dnf, $
    dec SoakTemp

check_pressed_sel2:
    jb select_flag, ButtonFSM_Stemp
    Wait_Milli_Seconds(#50)
    jb select_flag, ButtonFSM_Stemp
    jnb select_flag, $       
   
; ----- button_state = 3 -----
ButtonFSM_Rtime:                
    mov button_state, #3        

    jb upf, check_pressed_down3
    Wait_Milli_Seconds(#50)
    jb upf, check_pressed_down3
    jnb upf, $
    inc ReflowTime

check_pressed_down3:
    jb dnf, check_pressed_sel3
    Wait_Milli_Seconds(#50)
    jb dnf, check_pressed_sel3
    jnb dnf, $
    dec ReflowTime

check_pressed_sel3:
    jb select_flag, ButtonFSM_Rtime
    Wait_Milli_Seconds(#50)
    jb select_flag, ButtonFSM_Rtime
    jnb select_flag, $

; ----- button_state = 4 -----
ButtonFSM_Rtemp:                
    mov button_state, #4

    jb upf, check_pressed_down4     ; upf = up flag: 
    Wait_Milli_Seconds(#50)
    jb upf, check_pressed_down4
    jnb upf, $
    inc ReflowTemp

check_pressed_down4:
    jb dnf, check_pressed_sel4
    Wait_Milli_Seconds(#50)
    jb dnf, check_pressed_sel4
    jnb dnf, $
    dec ReflowTemp

check_pressed_sel4:
    jb select_flag, ButtonFSM_Rtemp
    Wait_Milli_Seconds(#50)
    jb select_flag, ButtonFSM_Rtemp
    jnb select_flag, $

; ----- button_state = 5 -----
ButtonFSM_CONFIRM:                  
    mov button_state, #5

check_conf_yes?:
    jb upf, check_conf_no?     ; up = yes 
    Wait_Milli_Seconds(#50)
    jb upf, check_conf_no?
    jnb upf, $
    ljmp ButtonFSM_Buffer

check_conf_no?:
    jb dnf, ButtonFSM_CONFIRM     ; down = no
    Wait_Milli_Seconds(#50)
    jb dnf, ButtonFSM_CONFIRM
    jnb dnf, $
    ljmp ButtonFSM_Start

ButtonFSM_Buffer:
    mov button_state, #6
    Wait_Milli_Seconds(#100)    ; wait a sec
    mov button_state, #7
    Wait_Milli_Seconds(#100)
    mov button_state, #8
    Wait_Milli_Seconds(#100)
    mov button_state, #9
    Wait_Milli_Seconds(#200)
    ljmp ButtonFSMret   

; ^^^^ END OF BUTTON FSM ^^^^




; ======================================== ;
; ========== OVEN ABORT ROUTINE ========== ;
; ======================================== ;
OvenAbortRoutine:
; check if temperature is above 240
    Load_y(240)
    mov x+0 , tempc
    mov x+1 , #0	
    mov x+2 , #0
    mov x+3 , #0
    lcall x_gteq_y
    jnb mf, OvenAbort2
; if below 240, x_gteq_y does not set the mf bit. skip over to check next condition
	clr mf
	mov oven_state, #15
    ; checks have confirmed temp is above 240. no further checks necessairy so skip to return
    ljmp quitroutine

OvenAbort2:
; check if temperature is below 50
    load_y(50)
    mov x+0, tempc
    mov x+1, #0
    mov x+2, #0
    mov x+3, #0
    lcall x_gteq_y
    jb mf, quitroutine
; if temp is above 50, mf will be set by x_gteq_y. reset the time counter to 0 and exit.
; now if temp is below 50, increment abort time by 1 and check if over 60 sec have passed
    clr mf
    inc abort_time
    load_y(5)
    mov x+0, abort_time
    mov x+1, #0
    mov x+2, #0
    mov x+3, #0
    lcall x_gteq_y
    jnb mf, quittimeroutine
; if time under 50 deg has been shorter than 60 sec, mf will not be set. keep the current value of abort time and return
    mov oven_state, #15
    ljmp quittimeroutine

quitroutine:
    mov abort_time, #0
quittimeroutine:
    clr mf
	ret





    





END



