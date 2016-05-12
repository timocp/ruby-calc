#include "calc.h"

/* Document-class: Calc::C
 *
 * Calc complex number.
 *
 * A complex number consists of a real and an imaginary part, both of which
 * are Calc::Q objects.
 *
 * Wraps the libcalc C type `COMPLEX*`.
 */
VALUE cC;

void
cc_free(void *p)
{
    comfree((COMPLEX *) p);
}

const rb_data_type_t calc_c_type = {
    "Calc::C",
    {0, cc_free, 0},
    0, 0
#ifdef RUBY_TYPED_FREE_IMMEDIATELY
        , RUBY_TYPED_FREE_IMMEDIATELY
#endif
};

VALUE
cc_alloc(VALUE klass)
{
    return TypedData_Wrap_Struct(klass, &calc_c_type, 0);
}

/* Creates a new complex number.
 *
 * If a single param of type Complex or Calc::C, returns a new complex number
 * with the same real and imaginary parts.
 *
 * If a single param of other numeric types (Fixnum, Bignum, Rational, Float,
 * Calc::Q), returns a complex number with the specified real part and zero
 * imaginary part.
 *
 * If two params, returns a complex number with the specified real and
 * imaginary parts; the parts can be any type allowed by Calc::Q.new.
 */
static VALUE
cc_initialize(int argc, VALUE * argv, VALUE self)
{
    COMPLEX *cself;
    NUMBER *qre, *qim;
    VALUE re, im;
    setup_math_error();

    if (rb_scan_args(argc, argv, "11", &re, &im) == 1) {
        if (CALC_C_P(re)) {
            cself = clink((COMPLEX *) DATA_PTR(re));
        }
        else if (TYPE(re) == T_COMPLEX) {
            cself = value_to_complex(re);
        }
        else {
            qre = value_to_number(re, 1);
            cself = qqtoc(qre, &_qzero_);
            qfree(qre);
        }
    }
    else {
        qre = value_to_number(re, 1);
        qim = value_to_number(im, 1);
        cself = qqtoc(qre, qim);
        qfree(qre);
        qfree(qim);
    }
    DATA_PTR(self) = cself;

    return self;
}

static VALUE
cc_initialize_copy(VALUE obj, VALUE orig)
{
    COMPLEX *corig;

    if (obj == orig) {
        return obj;
    }
    if (!CALC_C_P(orig)) {
        rb_raise(rb_eTypeError, "wrong argument type");
    }
    corig = DATA_PTR(orig);
    DATA_PTR(obj) = clink(corig);
    return obj;
}

static VALUE
numeric_op(VALUE self, VALUE other,
           COMPLEX * (fcc) (COMPLEX *, COMPLEX *), COMPLEX * (fcq) (COMPLEX *, NUMBER *))
{
    COMPLEX *cresult, *cother;
    setup_math_error();

    if (CALC_C_P(other)) {
        cresult = (*fcc) (DATA_PTR(self), DATA_PTR(other));
    }
    else if (fcq && CALC_Q_P(other)) {
        cresult = (*fcq) (DATA_PTR(self), DATA_PTR(other));
    }
    else {
        cother = value_to_complex(other);
        cresult = (*fcc) (DATA_PTR(self), cother);
        comfree(cother);
    }
    return complex_to_value(cresult);
}

static VALUE
trans_function(int argc, VALUE * argv, VALUE self, COMPLEX * (*f) (COMPLEX *, NUMBER *))
{
    VALUE result, epsilon;
    COMPLEX *cresult;
    NUMBER *qepsilon;
    setup_math_error();

    if (rb_scan_args(argc, argv, "01", &epsilon) == 0) {
        cresult = (*f) (DATA_PTR(self), conf->epsilon);
    }
    else {
        qepsilon = value_to_number(epsilon, 1);
        cresult = (*f) (DATA_PTR(self), qepsilon);
        qfree(qepsilon);
    }
    if (!cresult) {
        rb_raise(e_MathError, "Complex transcendental function returned NULL");
    }
    result = complex_to_value(cresult);
    return result;
}

static VALUE
trans_function2(int argc, VALUE * argv, VALUE self,
                COMPLEX * (f) (COMPLEX *, COMPLEX *, NUMBER *))
{
    VALUE arg, epsilon;
    COMPLEX *carg, *cresult;
    NUMBER *qepsilon;
    setup_math_error();

    if (rb_scan_args(argc, argv, "11", &arg, &epsilon) == 1) {
        carg = value_to_complex(arg);
        cresult = (*f) (DATA_PTR(self), carg, conf->epsilon);
        comfree(carg);
    }
    else {
        carg = value_to_complex(arg);
        qepsilon = value_to_number(epsilon, 1);
        cresult = (*f) (DATA_PTR(self), carg, qepsilon);
        qfree(qepsilon);
        comfree(carg);
    }
    if (!cresult) {
        rb_raise(e_MathError, "Complex transcendental function returned NULL");
    }
    return complex_to_value(cresult);
}

