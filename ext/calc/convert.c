#include "calc.h"

/* converts a ruby value into a ZVALUE.  Allowed types:
 *  - Fixnum
 *  - Bignum (has to fit in a long)
 *  - Calc::Z
 *  - String (using libcalc str2z)
 */
ZVALUE
value_to_zvalue(VALUE arg, int string_allowed)
{
    ZVALUE *zarg;
    ZVALUE result;
    setup_math_error();

    if (TYPE(arg) == T_FIXNUM) {
        itoz(NUM2LONG(arg), &result);
    }
    else if (TYPE(arg) == T_BIGNUM) {
        itoz(NUM2LONG(arg), &result);
    }
    else if (ISZVALUE(arg)) {
        get_zvalue(arg, zarg);
        zcopy(*zarg, &result);
    }
    else if (string_allowed && TYPE(arg) == T_STRING) {
        str2z(StringValueCStr(arg), &result);
    }
    else {
        if (string_allowed) {
            rb_raise(rb_eArgError, "expected number, Calc::Z or String");
        }
        else {
            rb_raise(rb_eArgError, "expected number or Calc::Z");
        }
    }

    return result;
}

/* converts a ruby value into a NUMBER*.  Allowed types:
 *  - Fixnum
 *  - Bignum (has to fit in a long)
 *  - Calc::Z
 *  - Calc::Q
 *  - Rational
 *  - String (using libcalc str2q)
 *  - Float (will be converted to a Rational first)
 *
 * the caller is responsible for freeing the returned number.  storing it in
 * a Calc::Q is sufficient for the ruby GC to get it.
 */
NUMBER *
value_to_number(VALUE arg, int string_allowed)
{
    NUMBER *qresult;
    ZVALUE *zarg;
    VALUE tmp;
    setup_math_error();

    if (TYPE(arg) == T_FIXNUM || TYPE(arg) == T_BIGNUM) {
        qresult = itoq(NUM2LONG(arg));
    }
    else if (ISZVALUE(arg)) {
        get_zvalue(arg, zarg);
        qresult = qalloc();
        zcopy(*zarg, &qresult->num);
    }
    else if (ISQVALUE(arg)) {
        qresult = qlink((NUMBER *) DATA_PTR(arg));
    }
    else if (TYPE(arg) == T_RATIONAL) {
        qresult = iitoq(NUM2LONG(rb_funcall(arg, rb_intern("numerator"), 0)),
                        NUM2LONG(rb_funcall(arg, rb_intern("denominator"), 0)));
    }
    else if (TYPE(arg) == T_FLOAT) {
        tmp = rb_funcall(arg, rb_intern("to_r"), 0);
        qresult = iitoq(NUM2LONG(rb_funcall(tmp, rb_intern("numerator"), 0)),
                        NUM2LONG(rb_funcall(tmp, rb_intern("denominator"), 0)));
    }
    else if (string_allowed && TYPE(arg) == T_STRING) {
        qresult = str2q(StringValueCStr(arg));
        /* libcalc str2q allows a 0 denominator */
        if (ziszero(qresult->den)) {
            qfree(qresult);
            rb_raise(rb_eZeroDivError, "division by zero");
        }
    }
    else {
        if (string_allowed) {
            rb_raise(rb_eArgError,
                     "expected number, Rational, Float, Calc::Z, Calc::Q or string");
        }
        else {
            rb_raise(rb_eArgError, "expected number, Rational, Float, Calc::Z or Calc::Q");
        }
    }
    return qresult;
}
