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
        ldr     r4, =DFLT_ALARM_TIME    @ This register will store the current alarm time for the duration of our program
        ldr     r5, =DFLT_STATE_STRT    @ This register will store the current state of the alarm (on/off) for the duration of our program
        @ Initialise LED pin and BTN pins
        bl      init_gpio_led           @ Initialiase the GPIO LED pin
        movs    r0, #GPIO_BTN_EN        @ Pass "enter" button pin as a parameter to the following subroutine
        bl      init_gpio_btn           @ Call the subroutine which initialises the GPIO button pin
        movs    r0, #GPIO_BTN_UP        @ Pass "up" button pin as a parameter to the following subroutine
        bl      init_gpio_btn           @ Call the subroutine which initialises the GPIO button pin
        movs    r0, #GPIO_BTN_DN        @ Pass "down" button pin as a parameter to the following subroutine
        bl      init_gpio_btn           @ Call the subroutine which initialises the GPIO button pin
        bl      btn_set_irqs            @ Call the subroutine which enables button interrupts

        bl      install_alarm0_isr
        bl      install_gpio_isr

main_loop:
        bl      set_alarm0
        wfi
        b       main_loop

@ Initialises the GPIO LED pin on the Pi PICO board
init_gpio_led:
        push    {lr}                    @ Push the contents of the link register onto the stack
        movs    r0, #GPIO_LED_PIN       @ This value is the GPIO LED pin on the PI PICO board
        bl      asm_gpio_init           @ Call the subroutine to initialise the GPIO pin specified by r0
        movs    r0, #GPIO_LED_PIN       @ This value is the GPIO LED pin on the PI PICO board
        movs    r1, #GPIO_LED_PIN       @ We want this GPIO pin to be setup as an output pin
        bl      asm_gpio_set_dir        @ Call the subroutine to set the GPIO pin specified by r0 to state specified by r1
        pop     {pc}                    @ Pop the stored address to the program counter

@ Initialises a GPIO Button pin specified by the value contained within r0
init_gpio_btn:
        push    {lr}                    @ Push the contents of the link register onto the stack                

        movs    r2, r0                  @ Store button GPIO pin parameter passed to function in r2
        bl      asm_gpio_init           @ Call the subroutine to initialise the GPIO pin specified by r0
        movs    r0, r2                  @ Re-store button GPIO pin in r0
        movs    r1, #GPIO_DIR_IN        @ We want this GPIO pin to be setup as an input pin
        bl      asm_gpio_set_dir        @ Call the subroutine to set the GPIO pin specified by r0 to state specified by r1

        pop     {pc}                    @ Pop the stored address to the program counter (return to main program)

@ Enables falling edge interrupts for all GPIO buttons in use in this program        
btn_set_irqs:
        push    {lr}                    @ Push the contents of the link register onto the stack

        movs    r0, #GPIO_BTN_DN        @ This value is the GP20 button pin on the PI PICO board       
        bl      asm_gpio_set_irq        @ Enables a falling-edge interrupt for the GP20 button
        movs    r0, #GPIO_BTN_EN        @ This value is the GP21 button pin on the PI PICO board
        bl      asm_gpio_set_irq        @ Enables a falling-edge interrupt for the GP21 button
        movs    r0, #GPIO_BTN_UP        @ This value is the GP22 button pin on the PI PICO board
        bl      asm_gpio_set_irq        @ Enables a falling-edge interrupt for the GP22 button

        pop {pc}                        @ Push the contents of the link register onto the stack


@ Alarm 0 interrupt handler
install_gpio_isr: 
        ldr     r2, =(PPB_BASE + M0PLUS_VTOR_OFFSET)            @ Load the address of the relocated Vector table base into r2
        ldr     r1, [r2]                                        @ Load the value at memory address found in r2 to register r1                                        
        ldr     r2, =GPIO_ISR_OFFSET                            @ Load the offset needed to arrive at entry 29 in the vector table
        add     r2, r1                                          @ Add the offset to the table base and store in r2
        ldr     r0, =gpio_isr                                   @ Load the entry address of gpio_isr into r0
        str     r0, [r2]                                        @ Store the address of the gpio_isr handler to the correct offset for GPIO in the vector table
    
        ldr     r0, =(PPB_BASE + M0PLUS_NVIC_ICPR_OFFSET)       @ Load address into r0
        movs    r2, #1                                          @ Move immediate value of 1 into r2
        lsls    r2, #13                                         @ Bit logical shift left 13 in order to choose int 13 in the vector table                          
        str     r2, [r0]                                        @ Disable the specific interrupt level by writing to the appropriate bit in (PPB_BASE + M0PLUS_NVIC_ICPR_OFFSET)           
        ldr     r0, =(PPB_BASE + M0PLUS_NVIC_ISER_OFFSET)       @ Load address into r0
        str     r2, [r0]                                        @ Enable the specific interrupt level by writing to the appropriate bit in (PPB_BASE + M0PLUS_NVIC_ISER_OFFSET)
    
        bx      lr                                              @ Exit subroutine

