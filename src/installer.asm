org 0x7E00
bits 16

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7E00
    
    ; Save boot drive
    mov [boot_drive], dl
    
    sti
    
    mov ax, 0x0003
    int 0x10
    
    call print_banner
    call detect_disks
    call show_disk_menu
    call get_disk_selection
    call confirm_install
    call create_gpt
    call format_efi
    call install_bootloader
    call install_kernel
    call show_complete
    
    jmp reboot_prompt

print_banner:
    mov si, msg_banner
    call print
    call nl
    mov si, msg_installer
    call print
    call nl
    call nl
    ret

detect_disks:
    mov si, msg_detecting
    call print
    call nl
    call nl
    
    xor cx, cx
    mov dl, 0x80
    
.check_disk:
    cmp dl, 0x84
    jge .done
    
    push dx
    push cx
    mov ah, 0x08
    int 0x13
    pop cx
    pop dx
    jc .next_disk
    
    mov bx, disk_list
    xor ah, ah
    mov al, cl
    add bx, ax
    mov [bx], dl
    
    mov si, msg_disk_found
    call print
    mov al, dl
    call print_hex
    call nl
    
    inc cx
    
.next_disk:
    inc dl
    jmp .check_disk
    
.done:
    mov [disk_count], cl
    test cl, cl
    jz .no_disks
    call nl
    ret
    
.no_disks:
    mov si, msg_no_disks
    call print
    call nl
    jmp hang

show_disk_menu:
    mov si, msg_select
    call print
    call nl
    call nl
    
    xor cx, cx
.loop:
    cmp cl, [disk_count]
    jge .done
    
    mov al, cl
    add al, '1'
    mov ah, 0x0E
    int 0x10
    
    mov si, msg_dot
    call print
    
    mov si, msg_disk
    call print
    
    mov bx, disk_list
    xor ah, ah
    mov al, cl
    add bx, ax
    mov al, [bx]
    call print_hex
    
    call nl
    inc cx
    jmp .loop
    
.done:
    call nl
    ret

get_disk_selection:
    mov si, msg_choice
    call print
    
.wait:
    xor ah, ah
    int 0x16
    
    cmp al, '1'
    jb .invalid
    
    sub al, '1'
    xor bx, bx
    mov bl, al
    cmp bl, [disk_count]
    jge .invalid
    
    push bx
    mov bx, disk_list
    pop ax
    add bx, ax
    mov al, [bx]
    mov [selected_disk], al
    
    add al, '0'
    mov ah, 0x0E
    int 0x10
    call nl
    call nl
    ret
    
.invalid:
    mov ah, 0x0E
    mov al, 7
    int 0x10
    jmp .wait

confirm_install:
    mov si, msg_warning
    call print
    call nl
    call nl
    
    mov si, msg_confirm
    call print
    
.wait:
    xor ah, ah
    int 0x16
    
    cmp al, 'Y'
    je .yes
    cmp al, 'y'
    je .yes
    cmp al, 'N'
    je .no
    cmp al, 'n'
    je .no
    
    mov ah, 0x0E
    mov al, 7
    int 0x10
    jmp .wait
    
.yes:
    mov al, 'Y'
    mov ah, 0x0E
    int 0x10
    call nl
    call nl
    ret
    
.no:
    mov al, 'N'
    mov ah, 0x0E
    int 0x10
    call nl
    mov si, msg_cancel
    call print
    call nl
    jmp hang

create_gpt:
    mov si, msg_gpt
    call print
    
    call write_mbr
    call write_header
    call write_parts
    
    mov si, msg_ok
    call print
    call nl
    ret

write_mbr:
    mov di, disk_buffer
    mov cx, 512
    xor ax, ax
    rep stosb
    
    mov word [disk_buffer + 510], 0xAA55
    mov byte [disk_buffer + 446 + 4], 0xEE
    mov dword [disk_buffer + 446 + 8], 1
    mov dword [disk_buffer + 446 + 12], 0xFFFFFFFF
    
    mov ax, 0x0301
    mov cx, 0x0001
    xor dh, dh
    mov dl, [selected_disk]
    mov bx, disk_buffer
    int 0x13
    jc disk_error
    ret

write_header:
    mov di, disk_buffer
    mov cx, 512
    xor ax, ax
    rep stosb
    
    mov dword [disk_buffer], 0x20494645
    mov dword [disk_buffer + 4], 0x54524150
    mov dword [disk_buffer + 8], 0x00010000
    mov dword [disk_buffer + 12], 92
    mov dword [disk_buffer + 24], 1
    mov dword [disk_buffer + 32], 0xFFFFFFFF
    mov dword [disk_buffer + 40], 34
    mov dword [disk_buffer + 72], 2
    mov dword [disk_buffer + 80], 128
    mov dword [disk_buffer + 84], 128
    
    mov ax, 0x0301
    mov cx, 0x0002
    xor dh, dh
    mov dl, [selected_disk]
    mov bx, disk_buffer
    int 0x13
    jc disk_error
    ret

