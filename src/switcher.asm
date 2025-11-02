; ============================================
; UltraOS Mode Switcher (16/32/64-bit safe)
; ============================================
org 0x7E00
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
    
    ; Clear screen
    mov ax, 0x0003
    int 0x10
    
    ; Set text mode
    mov ax, 0x0003
    int 0x10
    
    ; Display menu
    mov si, msg_title
    call print
    call nl
    mov si, msg_option1
    call print
    call nl
    mov si, msg_option2
    call print
    call nl
    call nl
    mov si, msg_prompt
    call print

.wait_key:
    mov ah, 0
    int 0x16
    cmp al, '1'
    je normal_boot
    cmp al, '2'
    je load_ui
    jmp .wait_key

normal_boot:
    mov si, msg_reboot
    call print
    jmp $

; -----------------------------
; Load UI (16-bit) - FULL VERSION
; -----------------------------
load_ui:
    ; Show we got here (BEFORE graphics mode)
    mov si, msg_option2_selected
    call print
    call nl
    
    ; Debug message
    mov si, msg_loading_ui
    call print
    call nl
    
    ; Detect GPU
    mov si, msg_detecting_gpu
    call print
    call nl
    call detect_gpu
    
    ; Load the UI binary FIRST
    mov si, msg_reading_disk
    call print
    call nl
    
    mov ah, 0x02
    mov al, 16          ; sectors to read
    mov ch, 0
    mov cl, 10          ; sector 10
    mov dh, 0
    mov dl, [boot_drive]
    
    ; Load to 0x1000:0x0000 = 0x10000 physical
    mov bx, 0x1000
    mov es, bx
    xor bx, bx
    int 0x13
    jc live_mode16
    
    mov si, msg_ui_loaded
    call print
    call nl
    
    ; DON'T set graphics mode - stay in text mode for now
    ; call set_graphics_mode
    
    mov byte [ui_loaded], 1
    jmp enter_pm

live_mode16:
    mov byte [ui_loaded], 0
    mov si, msg_live
    call print
    jmp enter_pm

; -----------------------------
; GPU Detection (16-bit VESA)
; -----------------------------
detect_gpu:
    pusha
    ; Get VESA VBE info
    mov ax, 0x4F00
    mov di, 0x5000      ; Use safe memory location instead of vbe_info_block
    push es
    xor ax, ax
    mov es, ax
    mov ax, 0x4F00
    int 0x10
    pop es
    
    cmp ax, 0x004F
    jne .no_vesa
    
    ; Store VESA capability
    mov byte [gpu_type], 1  ; 1 = VESA
    mov si, msg_vesa_detected
    call print
    call nl
    popa
    ret

.no_vesa:
    ; Fall back to VGA
    mov byte [gpu_type], 0  ; 0 = VGA
    mov si, msg_vga_fallback
    call print
    call nl
    popa
    ret

; -----------------------------
; Set Graphics Mode
; -----------------------------
set_graphics_mode:
    pusha
    cmp byte [gpu_type], 1
    je .set_vesa
    
.set_vga:
    ; VGA Mode 13h (320x200x256)
    mov ax, 0x0013
    int 0x10
    mov si, msg_vga_mode
    call print
    call nl
    popa
    ret

.set_vesa:
    ; Try VESA mode 0x115 (800x600x24)
    mov ax, 0x4F02
    mov bx, 0x4115
    int 0x10
    
    cmp ax, 0x004F
    je .vesa_ok
    
    ; Fallback to VGA mode 13h
    mov ax, 0x0013
    int 0x10
    
.vesa_ok:
    mov si, msg_vesa_mode
    call print
    call nl
    popa
    ret

; -----------------------------
; Enter Protected Mode (32-bit)
; -----------------------------
enter_pm:
    cli
    
    ; Debug in text mode before transition
    mov si, msg_entering_pm
    call print
    call nl
    
    lgdt [gdt32_descriptor]
    
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    
    ; Manual far jump using machine code with ABSOLUTE ADDRESS
    db 0x66  ; Operand size override (32-bit operand in 16-bit mode)
    db 0xEA  ; Far jump opcode
    dd 0x7E00 + (pm32_start - start)  ; Absolute offset (32-bit)
    dw 0x08        ; Segment selector

bits 32
pm32_start:
    ; Set up segments immediately
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000
    
    ; Jump to main 32-bit code
    jmp protected32

