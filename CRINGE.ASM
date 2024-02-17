.model tiny
.286
.code
org 100h
Start:		mov di, 0b800h
		mov es, di		;ES = 0b800h videomem segment
		xor di, di		;DI = 0000h cleaning
		cld				;flag DF = 0
		
		xor cx, cx		;CX = 0
		dec cx			;CX--  ->  CX = FFFFh, SF = 1,SP = 1  
		rep movsb		;copy bytes while CX <> 0 -> loop 65k from our segment to video mem 

;ends copy to videomem of our segment

       		ret

org 160d * 4d + 96d			
                db '                                                      ', 'B', 218d,'L', 218d,'A', 218d,'B', 218d,'L', 218d,'A', 218d,':', 218d,'K', 218d,'H', 218d,'M', 218d, 'E', 218d,'L', 218d,'N', 218d,'I', 218d,'T', 218d,'S', 218d,'K', 218d,'I', 218d, 'I', 218d,'A', 218d,'N', 218d,'T', 218d,'O', 218d,'N', 218d, '                                                           '
org 160d * 5d + 96d	
		db '     + = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = +       ' 
		db '     |                                                                                                                                       |       '
		db '     |                                                                                                                                       |       '
		db '     + = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = +       '
org $ + 160d*2
		db '! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! '
org $ + 160d

end		Start

