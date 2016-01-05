#include "calc.h"

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
            math_setmode(value_to_mode(new_value));
        break;

    case CONFIG_EPSILON:
        old_value = number_to_calc_q(conf->epsilon);
        if (args == 2)
            setepsilon(value_to_number(new_value, 1));
        break;

    default:
        rb_raise(rb_eArgError, "Invalid or unsupported config parameter");
    }
    return old_value;
}
