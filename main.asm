;
; Snake.asm
;
; Created: 2017-04-20 15:17:06
; Author : a15kriel
;


; Replace with your application code

	.DEF rTemp				= r16
	.DEF rNoll				= r17
	.DEF rPORTB				= r20
	.DEF rPORTC				= r21
	.DEF rPORTD				= r22


	ldi rTemp, 0b11111111
	ldi rNoll, 0b00000000


	out DDRB, rTemp
	out DDRC, rTemp
	out DDRD, rTemp


	out PORTB, rNoll
	out PORTC, rNoll
	out PORTC, rNoll



	
main:

	ldi rPORTB, 0b11111111
	ldi rPORTC, 0b11111110
	ldi rPORTD, 0b10111111
	
	out PORTB, rPORTB
	out PORTC, rPORTC
	out PORTD, rPORTD





    rjmp main
