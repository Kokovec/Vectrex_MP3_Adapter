;***************************************************************************
; DEFINE SECTION
;***************************************************************************
; load vectrex bios routine definitions
                    INCLUDE  "VECTREX.I"          ; vectrex function includes

;***************************************************************************
; Variable / RAM SECTION
;***************************************************************************
; insert your variables (RAM usage) in the BSS section
; user RAM starts at $c880
				BSS      
                    ORG      $c880                        ; start of our ram space 


PSG_Data_Temp			DS 1		; Saved data read from PSG Reg 7
SPI_Data				DS 1		; 1 byte, SPI data to be shifted out
SPI_Temp_Data			DS 2		; 2 byte
SPI_Mask				DS 1		; 1 byte
SPI_OUT				DS 1		; 1 byte
Byte_Count			DS 1		; 1 byte
Selected_Text			DS 1		; 1 byte
joy_prev_state_y 		DS 1     ; previous joy state: 0=not moved, 1=moved 
button_prev_state_4  	DS 1   	; previous state of button4: 0=not moved, 1=moved
Playing_State			DS 1		; 0 = not playing; 1 = playing
Delay_Count			DS 1		; not used


SPI_Initial_State	equ %00000100
Enable_LOW		equ	%00000000


;***************************************************************************
; HEADER SECTION
;***************************************************************************
; The cartridge ROM starts at address 0
                    CODE     
                    ORG      0 
; the first few bytes are mandatory, otherwise the BIOS will not load
; the ROM file, and will start MineStorm instead
                    DB       "g GCE 1998", $80    ; 'g' is copyright sign
                    DW       music1               ; music from the rom 
                    DB       $F8, $50, $20, -$30  ; hight, width, rel y, rel x (from 0,0) 
                    DB       "SPI DEMO", $80      ; some game information, ending with $80
                    DB       0                    ; end of game header 

;***************************************************************************
; CODE SECTION
;***************************************************************************
; here the cartridge program starts off
Initialize:
	JSR	Save_Reg_7			;get PSG register 07 bits
	LDA	#$00
	STA	Selected_Text
	JSR	Read_Btns                    ; set initial button state 
   	LDA	#1                           ; these set up the joystick 
	STA	Vec_Joy_Mux_1_X              ; enquiries 
	LDA	#3                           ; allowing only all directions 
 	STA	Vec_Joy_Mux_1_Y              ; for joystick one 
   	LDA	#0                           ; this setting up saves a few 
   	STA	Vec_Joy_Mux_2_X              ; hundred cycles 
   	STA	Vec_Joy_Mux_2_Y              ; don't miss it, if you don't 
                                          ; need the second joystick! 
	LDA      #0 
	LDA      joy_prev_state_y             ; reset joy y state flag 
	STA      button_prev_state_4          ; reset button 4 pressed flag 

	CLR Delay_Count

