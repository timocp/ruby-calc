#include "calc.h"

VALUE rb_mCalc;

void
Init_calc(void)
{
  libcalc_call_me_first();

  rb_mCalc = rb_define_module("Calc");
}
