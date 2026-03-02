.model tiny
.code
org 100h

Start:
    			mov ax, 0AAAAh
    			mov bx, 0BBBBh
    			mov cx, 0CCCCh
    			mov dx, 0DDDDh
    			mov si, 01111h
    			mov di, 02222h
    			mov bp, 03333h
    			mov es, ax
    			mov ds, bx
    
WaitLoop:		mov ah, 00h
    			int 16h
    			cmp al, 27
    			je Exit
    			jmp WaitLoop

Exit:			mov ax, cs
    			mov ds, ax
    
    			mov ax, 4C00h
    			int 21h

end Start