/*****************************************************************************
 * instance method implementations                                           *
 *****************************************************************************/

/* Performs complex multiplication.
 *
 * @param y [Numeric,Numeric::Calc]
 * @return [Calc::C]
 * @example
 *  Calc::C(1,1) * Calc::C(1,1) #=> Calc::C(2i)
 */
static VALUE
cc_multiply(VALUE x, VALUE y)
{
    return numeric_op(x, y, &c_mul, &c_mulq);
}

/* Performs complex addition.
 *
 * @param y [Numeric,Numeric::Calc]
 * @return [Calc::C]
 * @example
 *  Calc::C(1,1) + Calc::C(2,-2) #=> Calc::C(3-1i)
 */
static VALUE
cc_add(VALUE x, VALUE y)
{
    return numeric_op(x, y, &c_add, &c_addq);
}

/* Performs complex subtraction.
 *
 * @param y [Numeric,Numeric::Calc]
 * @return [Calc::C]
 * @example
 *  Calc::C(1,1) - Calc::C(2,2) #=> Calc::C(-1-1i)
 */
static VALUE
cc_subtract(VALUE x, VALUE y)
{
    return numeric_op(x, y, &c_sub, &c_subq);
}

/* Unary minus.  Returns the receiver's value, negated.
 *
 * @return [Calc::C]
 * @example
 *  -Calc::C(1,-1) #=> Calc::C(-1,1)
 */
static VALUE
cc_uminus(VALUE self)
{
    setup_math_error();
    return complex_to_value(c_sub(&_czero_, DATA_PTR(self)));
}

/* Performs complex division.
 *
 * @param y [Numeric,Numeric::Calc]
 * @return [Calc::C]
 * @example
 *  Calc::C(1,1) / Calc::C(0,1) #=> Calc::C(1-1i)
 */
static VALUE
cc_divide(VALUE x, VALUE y)
{
    return numeric_op(x, y, &c_div, &c_divq);
}

/* Test for equality.
 *
 * If the other value is complex (Calc::C or Complex), returns true if the
 * real an imaginary parts of both numbers are the same.
 *
 * The other value is some other numberic type (Fixnum, Bignum, Calc::Q,
 * Rational or Float) then returns true if the complex part of this number is
 * zero and the real part is equal to the other.
 *
 * For any other type, returns false.
 *
 * @return [Boolean]
 * @example
 *  Calc::C(1,2) == Complex(1,2) #=> true
 *  Calc::C(1,2) == Calc::C(1,2) #=> true
 *  Calc::C(4,0) == 4            #=> true
 *  Calc::C(4,1) == 4            #=> false
 */
static VALUE
cc_equal(VALUE self, VALUE other)
{
    COMPLEX *cself, *cother;
    int result;
    setup_math_error();

    cself = DATA_PTR(self);
    if (CALC_C_P(other)) {
        result = !c_cmp(cself, DATA_PTR(other));
    }
    else if (TYPE(other) == T_COMPLEX) {
        cother = value_to_complex(other);
        result = !c_cmp(cself, cother);
        comfree(cother);
    }
    else if (TYPE(other) == T_FIXNUM || TYPE(other) == T_BIGNUM || TYPE(other) == T_RATIONAL ||
             TYPE(other) == T_FLOAT || CALC_Q_P(other)) {
        cother = qqtoc(value_to_number(other, 0), &_qzero_);
        result = !c_cmp(cself, cother);
        comfree(cother);
    }
    else {
        return Qfalse;
    }

    return result ? Qtrue : Qfalse;
}

/* Inverse trigonometric cosine
 *
 * @param eps [Calc::Q] (optional) calculation accuracy
 * @return [Calc::C]
 * @example
 *  Calc::C(2,3).acos #=> Calc::C(1.00014354247379721852-1.98338702991653543235i)
 */
static VALUE
cc_acos(int argc, VALUE * argv, VALUE self)
{
    return trans_function(argc, argv, self, &c_acos);
}

/* Inverse hyperbolic cosine
 *
 * @param eps [Calc::Q] (optional) calculation accuracy
 * @return [Calc::C]
 * @example
 *  Calc::C(2,3).acosh #=> Calc::C(1.98338702991653543235+1.00014354247379721852i)
 */