protected32:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov esp, 0x90000
    
    ; Write checkpoint to VGA (no string loading to avoid issues)
    mov edi, 0xB8000
    mov word [edi], 0x0F50  ; 'P' in white
    mov word [edi+2], 0x0F4D  ; 'M'
    mov word [edi+4], 0x0F20  ; ' '
    mov word [edi+6], 0x0F4F  ; 'O'
    mov word [edi+8], 0x0F4B  ; 'K'
    
    ; Setup identity paging for long mode
    ; Clear page tables
    mov edi, 0x1000
    mov ecx, 0x3000
    xor eax, eax
    rep stosb
    
    ; Build page tables
    mov edi, 0x1000     ; PML4
    mov dword [edi], 0x2003
    
    mov edi, 0x2000     ; PDPT
    mov dword [edi], 0x3003
    
    ; Map first 1GB with 2MB pages (covers VGA at 0xA0000)
    mov edi, 0x3000     ; PD
    mov ebx, 0x00000083 ; 2MB pages, present, writable
    mov ecx, 512
.build_pd:
    mov dword [edi], ebx
    add ebx, 0x200000
    add edi, 8
    loop .build_pd
    
    ; Checkpoint 2
    mov edi, 0xB8000 + 160
    mov word [edi], 0x0F50  ; 'P'
    mov word [edi+2], 0x0F47  ; 'G'
    mov word [edi+4], 0x0F20  ; ' '
    mov word [edi+6], 0x0F4F  ; 'O'
    mov word [edi+8], 0x0F4B  ; 'K'
    
    ; Load CR3 with PML4
    mov eax, 0x1000
    mov cr3, eax
    
    ; Enable PAE
    mov eax, cr4
    or eax, 0x20
    mov cr4, eax
    
    ; Enable long mode
    mov ecx, 0xC0000080  ; EFER MSR
    rdmsr
    or eax, 0x100        ; Set LME bit
    wrmsr
    
    ; Enable paging
    mov eax, cr0
    or eax, 0x80000000
    mov cr0, eax
    
    ; Checkpoint 3
    mov edi, 0xB8000 + 320
    mov word [edi], 0x0F36  ; '6'
    mov word [edi+2], 0x0F34  ; '4'
    mov word [edi+4], 0x0F2E  ; '.'
    mov word [edi+6], 0x0F2E  ; '.'
    mov word [edi+8], 0x0F2E  ; '.'
    
    ; Load 64-bit GDT
    lgdt [gdt64_descriptor]
    
    ; Try inline assembly trick - just change to bits 64 and continue!
    ; Push far return address manually
    sub esp, 8
    mov dword [esp + 4], 0x08  ; Selector
    mov dword [esp], long64_entry  ; Offset
    
    ; Far return
    db 0x48  ; REX.W prefix (64-bit operand)
    db 0xCB  ; retf

bits 64
long64_entry:
    ; Immediately write to screen to prove we're here
    mov rdi, 0xB8000 + 480
    mov word [rdi], 0x0F59  ; 'Y'
    mov word [rdi+2], 0x0F45  ; 'E'
    mov word [rdi+4], 0x0F53  ; 'S'
    mov word [rdi+6], 0x0F21  ; '!'
    
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    
    ; Another checkpoint
    mov word [rdi+8], 0x0F32  ; '2'
    
    jmp long64

long64:
    ; Another checkpoint at long64
    mov rdi, 0xB8000 + 640  ; Line 5
    mov word [rdi], 0x0F4C  ; 'L'
    mov word [rdi+2], 0x0F4E  ; 'N'
    mov word [rdi+4], 0x0F47  ; 'G'
    
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov ss, ax
    
    ; Debug: show we're in 64-bit mode
    mov rsi, msg_in64bit
    mov rdi, 0xB8000
    call print64_simple
    
    cmp byte [ui_loaded], 1
    je jump_ui
    jmp live_mode64

jump_ui:
    ; Show jump message
    mov rsi, msg_jumping
    mov rdi, 0xB8000
    add rdi, 160  ; Next line
    call print64_simple
    
    ; Infinite loop for testing - comment out to actually jump
    ; jmp $
    
    mov rax, 0x10000
    jmp rax

print64_simple:
    push rax
.loop:
    lodsb
    test al, al
    jz .done
    mov ah, 0x0F
    stosw
    jmp .loop
.done:
    pop rax
    ret

