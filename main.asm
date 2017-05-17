;avrdude -C "C:\WinAVR-20100110\bin\avrdude.conf" -patmega328p -Pcom4 -carduino -b115200 -Uflash:w:Snake.hex


; Registerdefinitioner
	.DEF rTemp			= r16
	.DEF rTemp2			= r17
	.DEF rDirection		= r18
	.DEF rXvalue		= r19
	.DEF rLength		= r20
	.DEF rYKord			= r21	
	.DEF rUpdateFlag	= r22
	.DEF rUpdateDelay	= r23
	.DEF rCounter       = r24
	.DEF rXkord			= r25

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
	ldi rTemp2, 0b00000000

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


	out PORTB, rTemp2
	out PORTC, rTemp2
	out PORTD, rTemp2

	ldi rUpdateDelay, 0b00000000
	ldi rDirection, 0b00000000
	ldi rCounter, 0b00000000
	ldi rLength, 2

	rcall clear 	

	ldi rXkord, 4
	ldi rYkord, 1

	ldi YH, 0
	ldi YL, 0

	st Y+, rXkord
	st Y+, rYkord

	ldi rXkord, 2
	ldi rYkord, 1

	st Y+, rXkord
	st Y+, rYkord


main:

	ldi YH, 0
	ldi YL, 0


	rcall laddarad
	rcall laddarader
	rcall clear




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
	ldi rTemp2, 0
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
 
 
 	lds rTemp2, ADCH		; Läs av resultat 


	cpi rXvalue, 165	; Deadzone (var 165)
 	brsh go_left 
 
 
 	cpi rXvalue, 91		
 	brlo go_right 

	cpi rTemp2, 165 
 	brsh go_up 
 
 
 	cpi rTemp2, 91 
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

		cpi rDirection, 0
		breq done
		
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
		ld rTemp2, Y
		cpi rTemp2, 128
		brsh outsideleft

		lsl rTemp2
		jmp outsidecheckdone
		
		

		right:
		ld rTemp2, Y
		cpi rTemp2, 2
		brlo outsideright

		lsr rTemp2
		jmp outsidecheckdone
			
		up:
		inc YL
		ld rTemp2, Y
		cpi rTemp2, 2
		brlo outsideup
		
		lsr rTemp2
		jmp outsidecheckdone


		down:
		inc YL
		ld rTemp2, Y
		cpi rTemp2, 128
		brsh outsidedown
		
		lsl rTemp2
		jmp outsidecheckdone
 

 
 
 	outsideleft:
	ldi rTemp2, 1 
	jmp outsidecheckdone

 	outsideright:
	ldi rTemp2, 128
	jmp outsidecheckdone
		
	outsideup:
	ldi rTemp2, 128
	jmp outsidecheckdone

	outsidedown: 
	ldi rTemp2, 1

	

outsidecheckdone: 

	cpi rDirection, 4
	brsh updown
	
	st Y+, rTemp2
	inc YL
	inc rCounter
	cp rCounter, rLength
	breq done
 
 	jmp checkdircont 

	updown:
	
	st Y, rTemp2
	inc rCounter
	cp rCounter, rLength
	breq done

	jmp checkdircont

done:
	ret

Laddarad: 

	ldi YH, 0
	ldi YL, 0


 
 	in rTemp, PORTD 
	ld rTemp2, Y+ 

	bst rTemp2, 7 
 	bld rTemp, 6 
	bst rTemp2, 6 
	bld rTemp, 7 
 	out PORTD, rTemp 

 	in rTemp, PORTB 
	 
 	bst rTemp2, 5 
 	bld rTemp, 0 
 	bst rTemp2, 4 
 	bld rTemp, 1 
 	bst rTemp2, 3 
 	bld rTemp, 2 
 	bst rTemp2, 2 
 	bld rTemp, 3 
 	bst rTemp2, 1 
 	bld rTemp, 4 
 	bst rTemp2, 0 
 	bld rTemp, 5 
	 
 	out PORTB, rTemp  
 
 	ret 

Laddarader: 
 
 	in rTemp, PORTC 
	ld rTemp2, Y

	bst rTemp2, 0 
 	bld rTemp, 0
	bst rTemp2, 1 
	bld rTemp, 1
	bst rTemp2, 2
	bld rTemp, 2
	bst rTemp2, 3
	bld rTemp, 3
	out PORTC, rTemp 

 	in rTemp, PORTD 
	 
 	bst rTemp2, 4 
 	bld rTemp, 2 
 	bst rTemp2, 5 
 	bld rTemp, 3 
 	bst rTemp2, 6 
 	bld rTemp, 4 
 	bst rTemp2, 7 
 	bld rTemp, 5	 
 	out PORTD, rTemp  
 
	/*cp YL, rLength
	breq done
	jmp Laddarad*/


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

	cbi PORTC, PC0
	cbi PORTC, PC1
	cbi PORTC, PC2
	cbi PORTC, PC3
	cbi PORTD, PD2
	cbi PORTD, PD3
	cbi PORTD, PD4
	cbi PORTD, PD5

	ret

isr_timerOF:
	ldi rUpdateFlag, 0b00000001
	reti
