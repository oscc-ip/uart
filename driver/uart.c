#include <am.h>
#include <klib.h>
#include <klib-macros.h>

#define UART1_BASE_ADDR 0x10004000
#define UART1_REG_LCR *((volatile uint32_t *)(UART1_BASE_ADDR + 0))
#define UART1_REG_DIV *((volatile uint32_t *)(UART1_BASE_ADDR + 4))
#define UART1_REG_TRX *((volatile uint32_t *)(UART1_BASE_ADDR + 8))
#define UART1_REG_FCR *((volatile uint32_t *)(UART1_BASE_ADDR + 12))
#define UART1_REG_LSR *((volatile uint32_t *)(UART1_BASE_ADDR + 16))

int main(){
    putstr("uart test\n");
    printf("REG_DIV: %x REG_LCR: %x\n", UART1_REG_DIV, UART1_REG_LCR);
    UART1_REG_DIV = (uint32_t) 434;        // 50x10^6 / 115200
    UART1_REG_FCR = (uint32_t) 0b1111;     // clear tx and rx fifo
    UART1_REG_FCR = (uint32_t) 0b1100;
    UART1_REG_LCR = (uint32_t) 0b00011111; // 8N1, en all irq
    printf("REG_DIV: %x REG_LCR: %x\n", UART1_REG_DIV, UART1_REG_LCR);

    putstr("uart tx test\n");
    uint32_t val = (uint32_t) 0x41;
    for(int i = 0; i < 48; ++i) { 
        while(((UART1_REG_LSR & 0x100) >> 8) == 1);
        UART1_REG_TRX = (uint32_t)(val + i);
    }

    putstr("uart tx test done\n");
    putstr("uart rx test\n");
    uint32_t rx_val = 0;
    for(int i = 0; i < 100; ++i) {
        while(((UART1_REG_LSR & 0x080) >> 7) == 1);
        rx_val = UART1_REG_TRX;
        printf("%d RECV: %x CHAR: %c\n", i, rx_val, rx_val);
    }

    putstr("uart rx test done\n");
    putstr("uart done\n");
    return 0;
}
