.model tiny
.code

org 100h

CR		equ 0dh
LF		equ 0ah
atr		equ 04h

Start:
                call install

                mov ah, 4ch 
                int 21h

old_int9h       dd ?  

;---------------------------------------------------------------------------
;Prints comand string text to screen
;Entry:		--
;Exit:		--
;Destr:		SI, CX, AX, BX
;---------------------------------------------------------------------------

print_text  	proc 

				mov si, offset regstr
				dec si
                mov cx, 103d 			;num of sumbols in string
                mov bx, 2cah


metka1:			inc si					; text ouput cycle
				cmp byte ptr [si], '#'
				jne skip1
				add bx, 0a0h
				sub bx, 14d
				dec cx
				jmp metka1
		
skip1:			mov al, [si]
				mov es:[bx], al
				mov byte ptr es:[bx + 01], 75h
				add bx, 02h
				loop metka1

				ret
				endp

regstr:         db 'AX:0000#BX:0000#CX:0000#DX:0000#SI:0000#DI:0000#BP:0000#SP:0000#DS:0000#ES:0000#SS:0000#CS:0000#IP:0000'

;-------------------------------------------------------------------------
;Set registers values to regstr 
;Entry:		--
;Exit:		--
;Distr:		AX, BX, CX, DX 
;Expected:	label regstr --> string 'AX:0000#BX:0000' etc
;			all registers in stack from the interrupt function (my_kb_int)
;-------------------------------------------------------------------------

set_regs_val	proc

                push bp
                mov bp, sp

                ; [bp+22] = cs (before interruption)
                ; [bp+20] = ip (before interruption)
                ; [bp+18] = ax
                ; [bp+16] = bx
                ; [bp+14] = cx
                ; [bp+12] = dx
                ; [bp+10] = si
                ; [bp+8]  = di
                ; [bp+6]  = ds
                ; [bp+4]  = es
				; [bp+2]  = ret_addr in my_kb_int
                ; [bp]    = bp (in this function)
				
                mov ax, [bp+18]
                mov di, offset regstr + 3
                call hex2ascii

                mov ax, [bp+16]
                mov di, offset regstr + 11
                call hex2ascii

                mov ax, [bp+14]
                mov di, offset regstr + 19
                call hex2ascii

                mov ax, [bp+12]
                mov di, offset regstr + 27
                call hex2ascii

                mov ax, [bp+10]
                mov di, offset regstr + 35
                call hex2ascii

                mov ax, [bp+8]
                mov di, offset regstr + 43
                call hex2ascii

                mov ax, [bp]
                mov di, offset regstr + 51
                call hex2ascii

                mov ax, bp
                add ax, 26					; SP = bp + 26 (24 is flags)
                mov di, offset regstr + 59
                call hex2ascii

                mov ax, [bp+6]
                mov di, offset regstr + 67
                call hex2ascii

                mov ax, [bp+4]
                mov di, offset regstr + 75
                call hex2ascii

                mov ax, ss
                mov di, offset regstr + 83
                call hex2ascii

                mov ax, [bp+22]
                mov di, offset regstr + 91
                call hex2ascii

                mov ax, [bp+20]
                mov di, offset regstr + 99
                call hex2ascii

				pop bp
                ret
				endp

;---------------------------------------------------------------------------
;Cast 16-bit value to 4 hex symbols and write it to DS:DI 
;Entry:		AX == 16-bit value
;			DS:DI --> place to write sumbols
;Exit:		--
;Distr:		AX, CX, DX, DI
;---------------------------------------------------------------------------

hex2ascii		proc

                mov cx, 4
                mov dx, ax
				
@@next:         mov al, dh          ; high 8-bit value 
                shr al, 4           ; al - high 4-bit value
                call halfbyte2ascii

                mov [di], al
                inc di
                shl dx, 4
                loop @@next

                ret
				endp

;---------------------------------------------------------------------------
;Cast 4-bit piece to ASCII sumbol
;Entry: 	AL = 4-bit value (0-15)
;Exit: 		AL = ASCII sumbol
;Distr:		--
;---------------------------------------------------------------------------
halfbyte2ascii	proc

                add al, '0'
                cmp al, '9'
                jbe @@ok
                add al, 'A' - '0' - 10   ; ASCII 'A'

@@ok:           ret
				endp


;----------------------------------------------------------------------
;New 09h function (calls real 09h at th e end)
;Entry:     --
;Exit:      --
;Distr:     --
;Expected: label EORP after this procedure
;----------------------------------------------------------------------
my_kb_int       proc
                push ax
                push bx
                push cx
                push dx
                push si
                push di
                push ds
                push es

                mov ax, cs
                mov ds, ax

                mov ax, 0b800h
                mov es, ax
                mov bx, 690h          
                mov ah, atr
                in al, 60h

				cmp al, 87d
				jnz skip_regs

				call set_regs_val
                call print_text
skip_regs:
                pop es
                pop ds
                pop di
                pop si
                pop dx
                pop cx
                pop bx
                pop ax

                jmp dword ptr cs:[old_int9h]
                ret
                endp

EORP:              

;--------------------------------------------------------------------------
;Install and save in memory new 09h interuption
;Entry:     --
;Exit:      --
;Distr:     AX, BX, DX, ES
;Expected:  code of new int 09h ends with EORP: (end of resident programm)
;--------------------------------------------------------------------------

install         proc

                xor ax, ax
                mov es, ax
                mov bx, 4 * 9 

                mov ax, es:[bx]                 ;save old 09h function address
                mov word ptr [old_int9h], ax
                mov ax, es:[bx+2]
                mov word ptr [old_int9h+2], ax

                cli                             ;set new 09h function
                mov es:[bx], offset my_kb_int   
                mov es:[bx+2], cs
                sti

                mov ax, 3100h                   ;save in memory
                mov dx, offset EORP
                shr dx, 4         
                inc dx
                int 21h

                ret 
                endp

end             Start