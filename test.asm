.model tiny
.code
org 100h

Start:
    			mov cx, offset EOP 
				sub cx, offset Start 
				mov bx, offset Start

				mov cx, offset EOP - offset Start
        		mov si, offset Start
        		mov di, 11Fch
        		mov ax, 7777h
				mov es, ax 
        		rep movsb

				db 0eah
				dw 1218h
				dw 7777h 

				mov ax, 0AAAAh
    			mov bx, 0BBBBh
    			mov cx, 0CCCCh
    			mov dx, 0DDDDh
    			mov si, 01111h
    			mov di, 02222h
    			mov bp, 03333h
    			mov es, ax
    			mov ds, bx
    
; WaitLoop:		mov ah, 00h
;     			int 16h
;     			cmp al, 27
;     			je Exit
;     			jmp WaitLoop

				
zaloop:			jmp zaloop 

Exit:			mov ax, cs
    			mov ds, ax
    
    			mov ax, 4C00h
    			int 21h
EOP:
end Start