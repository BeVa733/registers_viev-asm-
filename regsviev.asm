.model tiny
.code

org 100h

atr		equ 04h

Start:
                call install

                mov ah, 4ch 
                int 21h

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
				push bp 

                mov ax, cs
                mov ds, ax

                mov ax, 0b800h
                mov es, ax
                mov bx, 690h          
                mov ah, atr
                in al, 60h
				; mov es:[bx], ax

				cmp al, 87d
				jnz skip_regs

				mov di, offset save_buffer
				call video_cpy

				call set_regs_val
                call print_text

				push 14d 
				push 7d
				push offset sum_buf
				push 2cah
				call print_bframe
				add sp, 8

				mov di, offset draw_buffer
				call video_cpy

				mov cs:[active_flag], 1

skip_regs:
				in al, 60h 
				cmp al, 82d
				jne skip_clean
				
				mov al, 128d
				out 60h, al

				cmp cs:[active_flag], 0
				je skip_clean

				call clean_place
				mov cs:[active_flag], 0

skip_clean:		pop bp 
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

;------------------------------------------------------------------------
;Copy save_buffer to videoemory
;Entry:		--
;Exit:		--
;Distr:		DS, CX, SI, DI
;------------------------------------------------------------------------
clean_place		proc 

				mov cx, cs 
				mov ds, cx
				mov si, offset save_buffer

				mov cx, 0b800h
				mov es, cx 
				mov di, 0 

				mov cx, 4000
				rep movsb

				ret 
				endp 

;------------------------------------------------------------------------
;Copies videomem to buffer
;Entry:		cs:di--> destination buffer
;Exit:		--
;Distr:		CX, SI
;------------------------------------------------------------------------
video_cpy		proc 

				push ds
				push es

				mov cx, 0b800h
				mov ds, cx
				mov si, 0

				mov cx, cs
				mov es, cx 
				
				mov cx, 4000
				rep movsb

				pop es 
				pop ds
				ret 
				endp 



;------------------------------------------------------------------------
;Actualize save and draw buffer
;Entry:		--
;Exit:		--
;Distr:		CX, DI, AX, SI, BX
;------------------------------------------------------------------------
act_buffers		proc 

				mov cx, cs 
				mov ds, cx
				mov si, offset draw_buffer
				mov bx, offset save_buffer

				mov cx, 0b800h
				mov es, cx 
				mov di, 0 
				
				mov cx, 4000

@@cycle:		mov al, es:[di]
				mov ah, [si]
				cmp al, ah 
				je @@cont

				mov [si], al
				mov [bx], al

@@cont:			inc di
				inc si 
				inc bx

				loop @@cycle

				ret 
				endp

;------------------------------------------------------------------------
;New 08h interrupt
;Entry:     --
;Exit:      --
;Distr:     --
;Expected: label EORP after this procedure
;------------------------------------------------------------------------

my_timer_int	proc

				push ax
				push bx
				push cx
				push dx
				push si
				push di
				push ds
				push es
				push bp

				mov ax, cs
                mov ds, ax

				cmp active_flag, 1
    			jne timer_exit

				call act_buffers

timer_exit:
				pop bp
				pop es
				pop ds
				pop di
				pop si
				pop dx
				pop cx
				pop bx
				pop ax

				jmp dword ptr cs:[old_int8h]
				endp


;---------------------------------------------------------------------------
;Prints string text to screen
;Entry:		ES --> videomemory segment
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
set_regs_val    proc

                push bp
                mov bp, sp

				; [bp+24] = cs (before interruption)
                ; [bp+22] = ip (before interruption)
                ; [bp+20] = ax
                ; [bp+18] = bx
                ; [bp+16] = cx
                ; [bp+14] = dx
                ; [bp+12] = si
                ; [bp+10] = di
                ; [bp+8]  = ds
                ; [bp+6]  = es
				; [bp+4]  = bp
                ; [bp+2]  = ret_addr in my_kb_int
				; [bp]    = bp(this function)

				;AX
                mov ax, [bp + 20]
                mov di, offset regstr + 3
                call hex2ascii

                ; BX
                mov ax, [bp + 18]
                mov di, offset regstr + 11
                call hex2ascii

                ; CX
                mov ax, [bp + 16]
                mov di, offset regstr + 19
                call hex2ascii

                ; DX
                mov ax, [bp + 14]
                mov di, offset regstr + 27
                call hex2ascii

                ; SI
                mov ax, [bp + 12]
                mov di, offset regstr + 35
                call hex2ascii

                ; DI
                mov ax, [bp + 10]
                mov di, offset regstr + 43
                call hex2ascii

                ; BP
                mov ax, [bp + 4]
                mov di, offset regstr + 51
                call hex2ascii

                ; SP 
                mov ax, bp
                add ax, 28
                mov di, offset regstr + 59
                call hex2ascii

                ; DS
                mov ax, [bp + 8]
                mov di, offset regstr + 67
                call hex2ascii

                ; ES
                mov ax, [bp + 6]
                mov di, offset regstr + 75
                call hex2ascii

                ; SS
                mov ax, ss
                mov di, offset regstr + 83
                call hex2ascii

                ; CS
                mov ax, [bp + 24]
                mov di, offset regstr + 91
                call hex2ascii

                ; IP
                mov ax, [bp + 22]
                mov di, offset regstr + 99
                call hex2ascii

                pop bp
                ret
