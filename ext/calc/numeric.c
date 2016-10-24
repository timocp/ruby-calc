#include <calc.h>

/* Document-class: Calc::Numeric
 *
 * Parent class to the libraries numeric classes (Calc::Q and Calc::C)
 */
VALUE cNumeric;

/* similar to trans_function, but for ln and log; the rational versions (qln,
 * qlog) return wrong results for self < 0, so call the complex version in that
 * case.
 * ref: f_ln() and f_log() in calc's func.c
 */
static VALUE
log_function(int argc, VALUE * argv, VALUE self, NUMBER * (fq) (NUMBER *, NUMBER *),
             COMPLEX * (*fc) (COMPLEX *, NUMBER *))
{
    VALUE epsilon, result;
    NUMBER *qepsilon, *qself;
    COMPLEX *cself;
    setup_math_error();

    if (rb_scan_args(argc, argv, "01", &epsilon) == 0) {
        qepsilon = NULL;
    }
    else {
        qepsilon = value_to_number(epsilon, 1);
    }
    if (CALC_Q_P(self)) {
        qself = DATA_PTR(self);
        if (!qisneg(qself) && !qiszero(qself)) {
            result = cq_new();
            DATA_PTR(result) = (*fq) (qself, qepsilon ? qepsilon : conf->epsilon);
        }
        else {
            cself = comalloc();
            qfree(cself->real);
            cself->real = qlink(qself);
            result = wrap_complex((*fc) (cself, qepsilon ? qepsilon : conf->epsilon));
            comfree(cself);
        }
    }
    else if (CALC_C_P(self)) {
        cself = DATA_PTR(self);
        result = wrap_complex((*fc) (cself, qepsilon ? qepsilon : conf->epsilon));
    }
    else {
        rb_raise(e_MathError, "log_function called with invalid receiver");
    }
    if (qepsilon) {
        qfree(qepsilon);
    }
    return result;
}

static VALUE
shift(VALUE self, VALUE other, BOOL rightshift)
{
    NUMBER *qother;
    long n;
    setup_math_error();

    qother = value_to_number(other, 0);
    if (qisfrac(qother)) {
        qfree(qother);
        rb_raise(rb_eArgError, "shift by non-integer");
    }
    if (zge31b(qother->num)) {
        qfree(qother);
        rb_raise(rb_eArgError, "shift by too many bits");
    }
    n = qtoi(qother);
    qfree(qother);
    if (rightshift) {
        n = -n;
    }
    if (CALC_Q_P(self)) {
        return wrap_number(qshift(DATA_PTR(self), n));
    }
    return wrap_complex(c_shift(DATA_PTR(self), n));
}


NUMBER *
sign_of_int(int r)
{
    return (r > 0) ? qlink(&_qone_) : (r < 0) ? qlink(&_qnegone_) : qlink(&_qzero_);
}

/* Left shift an integer by a given number of bits.  This multiplies the number
 * by the appropriate power of 2.
 *
 * @param n [Integer] number of bits to shift
 * @return [Calc::C,Calc::Q]
 * @raise [Calc::MathError] if self is a non-integer
 * @raise [ArgumentError] if abs(n) is >= 2^31
 * @example:
 *  Calc::Q(2) << 3    #=> Calc::Q(16)
 *  Calc::C(2, 3) << 3 #=> Calc::C(16+24i)
 */
static VALUE
cn_shift_left(VALUE self, VALUE other)
{
    return shift(self, other, FALSE);
}

/* Right shift an integer by a given number of bits.  This multiplies the
 * number by the appropriate power of 2.  Low bits are truncated.
 *
 * @param n [Integer] number of bits to shift
 * @return [Calc::C,Calc::Q]
 * @raise [Calc::MathError] if self is a non-integer
 * @raise [ArgumentError] if abs(n) is >= 2^31
 * @example:
 *  Calc::Q(8) >> 2     #=> Calc::Q(2)
 *  Calc::C(8, 12) >> 2 #=> Calc::C(2+3i)
 */
