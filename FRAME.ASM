;<GITHUB>: khmelnitskiianton
;This programm draws frame in dos
;
;<Use>:   1) close manager CTRL+O
;       2) clear window  >cls
;       3) run program with arguments
;       > frame.com <length> <width> <color> <style> <string>
;       length of frame - decimal number
;       width of frame  - decimal number
;       color of frame  - hex number like '4e' in lower register <= ffh
;       style - number 0-2 set format of frame(only 3 types)
;       string - everithing you want to write in frame
;       if string will be too big it just stops writing(it is safe)
;
;<WARNING>
;-IF you forgot length or width or color or style it will be UB !!!
; Only no str is possible
;GOOD LUCK

.model tiny
.286
.code
org 100h
locals @@

;LAUNCH:
;> frame.com    40    15    4e     0    Hello Meow
;             length width color style  str

;CTRL + O -> cls -> start program
;Window: 22 lines 160 cells

;--------------------------DEFINE--------------------------------
PTR_VIDMEM equ 0b800h ; segment of videomem
PTR_CMD    equ 0080h  ; ptr of cmd line
CH_END_STR equ 0024h  ; end char of string
CH_NULL    equ 0030h  ; '0'
CH_W_HEX   equ 0057h  ; 'w' in hex
END_CODE   equ 4c00h  ; Dos fn terminate with 0

SIZE_STYLE equ 9d
SETCOLOR   equ 047h
SHADOW     equ 070h
;--------------------------------------------------------------------
Start:	jmp main
;------------------------------MAIN----------------------------------
main    proc
        nop
        push bp     ;input action
        mov bp, sp  
        sub sp, 10   ;5 local vars in stack

        ;no save regs

        mov bx, PTR_VIDMEM
        mov es, bx	  ;set segment of vido memory in ES
        xor bx, bx

        ;Vars to save
        mov [bp-2], word ptr 0000h  ;size of cmd line
        mov [bp-4], word ptr 0000h  ;length
        mov [bp-6], word ptr 0000h  ;width
        mov [bp-8], word ptr 0000h  ;color
        mov [bp-10],word ptr 0000h  ;style of frame

        mov si, PTR_CMD         ;SI - index of cmd line
        xor ax, ax
        mov al, [si]            ;[bp-2] - size of cmd line 
        mov word ptr [bp-2], ax       
        inc si                  ;set si on first char

        push si                 ;save si
        mov ax, word ptr [bp-2]
        add si, ax              ;move to end of cmd line
        mov [si], byte ptr CH_END_STR ; set end symbol '$'
        pop si

        ;Start parsing cmd line

        call skip_spaces
        call atoi       ;scan 1 number - length
        mov [bp-4], ax  ;length = ax 

        call skip_spaces
        call atoi       ;scan 2 number - width
        mov [bp-6], ax  ;width = ax 

        call skip_spaces
        call atoh       ;scan 3 number hex - color 
        mov [bp-8], ax  ;color = ax 

        call skip_spaces
        call atoi       ;scan 4 number - style of frame
        mov [bp-10], ax  ;style = ax 
        
        call skip_spaces
        ;Start draw frame! draw_frame(length, width, color, style, str)

        push [bp-4]
        push [bp-6]
        push [bp-8]
        push [bp-10]
        push si
        call draw_frame
        


        ;END
        	mov ax, END_CODE
        	int 21h

        mov sp,bp ; close action
        pop bp
        ret
