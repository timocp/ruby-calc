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

/* Unfortunately in this module we can't use the libcalc method setconfig()
 * or config_value() - because it is defined in value.h which is
 * incompatible with the ruby C API (they both define a type called VALUE).
 *
 * some of its code is duplicated here.
 */

/*** module methods ***/

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

static VALUE
cc_get_mode(VALUE klass)
{
    setup_math_error();

    return mode_to_string(conf->outmode);
}

static VALUE
cc_set_mode(VALUE klass, VALUE v)
{
    setup_math_error();

    math_setmode(value_to_mode(v));
    return v;
}

void
define_calc_config(VALUE m)
{
    mConfig = rb_define_module_under(m, "Config");
    rb_define_module_function(mConfig, "epsilon", cc_get_epsilon, 0);
    rb_define_module_function(mConfig, "epsilon=", cc_set_epsilon, 1);
    rb_define_module_function(mConfig, "mode", cc_get_mode, 0);
    rb_define_module_function(mConfig, "mode=", cc_set_mode, 1);
}