static VALUE
cc_acosh(int argc, VALUE * argv, VALUE self)
{
    return trans_function(argc, argv, self, &c_acosh);
}

/* Inverse trigonometric cotangent
 *
 * @param eps [Calc::Q] (optional) calculation accuracy
 * @return [Calc::C]
 * @example
 *  Calc::C(2,3).acot #=> Calc::C(0.1608752771983210967-~0.22907268296853876630i)
 */
static VALUE
cc_acot(int argc, VALUE * argv, VALUE self)
{
    return trans_function(argc, argv, self, &c_acot);
}

/* Inverse hyperbolic cotangent
 *
 * @param eps [Calc::Q] (optional) calculation accuracy
 * @return [Calc::C]
 * @example
 *  Calc::C(2,3).acoth #=> Calc::C(~0.14694666622552975204-~0.23182380450040305810i)
 */
static VALUE
cc_acoth(int argc, VALUE * argv, VALUE self)
{
    return trans_function(argc, argv, self, &c_acoth);
}

/* Inverse trigonometric cosecant
 *
 * @param eps [Calc::Q] (optional) calculation accuracy
 * @return [Calc::C]
 * @example
 *  Calc::C(2,3).acsc #=> Calc::C(0.15038560432786196325-0.23133469857397331455i)
 */
static VALUE
cc_acsc(int argc, VALUE * argv, VALUE self)
{
    return trans_function(argc, argv, self, &c_acsc);
}

/* Inverse hyperbolic cosecant
 *
 * @param eps [Calc::Q] (optional) calculation accuracy
 * @return [Calc::C]
 * @example
 *  Calc::C(2,3).acsch #=> Calc::C(0.15735549884498542878-0.22996290237720785451i)
 */
static VALUE
cc_acsch(int argc, VALUE * argv, VALUE self)
{
    return trans_function(argc, argv, self, &c_acsch);
}

/* Inverse gudermannian function
 *
 * @param eps [Calc::Q] (optional) calculation accuracy
 * @return [Calc::C]
 * @example
 *  Calc::C(1,2).agd #=> Calc::C(0.22751065843194319695+1.422911462459226797i)
 */
static VALUE
cc_agd(int argc, VALUE * argv, VALUE self)
{
    return trans_function(argc, argv, self, &c_agd);
}

/* Inverse trigonometric secant
 *
 * @param eps [Calc::Q] (optional) calculation accuracy
 * @return [Calc::C]
 * @example
 *  Calc::C(2,3).asec #=> Calc::C(1.42041072246703465598+0.23133469857397331455i)
 */
static VALUE
cc_asec(int argc, VALUE * argv, VALUE self)
{
    return trans_function(argc, argv, self, &c_asec);
}

/* Inverse hyperbolic secant
 *
 * @param eps [Calc::Q] (optional) calculation accuracy
 * @return [Calc::C]
 * @example
 *  Calc::C(2,3).asech #=> Calc::C(0.23133469857397331455-1.42041072246703465598i)
 */
static VALUE
cc_asech(int argc, VALUE * argv, VALUE self)
{
    return trans_function(argc, argv, self, &c_asech);
}

/* Inverse trigonometric sine
 *
 * @param eps [Calc::Q] (optional) calculation accuracy
 * @return [Calc::C]
 * @example
 *  Calc::C(2,3).asin #=> Calc::C(0.57065278432109940071+1.98338702991653543235i)
 */
static VALUE
cc_asin(int argc, VALUE * argv, VALUE self)
{
    return trans_function(argc, argv, self, &c_asin);
}

/* Inverse hyperbolic sine
 *
 * @param eps [Calc::Q] (optional) calculation accuracy
 * @return [Calc::C]
 * @example
 *  Calc::C(2,3).asinh #=> Calc::C(1.96863792579309629179+0.96465850440760279204i
 */
static VALUE
cc_asinh(int argc, VALUE * argv, VALUE self)
{
    return trans_function(argc, argv, self, &c_asinh);
}

/* Inverse trigonometric tangent
 *
 * @param eps [Calc::Q] (optional) calculation accuracy
 * @return [Calc::C]
 * @example
 *  Calc::C(2,3).atan #=> Calc::C(1.40992104959657552253+~0.22907268296853876630i)
 */
static VALUE
cc_atan(int argc, VALUE * argv, VALUE self)
{
    return trans_function(argc, argv, self, &c_atan);
}

