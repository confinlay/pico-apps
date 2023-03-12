#include "hardware/regs/addressmap.h"
#include "hardware/regs/io_bank0.h"
#include "hardware/regs/timer.h"
#include "hardware/regs/m0plus.h"

.syntax unified
.cpu    cortex-m0plus
.thumb
.global main_asm
.align  4

.equ    DFLT_STATE_STRT, 1            @ Specify the value to start flashing
.equ    DFLT_STATE_STOP, 0            @ Specify the value to stop flashing
.equ    DFLT_ALARM_TIME, 1000000      @ Specify the default alarm timeout

.equ    GPIO_BTN_DN_MSK, 0x00040000   @ Bit-18 for falling-edge event on GP20
.equ    GPIO_BTN_EN_MSK, 0x00400000   @ Bit-22 for falling-edge event on GP21
.equ    GPIO_BTN_UP_MSK, 0x04000000   @ Bit-26 for falling-edge event on GP22

.equ    GPIO_BTN_DN,  20              @ Specify pin for the "down" button
.equ    GPIO_BTN_EN,  21              @ Specify pin for the "enter" button
.equ    GPIO_BTN_UP,  22              @ Specify pin for the "up" button
.equ    GPIO_LED_PIN, 25              @ Specify pin for the built-in LED
.equ    GPIO_DIR_IN,   0              @ Specify input direction for a GPIO pin
.equ    GPIO_DIR_OUT,  1              @ Specify output direction for a GPIO pin

.equ    LED_VAL_ON,    1              @ Specify value that turns the LED "on"
.equ    LED_VAL_OFF,   0              @ Specify value that turns the LED "off"

.equ    GPIO_ISR_OFFSET, 0x74         @ GPIO is int #13 (vector table entry 29)
.equ    ALRM_ISR_OFFSET, 0x40         @ ALARM0 is int #0 (vector table entry 16)

@ Entry point to the ASM portion of the program
main_asm:
        ldr     r4, =DFLT_ALARM_TIME
        ldr     r5, =DFLT_STATE_STRT
        @ Initialise LED pin and BTN pins
        bl      init_gpio_led           @ Initialiase the GPIO LED pin
        movs    r0, #GPIO_BTN_EN        @ Pass "enter" button pin as a parameter to the following subroutine
        bl      init_gpio_btn           @ Call the subroutine which initialises the GPIO button pin
        movs    r0, #GPIO_BTN_UP        @ Pass "up" button pin as a parameter to the following subroutine
        bl      init_gpio_btn           @ Call the subroutine which initialises the GPIO button pin
        movs    r0, #GPIO_BTN_DN        @ Pass "down" button pin as a parameter to the following subroutine
        bl      init_gpio_btn           @ Call the subroutine which initialises the GPIO button pin
        bl      btn_set_irqs

        bl      install_alarm0_isr
        bl      install_gpio_isr

main_loop:
        bl      set_alarm0
        wfi
        b       main_loop

init_gpio_led:
        push    {lr}                    @ Push the contents of the link register onto the stack
        movs    r0, #GPIO_LED_PIN       @ This value is the GPIO LED pin on the PI PICO board
        bl      asm_gpio_init           @ Call the subroutine to initialise the GPIO pin specified by r0
        movs    r0, #GPIO_LED_PIN       @ This value is the GPIO LED pin on the PI PICO board
        movs    r1, #GPIO_LED_PIN       @ We want this GPIO pin to be setup as an output pin
        bl      asm_gpio_set_dir        @ Call the subroutine to set the GPIO pin specified by r0 to state specified by r1
        pop     {pc}                    @ Pop the stored address to the program counter

init_gpio_btn:
        push    {lr}                    @ Push the contents of the link register onto the stack                

        movs    r2, r0                  @ Store button GPIO pin parameter passed to function in r2
        bl      asm_gpio_init           @ Call the subroutine to initialise the GPIO pin specified by r0
        movs    r0, r2                  @ Re-store button GPIO pin in r0
        movs    r1, #GPIO_DIR_IN        @ We want this GPIO pin to be setup as an input pin
        bl      asm_gpio_set_dir        @ Call the subroutine to set the GPIO pin specified by r0 to state specified by r1

        pop     {pc}                    @ Pop the stored address to the program counter (return to main program)
        
btn_set_irqs:
        push    {lr}

        movs    r0, #GPIO_BTN_DN
        bl      asm_gpio_set_irq
        movs    r0, #GPIO_BTN_EN
        bl      asm_gpio_set_irq
        movs    r0, #GPIO_BTN_UP
        bl      asm_gpio_set_irq

        pop {pc}