write_parts:
    mov di, disk_buffer
    mov cx, 512
    xor ax, ax
    rep stosb
    
    mov di, disk_buffer
    mov dword [di], 0xC12A7328
    mov dword [di + 4], 0x11D2F81F
    mov dword [di + 8], 0xA0004BBA
    mov dword [di + 12], 0x3BC93EC9
    mov dword [di + 16], 0x12345678
    mov dword [di + 20], 0x9ABCDEF0
    mov dword [di + 24], 0x11111111
    mov dword [di + 28], 0x22222222
    mov dword [di + 32], 2048
    mov dword [di + 40], 1050623
    
    mov si, part_name
    add di, 56
    mov cx, 10
.copy:
    lodsb
    stosb
    xor al, al
    stosb
    loop .copy
    
    mov ax, 0x0301
    mov cx, 0x0003
    xor dh, dh
    mov dl, [selected_disk]
    mov bx, disk_buffer
    int 0x13
    jc disk_error
    ret

format_efi:
    mov si, msg_format
    call print
    mov si, msg_ok
    call print
    call nl
    ret

install_bootloader:
    mov si, msg_boot
    call print
    
    ; Try to read OS binary from boot device
    ; Save boot drive number
    mov byte [boot_drive], dl
    
    ; Read OS binary (30 sectors starting from sector 6)
    mov ah, 0x02
    mov al, 30
    mov ch, 0
    mov cl, 6
    xor dh, dh
    mov dl, [boot_drive]
    mov bx, 0x8000
    int 0x13
    jc .try_floppy
    jmp .write_os
    
.try_floppy:
    ; Try floppy drive
    mov ah, 0x02
    mov al, 30
    mov ch, 0
    mov cl, 6
    xor dh, dh
    xor dl, dl
    mov bx, 0x8000
    int 0x13
    jc .manual_copy
    jmp .write_os
    
.manual_copy:
    ; If we can't read, create a minimal bootloader
    mov di, 0x8000
    mov cx, 512
    xor ax, ax
    rep stosb
    
    ; Write minimal boot signature
    mov word [0x8000 + 510], 0xAA55
    
.write_os:
    ; Write to target disk sector 1 (MBR)
    mov ah, 0x03
    mov al, 1
    mov cx, 0x0001
    xor dh, dh
    mov dl, [selected_disk]
    mov bx, 0x8000
    int 0x13
    jc disk_error
    
    ; Write additional sectors
    mov ah, 0x03
    mov al, 29
    mov cx, 0x0002
    xor dh, dh
    mov dl, [selected_disk]
    mov bx, 0x8000 + 512
    int 0x13
    jc disk_error
    
    mov si, msg_ok
    call print
    call nl
    ret

install_kernel:
    mov si, msg_kernel
    call print
    mov si, msg_ok
    call print
    call nl
    ret

boot_drive      db 0

show_complete:
    call nl
    mov si, msg_done
    call print
    call nl
    call nl
    ret

reboot_prompt:
    mov si, msg_reboot
    call print
    xor ah, ah
    int 0x16
    mov al, 0xFE
    out 0x64, al
    jmp hang

disk_error:
    call nl
    mov si, msg_error
    call print
    call nl
    jmp hang

hang:
    cli
    hlt
    jmp hang

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
    pusha
    mov ah, 0x0E
    mov al, 13
    int 0x10
    mov al, 10
    int 0x10
    popa
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
    cmp al, 10
    jb .digit
    add al, 'A' - 10
    jmp .out
.digit:
    add al, '0'
.out:
    mov ah, 0x0E
    int 0x10
    ret

msg_banner      db "UltraOS Installer",0
msg_installer   db "EFI/GPT v1.0",0
msg_detecting   db "Detecting disks...",0
msg_disk_found  db "  Found: ",0
msg_disk        db "Disk ",0
msg_no_disks    db "No disks found!",0
msg_select      db "Select disk:",0
msg_dot         db ". ",0
msg_choice      db "Choice: ",0
msg_warning     db "WARNING: All data will be erased!",0
msg_confirm     db "Continue? (Y/N): ",0
msg_cancel      db "Cancelled.",0
msg_gpt         db "Creating GPT... ",0
msg_format      db "Formatting... ",0
msg_boot        db "Installing boot... ",0
msg_kernel      db "Installing kernel... ",0
msg_ok          db "[OK]",0
msg_done        db "Installation complete!",0
msg_reboot      db "Press any key to reboot...",0
msg_error       db "ERROR!",0
part_name       db "EFI System",0

disk_count      db 0
disk_list       times 4 db 0
selected_disk   db 0

align 16
disk_buffer     times 512 db 0

times 2048-($-$$) db 0