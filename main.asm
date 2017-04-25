;
; Snake.asm
;
; Created: 2017-04-20 15:17:06
; Author : a15kriel
;


; Replace with your application code

	.DEF rTemp				= r16
	.DEF rNoll				= r17
	.DEF rPORTB				= r18
	.DEF rPORTC				= r19
	.DEF rPORTD				= r20
	.DEF rSnake				= r21

	.DSEG
	matrix: .BYTE 8

	.CSEG
	// Interrupt vector table 
	.ORG 0x0000 
 		jmp init // Reset vector 
	.ORG 0x0020 
 		jmp isr_timerOF 
	.ORG INT_VECTORS_SIZE 


init:
    // Sätt stackpekaren till högsta minnesadressen
    ldi rTemp, HIGH(RAMEND)
    out SPH, rTemp
    ldi rTemp, LOW(RAMEND)
    out SPL, rTemp

	ldi rTemp, 0b11111111
	ldi rNoll, 0b00000000
; Initiering av timer
; Pre-scaling konfigurerad genom att s�tta bit 0-2 i TCCR0B (SIDA 7 ledjoy spec)
	ldi rTemp, 0x00
	in rTemp, TCCR0B
	sbr rTemp,(1<<CS00)|(0<<CS01)|(1<<CS02)
	out TCCR0B, rTemp

; Aktivera globala avbrott genom instruktionen sei
	sei

	; Aktivera overflow-avbrottet f�r Timer0 genom att s�tta bit 0 i TIMSK0 till 1
	ldi rTemp, 0x00
	lds rTemp, TIMSK0
	sbr rTemp,(1<<TOIE0)
	sts TIMSK0, rTemp

	out DDRB, rTemp
	out DDRC, rTemp
	out DDRD, rTemp


	out PORTB, rNoll
	out PORTC, rNoll
	out PORTD, rNoll

	

	rcall clear 
 
 
	ldi YH, 0 
 	ldi YL, 0 

	ldi rTemp, 0b00000001 
 	std Y+0, rTemp 
	ldi rTemp, 0b00000010 
 	std Y+1, rTemp 
 	ldi rTemp, 0b00000100 
 	std Y+2, rTemp 
 	ldi rTemp, 0b00001000 
 	std Y+3, rTemp 
 	ldi rTemp, 0b00010000 
 	std Y+4, rTemp 
 	ldi rTemp, 0b00100000 
 	std Y+5, rTemp 
 	ldi rTemp, 0b01000000 
 	std Y+6, rTemp 
 	ldi rTemp, 0b10000000 
 	std Y+7, rTemp






	
main:
	

	ldi YH, 0
	ldi YL, 0
	
;	================================
;			FIRST ROW
;	================================

	sbi PORTC, PC0	
	ld rSnake, Y+
	rcall Laddarad
	rcall clear	
	cbi PORTC, PC0

;	================================
;			SECOND ROW
;	================================

	sbi PORTC, PC1	
	ld rSnake, Y+
	rcall Laddarad
	rcall clear	
	cbi PORTC, PC1

;	================================
;			THIRD ROW
;	================================

	sbi PORTC, PC2	
	ld rSnake, Y+
	rcall Laddarad
	rcall clear	
	cbi PORTC, PC2

;	================================
;			FOURTH ROW
;	================================

	sbi PORTC, PC3	
	ld rSnake, Y+
	rcall Laddarad
	rcall clear	
	cbi PORTC, PC3

;	================================
;			FIFTH ROW
;	================================

	sbi PORTD, PD2
	ld rSnake, Y+
	rcall Laddarad
	rcall clear
	cbi PORTD, PD2

;	================================
;			SIXTH ROW
;	================================

	sbi PORTD, PD3	
	ld rSnake, Y+
	rcall Laddarad
	rcall clear	
	cbi PORTD, PD3

;	================================
;			SEVENTH ROW
;	================================

	sbi PORTD, PD4	
	ld rSnake, Y+
	rcall Laddarad
	rcall clear	
	cbi PORTD, PD4

;	================================
;			EIGTH ROW
;	================================

	sbi PORTD, PD5	
	ld rSnake, Y+
	rcall Laddarad
	rcall clear	
	cbi PORTD, PD5







    rjmp main


Laddarad: 

 
 	in rTemp, PORTD 

 
	bst rSnake, 7 
 	bld rTemp, 6 
	bst rSnake, 6 
	bld rTemp, 7 
 	out PORTD, rTemp 

 	in rTemp, PORTB 
 
 
 	bst rSnake, 5 
 	bld rTemp, 0 
 	bst rSnake, 4 
 	bld rTemp, 1 
 	bst rSnake, 3 
 	bld rTemp, 2 
 	bst rSnake, 2 
 	bld rTemp, 3 
 	bst rSnake, 1 
 	bld rTemp, 4 
 	bst rSnake, 0 
 	bld rTemp, 5 
 
 
 	out PORTB, rTemp 
 
 
 	ret 


clear:

	cbi PORTD, PD6
	cbi PORTD, PD7
	cbi PORTB, PB0
	cbi PORTB, PB1
	cbi PORTB, PB2
	cbi PORTB, PB3
	cbi PORTB, PB4
	cbi PORTB, PB5

	ret

isr_timerOF:
	reti
