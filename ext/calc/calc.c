#include "calc.h"

VALUE rb_mCalc;   /* ruby Calc module */
VALUE cZ;         /* ruby Calc::Z class */

void
Init_calc(void)
{
  libcalc_call_me_first();

  /* define Calc module */
  rb_mCalc = rb_define_module("Calc");

  /* define Calc::Z class */
  cZ = rb_define_class_under(rb_mCalc, "Z", rb_cObject);
  rb_define_alloc_func(cZ, cz_alloc);
  rb_define_method(cZ, "initialize", cz_initialize, 1);
  rb_define_method(cZ, "initialize_copy", cz_initialize_copy, 1);

  /* instance methods on Calc::Z */
  rb_define_method(cZ, "<=>",   cz_comparison, 1);
  rb_define_method(cZ, "==",    cz_equal, 1);
  rb_define_method(cZ, "to_s",  cz_to_s, 0);
}