main endp
;---------------------------------------------------------------
;-----------------------FUNCTIONS-------------------------------
;0)draw_frame(length,width,color,style,str)
;Function to write frame 
;Use & Change: length,width,color,style, es:[bx] if es = 0b800h - seg of vidmem
;Return: nothing
;Save Regs: AX,BX,CX,DX,DI
;Locals: -
draw_frame      proc
                nop
                push bp     ;input action
                mov bp, sp  
                sub sp, 4   ;2 local vars in stack
        
                push ax     ;save regs
                push bx
                push cx
                push dx
                push di
                push si

                ;-----------BODY-------------
                ; coordinate = line * 160d + shift
                ; center = 11 * 160 + 80
                ; es:[di] = coordinate of curr cell

                ;SI - ptr of style frame
                ;DI - pointer of current cell
                ;BH - color, BL - char
                ;AX,CX,DX - help

                ;1) Set style
                ;curr_style = style_frame + SIZE_STYLE*index
                xor si,si
                LEA si, style_frame
                mov ax, SIZE_STYLE
                mul word ptr [bp+6]
                add si, ax
                
                ;2) Color
                xor bx,bx
                mov bh, [bp+8]

                ;3) Set DI center
                xor dx, dx
                mov ax, 160d
                mov dx, 11d               
                mul dx
                add ax, 80
                mov di, ax
                ;4) Set start position di
                mov ax, [bp+12]         ; di = center-length/2*2(word)-160*(width/2)
                mov cl, 2
                div cl
                @@begin_if:             ; check if (di % 2 != 0) - need align 1 byte!
                        cmp ah, 0
                        je @@end_if 
                @@do_if:
                        dec di
                @@end_if:
                sub di, [bp+12] 
                mov ax, [bp+10]
                mov cl, 2d
                div cl          
                xor ah, ah
                mov cx, 160d
                mul cx
                sub di, ax

                push di         ; save begin

                ;5)Drawing frame
                push [bp+12]
                call draw_line
                add si, 3

                xor cx,cx       ;for (i = 2; i < width;i++){draw_line}
                add cx, 2       ;because of borders
        @@for_loop: 
                cmp cx, [bp+10] 
                jae @@for_end

                push [bp+12]
                call draw_line

                inc cx
                jmp @@for_loop                
        @@for_end:
                add si, 3
                push [bp+12]
                call draw_line

                add si, 3

                ;6) Write text
                pop di   ;revive begining
                add di, 2
                add di, 160    ;shift to text

                mov si, [bp+4]  ;change si

                mov ax, [bp+12] ; [bp-2] = length-2 * width-2 = squre
                sub ax, 2
                mov dx, [bp+10]
                sub dx, 2
                mul dx
                mov [bp-2], ax


                mov al, CH_END_STR
                mov cx, 2
                xor dx, dx      ; full counter of square
        @@while_loop:           ; while((*ptr != END_CHAR)&&(size < square)){write}
                cmp al, byte ptr [si]
                je @@while_end
                cmp dx, [bp-2]
                jae @@while_end

        @@begin_if2:
                cmp cx, [bp+12] ;if str is too big go next line
                jb @@end_if2
        @@do_if2:
                mov cx, 2
                sub di, [bp+12]
                sub di, [bp+12]
                add di, 4
                add di, 160
        @@end_if2:
                movsb
                mov byte ptr es:[di], bh
                inc di

                inc cx
                inc dx
                jmp @@while_loop
        @@while_end:

                ;--------------------------

                pop si
                pop di
                pop dx  ;revive regs
                pop cx 
                pop bx
                pop ax
                
                mov sp,bp ; close action
                pop bp
                ret 6
draw_frame      endp

;1)draw_line(length)
;Function to draw line and rotate 
;Use & Change:  BX, DI - jmps to next line(+160)
;Return: nothing
;Save Regs: CX, SI
;Locals: 0
draw_line proc
                nop
                push bp     ;input action
                mov bp, sp  
                
                push cx     ; save regs
                push si     ;

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

                pop si    ; revive regs
                pop cx

                mov sp,bp ; close action
                pop bp
                ret 2
draw_line endp

;2)skip_spaces()
;Function to skip spaces 
;Use & Change:  SI - address of string
;Return: nothing
;Save Regs: AX
;Locals: 0
skip_spaces	proc
                nop
                push ax 
;-------------------BODY---------------------
@@while_loop:       ;while(al == ' ') {si++}
                mov al, [si]
		        cmp al, ' '			
                jne @@while_end
		        inc si  
		        jmp @@while_loop
@@while_end:
;---------------------------------------------
                pop ax
	        ret
skip_spaces	endp

;3) atoi()
;Function to process decimal number from str
;Use & Change:  AX, SI - address of string
;Return: AX = return number
;Save Regs: BX,CX,DX
;Locals: 2
atoi    proc
        nop
        push bp     ;input action
        mov bp, sp  
        sub sp, 4   ;2 local vars in stack

        push bx     ;save regs, bx - return 
        push cx
        push dx