@ Alarm 0 interrupt handler
install_gpio_isr: 
        ldr     r2, =(PPB_BASE + M0PLUS_VTOR_OFFSET)            @ 
        ldr     r1, [r2]                                        @                                         
        ldr     r2, =GPIO_ISR_OFFSET                            @ Load the offset needed to arrive at entry 29 in the vector table
        add     r2, r1                                          @ Add the offset to the table base and store in r2
        ldr     r0, =gpio_isr                                   @ Load the entry address of gpio_isr into r0
        str     r0, [r2]                                        @ Store the address of the gpio_isr handler to the correct offset for GPIO in the vector table
    
        ldr     r0, =(PPB_BASE + M0PLUS_NVIC_ICPR_OFFSET)       @ Load address into r0
        movs    r2, #1                                          @ Move immediate value of 1 into r2
        lsls    r2, #13                                         @ Bit logical shift left 13 in order to choose int 13 in the vector table                          
        str     r2, [r0]                                        @ Disable the specific interrupt level by writing to the appropriate bit in (PPB_BASE + M0PLUS_NVIC_ICPR_OFFSET)           
        ldr     r0, =(PPB_BASE + M0PLUS_NVIC_ISER_OFFSET)
        str     r2, [r0]                                        @ Enable the specific interrupt level by writing to the appropriate bit in (PPB_BASE + M0PLUS_NVIC_ISER_OFFSET)
    
        bx      lr                                              @ Exit subroutine

set_alarm0: 
        ldr     r2, =(TIMER_BASE + TIMER_INTE_OFFSET)
        movs    r1, #1
        str     r1, [r2]

        ldr     r2, =(TIMER_BASE + TIMER_TIMELR_OFFSET)
        ldr     r1, [r2]
        add     r1, r4
        ldr     r2, =(TIMER_BASE + TIMER_ALARM0_OFFSET)
        str     r1, [r2]

        bx      lr

install_alarm0_isr:
        @ Set IRQ Handler to our routine
        ldr     r2, =(PPB_BASE + M0PLUS_VTOR_OFFSET)
        ldr     r1, [r2]
        ldr     r2, =ALRM_ISR_OFFSET
        adds    r2, r1
        ldr     r0, =alarm_isr
        str     r0, [r2]

        @ Enable alarm 0 IRQ (clear then set)
        movs    r0, #1
        ldr     r2, =(PPB_BASE + M0PLUS_NVIC_ICPR_OFFSET)
        str     r0, [r2]

        movs    R0, #1
        ldr     r2, =(PPB_BASE + M0PLUS_NVIC_ISER_OFFSET)
        str     r0, [r2]

        bx      lr
.thumb_func  
alarm_isr:
        push    {lr}

        movs    r0, #DFLT_STATE_STOP
        cmp     r5, r0
        beq     end
        @ Toggle LED
        ldr     r0, =GPIO_LED_PIN
        bl      asm_gpio_get
        cmp     r0, #LED_VAL_ON
        beq     led_off
        movs    r1, #LED_VAL_ON
        b       set_state
led_off:
        ldr     r0, =GPIO_LED_PIN
        movs    r1, #LED_VAL_OFF
set_state:
        ldr     r0, =GPIO_LED_PIN
        bl      asm_gpio_put
end:
        ldr     r1, =(TIMER_BASE + TIMER_INTR_OFFSET)
        movs    r0, #1
        str     r0, [r1]

        pop     {pc}
.thumb_func
gpio_isr:
        push    {lr}

        ldr     r2, =(IO_BANK0_BASE + IO_BANK0_PROC0_INTS2_OFFSET)

        ldr     r1, [r2]
        ldr     r0, =GPIO_BTN_DN_MSK
        ands    r1, r0
        cmp     r1, r0
        beq     btn_dn

        ldr     r1, [r2]
        ldr     r0, =GPIO_BTN_EN_MSK
        ands    r1, r0
        cmp     r1, r0
        beq     btn_en

        ldr     r1, [r2]
        ldr     r0, =GPIO_BTN_UP_MSK
        ands    r1, r0
        cmp     r1, r0
        beq     btn_up

btn_dn:
        movs    r0, #DFLT_STATE_STRT
        cmp     r0, r5
        beq     half
        ldr     r0, =GPIO_BTN_DN_MSK
        b       alarm_reset
half:
        lsls    r4, #1
        ldr     r0, =GPIO_BTN_DN_MSK
        b       finish

btn_en:
        movs    r0, #DFLT_STATE_STRT
        cmp     r5, r0
        beq     alarm_disable
        ldr     r0, =GPIO_BTN_EN_MSK
        movs    r5, #DFLT_STATE_STRT
        b       finish

alarm_disable:
        ldr     r0, =GPIO_BTN_EN_MSK
        movs    r5, #DFLT_STATE_STOP
        b       finish

btn_up:
        movs    r0, #DFLT_STATE_STRT
        cmp     r0, r5
        beq     double
        ldr     r0, =GPIO_BTN_UP_MSK
        b       alarm_reset
double:
        lsrs    r4, #1
        ldr     r0, =GPIO_BTN_UP_MSK
        b       finish
alarm_reset:
        ldr     r4, =DFLT_ALARM_TIME

finish:
        ldr     r2, =(IO_BANK0_BASE + IO_BANK0_INTR2_OFFSET)
        str     r0, [r2]

        pop     {pc}

.align 4
msg:    .asciz "Hello World!\n"

.data
lstate: .word   DFLT_STATE_STRT
ltimer: .word   DFLT_ALARM_TIME