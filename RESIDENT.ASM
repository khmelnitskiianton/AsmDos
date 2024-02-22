;<GITHUB>: khmelnitskiianton
;This programm use intr and draws frame with values of all registers(except ip & cs now)
;
;<Use>: run it, then hot key will be CTRL+A to start viewing
;--------------------------------------------------------------------------
.model tiny
.286
.code
org 100h
locals @@
;--------------------------------------------------------------------------
;--------------------------------DEFINE------------------------------------
PTR_VIDMEM equ 0b800h ; segment of videomem
PTR_CMD    equ 0080h  ; ptr of cmd line
CH_END_STR equ 0024h  ; end char of string '$'
CH_NULL    equ 0030h  ; '0'
CH_7_HEX   equ 0037h  ; '7' in hex
END_CODE   equ 4c00h  ; Dos fn terminate with 0
HOT_KEY    equ 001eh  ; scan code 'A' push
UP_HOT_KEY equ 009eh  ; scan code 'A' pop

SIZE_STYLE  equ 9d
FRAME_COLOR equ 01Bh
TEXT_COLOR  equ 01Bh
HEAD_COLOR  equ 01eh
SHADOW      equ 070h
MY_LENGTH   equ 11
MY_WIDTH    equ 15
AMOUNT_REGS equ 13
;--------------------------------------------------------------------------
;--------------------------------START-------------------------------------
Start:	        ;1) Save addr of intr vector with 35H
                push 0
		pop es   
		mov ax, 3508h	; AH = 35H - command Dos Fn, AL = 09H - addr of vector
		int 21h		; returns intr vector addr to <es:bx> 

		mov Old09Offs, bx ;saving old intr vector addr 09h
		mov bx, es
		mov Old09Seg, bx

                ;2) Set new intr vector to our with 25H
		push ds         ;save ds - seg of data
		mov dx, offset IntOverride09
		push cs 
		pop ds          ;ds = cs
                mov ax, 2508h   ;Dos Fn to set intr vector, AL - intr number
                        ;<ds:dx> addr of set vector
		int 21h		    ;set intr vector addr
		pop ds          ;revive ds

                ;3)End with resident new function in memory!
		mov dx, offset EndOfProg
		shr dx, 4       ;Shift bytes to right
		inc dx 		    ;dx++
                ;sizeof(prog)/16+1 = SIZE OF CODE IN 16 byte paragraphs
		mov ax, 3100h   ;Code of intr Dos: Terminate & Stay Resident
		int 21h         ;intr Dos Fn 31H need ax, dx

;-------------------------------------------------------------------
;-----------------------------INTERRUPT-----------------------------
IntOverride09	proc
        push bp
        mov bp, sp
        sub sp, 4          ;2 locals
        push ax bx cx dx   ;Change ax, but save in stack
        ;Take ip cs from stack after intr
        mov cx, [bp+4] ;ip
        mov dx, [bp+6] ;cs
        mov [bp-2], cx   ;[bp-2] = ip
        mov [bp-4], dx   ;[bp-4] = cs
        ;Analize keyboard flags on shift
        mov ah, 02h
        int 16h     
        ;AL := [417h] - kybd shift flag
        mov cl, al
        ;Take scan code and if hot key print frame
        mov bx, offset bool_var_draw ; bool value

        ;if((hotkey) && (bool==0)) bool := 1
        ;if((hotkey) && (bool==1)) bool := 0
        ;Hotkey turn on and turn off auto-timer change!  

        in  al, 60h      ;symbol
        cmp al, HOT_KEY  ;compare hot key
        jne @@end_if1
        cmp cl, 04h      ;Check 4-byte(CTRL)
        jne @@end_if1           
        cmp byte ptr [bx], 1
        je  @@else_if1
     @@do_if1:
        mov byte ptr [bx], 1
        jmp @@end_if1
     @@else_if1:
        mov byte ptr [bx], 0
     @@end_if1:  

        ;Start do
        cmp byte ptr [bx], 1       ; if global bool var = true do regs(without hotkey)
        jne @@else_if

        pop dx cx bx ax          ;Revive ax, now all actual
    @@do_if: 
        ;---------
        push [bp-2]
        push [bp-4]
        push ss es ds sp 
        push [bp] 
        push di si dx cx bx ax  ;save regs for 'call draw_regs'
        
        push cs         ;Changes only cs and ip in intr
        pop ds          ;We need to set ds := cs because of ds:[si] := cs:[si]
        push PTR_VIDMEM ;Set es = videomem
	pop es

        call print_frame ; draw frame, ret: di - angle of frame
        
        ; Write text
        add di, 4
        add di, 160    ;shift to text
        
        ;13 ACTUAL regs in stack now like args !!!
        call draw_regs  ;cdecl function
        pop ax bx cx dx si di 
        add sp, 2 
        pop sp ds es ss ;revive all actual regs
        pop [bp-2]
        pop [bp-4]
        ;---------
        jmp @@end_if
    @@else_if:
        pop dx cx bx ax          ;Revive ax, now all actual
    @@end_if:
        mov sp,bp ; close action
        pop bp
        ;Jump to old intr and run it
        ;Instruction Set Master
	db 0eah ; JMP FAR (To Electronic arts) Command - EA
        ;next - arguments
        Old09Offs dw 0  ;Old offset
        Old09Seg  dw 0  ;Old segment

