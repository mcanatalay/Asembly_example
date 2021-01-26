.INCLUDE "m128def.inc"

.def input = R16
.def output = R18
.def temp = R19
.def counter1 = R20
.def counter2 = R21

.equ CONSTANT = 0x55
.equ OFFSET = 0x1100
.equ fclk = 8000000

.org 0x0000

start:
	call initializeXMEM
	ldi input, CONSTANT
	call fillTheMemory
	ldi temp,0xFF
	out DDRB,temp
	out DDRD,temp
	out DDRE,temp
	call readAllMemory
end:
	jmp end

readAllMemory:
	ldi ZL, low(OFFSET)
	ldi ZH, high(OFFSET)
	ldi counter1,16
	ldi counter2,128
readAllMemory_01:
	dec counter1
	breq readAllMemory_03
readAllMemory_02:
	ld output,Z+
	call showInLed
	call delay1S
	dec counter2
	brne readAllMemory_02
	jmp readAllMemory_01
readAllMemory_03:
	ret

showInLed:
	out PORTB,output
	out PORTD,ZL
	out PORTE,ZH
	ret

fillTheMemory:
	ldi ZL, low(OFFSET)
	ldi ZH, high(OFFSET)
	ldi counter1,16
	ldi counter2,128
fillTheMemory_01:
	dec counter1
	breq fillTheMemory_03
fillTheMemory_02:
	st Z+,input
	dec counter2
	brne fillTheMemory_02
	jmp fillTheMemory_01
fillTheMemory_03:
	ret


initializeXMEM:
	ldi temp,0x80
	out MCUCR,temp
	ldi temp, (1<<XMM2)|(1<<XMM0)
	sts XMCRB, temp
	ret

delay1S:
	ldi temp,100
	call delayTx1mS
	ret

; ---------------------------------------------------------------------------
; Name: delayTx1mS Provide a delay of (temp) x 1 mS
delayTx1mS:
	call delay1mS ; delay for 1 mS
	dec temp ; update the delay counter
	brne delayTx1mS ; counter is not zero

; arrive here when delay counter is zero (total delay period is finished)
	ret

; ---------------------------------------------------------------------------
; Name: delay1mS -- Delay of 1 mS
delay1mS:
	push YL ; [2] preserve registers
	push YH ; [2]
	ldi YL, low (((fclk/1000)-18)/4) ; [1] delay counter
	ldi YH, high(((fclk/1000)-18)/4) ; [1]

delay1mS_01:
	sbiw YH:YL, 1 ; [2] update the the delay counter
	brne delay1mS_01 ; [2] delay counter is not zero
; arrive here when delay counter is zero
	pop YH ; [2] restore registers
	pop YL ; [2]
	ret