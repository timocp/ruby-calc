#include "calc.h"

VALUE rb_mCalc;

void
Init_calc(void)
{
  rb_mCalc = rb_define_module("Calc");
}
