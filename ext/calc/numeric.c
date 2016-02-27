#include <calc.h>

/* Document-class: Calc::Numeric
 *
 * Parent class to the libraries numeric classes (Calc::Q and Calc::C)
 */
VALUE cNumeric;

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
    if (CALC_Q_P(self) && !qisneg((NUMBER *)DATA_PTR(self))) {
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
    rb_define_method(cNumeric, "sqrt", cn_sqrt, -1);
}
