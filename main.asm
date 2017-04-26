;
; Snake.asm
;
; Created: 2017-04-20 15:17:06
; Author : a15kriel
;


; Replace with your application code

	.DEF rTemp				= r16
	.DEF rNoll				= r17
	.DEF rDirection			= r18
	.DEF rXvalue			= r19
	.DEF rYvalue			= r20
	.DEF rSnake				= r21	
	.DEF rUpdateFlag		= r22
	.DEF rUpdateDelay		= r23


	.DSEG
	matrix: .BYTE 8
	;snake: .BYTE 25

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
	
	
	; A/D omvandling
	ldi rTemp, 0x00 ;värde 0 laddas in i rTemp
	lds rTemp, ADMUX; ADMUX värde laddas in i hela rTemp
	sbr rTemp,(1<<REFS0)|(0<<REFS1)|(1<<ADLAR) ; Alla bitar ändras enligt instruktioner från led spec och laddas in i rTemp
	sts ADMUX, rTemp ; Bitarna som ändrats i rTemp skickas till ADMUX register

	ldi rTemp, 0x00	
	lds rTemp, ADCSRA ; värde 0 laddas in i ADSCRA
	sbr rTemp,(1<<ADPS0)|(1<<ADPS1)|(1<<ADPS2)|(1<<ADEN)
	sts ADCSRA, rTemp ;Värdet på bitarna som ändrats i rTemp sätts in i ADSCRA

	; Sätter allt som output
	out DDRB, rTemp
	out DDRC, rTemp
	out DDRD, rTemp

	; Sätter portarna för Y och X led i joytsticken som input
	cbi DDRC, PC4
	cbi DDRC, PC5

	out PORTB, rNoll
	out PORTC, rNoll
	out PORTD, rNoll

	ldi rUpdateDelay, 0b00000000
	ldi rXvalue, 0b00000000

	rcall clear 
 
 
	ldi YH, 0 
 	ldi YL, 0 

	ldi rTemp, 0b00000000
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

	sbi PORTC, PC0
	;lds rSnake, rXvalue
	rcall Laddarad
	rcall clear
	;cbi PORTC, PC0



/*
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
	cbi PORTD, PD5*/

	cpi rUpdateFlag, 1
	breq updateloop

    jmp main


updateloop:
	inc rUpdateDelay
	cpi rUpdateDelay, 15
	brne skip
	jmp contUpdate
	skip:
	ldi rUpdateFlag, 0b00000000
	jmp main
	

contUpdate:

; Välj x-axel ;Utveckla vidare i kommentarer
 	ldi rTemp, 0x00 
 	lds rTemp, ADMUX 
 	sbr rTemp,(0<<MUX3)|(1<<MUX2)|(0<<MUX1)|(1<<MUX0) ; (0b0101 = 5) 
 	sts ADMUX, rTemp 
 
 
 	; Starta A/D-konvertering.  
 	ldi rTemp, 0x00 
 	lds rTemp, ADCSRA		; Get ADCSRA 
 	sbr rTemp,(1<<ADSC)		; Starta konvertering ---> ADSC = 1 (bit 6) 
 	sts ADCSRA, rTemp		; Ladda in 
 	 
iterate_x: 
 	ldi rTemp, 0x00 
 	lds rTemp, ADCSRA		; Ta nuvarande ADCSRA för att jämföra 
 	sbrc rTemp, 6			; Kolla om bit 6 (ADSC) är 0 i rSettings (reflekterar ADCSRA) (instruktion = Skip next instruction if bit in register is cleared) ; Alltså om ej cleared, iterera. 	 
 	jmp iterate_x			; Iterera 
 	nop 
 
 
 	lds rXvalue, ADCH	; Läs av (kopiera) ADCH, som är de 8 bitarna.  
	lds rSnake, ADCH



	ret

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
	ldi rUpdateFlag, 0b00000001
	reti