static VALUE
cn_shift_right(VALUE self, VALUE other)
{
    return shift(self, other, TRUE);
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
    int r, i;
    setup_math_error();

    if (CALC_Q_P(self)) {
        qself = DATA_PTR(self);
        if (CALC_C_P(other) || RB_TYPE_P(other, T_COMPLEX)) {
            cother = value_to_complex(other);
            r = qrel(qself, cother->real);
            i = qrel(&_qzero_, cother->imag);
            comfree(cother);
        }
        else {
            qother = value_to_number(other, 0);
            r = qrel(qself, qother);
            i = 0;
            qfree(qother);
        }
    }
    else if (CALC_C_P(self)) {
        cself = DATA_PTR(self);
        if (CALC_C_P(other) || RB_TYPE_P(other, T_COMPLEX)) {
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

/* combinatorial number
 *
 * Returns the number of combinations in which `other` things may be chosen
 * from `self` items ignoring order.
 *
 * @param other [Integer]
 * @return [Calc::Q,Calc::C]
 * @raise [MathError] if `other` is too large or not a positive integer
 * @example
 *  Calc::Q(5).comb(3)     #=> Calc::Q(10)
 *  Calc::Q(60).comb(30)   #=> Calc::Q(118264581564861424)
 *  Calc::Q("5.1").comb(5) #=> Calc::Q(1.24780425)
 *  Calc::C(8,9).comb(3)   #=> Calc::C(-227.5+97.5i)
 */
static VALUE
cn_comb(VALUE self, VALUE other)
{
    VALUE result;
    NUMBER *qother, *qresult, *qdiv, *qtmp;
    COMPLEX *cresult, *ctmp1, *ctmp2;
    long n;
    setup_math_error();

    qother = value_to_number(other, 0);
    if (qisfrac(qother)) {
        qfree(qother);
        rb_raise(e_MathError, "non-integer argument to comb");
    }
    if (qisneg(qother)) {
        qfree(qother);
        result = cq_new();
        DATA_PTR(result) = qlink(&_qzero_);
        return result;
    }
    else if (qiszero(qother)) {
        qfree(qother);
        result = cq_new();
        DATA_PTR(result) = qlink(&_qone_);
        return result;
    }
    else if (qisone(qother)) {
        qfree(qother);
        return self;
    }
    else if (CALC_Q_P(self)) {
        qresult = qcomb(DATA_PTR(self), qother);
        qfree(qother);
        if (qresult == NULL) {
            rb_raise(e_MathError, "argument too large for comb");
        }
        result = cq_new();
        DATA_PTR(result) = qresult;
        return result;
    }
    /* if here, self is a Calc::C and qother is integer > 1.  algorithm based
     * on calc's func.c, but only for COMPLEX*. */
    if (zge24b(qother->num)) {
        qfree(qother);
        rb_raise(e_MathError, "argument too large for comb");
    }
    n = qtoi(qother);
    cresult = clink((COMPLEX *) DATA_PTR(self));
    ctmp1 = c_addq((COMPLEX *) DATA_PTR(self), &_qnegone_);
    qdiv = qlink(&_qtwo_);
    n--;
    for (;;) {
        ctmp2 = c_mul(cresult, ctmp1);
        comfree(cresult);
        cresult = c_divq(ctmp2, qdiv);
        comfree(ctmp2);
        if (--n == 0 || ciszero(cresult)) {
            comfree(ctmp1);
            qfree(qdiv);
            result = cc_new();
            DATA_PTR(result) = cresult;
            return result;
        }
        ctmp2 = c_addq(ctmp1, &_qnegone_);
        comfree(ctmp1);
        ctmp1 = ctmp2;
        qtmp = qinc(qdiv);
        qfree(qdiv);
        qdiv = qtmp;
    }
}

/* floor of logarithm to specified integer base
 *
 * x.ilog(b) returns the greatest integer for which b^n <= abs(x)
 *
 * @param base [Integer]
 * @return [Calc::Q]
 * @raise [Calc::MathError] if x is zero, b is non-integer or b is <= 1
 * @example
 *  Calc::Q(2).ilog(3) #=> Calc::Q(0)
 *  Calc::Q(8).ilog(3) #=> Calc::Q(1)
 *  Calc::Q(9).ilog(3) #=> Calc::Q(2)
 */
static VALUE
cn_ilog(VALUE self, VALUE base)
{
    VALUE result;
    NUMBER *qbase, *qresult;
    setup_math_error();

    qbase = value_to_number(base, 0);
    if (qisfrac(qbase) || qiszero(qbase) || qisunit(qbase) || qisneg(qbase)) {
        qfree(qbase);
        rb_raise(e_MathError, "base must be an integer > 1");
    }
    if (CALC_Q_P(self)) {
        qresult = qilog(DATA_PTR(self), qbase->num);
    }
    else if (CALC_C_P(self)) {
        qresult = c_ilog(DATA_PTR(self), qbase->num);
    }
    else {
        rb_raise(rb_eTypeError, "cn_ilog called with invalid receiver");
    }
    qfree(qbase);
    if (!qresult) {
        rb_raise(e_MathError, "invalid argument for ilog");
    }
    result = cq_new();
    DATA_PTR(result) = qresult;
    return result;
}

/* Natural logarithm
 *
 * Note that this is like using ruby's Math.log.
 *
 * @param eps [Numeric,Calc::Q] (optional) calculation accuracy
 * @return [Calc::Q,Calc::C]
 * @raise [Calc::MathError] if self is zero
 * @example
 *  Calc::Q(10).ln    #=> Calc::Q(2.30258509299404568402)
 *  Calc::Q(-10).ln   #=> Calc::C(2.30258509299404568402+3.14159265358979323846i)
 *  Calc::C(0, 10).ln #=> Calc::C(2.30258509299404568402+1.57079632679489661923i)
 */
static VALUE
cn_ln(int argc, VALUE * argv, VALUE self)
{
    return log_function(argc, argv, self, &qln, &c_ln);
}

/* Base 10 logarithm
 *
 * Note that this is like using ruby's Math.log10.
 *
 * @param eps [Numeric,Calc::Q] (optional) calculation accuracy
 * @return [Calc::Q,Calc::C]
 * @raise [Calc::MathError] if self is zero
 * @example
 *  Calc::Q(-1).log     #=> Calc::C(~1.36437635384184134748i)
 *  Calc::Q(10).log     #=> Calc::Q(1)
 *  Calc::Q(100).log    #=> Calc::Q(2)
 *  Calc::Q("1e10").log #=> Calc::Q(10)
 *  Calc::C(0, 10).log  #=> Calc::C(1+~0.68218817692092067374i)
 */
static VALUE
cn_log(int argc, VALUE * argv, VALUE self)
{
    return log_function(argc, argv, self, &qlog, &c_log);
}

/* Compute integer quotient of a value by a real number (integer division)
 *
 * If y is zero, returns zero.
 *
 * @param y [Numeric]
 * @param rnd [Integer] rounding flags, default Calc.config(:quo)
 * @return [Calc::Q,Calc::C]
 * @example
 *  Calc::Q(11,5) #=> Calc::Q(2)
 */
static VALUE
cn_quo(int argc, VALUE * argv, VALUE self)
{
    VALUE y, rnd;
    NUMBER *qy, *qresult;
    COMPLEX *cself, *cresult;
    long r;
    setup_math_error();

    if (rb_scan_args(argc, argv, "11", &y, &rnd) == 2) {
        r = value_to_long(rnd);
    }
    else {
        r = conf->quo;
    }
    qy = value_to_number(y, 1);
    if (qiszero(qy)) {
        qfree(qy);
        rb_raise(rb_eZeroDivError, "division by zero in quo");
    }
    if (CALC_Q_P(self)) {
        qresult = qquo(DATA_PTR(self), qy, r);
        qfree(qy);
        return wrap_number(qresult);
    }
    cself = DATA_PTR(self);
    cresult = comalloc();
    qfree(cresult->real);
    qfree(cresult->imag);
    cresult->real = qquo(cself->real, qy, r);
    cresult->imag = qquo(cself->imag, qy, r);
    qfree(qy);
    return wrap_complex(cresult);
}

/* Root of a number
 *
 * x.root(n) returns the nth root of x.  x can be real or complex, n must be
 * a positive integer.
 *
 * If the nth root of x is a multiple of eps, it will be returned exactly.
 * Otherwise the returned value will be a multiple of eps close to the real
 * nth root of x.
 *
 * @param n [Integer]
 * @param eps [Numeric] optional epsilon, default Calc.config(:epsilon)
 * @return [Calc::Q,Calc::C]
 * @raise [Calc::MathError] if n is not a positive integer
 * @example
 *  Calc::Q(7).root(4)    #=> Calc::Q(1.62657656169778574321)
 *  Calc::Q(-7).root(4)   #=> Calc::C(1.15016331689560300254+1.15016331689560300254i)
 *  Calc::C(7, 7).root(4) #=> Calc::C(1.73971135785495811228+0.34605010474820910752i)
 */
static VALUE
cn_root(int argc, VALUE * argv, VALUE self)
{
    VALUE n, epsilon, result;
    NUMBER *qn, *qepsilon, *qself;
    COMPLEX ctmp;
    setup_math_error();

    if (rb_scan_args(argc, argv, "11", &n, &epsilon) > 1) {
        qepsilon = value_to_number(epsilon, 1);
        if (qiszero(qepsilon)) {
            qfree(qepsilon);
            rb_raise(e_MathError, "zero epsilon for root");
        }
    }
    else {
        qepsilon = qlink(conf->epsilon);
    }
    qn = value_to_number(n, 0);
    if (qisneg(qn) || qiszero(qn) || qisfrac(qn)) {
        qfree(qepsilon);
        qfree(qn);
        rb_raise(e_MathError, "non-positive integer root");
    }
    if (CALC_Q_P(self)) {
        qself = DATA_PTR(self);
        if (!qisneg(qself)) {
            result = wrap_number(qroot(qself, qn, qepsilon));
        }
        else {
            ctmp.real = qself;
            ctmp.imag = &_qzero_;
            ctmp.links = 1;
            result = wrap_complex(c_root(&ctmp, qn, qepsilon));
        }
    }
    else {
        result = wrap_complex(c_root(DATA_PTR(self), qn, qepsilon));
    }
    qfree(qepsilon);
    qfree(qn);
    return result;
}

/* Scale a number by a power of 2
 *
 * x.scale(n) returns the value of 2**n * x.
 *
 * Unlike the << and >> operators, this function works on fractional x.
 *
 * @param n [Integer]
 * @return [Calc::C,Calc::Q]
 * @raise [ArgumentError] if n isn't an integer < 2^31
 * @example
 *  Calc::Q(3).scale(2)    #=> Calc::Q(12)
 *  Calc::Q(3).scale(-2)   #=> Calc::Q(0.75)
 *  Calc::C(3, 3).scale(2) #=> Calc::C(12+12i)
 */
static VALUE
cn_scale(VALUE self, VALUE other)
{
    NUMBER *qother;
    long n;
    setup_math_error();

    qother = value_to_number(other, 0);
    if (qisfrac(qother)) {
        qfree(qother);
        rb_raise(rb_eArgError, "scale by non-integer");
    }
    if (zge31b(qother->num)) {
        qfree(qother);
        rb_raise(rb_eArgError, "scale factor must be < 2^31");
    }
    n = qtoi(qother);
    qfree(qother);
    if (CALC_Q_P(self)) {
        return wrap_number(qscale(DATA_PTR(self), n));
    }
    else {
        return wrap_complex(c_scale(DATA_PTR(self), n));
    }
}

/* Indicates sign of a real or complex number
 *
 * For real x, x.sgn returns
 *   -1 if x < 0
 *    0 if x == 0
 *    1 if x > 0
 *
 * For complex x, x.sgn returns Calc::C(x.re.sgn, x.im.sgn)
 *
 * @return [Calc::C,Calc::Q]
 * @example
 *  Calc::Q(9).sgn     #=> Calc::Q(1)
 *  Calc::Q(0).sgn     #=> Calc::Q(0)
 *  Calc::Q(-9).sgn    #=> Calc::Q(-1)
 *  Calc::C(1, -1).sgn #=> Calc::C(1-1i)
 */
static VALUE
cn_sgn(VALUE self)
{
    COMPLEX *cself, *cresult;
    setup_math_error();

    if (CALC_Q_P(self)) {
        return wrap_number(qsign(DATA_PTR(self)));
    }
    cself = DATA_PTR(self);
    cresult = comalloc();
    qfree(cresult->real);
    qfree(cresult->imag);
    cresult->real = qsign(cself->real);
    cresult->imag = qsign(cself->imag);
    return wrap_complex(cresult);
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
        result = wrap_complex(cresult);
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
    rb_define_method(cNumeric, "<<", cn_shift_left, 1);
    rb_define_method(cNumeric, ">>", cn_shift_right, 1);
    rb_define_method(cNumeric, "cmp", cn_cmp, 1);
    rb_define_method(cNumeric, "comb", cn_comb, 1);
    rb_define_method(cNumeric, "ilog", cn_ilog, 1);
    rb_define_method(cNumeric, "ln", cn_ln, -1);
    rb_define_method(cNumeric, "log", cn_log, -1);
    rb_define_method(cNumeric, "quo", cn_quo, -1);
    rb_define_method(cNumeric, "root", cn_root, -1);
    rb_define_method(cNumeric, "scale", cn_scale, 1);
    rb_define_method(cNumeric, "sgn", cn_sgn, 0);
    rb_define_method(cNumeric, "sqrt", cn_sqrt, -1);
}