IntOverride09   endp
;------------------------------------------------------------------
;-----------------------------FUNCTIONS----------------------------
;NAME: print_frame()
;Function that draws frame with registers
;IN: 		ES = 0b800h, 
;RET: 		ES:[DS] - angle of frame
;SAVE: 		ax,bx,cx,dx
;LOCALS:	-
print_frame	proc
	        ;input action
                nop                
		push bp     ;save bp, bp = sp
                mov bp, sp  
                sub sp, 4   ;2 local vars in stack
		push ax bx cx dx si ;save regs

		;-------------------BODY----------------------
                ;SI - ptr of style frame
                ;DI - pointer of current cell
                ;BH - color, BL - char
                ;AX,CX,DX - help

                ;1) Set style
                ;curr_style = style_frame + SIZE_STYLE*index
                xor si,si
                mov si, offset style_frame
                ;...

                ;2) Color
                xor bx, bx
                mov bh, FRAME_COLOR
                ;...

                ;3) Set DI center(right angle)
                xor dx, dx
                mov ax, 160d
                mov dx, 11d               
                mul dx
                add ax, 140d
                mov di, ax

                ;4) Set start position di
                ; di = center-length/2*2(word)-160*(width/2)
                mov ax, MY_LENGTH   ;length
                mov cl, 2d
                div cl
                @@begin_if:             ; check if (di % 2 != 0) - need align 1 byte!
                        cmp ah, 0
                        je @@end_if 
                @@do_if:
                        dec di
                @@end_if:
                sub di, MY_LENGTH          ;length 
                mov ax, MY_WIDTH           ;width     
                mov cl, 2d
                div cl          
                xor ah, ah
                mov cx, 160d
                mul cx
                sub di, ax

                push di         ; save begin for p.6)

                ;5)Drawing frame
                
                ;5.1)Draw head
                push di     ; save cell to jmp to next line!
                ;first symbol
                mov bl, byte ptr [si]
                mov word ptr es:[di], bx
                add di, 2
                inc si
                ;name of frame
                mov bh, HEAD_COLOR
                mov al, CH_END_STR
                push si     ;save si
                mov si, offset say_my_frame ;set si to str with name
        @@while_loop:       ; while(*ptr != END_CHAR){write}
                cmp al, byte ptr [si]
                je @@while_end

                movsb
                mov byte ptr es:[di], bh
                inc di

                inc cx
                inc dx
                jmp @@while_loop
        @@while_end:
                pop si
                mov bh, FRAME_COLOR
                ;end symbol
                inc si
                mov bl, byte ptr [si]
                mov word ptr es:[di], bx
                add di, 2
                inc si
                ;revive di and jmp to next line
                pop di
                add di, 160
                ;----------------------------
                
                xor cx,cx       ;for (i = 2; i < width;i++){draw_line}
                add cx, 2d      ;because of borders
        @@for_loop: 
                cmp cx, MY_WIDTH       ;width
                jae @@for_end

                push MY_LENGTH         ;length
                call draw_line

                inc cx
                jmp @@for_loop                
        @@for_end:
                add si, 3
                push MY_LENGTH         ;lendth
                call draw_line

                add si, 3

                pop di ;Revive di - ptr to angle of frame
                ;--------------------------
		; close action
	        pop si dx cx bx ax ;revive regs
                mov sp,bp 	;sp = bp, revive bp
                pop bp
                ret
print_frame 	endp
;--------------------------------------------
;NAME: draw_line(length)
;Function to draw line and rotate 
;IN:  BX, DI - jmps to next line(+160)
;RET: -
;SAVE: CX, SI
;LOCALS: -
draw_line proc
                ;input action
                nop
                push bp     
                mov bp, sp       
                push cx si
                ;-----------------BODY----------------------
                push di     ; save cell to jmp to next line!
                ;first symbol
                mov bl, byte ptr [si]
                mov word ptr es:[di], bx
                add di, 2
                inc si

                ;many next
                xor cx,cx       ;for (i = 2; i < length;i++){...}
                add cx, 2    ; because of borders
        @@for_loop:
                cmp cx, [bp+4] 
                jae @@for_end
                
                mov bl, byte ptr [si]
                mov word ptr es:[di], bx
                add di, 2

                inc cx
                jmp @@for_loop
        @@for_end:
                ;end symbol
                inc si
                mov bl, byte ptr [si]
                mov word ptr es:[di], bx
                add di, 2

                ;revive di and jmp to next line
                pop di
                add di, 160
                ;-------------------------------------------
                ; close action
                pop si cx   
                mov sp,bp
                pop bp
                ret 2
