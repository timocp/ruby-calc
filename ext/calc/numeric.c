#include <calc.h>

/* Document-class: Calc::Numeric
 *
 * Parent class to the libraries numeric classes (Calc::Q and Calc::C)
 */
VALUE cNumeric;

void
define_calc_numeric(VALUE m)
{
    cNumeric = rb_define_class_under(m, "Numeric", rb_cData);
}
