#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "pico/stdlib.h"
#include "pico/float.h"     // Required for using single-precision variables.
#include "pico/double.h"    // Required for using double-precision variables.
#include "hardware/timer.h"
#include "pico/multicore.h"

//function declarations
float wallis_float(float iter); 
double wallis_double(double iter);
//definition of correct value of pi
const double pi = 3.14159265359;
uint32_t float_elapsed_time;


void core1_entry() {
    while (1) {
        // 
        int32_t (*func)() = (int32_t(*)()) multicore_fifo_pop_blocking();
        int32_t p = multicore_fifo_pop_blocking();
        int32_t result = (*func)(p);
        multicore_fifo_push_blocking(result);
    }
}

int main() {

#ifndef WOKWI
    // Initialise the IO as we will be using the UART
    // Only required for hardware and not needed for Wokwi
    stdio_init_all();
#endif
    multicore_launch_core1(core1_entry);
    //Assign single-precision wallis product estimate to a float variable. 
    //float pi_float = 2*wallis_float(10000);
    multicore_fifo_push_blocking((uintptr_t)&wallis_float);
    multicore_fifo_push_blocking(10000);

    //Assign double-precision wallis product estimate to a double variable.
    uint32_t start_time = time_us_32(); 
    double pi_double = 2*wallis_double(10000);
    uint32_t end_time = time_us_32();
    uint32_t double_elapsed_time = end_time - start_time;
    float pi_float = multicore_fifo_pop_blocking();
    //Calculate approximation error and assign to a double variable
    double pi_double_error = fabs(100*(pi_double - pi)/pi);
    //Calculate approximation error and assign to double variable
    double pi_float_error = fabs(100*(pi_float - pi)/pi);
    //Print results
    printf("Estimate of PI using single-precision representation: %f \n", pi_float);
    printf("Approximation error: %lf%%\n", pi_float_error);
    printf("Elapsed time using single-precision: %ims\n", float_elapsed_time);

    //Print results
    printf("\nEstimate of PI using double-precision representation: %lf \n", pi_double);
    printf("Approximation error: %lf%%\n", pi_double_error);
    printf("Elapsed time using double-precision: %ims\n", double_elapsed_time);

    uint32_t total_elapsed_time = float_elapsed_time + double_elapsed_time;
    printf("\nTotal elapsed time: %ims\n", total_elapsed_time);

    // Returning zero indicates everything went okay.
    return 0;
}

float wallis_float(float iter){
  uint32_t start_time = time_us_32();
  float x = 1.0;
  for(float n = 1; n <= 10000; n+=1.0){
    x = x*(4*n*n)/(4*n*n-1);
  }
  uint32_t end_time = time_us_32();
  float_elapsed_time = end_time - start_time;
  return x;
}

double wallis_double(double iter){
  double x = 1.0;
  for(double n = 1; n <= iter; n+=1.0){
    x = x*(4*n*n)/(4*n*n-1);
  }
  return x;
}