#include "calc.h"

void
Init_calc(void)
{
    VALUE m;
    libcalc_call_me_first();

    m = rb_define_module("Calc");
    rb_define_module_function(m, "config", calc_config, -1);
    define_calc_math_error(m);
    define_calc_numeric(m);
    define_calc_z(m);
    define_calc_q(m);
    define_calc_c(m);
}