main: 
	JSR	Wait_Recal			; Vectrex BIOS recalibration 
	LDA	#$00
	JSR 	Set_Intensity
	LDU	#Track_String1  		; address of string 
	LDA	#$30                 	; Text position relative Y 
	LDB	#-$50                	; Text position relative X 
	JSR	Print_Str_d			; Vectrex BIOS print routine 

	LDA	#$01
	JSR 	Set_Intensity
	LDU	#Track_String2  		; address of string 
	LDA	#$20                 	; Text position relative Y 
	LDB	#-$50                	; Text position relative X 
	JSR	Print_Str_d			; Vectrex BIOS print routine 

	LDA	#$02
	JSR 	Set_Intensity
	LDU	#Track_String3  		; address of string 
	LDA	#$10                 	; Text position relative Y 
	LDB	#-$50                	; Text position relative X 
	JSR	Print_Str_d			; Vectrex BIOS print routine

	LDA	#$03
	JSR 	Set_Intensity
	LDU	#Track_String4  		; address of string 
	LDA	#$00                 	; Text position relative Y 
	LDB	#-$50                	; Text position relative X 
	JSR	Print_Str_d			; Vectrex BIOS print routine 

	LDA	#$04
	JSR 	Set_Intensity
	LDU	#Track_Pause  		; address of string 
	LDA	#-$10                	; Text position relative Y 
	LDB	#-$50                	; Text position relative X 
	JSR	Print_Str_d			; Vectrex BIOS print routine

	LDA	#$05
	JSR 	Set_Intensity
	LDU	#Track_Play  			; address of string 
	LDA	#-$20                 ; Text position relative Y 
	LDB	#-$50                	; Text position relative X 
	JSR	Print_Str_d			; Vectrex BIOS print routine

	LDA	#$06
	JSR 	Set_Intensity
	LDU	#TRACK_NEXT  			; address of string 
	LDA	#-$30                 ; Text position relative Y 
	LDB	#-$50                	; Text position relative X 
	JSR	Print_Str_d			; Vectrex BIOS print routine

	LDA	#$07
	JSR 	Set_Intensity
	LDU	#TRACK_PREVIOUS  		; address of string 
	LDA	#-$40                 ; Text position relative Y 
	LDB	#-$50                	; Text position relative X 
	JSR	Print_Str_d			; Vectrex BIOS print routine

	JSR	Joy_Digital          	; read joystick positions 
	LDA 	Vec_Joy_1_Y        	; load joystick 1 position 
	BEQ	no_joy_y          	; if zero, than no y position 
	BMI	y_down              	; if negative, then down 
	LDA	joy_prev_state_y     	; still being pressed from last check? 
	BNE	keep_going           	; yes, ignore 
	LDA	#1                  	; nope.. 
	STA	joy_prev_state_y     	; flag joy as being pressed 
	LDA Selected_Text
	BEQ	Top_Text
	DEC Selected_Text
Top_Text:	
	BRA	keep_going 
y_down: 
	LDA	joy_prev_state_y          	; still being pressed from last check? 
	BNE 	keep_going				; yes, ignore
	LDA	#1 
	STA	joy_prev_state_y         	; flag joy as being pressed 
	LDA	Selected_Text
	CMPA	#$07						; check if hit bottom of text list
	BEQ	keep_going				; yes, stay put
	INC Selected_Text				; no, move down the list
	BRA	keep_going
no_joy_y: 
	CLR      joy_prev_state_y   	; clear the joy state flag 
keep_going: 
	JSR	Read_Btns                	; get button status 
	 LDA     Vec_Btn_State
	BITA	#$08                     	; test for button 1-4 
	BEQ	button_not_pressed        	; not pressed 
	LDA button_prev_state_4		; check if button 4 still being pressed
	LBNE	Check_Playing				; yes, ignore
	LDA	#1                       	; flag that y button was pressed 
	STA	button_prev_state_4 
	BRA	Handle_Button
button_not_pressed: 
	LDA	#0                       	; flag that y button was not pressed 
	STA	button_prev_state_4 
	LBRA	Check_Playing				; no button pressed, go back and display text 

Handle_Button:
	LDA	Selected_Text				; what are we doing?
	BNE	Check_track_2
	LDA	#'A'						; we are playing track 1
	LDB	#$01
	JSR	SPI_SEND
	BRA Check_Playing
Check_track_2
	CMPA	#$01
	BNE	Check_track_3
	LDA	#'A'						; we are playing track 2
	LDB	#$02
	JSR	SPI_SEND
	BRA Check_Playing
Check_track_3:
	CMPA	#$02
	BNE	Check_track_4
	LDA	#'A'						; we are playing track 3
	LDB	#$03
	JSR	SPI_SEND
	BRA Check_Playing
Check_track_4:
	CMPA	#$03
	BNE	Check_Pause
	LDA	#'A'						; we are playing track 4
	LDB	#$04
	JSR	SPI_SEND
	BRA Check_Playing
Check_Pause:
	CMPA	#$04
	BNE	Check_Play
	LDA	#'B'						; we are pausing
	LDB	#$00
	JSR	SPI_SEND
	BRA	Check_Playing
Check_Play
	CMPA	#$05
	BNE	Check_Next
	LDA	#'C'						; we resume playing
	LDB	#$00
	JSR	SPI_SEND		
	BRA	Check_Playing
Check_Next
	CMPA	#$06
	BNE	Check_Previous
	LDA	#'D'						; we playing the next track
	LDB	#$00
	JSR	SPI_SEND
	BRA	Check_Playing
Check_Previous
	CMPA	#$07
	BNE	Check_Playing
	LDA	#'E'						; we playing the previous track
	LDB	#$00
	JSR	SPI_SEND								