; -----------------------------
; Heap Allocator (64-bit)
; -----------------------------
; malloc(size in RCX) -> returns pointer in RAX
malloc:
    push rbx
    mov rax, [heap_current]
    mov rbx, rax
    add rbx, rcx
    
    ; Check if we have space
    cmp rbx, [heap_end]
    ja .out_of_memory
    
    ; Update heap pointer
    mov [heap_current], rbx
    
    ; Zero the allocated memory
    push rdi
    push rcx
    mov rdi, rax
    xor al, al
    rep stosb
    pop rcx
    pop rdi
    
    mov rax, rbx
    sub rax, rcx
    pop rbx
    ret

.out_of_memory:
    xor rax, rax
    pop rbx
    ret

; free(pointer in RCX) - simple bump allocator, can't free individual blocks
free:
    ret

live_mode64:
    mov rsi, msg_live64
    mov rdi, 0xB8000
.print64:
    lodsb
    test al, al
    jz .done64
    mov ah, 0x0F
    stosw
    jmp .print64
.done64:
    jmp $

; -----------------------------
; 16-bit print routines
; -----------------------------
bits 16
print:
    pusha
.print_loop:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp .print_loop
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

; 32-bit strings (need to be in the right section)
bits 32
msg_in_pm db "Protected mode OK",0
msg_paging_setup db "Paging setup OK",0
msg_entering_64 db "Entering 64-bit...",0

; -----------------------------
; Data & GDT
; -----------------------------
boot_drive db 0
ui_loaded  db 0
gpu_type   db 0  ; 0=VGA, 1=VESA

; Heap management (64-bit pointers)
align 8
heap_start   dq 0
heap_current dq 0
heap_end     dq 0

msg_title     db "=== UltraOS Boot Menu ===",0
msg_option1   db "1. Normal Boot",0
msg_option2   db "2. Enter 64-bit UI",0
msg_option2_selected db "Option 2 selected!",0
msg_test_mode db "Testing 32/64-bit transition...",0
msg_press_key db "Press key to continue...",0
msg_prompt    db "Select option: ",0
msg_reboot    db "Rebooting...",0
msg_live      db "[LIVE MODE ACTIVE]",0
msg_live64    db "[LIVE MODE 64-BIT ACTIVE]",0
msg_loading_ui db "Loading UI...",0
msg_detecting_gpu db "Detecting GPU...",0
msg_reading_disk db "Reading from disk...",0
msg_ui_loaded db "UI loaded successfully!",0
msg_entering_pm db "Entering protected mode...",0
msg_in64bit   db "In 64-bit mode!",0
msg_jumping   db "Jumping to UI at 0x10000...",0
msg_vesa_detected db "VESA GPU detected",0
msg_vga_fallback  db "VGA mode (no VESA)",0
msg_vga_mode      db "VGA 320x200x8 set",0
msg_vesa_mode     db "VESA mode set",0

align 16
vbe_info_block equ 0x5000  ; Use memory location instead of embedded buffer

align 8
gdt32_start:
    ; Null descriptor
    dq 0x0000000000000000
    ; 32-bit code segment (base=0, limit=0xFFFFF, 4KB granularity, readable, executable)
    dw 0xFFFF       ; Limit low
    dw 0x0000       ; Base low
    db 0x00         ; Base middle
    db 10011010b    ; Access: present, ring 0, code, executable, readable
    db 11001111b    ; Flags: 4KB pages, 32-bit, limit high
    db 0x00         ; Base high
    ; 32-bit data segment
    dw 0xFFFF       ; Limit low
    dw 0x0000       ; Base low
    db 0x00         ; Base middle
    db 10010010b    ; Access: present, ring 0, data, writable
    db 11001111b    ; Flags: 4KB pages, 32-bit, limit high
    db 0x00         ; Base high
gdt32_end:

gdt32_descriptor:
    dw gdt32_end - gdt32_start - 1
    dd gdt32_start

align 8
gdt64_start:
    ; Null descriptor
    dq 0x0000000000000000
    ; 64-bit code segment
    dw 0x0000       ; Limit (ignored in 64-bit)
    dw 0x0000       ; Base low
    db 0x00         ; Base middle
    db 10011010b    ; Access: present, ring 0, code, executable, readable
    db 00100000b    ; Flags: 64-bit mode
    db 0x00         ; Base high
    ; 64-bit data segment
    dw 0x0000       ; Limit (ignored)
    dw 0x0000       ; Base low
    db 0x00         ; Base middle
    db 10010010b    ; Access: present, ring 0, data, writable
    db 00000000b    ; Flags
    db 0x00         ; Base high
gdt64_end:

gdt64_descriptor:
    dw gdt64_end - gdt64_start - 1
    dd gdt64_start

times 2048-($-$$) db 0