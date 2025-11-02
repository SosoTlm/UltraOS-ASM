// ui.c - Minimal test
void _start(void) {
    // Write directly to VGA memory
    volatile unsigned short* vga = (unsigned short*)0xB8000;
    
    // Clear screen
    for (int i = 0; i < 80 * 25; i++) {
        vga[i] = 0x1F00 | ' ';  // Blue background, black text, space
    }
    
    // Write "UI WORKS!"
    const char* msg = "UI WORKS!";
    for (int i = 0; msg[i]; i++) {
        vga[10 * 80 + 35 + i] = 0x1F00 | msg[i];  // Centered
    }
    
    // Infinite loop
    while(1) {
        __asm__ volatile ("hlt");
    }
}