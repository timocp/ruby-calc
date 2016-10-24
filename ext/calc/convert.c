#include "calc.h"

/* attempt to convert a bignum a long then to Calc::Q using itoq().
 * NUM2LONG will raise a RangeError if arg doesn't fit in a long */
static VALUE
bignum_to_calc_q_via_long(VALUE arg)
{
    return wrap_number(itoq(NUM2LONG(arg)));
}

/* handles exceptions during via_long.  convert the arg to a string, then
 * Calc::Q using str2q() */
static VALUE
bignum_to_calc_q_via_string(VALUE arg, VALUE e)
{
    VALUE string;

    if (!rb_obj_is_kind_of(e, rb_eRangeError)) {
        /* something other than RangeError; re-raise it */
        rb_exc_raise(e);
    }
    string = rb_funcall(arg, rb_intern("to_s"), 0);
    return wrap_number(str2q(StringValueCStr(string)));
}

/* convert a Bignum to Calc::Q
 * first tries to convert via a long; if that raises an exception, convert via
 * a string */
static VALUE
bignum_to_calc_q(VALUE arg)
{
    return rb_rescue(&bignum_to_calc_q_via_long, arg, &bignum_to_calc_q_via_string, arg);
}

/* convert a ruby Rational to a NUMBER*.  Since the denominator/numerator of
 * the rational number could be too big for long, they are converted to NUMBER*
 * first.
 */
static NUMBER *
rational_to_number(VALUE arg)
{
    NUMBER *qresult, *qnum, *qden;

    qnum = value_to_number(rb_funcall(arg, rb_intern("numerator"), 0), 0);
    qden = value_to_number(rb_funcall(arg, rb_intern("denominator"), 0), 0);
    qresult = qqdiv(qnum, qden);
    qfree(qnum);
    qfree(qden);
    return qresult;
}

/* converts a ruby value into a NUMBER*.  Allowed types:
 *  - Integer
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
    VALUE num, tmp;

    if (FIXNUM_P(arg)) {
        qresult = itoq(NUM2LONG(arg));
    }
    else if (RB_TYPE_P(arg, T_BIGNUM)) {
        num = bignum_to_calc_q(arg);
        qresult = qlink((NUMBER *) DATA_PTR(num));
    }
    else if (CALC_Q_P(arg)) {
        qresult = qlink((NUMBER *) DATA_PTR(arg));
    }
    else if (RB_TYPE_P(arg, T_RATIONAL)) {
        qresult = rational_to_number(arg);
    }
    else if (RB_TYPE_P(arg, T_FLOAT)) {
        tmp = rb_funcall(arg, rb_intern("to_r"), 0);
        qresult = rational_to_number(tmp);
    }
    else if (string_allowed && RB_TYPE_P(arg, T_STRING)) {
        qresult = str2q(StringValueCStr(arg));
        /* libcalc str2q allows a 0 denominator */
        if (ziszero(qresult->den)) {
            qfree(qresult);
            rb_raise(rb_eZeroDivError, "division by zero");
        }
    }
    else {
        rb_raise(rb_eArgError, "%" PRIsVALUE " (%" PRIsVALUE ") can't be converted to Calc::Q",
                 arg, rb_obj_class(arg));
    }
    return qresult;
}

/* convert a ruby value into a COMPLEX*.  Allowed types:
 * - Complex
 * - Any type allowed by value_to_number (except string).
 *
 * libcalc doesn't provide any way to convert a string to a complex number.
 *
 * caller is responseible for freeing the returned complex.  storing it in
 * a Calc::C is sufficient for the ruby GC to get it.
 */
COMPLEX *
value_to_complex(VALUE arg)
{
    COMPLEX *cresult;
    VALUE real, imag;

    if (CALC_C_P(arg)) {
        cresult = clink((COMPLEX *) DATA_PTR(arg));
    }
    else if (RB_TYPE_P(arg, T_COMPLEX)) {
        real = rb_funcall(arg, rb_intern("real"), 0);
        imag = rb_funcall(arg, rb_intern("imag"), 0);
        cresult = qqtoc(value_to_number(real, 0), value_to_number(imag, 0));
    }
    else if (CALC_Q_P(arg)) {
        cresult = qqtoc(DATA_PTR(arg), &_qzero_);
    }
    else if (FIXNUM_P(arg) || RB_TYPE_P(arg, T_BIGNUM) || RB_TYPE_P(arg, T_RATIONAL)
             || RB_TYPE_P(arg, T_FLOAT)) {
        cresult = qqtoc(value_to_number(arg, 0), &_qzero_);
    }
    else {
        rb_raise(rb_eArgError, "%" PRIsVALUE " (%" PRIsVALUE ") can't be converted to Calc::C",
                 arg, rb_obj_class(arg));
    }

    return cresult;
}

/* get a long out of a ruby VALUE.  if it is fractional, or too big to be
 * represented, raises an error */
long
value_to_long(VALUE v)
{
    long l;
    NUMBER *q;

    if (FIXNUM_P(v)) {
        return FIX2LONG(v);
    }
    q = value_to_number(v, 0);
    if (qisfrac(q)) {
        qfree(q);
        rb_raise(rb_eTypeError, "Fraction (%" PRIsVALUE ") can't be converted to long", v);
    }
    if (zgtmaxlong(q->num)) {
        qfree(q);
        rb_raise(rb_eTypeError, "%" PRIsVALUE " is too large to convert to long", v);
    }
    l = qtoi(q);
    qfree(q);
    return l;
}

/* wrap a COMPLEX* into a ruby VALUE of class Calc::C (if there is a non-zero
 * imaginary part) or Calc::Q (otherwise).
 */
VALUE
wrap_complex(COMPLEX * c)
{
    VALUE result;

    if (cisreal(c)) {
        result = cq_new();
        DATA_PTR(result) = qlink(c->real);
        comfree(c);
    }
    else {
        result = cc_new();
        DATA_PTR(result) = c;
    }
    return result;
}

/* wrap a NUMBER* into a ruby VALUE of class Calc::Q. */
VALUE
wrap_number(NUMBER * n)
{
    VALUE result;

    result = cq_new();
    DATA_PTR(result) = n;
    return result;
}
