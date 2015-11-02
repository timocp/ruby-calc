#include "calc.h"

VALUE rb_mCalc;   /* ruby Calc module */
VALUE cZ;         /* ruby Calc::Z class */

void
Init_calc(void)
{
  libcalc_call_me_first();

  rb_mCalc = rb_define_module("Calc");

  cZ = rb_define_class_under(rb_mCalc, "Z", rb_cObject);
  rb_define_alloc_func(cZ, zvalue_alloc);
  rb_define_method(cZ, "initialize",      zvalue_init, 1);
}
