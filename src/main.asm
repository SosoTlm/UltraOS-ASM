; main.asm - UltraOS Bootloader (Live Ready)
org 0x7C00
bits 16

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov [boot_drive], dl
    mov ss, ax
    mov sp, 0x7C00
    sti
    
    ; Set text mode 80x25
    mov ax, 0x0003
    int 0x10
    
    ; Print banner
    mov si, msg_kernel
    call print
    call nl
    mov si, msg_load
    call print
    call nl
    
    ; Reset disk system first
    mov ah, 0x00
    mov dl, [boot_drive]
    int 0x13
    
    ; Debug: show we're trying to load
    mov si, msg_loading
    call print
    
    ; === Load switcher.bin at 0x7E00 (always present) ===
    mov ah, 0x02      ; BIOS read sectors
    mov al, 4         ; 4 sectors = 2KB switcher
    mov ch, 0         ; cylinder 0
    mov cl, 2         ; sector 2 (sectors start at 1!)
    mov dh, 0         ; head 0
    mov dl, [boot_drive]
    xor bx, bx
    mov es, bx        ; ES:BX = 0x0000:0x7E00
    mov bx, 0x7E00
    int 0x13
    jc show_error
    
    ; Debug: show success
    mov si, msg_success
    call print
    call nl
    
    ; Verify we loaded something (check first byte isn't zero)
    mov al, [0x7E00]
    cmp al, 0
    je boot_fail
    
    ; === Attempt to load installer at 0x9000 (optional) ===
    mov ah, 0x02
    mov al, 4         ; 4 sectors = 2KB installer
    mov ch, 0
    mov cl, 6         ; sector 6
    mov dh, 0
    mov dl, [boot_drive]
    xor bx, bx
    mov es, bx        ; ES:BX = 0x0000:0x9000
    mov bx, 0x9000
    int 0x13
    jc live_mode      ; Installer not found → live mode
    
    ; Check if installer has valid signature (optional verification)
    mov ax, [0x9000]
    cmp ax, 0x5A4D    ; Check for 'MZ' or your custom signature
    jne live_mode     ; Not valid installer → live mode
    
    ; Installer loaded successfully, jump to installer
    mov si, msg_installer
    call print
    call nl
    jmp 0x0000:0x9000

; Live mode → jump directly to switcher
live_mode:
    mov si, msg_live
    call print
    call nl
    jmp 0x0000:0x7E00

show_error:
    ; Show AH error code
    mov si, msg_error_code
    call print
    mov al, ah
    call print_hex
    call nl
    ; Fall through to boot_fail

boot_fail:
    mov si, msg_err
    call print
    call nl
    hlt
    jmp $
; =============================
; Print routines
; =============================
print:
    pusha
.loop:
    lodsb
    test al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp .loop
.done:
    popa
    ret

nl:
    push ax
    mov ah, 0x0E
    mov al, 13
    int 0x10
    mov al, 10
    int 0x10
    pop ax
    ret

print_hex:
    push ax
    push bx
    mov bl, al
    shr al, 4
    call .nibble
    mov al, bl
    and al, 0x0F
    call .nibble
    pop bx
    pop ax
    ret
.nibble:
    cmp al, 9
    jle .digit
    add al, 7
.digit:
    add al, '0'
    mov ah, 0x0E
    int 0x10
    ret

; =============================
; Data
; =============================
boot_drive db 0

msg_kernel     db "UltraOS - BOOT",0
msg_load       db "Finding installer... or switcher...",0
msg_loading    db "Loading switcher...",0
msg_success    db "[OK] SWITCHER.BIN",0
msg_error_code db "[FAILED]: 0x",0
msg_installer  db "Installer found, launching...",0
msg_live       db "Live mode: booting switcher...",0
msg_err        db "[FAILED] Cannot load switcher",0

times 510-($-$$) db 0
dw 0xAA55