/* Inverse hyperbolic tangent
 *
 * @param eps [Calc::Q] (optional) calculation accuracy
 * @return [Calc::C]
 * @example
 *  Calc::C(2,3).atanh #=> Calc::C(~0.14694666622552975204+~1.33897252229449356112i)
 */
static VALUE
cc_atanh(int argc, VALUE * argv, VALUE self)
{
    return trans_function(argc, argv, self, &c_atanh);
}

/* Cosine
 *
 * @param eps [Calc::Q] (optional) calculation accuracy
 * @return [Calc::C]
 * @example
 *  Calc::C(2,3).cos #=> Calc::C(-4.18962569096880723013-9.10922789375533659798i)
 */
static VALUE
cc_cos(int argc, VALUE * argv, VALUE self)
{
    return trans_function(argc, argv, self, &c_cos);
}

/* Hyperbolic cosine
 *
 * @param eps [Calc::Q] (optional) calculation accuracy
 * @return [Calc::C]
 * @example
 *  Calc::C(2,3).cosh #=> Calc::C(~-3.72454550491532256548+~0.51182256998738460884i)
 */
static VALUE
cc_cosh(int argc, VALUE * argv, VALUE self)
{
    return trans_function(argc, argv, self, &c_cosh);
}

/* Returns true if the number is real and even
 *
 * @return [Boolean]
 * @example
 *  Calc::C(2,0).even? #=> true
 *  Calc::C(2,2).even? #=> false
 */
static VALUE
cc_evenp(VALUE self)
{
    /* note that macro ciseven() doesn't match calc's actual behaviour */
    COMPLEX *cself = DATA_PTR(self);
    if (cisreal(cself) && qiseven(cself->real)) {
        return Qtrue;
    }
    return Qfalse;
}

/* Exponential function
 *
 * @param eps [Numeric] (optional) calculation accuracy
 * @return [Calc::C]
 * @example
 *  Calc::C(1,2).exp #=> Calc::C(-1.13120438375681363843+2.47172667200481892762i)
 */
static VALUE
cc_exp(int argc, VALUE * argv, VALUE self)
{
    return trans_function(argc, argv, self, &c_exp);
}

/* Return the fractional part of self
 *
 * @return [Calc::C]
 * @example
 *  Calc::C("2.15", "-3.25").frac #=> Calc::C(0.15-0.25i)
 */
static VALUE
cc_frac(VALUE self)
{
    setup_math_error();
    return complex_to_value(c_frac(DATA_PTR(self)));
}

/* Gudermannian function
 *
 * @param eps [Calc::Q] (optional) calculation accuracy
 * @return [Calc::C]
 * @example
 */
static VALUE
cc_gd(int argc, VALUE * argv, VALUE self)
{
    return trans_function(argc, argv, self, &c_gd);
}

/* Returns the imaginary part of a complex number
 *
 * @return [Calc::Q]
 * @example
 *  Calc::C(1,2).im #=> Calc::Q(2)
 */
static VALUE
cc_im(VALUE self)
{
    VALUE result;
    COMPLEX *cself;
    setup_math_error();

    cself = DATA_PTR(self);
    result = cq_new();
    DATA_PTR(result) = qlink(cself->imag);
    return result;
}

/* Returns true if the number is imaginary (ie, has zero real part and non-zero
 * imaginary part)
 *
 * @return [Boolean]
 * @example
 *  Calc::C(0,1).imag? #=> true
 *  Calc::C(1,1).imag? #=> false
 */
static VALUE
cc_imagp(VALUE self)
{
    return cisimag((COMPLEX *) DATA_PTR(self)) ? Qtrue : Qfalse;
}

/* Inverse of a complex number
 *
 * @return [Calc::C]
 * @raise [Calc::MathError] if self is zero
 * @example
 *  Calc::C(2+2i).inverse #=> Calc::C(0.25-0.25i)
 */
static VALUE
cc_inverse(VALUE self)
{
    setup_math_error();
    return complex_to_value(c_inv(DATA_PTR(self)));
}

/* Returns true if the number is real and odd
 *
 * @return [Boolean]
 * @example
 *  Calc::C(1,0).odd? #=> true
 *  Calc::C(1,1).odd? #=> false
 */
static VALUE
cc_oddp(VALUE self)
{
    /* note that macro cisodd() doesn't match calc's actual behaviour */
    COMPLEX *cself = DATA_PTR(self);
    if (cisreal(cself) && qisodd(cself->real)) {
        return Qtrue;
    }
    return Qfalse;
}

/* Raise to a specified power
 *
 * @param y [Numeric,Numeric::Calc]
 * @param eps [Numeric,Calc::Q] (optional) calculation accuracy
 * @return [Calc::C]
 * @example
 *  Calc::C(1,1) ** 2 #=> Calc::C(2i)
 */
