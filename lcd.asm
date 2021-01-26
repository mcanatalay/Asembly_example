.INCLUDE "M128DEF.INC"
.def temp = R16
.def input = R17
.def output = R18
.def flag = R19
.def counter = R20
.equ textInput = 0x0200
.equ textOutput = 0x0400

.CSEG
jmp start

.ORG 0x24
rjmp IsrRec

.ORG 0x28
rjmp IsrTr

.ORG 0x1C
rjmp IsrTim

.ORG 0x40
start:
	ldi temp,low(RAMEND)
	out SPL,temp
	ldi temp,high(RAMEND)
	out SPH,temp
	ldi temp,0xFF
	out DDRA,temp
	out DDRB,temp
	call InitializeVT
	call Welcome
end:
	jmp end

Welcome:
	call Inten
	call Timer
	call SystemQuestion
	call RecvStr
	call Transfer
	call SystemWelcome
	call SendStr
	ret

InitializeVT:
	ldi R16,(1<<UCSZ01)|(1<<UCSZ00); 8 bit data and 1 stop bit, no parity (pg 36)
	sts UCSR0C,temp

	ldi temp,64
	out UBRR0L, temp

	ret

SendStr:
	ldi ZL,low(textInput)
	ldi ZH,high(textInput)
	ldi flag,0
	ldi temp, (1<<TXEN0)|(1<<TXCIE0)
	out UCSR0B, temp
	ldi output,' '
	call SendChar
SendStr_01:
	ld output,Z+
	cpi output,'$'
	breq SendStr_03
SendStr_02:
	cpi flag,1
	brne SendStr_02
	ldi flag,0
	jmp SendStr_01
SendStr_03:
	ldi temp, 0x00
	out UCSR0B,temp
	ret

SystemWelcome:
	ldi ZL,low(welcomeMessage<<1)
	ldi ZH,high(welcomeMessage<<1)
	call SendStrPM
	ret

SystemQuestion:
	ldi ZL,low(question<<1)
	ldi ZH,high(question<<1)
	call SendStrPM
	ret

SendStrPM:
	ldi flag,0
	ldi temp, (1<<TXEN0)|(1<<TXCIE0)
	out UCSR0B, temp
	ldi output,' '
	call SendChar
SendStrPM_01:
	lpm output,Z+
	cpi output,'$'
	breq SendStrPM_03
SendStrPM_02:
	cpi flag,1
	brne SendStrPM_02
	ldi flag,0
	jmp SendStrPM_01
SendStrPM_03:
	ret

SendChar:
	sbis UCSR0A, UDRE0 ; if UDR is empty wait
	jmp SendChar
	out UDR0, output ; to UDR

	ret

RecvStr:
	ldi ZL,low(textOutput)
	ldi ZH,high(textOutput)
	ldi flag,0
	ldi temp, (1<<RXEN0)|(1<<RXCIE0)
	out UCSR0B, temp
RecvStr_01:
	cpi flag,1
	brne RecvStr_01
	ldi flag,0
	cpi input,13
	breq RecvStr_02
	st Z+,input
	jmp RecvStr_01
RecvStr_02:
	ldi temp,'$'
	st Z,temp
	ret

Transfer:
	ldi YL,low(textInput)
	ldi YH,high(textInput)
	ldi ZL,low(textOutput)
	ldi ZH,high(textOutput)
Transfer_01:
	ld temp,Z+
	cpi temp,'$'
	breq Transfer_02
	st Y+,temp
	jmp Transfer_01
Transfer_02:
	ldi temp,'$'
	st Y,temp
	ret

Inten:
	sei
	ret

IsrRec:
	in input,UDR0
	ldi flag,1
	reti

IsrTr:
	out UDR0,output
	ldi flag,1
	reti

IsrTim:
	inc counter
	cpi counter,19
	brlo IsrTim_01
	ldi counter,0
	adiw XH:XL,1
	out PORTA,XL
	out PORTB,XH
IsrTim_01:
	reti

Timer:
	ldi temp,(1 << CS11)
	out TCCR1B,temp
	ldi temp,(1 << TOIE1)
	out TIMSK,temp
	ldi counter,0
	ldi XL,0
	ldi XH,0
	ret



.CSEG
question: .db "What is your name ?",13,'$',0
welcomeMessage: .db " Welcome ",'$'