;-------------------BODY---------------------
        call num_len    ; ax := length of str
        mov [bp-2], ax  ; [bp-2] = s.size
        xor ax,ax       ; ax = 0

        mov [bp-4], ax      ; [bp-4] = i = ax = 0
@@for_loop:                         ;for ([bp-4]; [bp-4] < [bp-2]; [bp-4]++)
            mov bx, [bp-4] 
            cmp bx, [bp-2]
            jae @@for_end

            mov bx, 10d             ;bx*10 -> bx + digit -> bx*10 -> ...
            mul bx                  ;loop for process str to int
            mov dl, [si]
            sub dl, CH_NULL 
            add ax, dx
            inc si

            inc word ptr [bp-4]
            jmp @@for_loop
@@for_end:
;---------------------------------------------
        pop dx  ;revive regs
        pop cx 
        pop bx
        
        mov sp,bp ; close action
        pop bp
        ret
atoi    endp

;4) num_len
;Function of processing length of string till not digit
;Use & Change:  AX,SI - address of string
;Return: AX = length of number
;Save Regs: BX,CX,DX
;Locals: 0
num_len proc
        nop

        push bx ;save regs
        push cx
        push dx
;-------------------BODY---------------------
        mov bx, si
@@do_while:		;do {bx++} while([ax] >= '0' && [ax] =< '9')
        
        inc bx  

        xor dx,dx   ;dx=0
        mov al, [bx]            
        @@begin_if1: cmp al, '0' 
                    jb @@end_if1
                    cmp al, '9'
                    ja @@end_if1
        @@do_if1:  mov dx, 1
        @@end_if1:
        @@begin_if2: cmp al, 'a' 
                    jb @@end_if2
                    cmp al, 'f'
                    ja @@end_if2
        @@do_if2:  mov dx, 1
        @@end_if2:         
        cmp dx, 1 
je @@do_while		
        sub bx, si  ; ax = ax - si - length of line
        mov ax, bx  ; final length in ax
;---------------------------------------------
        pop dx  ;revive regs
        pop cx
        pop bx
        
        ret
num_len endp

;5) atoh
;Function to process hex number from str
;Use & Change:  AX, SI - address of string
;Return: AX = return number
;Save Regs: BX,CX,DX
;Locals: 2
atoh    proc
        nop
        push bp     ;input action
        mov bp, sp  
        sub sp, 4   ;2 local vars in stack

        push bx     ;save regs, bx - return 
        push cx
        push dx
;-------------------BODY---------------------
        call num_len    ; ax := length of str

        mov [bp-2], ax  ; [bp-2] = s.size
        xor ax,ax       ; ax = 0

        mov [bp-4], ax      ; [bp-4] = i = ax = 0
@@for_loop:                         ;for ([bp-4]; [bp-4] < [bp-2]; [bp-4]++)
            mov bx, [bp-4] 
            cmp bx, [bp-2]
            jae @@for_end

            mov bx, 16d             ;bx*10 -> bx + digit -> bx*10 -> ...
            mul bx                  ;loop for process str to int
            mov dl, [si]
            @@begin_if: cmp dl, '0' 
                        jb @@do_else
                        cmp dl, '9'
                        ja @@do_else
            @@do_if:    sub dl, CH_NULL  ;'0-9' - '0' = digit
                        jmp @@end_if
            @@do_else:  
                        sub dl, CH_W_HEX ;'a-f' - 'w' = digit
            @@end_if:
            add ax, dx
            inc si

            inc word ptr [bp-4]
            jmp @@for_loop
@@for_end:
;---------------------------------------------
        pop dx  ;revive regs
        pop cx 
        pop bx
        
        mov sp,bp ; close action
        pop bp
        ret
atoh    endp

;----------------------------CONSTANTS------------------------------
style_frame     db 0c9h, 0cdh, 0bbh, 0bah, 020h, 0bah, 0c8h, 0cdh, 0bch
                db 0dah, 0c4h, 0bfh, 0b3h, 020h, 0b3h, 0c0h, 0c4h, 0d9h
                db 0dch, 0dch, 0dch, 0ddh, 020h, 0deh, 0dfh, 0dfh, 0dfh
;-------------------------------------------------------------------
end Start