draw_line endp
;------------------------------------------------
;NAME:draw_regs(ax bx cx dx si di bp sp ds es ss cs ip)
;             [bp+28]                             [bp+4]
;Function to draw regs 
;IN:  13 regs, position of di
;RET: -
;SAVE: CX, SI
;LOCALS: 1
draw_regs       proc
                ;input action
                nop
                push bp     
                mov bp, sp      
                sub sp, 2   ;1 local vars in stack
                push ax bx cx dx di si
                ;---------------BODY--------------
                ; Symbol & color in DX !
                ;1) Set text color
                xor dx, dx
                mov dh, TEXT_COLOR

                push di ; Save angle p.3)
                
                ;2) Draw names regs
                mov si, offset name_of_regs ; set ds:[si] to str with names
                mov [bp-2], word ptr 0d   ;counter for regs!
    @@for_loop1:               ;for([bp-2]; [bp-2]< N_REGS; [bp-2]++){for...}
                cmp [bp-2], word ptr AMOUNT_REGS
                jae @@for_end1

                push di        ;save start
                xor cx,cx      ;for(cx = 0; cx < 2; cx++){draw 1 symbol}
        @@for_loop:
                cmp cx, 2 
                jae @@for_end
                
                movsb
                mov byte ptr es:[di], dh
                inc di

                inc cx
                jmp @@for_loop
        @@for_end: 
                mov dl, 020h                ;set space ' ' after
                mov word ptr es:[di], dx
                add di, 2

                pop di  ;revive and set next line
                add di, 160d

                inc word ptr [bp-2]
                jmp @@for_loop1
    @@for_end1:            
                ;3)Draw content of regs
                pop di  ;revive angle
                push bp ;save bp before change
                mov cx, AMOUNT_REGS 
        @@for_loop2:        ;for(cx = AMOUNT OF REGS; cx > 0; cx++){...}
                push di          ;"ax_0000" ptr to last digit
                add di, 12       ;"ax_0000" ptr to last digit

                push [bp+4]  ; push [bp];bp += 2
                call draw_hex_word  
                add bp,2

                pop di  ;revive and set next line
                add di, 160d
        loop @@for_loop2
                pop bp
                ;---------------------------------
                ;close action
                pop si di dx cx bx ax
                mov sp,bp ; close action
                pop bp
                ret 
draw_regs endp
;-------------------------------------------------
;NAME: draw_hex_word(number)
;Function to draw one hex word in videomem
;IN: one hex number and di - ptr to last digit, es - set to vidmem
;RET: -
;SAVE: ax bx cx di si
;LOCALS: -
draw_hex_word   proc
                ;input action
                nop
                push bp     
                mov bp, sp      
                push ax bx cx di si
                ;---------------BODY--------------
                ;translate hex to str
                ;DX:=(DX,AX) mod op, AX:=(DX,AX) div op
                ;DX = 0, AX = [bp+4] - number
                ;Div 16 -> result = digit in hex

                mov cx,4
                mov ax, [bp+4]
    @@for_1:            
                xor dx,dx
                mov bx, 16d
                div bx
                ;Translate digit to symbol(dx - digit)
        @@begin_if: 
                cmp dl, 9
                ja @@do_else
        @@do_if:
                add dl, CH_NULL  ;'0' + digit = '0-9'
                jmp @@end_if
        @@do_else:  
                add dl, CH_7_HEX ;'7' + digit = 'A-F'
        @@end_if:
                ;Draw digit to videomem
                mov dh, TEXT_COLOR          ;dl = digit symbol 
                mov word ptr es:[di], dx    
                sub di, 2
    loop @@for_1

                ;---------------------------------
                ;close action
                pop si di cx bx ax
                mov sp,bp ; close action
                pop bp
                ret 2
draw_hex_word   endp
;-----------------------------------------------------------------------
;--------------------------------CONSTANTS------------------------------
bool_var_draw   db 0
bool_var_butt   db 0
style_frame     db 0c9h, 0cdh, 0bbh, 0bah, 020h, 0bah, 0c8h, 0cdh, 0bch
name_of_regs    db 'ax', 'bx', 'cx', 'dx', 'si', 'di', 'bp', 'sp', 'ds', 'es', 'ss', 'cs', 'ip'
say_my_frame    db 'REGISTERS',CH_END_STR
;-----------------------------------------------------------------------
EndOfProg:
end		Start