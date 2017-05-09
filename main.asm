;
; Snake.asm
;
; Created: 2017-04-20 15:17:06
; Author : a15kriel
;


; Registerdefinitioner
	.DEF rTemp			= r16
	.DEF rNoll			= r17
	.DEF rDirection		= r18
	.DEF rXvalue		= r19
	.DEF rYvalue		= r20
	.DEF rSnake			= r21	
	.DEF rUpdateFlag	= r22
	.DEF rUpdateDelay	= r23
	.DEF rCounter       = r24
	.DEF rXkord			= r25
	.DEF rYkord			= r26

; Datasegment
	.DSEG
	matrix: .BYTE 8
	;snake: .BYTE 25
	;apple: .BYTE 25

	.CSEG
	// Interrupt vector table 
	.ORG 0x0000 
 		jmp init // Reset vector 
	.ORG 0x0020 
 		jmp isr_timerOF 
	.ORG INT_VECTORS_SIZE 


init:
    // Sätt stackpekaren till högsta minnesadressen. Detta initialiseras först för att vi ska kunna använda oss utav push och pop-instruktionerna. 
    ldi rTemp, HIGH(RAMEND)
    out SPH, rTemp ; Stackpointer High
    ldi rTemp, LOW(RAMEND)
    out SPL, rTemp ; Stackpointer Low

	ldi rTemp, 0b11111111
	ldi rNoll, 0b00000000

	; Sätter allt som output
	out DDRB, rTemp
	out DDRC, rTemp
	out DDRD, rTemp

	; Sätter portarna för Y och X led i joytsticken som input
	cbi DDRC, PC4
	cbi DDRC, PC5

	
	
	; Initiering av timer
	; Pre-scaling konfigurerad genom att s�tta bit 0-2 i TCCR0B (SIDA 7 ledjoy spec)
	ldi rTemp, 0x00
	in rTemp, TCCR0B
	sbr rTemp,(1<<CS00)|(0<<CS01)|(1<<CS02) ; Timern ökas med 1 för varje 1024:e klockcykel
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
	sbr rTemp,(1<<REFS0)|(0<<REFS1)|(1<<ADLAR) ; Alla bitar ändras enligt instruktioner från led spec och laddas in i rTemp, genom att sätta ADLAR till 1 så ställer vi in A/D omvandlaren till 8-bitarsläge.
	sts ADMUX, rTemp ; Bitarna som ändrats i rTemp skickas till ADMUX register

	ldi rTemp, 0x00	
	lds rTemp, ADCSRA ; värde 0 laddas in i ADSCRA
	sbr rTemp,(1<<ADPS0)|(1<<ADPS1)|(1<<ADPS2)|(1<<ADEN)
	sts ADCSRA, rTemp ;Värdet på bitarna som ändrats i rTemp sätts in i ADSCRA


	out PORTB, rNoll
	out PORTC, rNoll
	out PORTD, rNoll

	ldi rUpdateDelay, 0b00000000
	ldi rXvalue, 0b00000000
	ldi rYvalue, 0b00000000
	ldi rDirection, 0b00000000
	ldi rCounter, 0b00000000

	rcall clear 	

	ldi rXkord, 1
	ldi rYkord, 1


main:

	rcall clear

	; Kordinatsystem införs i koden
	rad1:
	cpi rYkord, 1 ; Kolla ifall rYkord har ett värde lika med 1
	brne rad2 ; Om inte skippa till rad2
	sbi PORTC, PC0 ; Set bit i PORTC, PC0 (Alltså första raden)
	rcall laddarad 
	rcall clear ; Kalla till clear för att sätta värdet 0 på alla kolumner	
	cbi PORTC, PC0

	rad2:
	cpi rYkord, 2
	brne rad3
	sbi PORTC, PC1
	rcall laddarad
	rcall clear
	cbi PORTC, PC1

	rad3:
	cpi rYkord, 4
	brne rad4
	sbi PORTC, PC2
	rcall laddarad
	rcall clear
	cbi PORTC, PC2

	rad4:
	cpi rYkord, 8
	brne rad5
	sbi PORTC, PC3
	rcall laddarad
	rcall clear
	cbi PORTC, PC3

	rad5:
	cpi rYkord, 16
	brne rad6
	sbi PORTD, PD2
	rcall laddarad
	rcall clear
	cbi PORTD, PD2

	rad6:
	cpi rYkord, 32
	brne rad7
	sbi PORTD, PD3
	rcall laddarad
	rcall clear
	cbi PORTD, PD3

	rad7:
	cpi rYkord, 64
	brne rad8
	sbi PORTD, PD4
	rcall laddarad
	rcall clear
	cbi PORTD, PD4

	rad8:
	cpi rYkord, 128
	brne update
	sbi PORTD, PD5
	rcall laddarad
	rcall clear
	cbi PORTD, PD5

	update:

	cpi rUpdateFlag, 1 ;Jämför om rUpdateFlag är detsamma som värdet 1
	breq updateloop ;Branchar till updateloop ifall rUpdateFlag har samma värde som 1

    jmp main


updateloop: 
	inc rUpdateDelay ;Inkrementering av rUpdateDelay
	cpi rUpdateDelay, 15 ; Uppdaterar efter var 15:e interrupt
	brne skip ; Om inte 15 interrupts inte har gått så skippas contUpdate
	rcall contUpdate
	skip:
	ldi rUpdateFlag, 0b00000000 ; rUpdateFlag nollställs inför nästa interrupt
	jmp main
	

contUpdate:

	ldi rUpdatedelay, 0b00000000 ; utan denna rad så kommer ingen rendering ske under updateloop