@ Sets the alarm initially, and every time an interrupt is fired
set_alarm0: 
        ldr     r2, =(TIMER_BASE + TIMER_INTE_OFFSET)           @ Load the memory location which enables alarm timer interrups
        movs    r1, #1                                          @ Move a single bit into r1       
        str     r1, [r2]                                        @ Enables alarm timer interrupts by setting the value at this memory lcoation to 1

        ldr     r2, =(TIMER_BASE + TIMER_TIMELR_OFFSET)         @ Load the memory location which stores the current timer count    
        ldr     r1, [r2]                                        @ Load the value stored at this memory location to r1       
        add     r1, r4                                          @ Add the currently set alarm time to this counter
        ldr     r2, =(TIMER_BASE + TIMER_ALARM0_OFFSET)         @ Store this new value into the counter
        str     r1, [r2]

        bx      lr                                              @ Exit subroutine

install_alarm0_isr:
        @ Set IRQ Handler to our routine
        ldr     r2, =(PPB_BASE + M0PLUS_VTOR_OFFSET)            @ Load the address of the relocated Vector table base into r2
        ldr     r1, [r2]                                        @ Load the value at memory address found in r2 to register r1
        ldr     r2, =ALRM_ISR_OFFSET                            @ Load the offset needed to arrive at entry 16 in the vector table
        adds    r2, r1                                          @ Add the offset to the table base and store in r2
        ldr     r0, =alarm_isr                                  @ Load the entry address of alarm_isr into r0
        str     r0, [r2]                                        @ Store the address of the alarm_isr handler to the correct offset for alarm0 in the vector table

        @ Enable alarm 0 IRQ (clear then set)
        movs    r0, #1
        ldr     r2, =(PPB_BASE + M0PLUS_NVIC_ICPR_OFFSET)       @ Disable the specific interrupt level by writing to the appropriate bit in (PPB_BASE + M0PLUS_NVIC_ICPR_OFFSET)
        str     r0, [r2]

        movs    R0, #1
        ldr     r2, =(PPB_BASE + M0PLUS_NVIC_ISER_OFFSET)       @ Enable the specific interrupt level by writing to the appropriate bit in (PPB_BASE + M0PLUS_NVIC_ICPR_OFFSET
        str     r0, [r2]

        bx      lr                                              @ Exit subroutine
.thumb_func  
alarm_isr:
        push    {lr}                                            @ Push the contents of the link register to the stack

        movs    r0, #DFLT_STATE_STOP                            @ Store the value which indicates that the alarm is disabled in r0
        cmp     r5, r0                                          @ If the alarm is disabled...       
        beq     end                                             @ Branch to end of subroutine
        @ Toggle LED
        ldr     r0, =GPIO_LED_PIN                               @ This value is the GPIO LED pin on the PI PICO board     
        bl      asm_gpio_get                                    @ Get the current state of the LED 
        cmp     r0, #LED_VAL_ON                                 @ If the LED is on...
        beq     led_off                                         @ Branch to subroutine to turn the LED off
        movs    r1, #LED_VAL_ON                                 @ Else, store the value which will turn the LED on in r1
        b       set_state                                       @ Branch to set_state
led_off:
        ldr     r0, =GPIO_LED_PIN                               @ This value is the GPIO LED pin on the PI PICO board
        movs    r1, #LED_VAL_OFF                                @ Store the value which will turn the LED on in r1
set_state:
        ldr     r0, =GPIO_LED_PIN                               @ This value is the GPIO LED pin on the PI PICO board
        bl      asm_gpio_put                                    @ Turn the LED on/off depending on the contents of r1
end:
        ldr     r1, =(TIMER_BASE + TIMER_INTR_OFFSET)           @ Store the memory address for the TIMER raw interrupts register in r1
        movs    r0, #1                                          @ Move a single bit into r0      
        str     r0, [r1]                                        @ Disable the pending interrupt from timer

        pop     {pc}                                            @ Exit interrupt service routine

.thumb_func
gpio_isr:
        @ Perform desired functions depending on which button was pressed and under what conditions
        push    {lr}                                                    @ Push the link register to the stack

        ldr     r2, =(IO_BANK0_BASE + IO_BANK0_PROC0_INTS2_OFFSET)      @ Load the memory address of the GPIO raw interrupts #2 register

        ldr     r1, [r2]                                        @ Load the value stored at this addres to r1
        ldr     r0, =GPIO_BTN_DN_MSK                            @ Load bit-18 into r0 to indicate a falling edge event for GP20
        ands    r1, r0                                          @ And these values to check if bit-18 is high in r1
        cmp     r1, r0                                          @ If this button has been pressed...
        beq     btn_dn                                          @ Branch to btn_dn

        ldr     r1, [r2]                                        @ Load the value stored at this addres to r1
        ldr     r0, =GPIO_BTN_EN_MSK                            @ Load bit-22 into r0 to indicate a falling edge event for GP21        
        ands    r1, r0                                          @ And these values to check if bit-22 is high in r1        
        cmp     r1, r0                                          @ If this button has been pressed...       
        beq     btn_en                                          @ Branch to btn_en

        ldr     r1, [r2]                                        @ Load the value stored at this addres to r1
        ldr     r0, =GPIO_BTN_UP_MSK                            @ Load bit-29 into r0 to indicate a falling edge event for GP22
        ands    r1, r0                                          @ And these values to check if bit-29 is high in r1
        cmp     r1, r0                                          @ If this button has been pressed...
        beq     btn_up                                          @ Branch to btn_up

btn_dn:
        movs    r0, #DFLT_STATE_STRT                            @ Move the value which indicates that the alarm is enabled into r0
        cmp     r5, r0                                          @ Check if this is equal to the current state of the alarm
        beq     half                                            @ If it is, branch to half
        ldr     r0, =GPIO_BTN_DN_MSK                            @ Else, reload bit-18 into r0 to indicate a falling edge event for GP20 
        b       alarm_reset                                     @ Branch to alarm_reset
half:
        lsls    r4, #1                                          @ Shift bits left by 1 in alarm time to half it
        ldr     r0, =GPIO_BTN_DN_MSK                            @ Reload bit-18 into r0 to indicate a falling edge event for GP20 into r0
        b       finish                                          @ Branch to finish       

btn_en:
        movs    r0, #DFLT_STATE_STRT                            @ Move the value which indicates that the alarm is enabled into r0                 
        cmp     r5, r0                                          @ Check if this is equal to the current state of the alarm
        beq     alarm_disable                                   @ If it is, branch to alarm_disable
        ldr     r0, =GPIO_BTN_EN_MSK                            @ Else, reload bit-22 into r0 to indicate a falling edge event for GP21 
        movs    r5, #DFLT_STATE_STRT                            @ Enable the alarm
        b       finish                                          @ Branch to finish

alarm_disable:
        ldr     r0, =GPIO_BTN_EN_MSK                            @ Reload bit-22 into r0 to indicate a falling edge event for GP21 
        movs    r5, #DFLT_STATE_STOP                            @ Disable the alarm
        b       finish                                          @ Branch to finish

btn_up:
        movs    r0, #DFLT_STATE_STRT                            @ Move the value which indicates that the alarm is enabled into r0
        cmp     r5, r0                                          @ Check if this is equal to the current state of the alarm
        beq     double                                          @ If it is, branch to double
        ldr     r0, =GPIO_BTN_UP_MSK                            @ Reload bit-29 into r0 to indicate a falling edge event for GP22 
        b       alarm_reset                                     @ Branch to alarm_reset
double:
        lsrs    r4, #1                                          @ Shift the alarm time right by 1 bit to double it
        ldr     r0, =GPIO_BTN_UP_MSK                            @ Reload bit-29 into r0 to indicate a falling edge event for GP22
        b       finish                                          @ Branch to finish
alarm_reset:
        ldr     r4, =DFLT_ALARM_TIME                            @ Reset the alarm time to the default alarm time

finish:
        ldr     r2, =(IO_BANK0_BASE + IO_BANK0_INTR2_OFFSET)    @ Load the memory address of the GPIO raw interrupts #2 register        
        str     r0, [r2]                                        @ Store the current buttone falling edge event in this register

        pop     {pc}                                            @ Exit subroutine

.align 4
msg:    .asciz "Hello World!\n"

.data
lstate: .word   DFLT_STATE_STRT
ltimer: .word   DFLT_ALARM_TIME