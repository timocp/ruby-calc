#include <stdarg.h>
#include "calc.h"

VALUE e_MathError;

#ifdef JUMP_ON_MATH_ERROR

/* this is an alternative error handler used on systems when we can't tell
 * the linker to use our version of math_error.  uses setjmp to tell libcalc's
 * default math_error to return here instead of exiting.  a ruby exception
 * is raised if the longjmp is made.
 *
 * the downside of this is that each c function which calls libcalc methods
 * that /could/ call math_error needs to call this first.  apart from the small
 * performance hit, this is extra unwanted code in many functions.  if I
 * could find a way to tell the macosx linker to replace math_error() like
 * it works on Linux, this method would not be necessary.
 *
 * unfortunately it is not possible to call this once (say, during definition
 * of Calc::MathError) and except later C functions to be able to jump into it.
 * crossing the ruby/C boundary like that causes crashes or hangs.
 *
 * on other systems, this function name is #defined to nothing.
 */

void
setup_math_error(void)
{
    int error;
    VALUE mesg;

    if ((error = setjmp(calc_matherr_jmpbuf)) != 0) {
        mesg = rb_str_new2(calc_err_msg);
        reinitialize();
        rb_exc_raise(rb_exc_new3(e_MathError, mesg));
    }
    calc_use_matherr_jmpbuf = 1;
}

#else

/* provide our own version of math_error which raises a ruby exception
 * instead of exiting.
 *
 * ideally this would call rb_raise, but you can't just pass a varargs list to
 * another function (see http://c-faq.com/varargs/handoff.html).
 * so this just does what rb_raise does internally.
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

#endif                          /* JUMP_ON_MATH_ERROR */

void
define_calc_math_error(VALUE m)
{
    e_MathError = rb_define_class_under(m, "MathError", rb_eStandardError);
}
