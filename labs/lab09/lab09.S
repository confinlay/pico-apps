#include "hardware/regs/addressmap.h"
#include "hardware/regs/adc.h"
#include "hardware/regs/io_bank0.h"
#include "hardware/regs/timer.h"
#include "hardware/regs/m0plus.h"

.syntax unified                 @ Specify unified assembly syntax
.cpu    cortex-m0plus           @ Specify CPU type is Cortex M0+
.thumb                          @ Specify thumb assembly for RP2040
.global main_asm                @ Provide program starting address to the linker
.align 4                        @ Specify code alignment

.equ GPIO_LED_PIN, 25                                        @ Specify pin for the built-in LED
.equ GPIO_DIR_IN, 0                                          @ Specify input direction for a GPIO pin
.equ GPIO_DIR_OUT, 1                                         @ Specify output direction for a GPIO pin

.equ LED_VAL_ON, 1                                           @ Specify value that turns the LED "on"
.equ LED_VAL_OFF, 0                                          @ Specify value that turns the LED "off"

.equ GPIO_ISR_OFFSET, 0x74                                   @ GPIO is int #13 (vector table entry 29)
.equ ALRM_ISR_OFFSET, 0x40                                   @ ALARM0 is int #0 (vector table entry 16)

.equ DFLT_ALARM_TIME, 500000                                 @ Specify the default alarm timeout @ 2 sec

.equ TEMPADC, 4                                              @ Specify the ADC we want to read from
.thumb_func
.global convert_temp, initTempSensor, readTemp               @ Initialise global functions

@ Entry point to the ASM portion of the program
main_asm:
    bl     init_gpio_led                                         @ initialise the led pin
    bl     alrm_isr_installer                                    @ install the alarm ISR
    bl     initTempSensor                                        @ initiliase the temperature sensor

loop:
    b       loop


initTempSensor:
    movs     r1, #TEMPADC
    lsls     r1, #ADC_CS_AINSEL_LSB
    adds     r1, #(ADC_CS_TS_EN_BITS+ADC_CS_EN_BITS)
    ldr      r2, =adcbase
    str      r1, [r2, #ADC_CS_OFFSET]
    bx       lr

readTemp:
    push {lr}
    ldr r2, =adcbase
    ldr r1, [r2, #ADC_CS_OFFSET] @ load status register
    adds r1, #ADC_CS_START_ONCE_BITS @ add read value once
    str r1, [r2, #ADC_CS_OFFSET] @ write to do it
notReady: 
    ldr r1, [r2, #ADC_CS_OFFSET] @ wait for read
    movs r3, #1
    lsls r3, #ADC_CS_READY_LSB @ done yet?
    ands r1, r3
    beq notReady
    ldr r0, [r2, #ADC_RESULT_OFFSET] @ read result
    bl  convert_temp
    bx lr

init_gpio_led:
    push   {lr}                                                  @ push the link register, we will call other functions within this one
    movs   r0, #GPIO_LED_PIN                                     @ This value is the GPIO LED pin on the PI PICO board
    bl     asm_gpio_init                                         @ Call the subroutine to initialise the GPIO pin specified by r0
    movs   r0, #GPIO_LED_PIN                                     @ This value is the GPIO LED pin on the PI PICO
    movs   r1, #LED_VAL_ON                                       @ We want to set it as an output pin
    bl     asm_gpio_set_dir                                      @ Call the subroutine to set the GPIO pin specified by r0 to state specified by r1
    pop    {pc}                                                  @ pop the program counter to return to where we were before

/////////////////////// ALARM TIMER CODE ///////////////////////////
alrm_isr_installer:
    @install the Alarm ISR Handler into the Alarm0 slot in the IVT
    ldr     r0, =(PPB_BASE + M0PLUS_VTOR_OFFSET)    @ Load in the location where the IVT address is stored in the hardware registers
    ldr     r1, [r0]                                @ Load in the adress of the Interrupt vector table
    ldr     r0, =ALRM_ISR_OFFSET                    @ Load in the Alarm ISR offset for the IVT
    adds    r0, r1                                  @ Add the Alarm ISR offset to the IVT adress to get the adress of the Alarm ISR
    ldr     r2, =alarm_isr                          @ Load in the adress of our Alarm ISR Handler subroutine
    str     r2, [r0]                                @ Store the address of our Alarm ISR Handler subroutine at the Alarm ISR address in the IVT
    
    @Enabling Alarm IRQ0 step1, Clear the interrupt
    ldr     r2, =(PPB_BASE+M0PLUS_NVIC_ICPR_OFFSET) @ Load in address of the NVIC Interrupt Clear Pending register
    movs    r0, #1                                  
    str     r0, [r2]                                @ Store 1 (replacing the 0) at bit 1 in the ICP Register to clear the interrupt
    @Enabling Alarm IRQ0 step2, Set the interrupt
    ldr     r2, =(PPB_BASE+M0PLUS_NVIC_ISER_OFFSET) @ Load in address of the NVIC Interrupt Set Pending register
    movs    r0, #1
    str     r0, [r2]                                @ Store 1 (replacing the 0) at bit 1 in the ISP Register to Set the interrupt

    bx      lr                                      @ Return to the Link registry Adress

@ Subroutine to set the alarm time and enable timer interupts
init_alarm:
    push    {lr}                                    @ Store the link register to the stack
    @Enables timer interupt
    movs    r0, #1                                  @ Load 1 into the regster for use in enabling timer interupts
    ldr     r1, =(TIMER_BASE + TIMER_INTE_OFFSET)   @ Load the adress for the timer interrupt enable register    
    str     r0, [r1]                                @ Set the interrupt enable register to 1 to enable timer interrupts

    @Reads in current time and adds time delay, i.e determines the alarm time
    ldr     r1, =(TIMER_BASE + TIMER_TIMELR_OFFSET) @ Load in the address for the lower 32 bits of the timer regisiter
    ldr     r0, [r1]                                @ Load the timer count from the timer register
    ldr     r1, =DFLT_ALARM_TIME                    @ Set the default ALarm Time as 1000000 microseconds, 1 second
    adds    r0, r0, r1                              @ Add the current time delay to the current timer count

    @Sets the Alarm time in the Alarm control reg
    ldr     r1, =(TIMER_BASE + TIMER_ALARM0_OFFSET) @ Load in the address for the ALARM0 control register
    str     r0, [r1]                                @ Store the new alarm time to the Control register

    pop     {pc}                                    @ Pop the link register from the stack to the program counter

.thumb_func
alarm_isr:
    push    {lr}                                    @ Store the link register to the stack
   
    @clears the timer interrupt 
    movs    r0, #1                                  @ Load 1 into the regster for use in clearing timer interupt
    ldr     r1, =(TIMER_BASE + TIMER_INTR_OFFSET)   @ Load the adress for the TIMER raw interrupts register.  
    str     r0, [r1]                                @ Set the interrupt raw register to 1 to clear timer interrupts                
    
    cmp     r0, r7                                  @ R7 will be high if button is still being pressed                   
    bl      readTemp                            @ call c function which handles spaces
    bl      init_alarm                              @ re-initialise the alarm 
    pop     {pc}

 

@ Set data alignment
.data
    .align 4
adcbase: .word 0x4004c000 @ base for analog to digital