static VALUE
cc_power(int argc, VALUE * argv, VALUE self)
{
    /* todo: if y is integer, converting to NUMBER* and using c_powi might
     * be faster */
    return trans_function2(argc, argv, self, &c_power);
}

/* Returns the real part of a complex number
 *
 * @return [Calc::Q]
 * @example
 *  Calc::C(1,2).re #=> Calc::Q(1)
 */
static VALUE
cc_re(VALUE self)
{
    VALUE result;
    COMPLEX *cself;
    setup_math_error();

    cself = DATA_PTR(self);
    result = cq_new();
    DATA_PTR(result) = qlink(cself->real);
    return result;
}

/* Returns true if the number is real (ie, has zero imaginary part)
 *
 * @return [Boolean]
 * @example
 *  Calc::C(1,1).real? #=> false
 *  Calc::C(1,0).real? #=> true
 */
static VALUE
cc_realp(VALUE self)
{
    return cisreal((COMPLEX *) DATA_PTR(self)) ? Qtrue : Qfalse;
}

/* Trigonometric sine
 *
 * @param eps [Calc::Q] (optional) calculation accuracy
 * @return [Calc::C]
 * @example
 *  Calc::C(2,3).sin #=> Calc::C(9.15449914691142957347-4.16890695996656435076i)
 */
static VALUE
cc_sin(int argc, VALUE * argv, VALUE self)
{
    return trans_function(argc, argv, self, &c_sin);
}

/* Hyperbolic sine
 *
 * @param eps [Calc::Q] (optional) calculation accuracy
 * @return [Calc::C]
 * @example
 *  Calc::C(2,3).acos #=> 
 */
static VALUE
cc_sinh(int argc, VALUE * argv, VALUE self)
{
    return trans_function(argc, argv, self, &c_sinh);
}

/* class initialization */

void
define_calc_c(VALUE m)
{
    cC = rb_define_class_under(m, "C", cNumeric);
    rb_define_alloc_func(cC, cc_alloc);
    rb_define_method(cC, "initialize", cc_initialize, -1);
    rb_define_method(cC, "initialize_copy", cc_initialize_copy, 1);

    rb_define_method(cC, "*", cc_multiply, 1);
    rb_define_method(cC, "+", cc_add, 1);
    rb_define_method(cC, "-", cc_subtract, 1);
    rb_define_method(cC, "-@", cc_uminus, 0);
    rb_define_method(cC, "/", cc_divide, 1);
    rb_define_method(cC, "==", cc_equal, 1);
    rb_define_method(cC, "acos", cc_acos, -1);
    rb_define_method(cC, "acosh", cc_acosh, -1);
    rb_define_method(cC, "acot", cc_acot, -1);
    rb_define_method(cC, "acoth", cc_acoth, -1);
    rb_define_method(cC, "acsc", cc_acsc, -1);
    rb_define_method(cC, "acsch", cc_acsch, -1);
    rb_define_method(cC, "agd", cc_agd, -1);
    rb_define_method(cC, "asec", cc_asec, -1);
    rb_define_method(cC, "asech", cc_asech, -1);
    rb_define_method(cC, "asin", cc_asin, -1);
    rb_define_method(cC, "asinh", cc_asinh, -1);
    rb_define_method(cC, "atan", cc_atan, -1);
    rb_define_method(cC, "atanh", cc_atanh, -1);
    rb_define_method(cC, "cos", cc_cos, -1);
    rb_define_method(cC, "cosh", cc_cosh, -1);
    rb_define_method(cC, "even?", cc_evenp, 0);
    rb_define_method(cC, "exp", cc_exp, -1);
    rb_define_method(cC, "frac", cc_frac, 0);
    rb_define_method(cC, "gd", cc_gd, -1);
    rb_define_method(cC, "im", cc_im, 0);
    rb_define_method(cC, "imag?", cc_imagp, 0);
    rb_define_method(cC, "inverse", cc_inverse, 0);
    rb_define_method(cC, "odd?", cc_oddp, 0);
    rb_define_method(cC, "power", cc_power, -1);
    rb_define_method(cC, "re", cc_re, 0);
    rb_define_method(cC, "real?", cc_realp, 0);
    rb_define_method(cC, "sin", cc_sin, -1);
    rb_define_method(cC, "sinh", cc_sinh, -1);

    rb_define_alias(cC, "**", "power");
    rb_define_alias(cC, "imag", "im");
    rb_define_alias(cC, "real", "re");
}
