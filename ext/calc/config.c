#include "calc.h"

/* Document-module: Calc::Config
 *
 * Configuration parameters.
 *
 * Provides an API for reading and writing the libcalc configuration options.
 *
 * Conceptually this is equivalent to the calc command line interface's
 * config() function.
 */
static VALUE mConfig;

static VALUE
cc_get_epsilon(VALUE klass)
{
    setup_math_error();
    return number_to_calc_q(conf->epsilon);
}

static VALUE
cc_set_epsilon(VALUE klass, VALUE v)
{
    setup_math_error();
    setepsilon(value_to_number(v, 1));
    return v;
}

void
define_calc_config(VALUE m)
{
    mConfig = rb_define_module_under(m, "Config");
    rb_define_module_function(mConfig, "epsilon", cc_get_epsilon, 0);
    rb_define_module_function(mConfig, "epsilon=", cc_set_epsilon, 1);
    
    /*
    printf("default outmode: %d\n", conf->outmode);
    printf("default epsilon: ");
    qprintnum(conf->epsilon, MODE_FRAC);
    printf("\n");
    */
}
