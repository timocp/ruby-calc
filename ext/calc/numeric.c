#include <calc.h>

/* Document-class: Calc::Numeric
 *
 * Parent class to the libraries numeric classes (Calc::Q and Calc::C)
 */
VALUE cNumeric;

NUMBER *
sign_of_int(int r)
{
    return (r > 0) ? qlink(&_qone_) : (r < 0) ? qlink(&_qnegone_) : qlink(&_qzero_);
}

/* Compare 2 values.
 *
 * If x and y are both real, returns -1, 0 or 1 according as x < y, x == y or
 * x > y.
 *
 * If one or both of x and y are complex, returns a complex number composed
 * of the real and imaginary parts being compared individually as above.
 *
 * @param y [Numeric] value to compare self to
 * @example
 *  Calc::Q(3).cmp(4)     #=> Calc::Q(-1)
 *  Calc::Q(3).cmp(4+4i)  #=> Calc::C(-1-1i)
 *  Calc::C(3i).cmp(3+3i) #=> Calc::Q(-1)
 */
static VALUE
cn_cmp(VALUE self, VALUE other)
{
    VALUE result;
    NUMBER *qself, *qother;
    COMPLEX *cself, *cother, *cresult;
    int r = 0;
    int i = 0;
    setup_math_error();

    if (CALC_Q_P(self)) {
        qself = DATA_PTR(self);
        if (CALC_C_P(other) || TYPE(other) == T_COMPLEX) {
            cother = value_to_complex(other);
            r = qrel(qself, cother->real);
            i = qrel(&_qzero_, cother->imag);
            comfree(cother);
        }
        else {
            qother = value_to_number(other, 0);
            r = qrel(qself, qother);
            qfree(qother);
        }
    }
    else if (CALC_C_P(self)) {
        cself = DATA_PTR(self);
        if (CALC_C_P(other) || TYPE(other) == T_COMPLEX) {
            cother = value_to_complex(other);
            r = qrel(cself->real, cother->real);
            i = qrel(cself->imag, cother->imag);
        }
        else {
            qother = value_to_number(other, 0);
            r = qrel(cself->real, qother);
            i = qrel(cself->imag, &_qzero_);
            qfree(qother);
        }
    }
    else {
        rb_raise(rb_eTypeError, "receiver must be Calc::Q or Calc::C");
    }
    if (i == 0) {
        result = cq_new();
        DATA_PTR(result) = sign_of_int(r);
    }
    else {
        result = cc_new();
        cresult = comalloc();
        qfree(cresult->real);
        cresult->real = sign_of_int(r);
        qfree(cresult->imag);
        cresult->imag = sign_of_int(i);
        DATA_PTR(result) = cresult;
    }
    return result;
}

/* Square root
 *
 * Calculates the square root of self (rational or complex).  If eps
 * is provided, it specifies the accuracy/error of the calculation, otherwise
 * config("epsilon") is used.
 * If z is provided, it controls the sign and rounding if required, otherwise
 * config("sqrt") is used.
 * Type "help sqrt" in calc for a full explanation of z.
 *
 * @param eps [Numeric,Calc::Q] (optional) calculation accuracy
 * @param z [Integer] (optional) sign and rounding flags
 * @example
 *  Calc::Q(4).sqrt     #=> Calc::Q(2)
 *  Calc::Q(5).sqrt     #=> Calc::Q(2.23606797749978969641)
 *  Calc::C(0,8).sqrt   #=> Calc::C(2+2i)
 */
static VALUE
cn_sqrt(int argc, VALUE * argv, VALUE self)
{
    VALUE result, epsilon, z;
    NUMBER *qtmp, *qepsilon;
    COMPLEX *cresult;
    long R;
    int n;
    setup_math_error();

    n = rb_scan_args(argc, argv, "02", &epsilon, &z);
    if (n >= 1) {
        qepsilon = value_to_number(epsilon, 1);
    }
    else {
        qepsilon = conf->epsilon;
    }
    if (n == 2) {
        R = FIX2LONG(z);
    }
    else {
        R = conf->sqrt;
    }
    if (CALC_Q_P(self) && !qisneg((NUMBER *) DATA_PTR(self))) {
        /* non-negative rational */
        result = cq_new();
        DATA_PTR(result) = qsqrt(DATA_PTR(self), qepsilon, R);
    }
    else {
        if (CALC_Q_P(self)) {
            /* negative rational */
            qtmp = qneg(DATA_PTR(self));
            cresult = comalloc();
            qfree(cresult->imag);
            cresult->imag = qsqrt(qtmp, qepsilon, R);
            qfree(qtmp);
        }
        else {
            /* complex */
            cresult = c_sqrt(DATA_PTR(self), qepsilon, R);
        }
        result = complex_to_value(cresult);
    }
    if (n >= 1) {
        qfree(qepsilon);
    }
    return result;
}

void
define_calc_numeric(VALUE m)
{
    cNumeric = rb_define_class_under(m, "Numeric", rb_cData);
    rb_define_method(cNumeric, "cmp", cn_cmp, 1);
    rb_define_method(cNumeric, "sqrt", cn_sqrt, -1);
}
