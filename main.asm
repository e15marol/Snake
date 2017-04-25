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
	matrix: .BYTE = 8


init:
    // Sätt stackpekaren till högsta minnesadressen
    ldi rTemp, HIGH(RAMEND)
    out SPH, rTemp
    ldi rTemp, LOW(RAMEND)
    out SPL, rTemp

	ldi rTemp, 0b11111111
	ldi rNoll, 0b00000000


	out DDRB, rTemp
	out DDRC, rTemp
	out DDRD, rTemp


	out PORTB, rNoll
	out PORTC, rNoll
	out PORTD, rNoll

	; Kommentarer balbalbbabl

	rcall clear 
 
 
 	ldi YH, 0 
 	ldi YL, 0 
 
 
 	ldi rTemp, 0b00000001 
 	std Y+0, rTemp 
	ldi rTemp, 0b00000000 
 	std Y+1, rTemp 
 	ldi rTemp, 0b00000000 
 	std Y+2, rTemp 
 	ldi rTemp, 0b00000000 
 	std Y+3, rTemp 
 	ldi rTemp, 0b00000000 
 	std Y+4, rTemp 
 	ldi rTemp, 0b00000000 
 	std Y+5, rTemp 
 	ldi rTemp, 0b00000000 
 	std Y+6, rTemp 
 	ldi rTemp, 0b00000000 
 	std Y+7, rTemp 





	
main:

	ldi YH, 0
	ldi YL, 0

	sbi PORTC, PC0	
	ld rSnake, Y+
	rcall Laddarad
	rcall clear	
	cbi PORTC, PC0

	sbi PORTC, PC1	
	ld rSnake, Y+
	rcall Laddarad
	rcall clear	
	cbi PORTC, PC1

	sbi PORTC, PC2	
	ld rSnake, Y+
	rcall Laddarad
	rcall clear	
	cbi PORTC, PC2

	sbi PORTC, PC3	
	ld rSnake, Y+
	rcall Laddarad
	rcall clear	
	cbi PORTC, PC3

	sbi PORTD, PD3	
	ld rSnake, Y+
	rcall Laddarad
	rcall clear	
	cbi PORTD, PD3

	sbi PORTD, PD4	
	ld rSnake, Y+
	rcall Laddarad
	rcall clear	
	cbi PORTD, PD4

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