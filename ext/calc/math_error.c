#include <stdarg.h>
#include "calc.h"

VALUE e_MathError;

#ifndef SETJMP_ON_MATH_ERROR

/* provide our own version of math_error which raises a ruby exception
 * instead of exiting.
 *
 * ideally this would call rb_raise, but you can't just pass a varargs list to
 * another function (see http://c-faq.com/varargs/handoff.html).
 * so this just does what rb_raise does internally.
 *
 * TODO: test coverage of an error with a parameter.
 */
void
math_error(char *fmt, ...)
{
    va_list args;
    VALUE mesg;

    va_start(args, fmt);
    mesg = rb_vsprintf(fmt, args);
    va_end(args);
    rb_exc_raise(rb_exc_new3(e_MathError, mesg));
}

#endif /* SETJMP_ON_MATH_ERROR */

void
define_calc_math_error(VALUE m)
{
    e_MathError = rb_define_class_under(m, "MathError", rb_eStandardError);
}