; Välj x-axel 
 	ldi rTemp, 0x00 
 	lds rTemp, ADMUX 
 	sbr rTemp,(0<<MUX3)|(1<<MUX2)|(0<<MUX1)|(1<<MUX0) ; (0b0101 = 5) Dessa är de lägsta bitarna i ADMUX och genom att sätta dessa väljer man analogingång på ledjoyen. I detta fall har vi valt analogingång 5 (0b0101).
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


	; Välj y-axel 
 	ldi rTemp, 0x00 
 	lds rTemp, ADMUX 
 	sbr rTemp,(0<<MUX3)|(1<<MUX2)|(0<<MUX1)|(0<<MUX0) ; (0b0100 = 4) 
 	cbr rTemp,(1<<MUX3)|(1<<MUX1)|(1<<MUX0) 
 	sts ADMUX, rTemp 
 
 
	; Starta A/D-konvertering.  
 	ldi rTemp, 0x00 
 	lds rTemp, ADCSRA		; Get ADCSRA 
 	sbr rTemp,(1<<ADSC)		; Starta konvertering ---> ADSC = 1 (bit 6) 
 	sts ADCSRA, rTemp		; Ladda in 
 	 
 iterate_y: 
 	ldi rTemp, 0x00 
 	lds rTemp, ADCSRA		; Ta nuvarande ADCSRA för att jämföra 
 	sbrc rTemp, 6			; Kolla om bit 6 (ADSC) är 0 i rSettings (reflekterar ADCSRA) (instruktion = Skip next instruction if bit in register is cleared) ; Alltså om ej cleared, iterera. 	 
 	jmp iterate_y			; Iterera 
 	nop 
 
 
 	lds rYvalue, ADCH		; Läs av resultat 


	cpi rXvalue, 165	; Deadzone (var 165)
 	brsh go_left 
 
 
 	cpi rXvalue, 91		
 	brlo go_right 

	cpi rYvalue, 165 
 	brsh go_up 
 
 
 	cpi rYvalue, 91 
 	brlo go_down 
	



	jmp checkdir
	go_left:
 		ldi rDirection, 1 
 	jmp checkdir 
 	go_right: 
 		ldi rDirection, 2
 	jmp checkdir 
	
 	go_up: 
 		ldi rDirection, 4
 	jmp checkdir 
 	go_down: 
 		ldi rDirection, 8
		

checkdir:
		ldi YH, 0
		ldi YL, 0
		ldi rCounter, 0




checkdircont:

	
		
		cpi rDirection, 1
		breq left

		cpi rDirection, 2
		breq right
		
		cpi rDirection, 4
		breq up

		cpi rDirection, 8
		breq down
		
		jmp outsidecheckdone

		left:
			ld rTemp, Y
			lsl rTemp
			st Y, rTemp
			jmp outsidecheck

		right:
			ld rTemp, Y
			lsr rTemp
			st Y, rTemp
			jmp outsidecheck
		up: 
 	 
 		cpi YL, 0 
 		breq checkhighrow 
 		ld rTemp, Y 
 		cpi rTemp, 0 
 			brne moveup 
 				jmp outsidecheckdone 
 				moveup: 
 					st Y, rNoll 
 					subi YL, 1 
 					st Y, rTemp 
 			jmp outsidecheckdone 
 
 
 			checkhighrow: 
 				ld rTemp, Y 
 				cpi rTemp, 0 
 					brne movehigh 
 					jmp outsidecheckdone 
 					movehigh: 
 						st Y, rNoll 
 						ldi YL, 7 
 						st Y, rTemp 
 		 
 		jmp outsidecheckdone 


		down:  
 		cpi YL, 7 
 		breq checklowrow 
 		ld rTemp, Y 
 		cpi rTemp, 0 
 		brne movedown 
 			jmp outsidecheckdone 
 			movedown: 
 				st Y+, rNoll 
 				st Y, rTemp 
 
 
 		jmp outsidecheckdone 
 
 
 		checklowrow: 
 			ld rTemp, Y 
 			cpi rTemp, 0 
 				brne movelow 
 				jmp outsidecheckdone 
 				movelow: 
 					st Y, rNoll 
 					ldi YL, 0 
 					st Y, rTemp 
 
 
 
 
 		jmp outsidecheckdone 


			

		outsidecheck: 
 
 
 	brcc outsidecheckdone	; Kontrollera om Carry är cleared 
 
 
 	cpi rDirection, 1		;  
 	breq outsideleft 
 
 
 	cpi rDirection, 2 
 	breq outsideRight 
 
 
 	outsideleft: 
 	ldi rTemp, 1 
 	st Y, rTemp 
 	clc 
 	jmp outsidecheckdone 
 
 
 	outsideright: 
 	ldi rTemp, 128 
 	st Y, rTemp 
 	clc 

	

outsidecheckdone: 
 	cpi rCounter, 8 
 	breq done 
 	 
 cont: 
 	inc rCounter 
 
 
 	ld rTemp, Y+ 
 	jmp checkdircont 
 done: 
 	ret 



Laddarad: 
 
 	in rTemp, PORTD 
 
	bst rXkord, 7 
 	bld rTemp, 6 
	bst rXkord, 6 
	bld rTemp, 7 
 	out PORTD, rTemp 

 	in rTemp, PORTB 
	 
 	bst rXkord, 5 
 	bld rTemp, 0 
 	bst rXkord, 4 
 	bld rTemp, 1 
 	bst rXkord, 3 
 	bld rTemp, 2 
 	bst rXkord, 2 
 	bld rTemp, 3 
 	bst rXkord, 1 
 	bld rTemp, 4 
 	bst rXkord, 0 
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
