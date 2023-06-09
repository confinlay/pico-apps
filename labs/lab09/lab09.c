#include <stdio.h>
#include <stdlib.h>
#include "pico/stdlib.h"
#include "hardware/adc.h"

#include "hardware/gpio.h"
#include "pico/time.h"
#include "hardware/pio.h"
#include "hardware/clocks.h"
#include "ws2812.pio.h"

#define IS_RGBW true        // Will use RGBW format
#define NUM_PIXELS 1        // There is 1 WS2812 device in the chain
#define WS2812_PIN 28       // The GPIO pin that the WS2812 connected to

float tempC;

// Must declare the main assembly entry point before use.
void main_asm();
// Initialise a GPIO pin – see SDK for detail on gpio_init()
void asm_gpio_init(uint pin) {
 gpio_init(pin);
}
// Set direction of a GPIO pin – see SDK for detail on gpio_set_dir()
void asm_gpio_set_dir(uint pin, bool out) {
 gpio_set_dir(pin, out);
}
// Get the value of a GPIO pin – see SDK for detail on gpio_get()
bool asm_gpio_get(uint pin) {
 return gpio_get(pin);
}
// Set the value of a GPIO pin – see SDK for detail on gpio_put()
void asm_gpio_put(uint pin, bool value) {
 gpio_put(pin, value);
}

static inline void put_pixel(uint32_t pixel_grb) {
    pio_sm_put_blocking(pio0, 0, pixel_grb << 8u);
}

/**
 * @brief Function to generate an unsigned 32-bit composit GRB
 *        value by combining the individual 8-bit paramaters for
 *        red, green and blue together in the right order.
 * 
 * @param r     The 8-bit intensity value for the red component
 * @param g     The 8-bit intensity value for the green component
 * @param b     The 8-bit intensity value for the blue component
 * @return uint32_t Returns the resulting composit 32-bit RGB value
 */
static inline uint32_t urgb_u32(uint8_t r, uint8_t g, uint8_t b) {
    return  ((uint32_t) (r) << 8)  |
            ((uint32_t) (g) << 16) |
            (uint32_t) (b);
}

static inline void led_set_blue() {
    put_pixel(urgb_u32(0x00, 0x00, 0x7F));
}

static inline void led_set_red() {
    put_pixel(urgb_u32(0x7F, 0x00, 0x00));
}

static inline void led_set_orange() {
    put_pixel(urgb_u32(0xFF, 0x8C, 0x00));
}
static inline void led_set_green() {
    put_pixel(urgb_u32(0x00, 0xFF, 0x00));
}
static inline void led_set_off() {
    put_pixel(urgb_u32(0x00, 0x00, 0x00));
}
static inline void led_set_yellow() {
    put_pixel(urgb_u32(0xD7, 0xFF, 0x00));
}

void convert_temp(float adc){
    const float conversionFactor = 3.3f / (1 << 12);

    adc = adc * conversionFactor;
    tempC = 27.0f - (adc - 0.706f) / 0.001721f;

    printf("Current temperature: %f\n", tempC);
}

/**
 * @brief LAB #09 - TEMPLATE
 *        Main entry point for the code - calls the main assembly
 *        function where the body of the code is implemented.
 * 
 * @return int      Returns exit-status zero on completion.
 */
int main() {

    //initialising
    stdio_init_all(); 
    PIO pio = pio0;
    uint offset = pio_add_program(pio, &ws2812_program);
    ws2812_program_init(pio, 0, offset, WS2812_PIN, 800000, IS_RGBW);

    printf("Time to have fun!\n\n");

    // Jump into the main assembly code subroutine.
    main_asm();

    // Returning zero indicates everything went okay.
    return 0;
}
