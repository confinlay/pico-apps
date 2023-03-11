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
        ldr     r0, =msg
        bl      printf
        @ Initialise LED pin and BTN pins
        bl      init_gpio_led           @ Initialiase the GPIO LED pin
        movs    r0, #GPIO_BTN_EN        @ Pass "enter" button pin as a parameter to the following subroutine
        bl      init_gpio_btn           @ Call the subroutine which initialises the GPIO button pin
        movs    r0, #GPIO_BTN_UP        @ Pass "up" button pin as a parameter to the following subroutine
        bl      init_gpio_btn           @ Call the subroutine which initialises the GPIO button pin
        movs    r0, #GPIO_BTN_DN        @ Pass "down" button pin as a parameter to the following subroutine
        bl      init_gpio_btn           @ Call the subroutine which initialises the GPIO button pin

main_loop:
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
        movs    r0, r2                  @ Re-store button GPIO pin in r0
        bl      asm_gpio_set_irq        @ Call the subroutine which enables the falling edge interrupt 

        pop     {pc}                    @ Pop the stored address to the program counter (return to main program)

install_gpio_isr:
        ldr     r2, =(PPB_BASE + M0PLUS_VTOR_OFFSET)            @ Load the address of the relocated Vector table base into r2
        ldr     r1, [r2]                                        @ Load the value at memory address found in r2 to register r1                                        
        movs    r2, #SVC_ISR_OFFSET                             @ Load the offset needed to arrive at entry 11 in the vector table
        add     r2, r1                                          @ Add the offset to the table base and store in r2
        ldr     r0, =svc_isr                                    @ Load the entry address of svc_isr into r0
        str     r0, [r2]                                        @ Store the address of the gpio_isr handler to the correct offset for GPIO in the vector table
    
        ldr     r0, =(PPB_BASE + M0PLUS_NVIC_ICPR_OFFSET)       @ Load address into r0
        movs    r2, #1                                          @ Move immediate value of 1 into r2
        lsls    r2, #13                                         @ Bit single bit left 13 in order to choose int 13 in the vector table                          
        str     r2, [r0]                                        @ Disable the previous interrupt by writing this new value to PPB_BASE + M0PLUS_NVIC_ICPR_OFFSET
        ldr     r0, =(PPB_BASE + M0PLUS_NVIC_ISER_OFFSET)       @ Load address into r0                      
        str     r2, [r0]                                        @ Disable the new interrupt by writing the current value to PPB_BASE + M0PLUS_NVIC_ISER_OFFSET
    
    bx      lr                                        @ Exit subroutine


.align 4
msg:    .asciz "Hello World!\n"

.data
lstate: .word   DFLT_STATE_STRT
ltimer: .word   DFLT_ALARM_TIME