Check_Playing:
	JSR	Read_Playing_Flag			;Check if playing a tune
	LDA	Playing_State
	BEQ	Go_Back
	JSR Intensity_7F				; yes, display playing message
	LDU	#Playing  				; address of string 
	LDA	#-$50                 	; Text position relative Y 
	LDB	#-$50                		; Text position relative X 
	JSR	Print_Str_d				; Vectrex BIOS print routine
Go_Back:
	LBRA main

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Routine to set vector intesity 	;;
;;							   	;;
;; A = Selected Text Line			;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Set_Intensity:
	CMPA	Selected_Text				; are we currently on this line?
	BNE  I_3F					; no
	JSR 	Intensity_7F				; yes
	RTS
I_3F:
	JSR 	Intensity_3F
	RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Routine to check if a tune is playing 	;;
;; Inspects Joy Port 2 button 4			;;
;; Returns:								;;
;; Playing_State = 0 (Not playing)			;;
;; Playing_State = 1 (Playing)				;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Read_Playing_Flag:
	JSR	Read_Btns               	; get button status 
	LDA  Vec_Btn_State
	BITA	#$80                    	; test for button 2-4 pin
	BEQ Playing_Yes			  	; yes, playing
	LDA #$00						; not playing
	STA Playing_State
	RTS
Playing_Yes:
	LDA #$01						; playing
	STA Playing_State
	RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; This routine saves the data that is presently in PSG register 07  	;;
;; We do this to preserve important music flags 	             			;;
;; The PSG register 07 data is held in PSG_Data_Temp 	             		;;
;; PSG register 7 data is read in through the VIA                    	;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;                              

Save_Reg_7
	LDA	#$FF
	STA	VIA_DDR_a				;set via port A to output
	LDA	#$07						;setup PSG for register 7
	STA	VIA_port_a				;select PSG register 7
	LDA	#$19
	STA	VIA_port_b				;latch the PSG with register 7
	LDA	#$01
	STA	VIA_port_b				;PSG is inactive
	NOP
	CLR	VIA_DDR_a				;set Via Port A to input
	LDA	#$09
	STA	VIA_port_b				;get data in PSG Reg 7
	LDB	VIA_port_a
	STB	PSG_Data_Temp				;save reg 7 data
	LDA	#$01
	STA	VIA_port_b				;PSG is inactive
	NOP
	LDA	#$FF
	STA	VIA_DDR_a				;set via port A to output
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; This routine will restore the joy ports to input mode    ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Restore_Joy_Ports
	lda		#$07					;setup PSG for register 7
	ldb		#%00000000			;PSG IOA set to input
	eorb		PSG_Data_Temp			;Preserve music flags
	jsr		Sound_Byte_raw  		;send to PSG
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SPI Routine 							;;
;; Sends a 16 bit word out of Joy Port 2 	;;
;; Joy Pin 1 = CLK	(4)					;;
;; Joy Pin 2 = Data	(5)					;;
;; Joy Pin 3 = Enable (6)					;;
;; 										;;
;; A = Command							;;
;; B = Data								;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SPI_SEND:
	STD SPI_Temp_Data
	CLR	Byte_Count
SPI_FIRST_PASS:
	LDA SPI_Temp_Data
	STA SPI_Data
	JSR	Save_Reg_7				;get PSG register 07 bits (to preserve voice enables)
	; Setup SPI initial state (CPOL=0, CPHA=0)
	LDA	#$0e						;setup PSG for register 16
	LDB	SPI_Initial_State			;CLK=LOW, DATA=LOW, EN=HIGH
	JSR	Sound_Byte_raw  			;send to PSG
	lda	#$07						;setup PSG for register 7
	LDB	#%01000000				;PSG IOA set to output
	ORB	PSG_Data_Temp				;preserve the PSG R7 voice enable bits
	JSR	Sound_Byte_raw  			;send to PSG 
	LDA	#$0e						;setup PSG for register 16
	LDB	Enable_LOW				;CLK=LOW, DATA=LOW, EN=LOW
	ldb #$00
	JSR	Sound_Byte_raw  			;send to PSG
	NOP
