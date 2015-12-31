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

typedef struct {
    const char *name;
    long type;
} nametype2;

static nametype2 modes[] = {
    {"fraction", MODE_FRAC},
    {"frac", MODE_FRAC},
    {"integer", MODE_INT},
    {"int", MODE_INT},
    {"real", MODE_REAL},
    {"float", MODE_REAL},
    {"default", MODE_INITIAL},  /* MODE_REAL */
    {"scientific", MODE_EXP},
    {"sci", MODE_EXP},
    {"exp", MODE_EXP},
    {"hexadecimal", MODE_HEX},
    {"hex", MODE_HEX},
    {"octal", MODE_OCTAL},
    {"oct", MODE_OCTAL},
    {"binary", MODE_BINARY},
    {"bin", MODE_BINARY},
    {"off", MODE2_OFF},
    {NULL, 0}
};

static long
lookup_long(nametype2 * set, const char *name)
{
    nametype2 *cp;

    for (cp = set; cp->name; cp++) {
        if (strcmp(cp->name, name) == 0)
            return cp->type;
    }
    return -1;
}

static const char *
lookup_name(nametype2 * set, long val)
{
    nametype2 *cp;

    for (cp = set; cp->name; cp++) {
        if (val == cp->type)
            return cp->name;
    }
    return NULL;
}

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
    const char *p;
    setup_math_error();

    p = lookup_name(modes, conf->outmode);
    if (p == NULL) {
        rb_raise(e_MathError, "invalid output mode: %d", conf->outmode);
    }
    return rb_str_new2(p);
}

static VALUE
cc_set_mode(VALUE klass, VALUE v)
{
    char *str;
    long n;
    setup_math_error();

    str = StringValueCStr(v);
    n = lookup_long(modes, str);
    if (n < 0) {
        rb_raise(rb_eArgError, "Unknown mode \"%s\"", str);
    }
    math_setmode(n);
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
