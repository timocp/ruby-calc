#include "calc.h"

/* "mode" conversions.  this is based on code in config.c */

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

/* config types we support - a subset of "configs[]" in calc's config.c */

static nametype2 configs[] = {
    {"mode", CONFIG_MODE},
    {"display", CONFIG_DISPLAY},
    {"epsilon", CONFIG_EPSILON},
    {"quomod", CONFIG_QUOMOD},
    {"quo", CONFIG_QUO},
    {"mod", CONFIG_MOD},
    {"sqrt", CONFIG_SQRT},
    {"appr", CONFIG_APPR},
    {"cfappr", CONFIG_CFAPPR},
    {"cfsim", CONFIG_CFSIM},
    {"round", CONFIG_ROUND},
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

/* given a String or Symbol, returns the index into a nameset
 * or -1 if not found */
static long
value_to_nametype_long(VALUE v, nametype2 * set)
{
    VALUE tmp;
    char *str;

    if (TYPE(v) == T_STRING) {
        str = StringValueCStr(v);
    }
    else if (TYPE(v) == T_SYMBOL) {
        tmp = rb_funcall(v, rb_intern("to_s"), 0);
        str = StringValueCStr(tmp);
    }
    else {
        rb_raise(rb_eArgError, "expected String or Symbol");
    }
    return lookup_long(set, str);
}

/* convert value to a libcalc mode flag.  value may be a string or a symbol.
 * raises an exception if the mode in invalid. */
long
value_to_mode(VALUE v)
{
    long n;

    n = value_to_nametype_long(v, modes);
    if (n < 0) {
        rb_raise(rb_eArgError, "invalid output mode");
    }
    return n;
}

static VALUE
mode_to_string(long n)
{
    const char *p;

    p = lookup_name(modes, n);
    if (p == NULL) {
        rb_raise(e_MathError, "invalid output mode: %ld", n);
    }
    return rb_str_new2(p);
}

/* convert a string or symbol to the libcalc CALC_* enum
 * returns -1 if the name is invalid/unsupported in ruby-calc */
static long
value_to_config(VALUE v)
{
    return value_to_nametype_long(v, configs);
}

static LEN
value_to_len(VALUE v, const char *name)
{
    NUMBER *q;
    LEN len = 0;

    q = value_to_number(v, 1);
    if (!qisint(q)) {
        qfree(q);
        rb_raise(e_MathError, "Non-integer value for %s", name);
    }
    if (zge31b(q->num)) {
        qfree(q);
        rb_raise(e_MathError, "Integer too big for %s", name);
    }
    len = (LEN) ztoi(q->num);
    qfree(q);
    if (len < 0)
        rb_raise(e_MathError, "Negative value for %s", name);
    return len;
}

/* Unfortunately in this function we can't use the libcalc method setconfig()
 * or config_value() - because it is defined in value.h which is
 * incompatible with the ruby C API (they both define a type called VALUE).
 *
 * some of its code is duplicated here.
 */

/* Gets or sets a libcalc configuration type.
 */
VALUE
calc_config(int argc, VALUE * argv, VALUE klass)
{
    VALUE name, new_value, old_value;
    int args;
    setup_math_error();

    args = rb_scan_args(argc, argv, "11", &name, &new_value);

    switch (value_to_config(name)) {

    case CONFIG_DISPLAY:
        old_value = INT2FIX(conf->outdigits);
        if (args == 2)
            math_setdigits(FIX2INT(new_value));
        break;

    case CONFIG_MODE:
        old_value = mode_to_string(conf->outmode);
        if (args == 2)
            math_setmode((int) value_to_mode(new_value));
        break;

    case CONFIG_EPSILON:
        old_value = wrap_number(qlink(conf->epsilon));
        if (args == 2)
            setepsilon(value_to_number(new_value, 1));
        break;

    case CONFIG_QUOMOD:
        old_value = INT2FIX(conf->quomod);
        if (args == 2)
            conf->quomod = value_to_len(new_value, "quomod");
        break;

    case CONFIG_QUO:
        old_value = INT2FIX(conf->quo);
        if (args == 2)
            conf->quo = value_to_len(new_value, "quo");
        break;

    case CONFIG_MOD:
        old_value = INT2FIX(conf->mod);
        if (args == 2)
            conf->mod = value_to_len(new_value, "mod");
        break;

    case CONFIG_SQRT:
        old_value = INT2FIX(conf->sqrt);
        if (args == 2)
            conf->sqrt = value_to_len(new_value, "sqrt");
        break;

    case CONFIG_APPR:
        old_value = INT2FIX(conf->appr);
        if (args == 2)
            conf->appr = value_to_len(new_value, "appr");
        break;

    case CONFIG_CFAPPR:
        old_value = INT2FIX(conf->cfappr);
        if (args == 2)
            conf->cfappr = value_to_len(new_value, "cfappr");
        break;

    case CONFIG_CFSIM:
        old_value = INT2FIX(conf->cfsim);
        if (args == 2)
            conf->cfsim = value_to_len(new_value, "cfsim");
        break;

    case CONFIG_ROUND:
        old_value = INT2FIX(conf->round);
        if (args == 2)
            conf->round = value_to_len(new_value, "round");
        break;

    default:
        rb_raise(rb_eArgError, "Invalid or unsupported config parameter");
    }
    return old_value;
}