set_regs_val    endp

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
				

sum_buf:		db '123456789'

;-------------------------------------------------------------------------
;Prints beautiful frame with parameters 
;Entry: 	ss:[sp + 2] --> text start place
;			ss:[sp + 4] --> symbols buffer
;			ss:[sp + 6] == str_max_len
;			ss:[sp + 8] == n_strings + 1
;			es --> videomem
;Exit:		--
;Distr:		all regs (without sp)
;Expected:  sumbols buffer has 9 symbols
;-------------------------------------------------------------------------

print_bframe	proc

				mov bp, sp

				mov bx, ss:[bp + 2]
				mov si, ss:[bp + 4]

				sub bx, 326d					; first_param
				mov al, [si]
				mov es:[bx], al
				mov byte ptr es:[bx + 1], atr
				push bx
				add bx, 2

				mov al, [si + 1]				;second_param
				mov cx, ss:[bp + 6]
				add cx, 4
				push bx
				call pr_sum_str

				mov al, [si + 2]				;third param
				mov es:[bx], al
				mov byte ptr es:[bx + 1], atr

				pop bx							;5th param
				add bx, 160d
				mov al, [si + 4]
				mov cx, ss:[bp + 6]
				add cx, 4
				call pr_sum_str

				mov cx, ss:[bp + 8]
				inc cx	
				pop bx
				add bx, 160d
				push bx
				mov di, cx
				mov al, [si + 3]				;4th param
				call pr_sum_col
				pop bx
				push bx
				mov cx, di 
				mov dx, ss:[bp + 6]
				shl dx, 1
				add dx, 10d
				add bx, dx 
				mov al, [si + 5]
				call pr_sum_col

				pop bx 
				add bx, 2
				mov al, [si + 4]
				mov cx, di 
				push bx
				push bx
				call pr_sum_col

				pop bx 
				add bx, 2
				push bx
				mov cx, di
				call pr_sum_col

				pop bx
				mov dx, ss:[bp + 6]
				inc dx
				shl dx, 1
				add bx, dx
				mov cx, di
				push bx
				call pr_sum_col 

				pop bx 
				add bx, 2
				mov cx, di
				call pr_sum_col
                                                    
				pop bx ; from str 324
				mov ax, ss:[bp + 8]
				mov dl, 160d
				mul dl
				add bx, ax
				push bx

				mov al, [si + 4]
				mov cx, ss:[bp + 6]
				add cx, 4
				mov di, cx
				call pr_sum_str
				pop bx

				add bx, 158d
				mov al, [si + 6]
				mov es:[bx], al
				mov byte ptr es:[bx + 1], atr 
				add bx, 2

				mov al, [si + 7]
				mov cx, di
				call pr_sum_str

				mov al, [si + 8]
				mov es:[bx], al
				mov byte ptr es:[bx + 1], atr 

				ret
				endp

;---------------------------------------------------------------------------
;Prints row of symbols
;Entry:		ES:BX --> start of row
;			CX  == n symbols
;			AL  == symbol
;Exit:		--
;Distr:		BX, CX
;---------------------------------------------------------------------------

pr_sum_str		proc
metka2:
				mov es:[bx], al
				inc bx
				mov byte ptr es:[bx], 04h
				inc bx
				loop metka2

				ret
				endp

;---------------------------------------------------------------------------
;Prints column of sumbols
;Entry:		ES:BX --> start of column
;			CX  == n symbols
;			AL  == symbol
;Exit:		--
;Distr:		BX, CX
;---------------------------------------------------------------------------	

pr_sum_col		proc
metka4:
				mov es:[bx], al
				mov byte ptr es:[bx + 01], 04h
				add bx, 00a0h
				loop metka4

				ret
				endp


old_int9h       dd ?
old_int8h       dd ?
active_flag     db 0
save_buffer     db 4000 dup (?) 		;442 - size of frame in bytes (13*17*2)
draw_buffer     db 4000 dup (?)

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

				mov bx, 4 * 8					;set new 08h
                mov ax, es:[bx]
                mov word ptr [old_int8h], ax
                mov ax, es:[bx+2]
                mov word ptr [old_int8h+2], ax
                cli
                mov es:[bx], offset my_timer_int
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