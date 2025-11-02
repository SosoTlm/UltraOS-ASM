[bits 64]
[org 0x10000]

section .text
_start:

    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax

    call set_vga_mode
    
    ; Draw UI
    call draw_background
    call draw_title_bar
    call draw_desktop
    
    ; Main loop
.loop:
    hlt
    jmp .loop

set_vga_mode:
    ; We need to drop back to real mode briefly or use VESA from 64-bit
    ; For now, assume mode was set earlier, just clear framebuffer
    
    ; VGA framebuffer at 0xA0000
    mov rdi, 0xA0000
    mov rcx, 320 * 200
    xor al, al  ; Black
    rep stosb
    ret

; ==========================================
; Draw Functions
; ==========================================
draw_background:
    ; Fill with gradient blue
    mov rdi, 0xA0000
    mov rcx, 320 * 150  ; Top portion
    mov al, 17  ; Dark blue
    rep stosb
    
    mov rcx, 320 * 50  ; Bottom portion
    mov al, 25  ; Lighter blue
    rep stosb
    ret

draw_title_bar:
    ; Draw top bar (32px height, dark gray)
    mov rdi, 0xA0000
    mov rcx, 320 * 32
    mov al, 8  ; Dark gray
    rep stosb
    
    ; Draw title text
    mov rsi, msg_title
    mov rdi, 0xA0000 + (8 * 320) + 10
    mov bl, 15  ; White
    call draw_string
    ret

draw_desktop:
    ; Draw a window box (centered)
    mov r12, 60   ; X
    mov r13, 60   ; Y
    mov r14, 200  ; Width
    mov r15, 100  ; Height
    mov bl, 7     ; Light gray
    call draw_rect
    
    ; Draw window title bar
    mov r12, 60
    mov r13, 60
    mov r14, 200
    mov r15, 20
    mov bl, 1     ; Blue
    call draw_rect
    
    ; Window title
    mov rsi, msg_window
    mov rdi, 0xA0000 + (65 * 320) + 70
    mov bl, 15
    call draw_string
    ret

; ==========================================
; Graphics Primitives
; ==========================================

; Draw rectangle
; r12=x, r13=y, r14=width, r15=height, bl=color
draw_rect:
    push rcx
    push rdi
    push r12
    push r13
    
    mov r8, r13  ; Current Y
.row_loop:
    ; Calculate offset: Y * 320 + X
    mov rax, r8
    mov rcx, 320
    mul rcx
    add rax, r12
    mov rdi, 0xA0000
    add rdi, rax
    
    ; Draw row
    mov rcx, r14
    mov al, bl
    rep stosb
    
    inc r8
    mov rax, r13
    add rax, r15
    cmp r8, rax
    jl .row_loop
    
    pop r13
    pop r12
    pop rdi
    pop rcx
    ret

; Draw pixel
; r12=x, r13=y, bl=color
draw_pixel:
    push rax
    push rdi
    
    mov rax, r13
    mov rcx, 320
    mul rcx
    add rax, r12
    mov rdi, 0xA0000
    add rdi, rax
    mov byte [rdi], bl
    
    pop rdi
    pop rax
    ret

; Draw string (simple 8x8 font simulation)
; rsi=string, rdi=destination, bl=color
draw_string:
    push rax
    push rdi
    push rsi
    
.loop:
    lodsb
    test al, al
    jz .done
    
    ; Simple: just draw colored blocks for letters
    push rcx
    mov rcx, 8
    push rdi
.char_row:
    mov byte [rdi], bl
    mov byte [rdi+1], bl
    mov byte [rdi+2], bl
    mov byte [rdi+3], bl
    mov byte [rdi+4], bl
    add rdi, 320
    loop .char_row
    pop rdi
    pop rcx
    
    add rdi, 8 
    jmp .loop

.done:
    pop rsi
    pop rdi
    pop rax
    ret

section .data

msg_title    db "UltraOS v0.1",0
msg_window   db "Welcome!",0

; Pad to ensure proper size
times 8192-($-$) db 0