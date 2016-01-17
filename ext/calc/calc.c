#include "calc.h"

/* Frees memory used to store calculated bernoulli numbers.
 * 
 * @return [nil]
 * @example
 *  Calc::Q(100).bernoulli  #=> Calc::Q(...)
 *  Calc::Q.freebernoulli   #=> nil
 */
static VALUE
calc_freebernoulli(VALUE self)
{
    setup_math_error();
    qfreebern();
    return Qnil;
}

void
Init_calc(void)
{
    VALUE m;
    libcalc_call_me_first();

    m = rb_define_module("Calc");
    rb_define_module_function(m, "config", calc_config, -1);
    rb_define_module_function(m, "freebernoulli", calc_freebernoulli, 0);
    define_calc_math_error(m);
    define_calc_numeric(m);
    define_calc_q(m);
    define_calc_c(m);
}
