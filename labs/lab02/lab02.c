#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "pico/stdlib.h"
#include "pico/float.h"     // Required for using single-precision variables.
#include "pico/double.h"    // Required for using double-precision variables.

//function declarations
float wallis_float(); 
double wallis_double();
//definition of correct value of pi
const double pi = 3.14159265359;

int main() {

#ifndef WOKWI
    // Initialise the IO as we will be using the UART
    // Only required for hardware and not needed for Wokwi
    stdio_init_all();
#endif

    //Assign single-precision wallis product estimate to a float variable. 
    float pi_float = 2*wallis_float();
    //Calculate approximation error and assign to double variable
    double pi_float_error = fabs(100*(pi_float - pi)/pi);

    //Print results
    printf("Estimate of PI using single-precision representation: %f \n", pi_float);
    printf("Approximation error: %lf%%\n", pi_float_error);

    //Assign double-precision wallis product estimate to a double variable. 
    double pi_double = 2*wallis_double();
    //Calculate approximation error and assign to a double variable
    double pi_double_error = fabs(100*(pi_double - pi)/pi);

    //Print results
    printf("\nEstimate of PI using double-precision representation: %lf \n", pi_double);
    printf("Approximation error: %lf%%\n", pi_double_error);

    // Returning zero indicates everything went okay.
    return 0;
}

float wallis_float(){
  float x = 1.0;
  for(float n = 1; n <= 100000; n+=1.0){
    x = x*(4*n*n)/(4*n*n-1);
  }
  return x;
}

double wallis_double(){
  double x = 1.0;
  for(double n = 1; n <= 100000; n+=1.0){
    x = x*(4*n*n)/(4*n*n-1);
  }
  return x;
}