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
 */
static VALUE
cc_initialize(int argc, VALUE * argv, VALUE self)
{
    COMPLEX *cself;
    NUMBER *qre, *qim;
    VALUE re, im;
    setup_math_error();

    if (rb_scan_args(argc, argv, "11", &re, &im) == 1) {
        qre = value_to_number(re, 1);
        cself = qqtoc(qre, &_qzero_);
        qfree(qre);
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
    if (!ISCVALUE(orig)) {
        rb_raise(rb_eTypeError, "wrong argument type");
    }
    corig = DATA_PTR(orig);
    DATA_PTR(obj) = clink(corig);
    return obj;
}

/* Test for equality.
 *
 * If the other value is complex (Calc::C or Complex), returns true if the
 * real an imaginary parts of both numbers are the same.
 *
 * The other value is some other numberic type (Fixnum, Bignum, Calc::Q, Calc::Z,
 * Rational or Float) then retusn true if the complex part of this number is
 * zero and the real part is equal to the other.
 *
 * Otherwise returns false.
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
    if (ISCVALUE(other)) {
        result = !c_cmp(cself, DATA_PTR(other));
    }
    else if (TYPE(other) == T_COMPLEX) {
        cother = value_to_complex(other);
        result = !c_cmp(cself, cother);
        comfree(cother);
    }
    else {
        return Qfalse;
    }

    return result ? Qtrue : Qfalse;
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

/* class initialization */

void
define_calc_c(VALUE m)
{
    cC = rb_define_class_under(m, "C", rb_cData);
    rb_define_alloc_func(cC, cc_alloc);
    rb_define_method(cC, "initialize", cc_initialize, -1);
    rb_define_method(cC, "initialize_copy", cc_initialize_copy, 1);

    rb_define_method(cC, "==", cc_equal, 1);
    rb_define_method(cC, "im", cc_im, 0);
    rb_define_method(cC, "re", cc_re, 0);

    rb_define_alias(cC, "imag", "im");
    rb_define_alias(cC, "real", "re");
}
