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

/* Evaluates п (pi) to a specified accuracy
 *
 * @param eps [Numeric,Calc::Q] (optional) calculation accuracy
 * @return [Calc::Q]
 * @example
 *  Calc.pi          #=> Calc::Q(3.14159265358979323846)
 *  Calc.pi("1e-40") #=> Calc::Q(3.1415926535897932384626433832795028841972)
 */
static VALUE
calc_pi(int argc, VALUE * argv, VALUE self)
{
    NUMBER *qepsilon;
    VALUE epsilon, result;
    setup_math_error();

    result = cq_new();
    if (rb_scan_args(argc, argv, "01", &epsilon) == 0) {
        DATA_PTR(result) = qpi(conf->epsilon);
    }
    else {
        qepsilon = value_to_number(epsilon, 1);
        DATA_PTR(result) = qpi(qepsilon);
        qfree(qepsilon);
    }

    return result;
}

void
Init_calc(void)
{
    VALUE m;
    libcalc_call_me_first();

    m = rb_define_module("Calc");
    rb_define_module_function(m, "config", calc_config, -1);
    rb_define_module_function(m, "pi", calc_pi, -1);
    rb_define_module_function(m, "freebernoulli", calc_freebernoulli, 0);
    define_calc_math_error(m);
    define_calc_numeric(m);
    define_calc_q(m);
    define_calc_c(m);
}