SPI_CONTINUE:
	LDA	#%10000000				;Prep data shift with MSB bitmask
	STA SPI_Mask
	; Prep SPI Data and place on the Data Pin (Bit-7)
	LDB	SPI_Data
	ANDB SPI_Mask					;send out Bit-7
	LSRB							;move bit over to DATA pin (5)
	LSRB
	STB SPI_OUT					;save the result for later
	LDA	#$0e						;setup PSG for register 16
	JSR	Sound_Byte_raw  			;send to PSG
	;Bounce the CLK pin
	LDB	SPI_OUT					;get the data
	ORB #%00010000				;set the clock pin HIGH
	LDA	#$0e						;setup PSG for register 16
	JSR	Sound_Byte_raw  			;send to PSG
	LDB	SPI_OUT					;get the data
	ANDB	#%11111111				;set the CLK pin LOW
	LDA	#$0e						;setup PSG for register 16
	JSR	Sound_Byte_raw  			;send to PSG

	;Prep SPI Data and place on the Data Pin (Bit-6)
	LSR	SPI_Mask					;send out Bit-6
	LDB	SPI_Data
	ANDB SPI_Mask
	LSRB							;move bit over to DATA pin (5)
	STB SPI_OUT					;save the result for later
	LDA	#$0e						;setup PSG for register 16
	JSR	Sound_Byte_raw  			;send to PSG
	;Bounce the CLK pin
	LDB	SPI_OUT					;get the data
	ORB #%00010000				;set the clock pin HIGH
	LDA	#$0e						;setup PSG for register 16
	JSR	Sound_Byte_raw  			;send to PSG
	LDB	SPI_OUT					;get the data
	ANDB	#%11111111				;set the CLK pin LOW
	LDA	#$0e						;setup PSG for register 16
	JSR	Sound_Byte_raw  			;send to PSG
	
	;Prep SPI Data and place on the Data Pin (Bit-5)
	LSR	SPI_Mask					;send out Bit-5
	LDB	SPI_Data
	ANDB SPI_Mask
	;LSRB						;move bit over to DATA pin (5)
	STB SPI_OUT					;save the result for later
	LDA	#$0e						;setup PSG for register 16
	JSR	Sound_Byte_raw  			;send to PSG
	;Bounce the CLK pin
	LDB	SPI_OUT					;get the data
	ORB #%00010000				;set the clock pin HIGH
	LDA	#$0e						;setup PSG for register 16
	JSR	Sound_Byte_raw  			;send to PSG
	LDB	SPI_OUT					;get the data
	ANDB	#%11111111				;set the CLK pin LOW
	LDA	#$0e						;setup PSG for register 16
	JSR	Sound_Byte_raw  			;send to PSG
	;Prep SPI Data and place on the Data Pin (Bit-4)
	LSR	SPI_Mask					;send out Bit-4
	;LDA	SPI_Mask
	LDB	SPI_Data
	ANDB SPI_Mask
	LSLB							;move bit over to DATA pin (5)
	STB SPI_OUT					;save the result for later
	LDA	#$0e						;setup PSG for register 16
	JSR	Sound_Byte_raw  			;send to PSG
	;Bounce the CLK pin
	LDB	SPI_OUT					;get the data
	ORB #%00010000				;set the clock pin HIGH
	LDA	#$0e						;setup PSG for register 16
	JSR	Sound_Byte_raw  			;send to PSG
	LDB	SPI_OUT					;get the data
	ANDB	#%11111111				;set the CLK pin LOW
	LDA	#$0e						;setup PSG for register 16
	JSR	Sound_Byte_raw  			;send to PSG
	;Prep SPI Data and place on the Data Pin (Bit-3)
	LSR	SPI_Mask					;send out Bit-3
	;LDA	SPI_Mask
	LDB	SPI_Data
	ANDB SPI_Mask
	LSLB							;move bit over to DATA pin (5)
	LSLB
	STB SPI_OUT					;save the result for later
	LDA	#$0e						;setup PSG for register 16
	JSR	Sound_Byte_raw  			;send to PSG
	;Bounce the CLK pin
	LDB	SPI_OUT					;get the data
	ORB #%00010000				;set the clock pin HIGH
	LDA	#$0e						;setup PSG for register 16
	JSR	Sound_Byte_raw  			;send to PSG
	LDB	SPI_OUT					;get the data
	ANDB	#%11111111				;set the CLK pin LOW
	LDA	#$0e						;setup PSG for register 16
	JSR	Sound_Byte_raw  			;send to PSG
	;Prep SPI Data and place on the Data Pin (Bit-2)
	LSR	SPI_Mask					;send out Bit-2
	LDB	SPI_Data
	ANDB SPI_Mask
	LSLB							;move bit over to DATA pin (5)
	LSLB
	LSLB
	STB SPI_OUT					;save the result for later
	LDA	#$0e						;setup PSG for register 16
	JSR	Sound_Byte_raw  			;send to PSG
	;Bounce the CLK pin
	LDB	SPI_OUT					;get the data
	ORB #%00010000				;set the clock pin HIGH
	LDA	#$0e						;setup PSG for register 16
	JSR	Sound_Byte_raw  			;send to PSG
	LDB	SPI_OUT					;get the data
	ANDB	#%11111111				;set the CLK pin LOW
	LDA	#$0e						;setup PSG for register 16
	JSR	Sound_Byte_raw  			;send to PSG
	;Prep SPI Data and place on the Data Pin (Bit-1)
	LSR	SPI_Mask					;send out Bit-1
	LDB	SPI_Data
	ANDB SPI_Mask
	LSLB							;move bit over to DATA pin (5)
	LSLB
	LSLB
	LSLB
	STB SPI_OUT					;save the result for later
	LDA	#$0e						;setup PSG for register 16
	JSR	Sound_Byte_raw  			;send to PSG
	;Bounce the CLK pin
	LDB	SPI_OUT					;get the data
	ORB #%00010000				;set the clock pin HIGH
	LDA	#$0e						;setup PSG for register 16
	JSR	Sound_Byte_raw  			;send to PSG
	LDB	SPI_OUT					;get the data
	ANDB	#%11111111				;set the CLK pin LOW
	LDA	#$0e						;setup PSG for register 16
	JSR	Sound_Byte_raw  			;send to PSG
	;Prep SPI Data and place on the Data Pin (Bit-0)
	LSR	SPI_Mask					;send out Bit-5
	LDB	SPI_Data
	ANDB SPI_Mask
	LSLB							;move bit over to DATA pin (5)
	LSLB
	LSLB
	LSLB
	LSLB
	STB SPI_OUT					;save the result for later
	LDA	#$0e						;setup PSG for register 16
	JSR	Sound_Byte_raw  			;send to PSG
	;Bounce the CLK pin
	LDB	SPI_OUT					;get the data
	ORB #%00010000				;set the clock pin HIGH
	LDA	#$0e						;setup PSG for register 16
	JSR	Sound_Byte_raw  			;send to PSG
	LDB	SPI_OUT					;get the data
	ANDB	#%11111111				;set the CLK pin LOW
	LDA	#$0e						;setup PSG for register 16
	JSR	Sound_Byte_raw  			;send to PSG
	
	LDB	SPI_Temp_Data+1
	STB SPI_Data
	INC	Byte_Count
	LDA	Byte_Count
	CMPA	#$01
	LBEQ	SPI_CONTINUE
	; Setup SPI initial state (CPOL=0, CPHA=0)
	LDA	#$0e						;setup PSG for register 16
	LDB	SPI_Initial_State			;CLK=LOW, DATA=LOW, EN=HIGH
	JSR	Sound_Byte_raw  			;send to PSG
	LDA	#$07						;setup PSG for register 7
	LDB	#%00000000				;PSG IOA set to input
	EORB	PSG_Data_Temp				;Preserve music flags
	JSR	Sound_Byte_raw  			;send to PSG
	RTS
	

;***************************************************************************
; DATA SECTION
;***************************************************************************
hello_world_string: 
                    DB       "HELLO WORLD"        ; only capital letters
                    DB       $80                  ; $80 is end of string 

Track_String1:
				DB	"TRACK 1", $80
Track_String2:
				DB 	"TRACK 2", $80
Track_String3
				DB	"TRACK 3", $80
Track_String4
				DB	"TRACK 4", $80
Track_Pause:
				DB	"PAUSE", $80
Track_Play:
				DB	"PLAY", $80
TRACK_NEXT:
				DB	"NEXT", $80
TRACK_PREVIOUS:
				DB	"PREVIOUS", $80
Playing:
				DB	"PLAYING", $80
;***************************************************************************
