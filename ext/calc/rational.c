#include "calc.h"

VALUE cQ;                       /* Calc::Q class */

/* this global is the default epsilon used for transcendental functions if one
 * is not specified by the caller. */
static NUMBER *cq_default_epsilon;

/*****************************************************************************
 * functions related to memory allocation and object initialization          *
 *****************************************************************************/

void
cq_free(void *p)
{
    qfree((NUMBER *) p);
}

const rb_data_type_t calc_q_type = {
    "Calc::Q",
    {0, cq_free, 0},            /* TODO: 3rd param is optional dsize */
    0, 0
#ifdef RUBY_TYPED_FREE_IMMEDATELY
        , RUBY_TYPED_FREE_IMMEDIATELY   /* flags is in 2.1+ */
#endif
};

/* because the true type of rationals in calc is (NUMBER*), we don't do any
 * additional memory allocation in cq_alloc.  the 'data' elemnt of underlying
 * RTypedData struct is accessed directly via the DATA_PTR macro.
 *
 * DATA_PTR isn't documented, but it is used by some built in ruby ext libs.
 *
 * the data element can be replaced by assining to the DATA_PTR macro.  be
 * careful to free any existing value before replacing (most qmath.c functions
 * actually allocate a new NUMBER and return a pointer to it).
 */

/* no additional allocation beyond normal ruby alloc is required */
static VALUE
cq_alloc(VALUE klass)
{
    return TypedData_Wrap_Struct(klass, &calc_q_type, 0);
}

#define cq_new() cq_alloc(cQ)

static VALUE
cq_initialize(int argc, VALUE * argv, VALUE self)
{
    NUMBER *qself;
    VALUE arg1, arg2;
    ZVALUE znum, zden;
    setup_math_error();

    if (rb_scan_args(argc, argv, "11", &arg1, &arg2) == 1) {
        /* single param */
        qself = value_to_number(arg1, 1);
    }
    else {
        /* 2 params. both can be anything Calc::Z.new would allow */
        zden = value_to_zvalue(arg2, 1);
        if (ziszero(zden)) {
            zfree(zden);
            rb_raise(rb_eZeroDivError, "division by zero");
        }
        znum = value_to_zvalue(arg1, 1);
        qself = zz_to_number(znum, zden);
        zfree(zden);
        zfree(znum);
    }
    DATA_PTR(self) = qself;

    return self;
}

static VALUE
cq_initialize_copy(VALUE obj, VALUE orig)
{
    NUMBER *qorig, *qobj;

    if (obj == orig) {
        return obj;
    }
    if (!ISQVALUE(orig)) {
        rb_raise(rb_eTypeError, "wrong argument type");
    }

    qorig = DATA_PTR(orig);
    qobj = qlink(qorig);
    DATA_PTR(obj) = qobj;

    return obj;
}

/*****************************************************************************
 * private functions used by instance methods                                *
 *****************************************************************************/

static VALUE
numeric_op(VALUE self, VALUE other,
           NUMBER * (*fqq) (NUMBER *, NUMBER *), NUMBER * (*fql) (NUMBER *, long))
{
    NUMBER *qother, *qresult;
    VALUE result;
    setup_math_error();

    if (fql && TYPE(other) == T_FIXNUM) {
        qresult = (*fql) (DATA_PTR(self), NUM2LONG(other));
    }
    else if (ISQVALUE(other)) {
        qresult = (*fqq) (DATA_PTR(self), DATA_PTR(other));
    }
    else if (TYPE(other) == T_FIXNUM || TYPE(other) == T_BIGNUM || TYPE(other) == T_FLOAT
             || TYPE(other) == T_RATIONAL || ISZVALUE(other)) {
        qother = value_to_number(other, 0);
        qresult = (*fqq) (DATA_PTR(self), qother);
        qfree(qother);
    }
    else {
        rb_raise(rb_eArgError, "expected number");
    }

    result = cq_new();
    DATA_PTR(result) = qresult;
    return result;
}

static VALUE
shift(VALUE self, VALUE other, int sign)
{
    NUMBER *qother;
    VALUE result;
    long n;
    setup_math_error();

    qother = value_to_number(other, 0);
    if (qisfrac(qother)) {
        qfree(qother);
        rb_raise(rb_eArgError, "shift by non-integer");
    }
    /* check it will actually fit in a long (otherwise qtoi will be wrong) */
    if (zge31b(qother->num)) {
        qfree(qother);
        rb_raise(rb_eArgError, "shift by too many bits");
    }
    n = qtoi(qother);
    qfree(qother);
    result = cq_new();
    DATA_PTR(result) = qshift(DATA_PTR(self), n * sign);
    return result;
}

static VALUE
trans_function(int argc, VALUE * argv, VALUE self, NUMBER * (*f) (NUMBER *, NUMBER *))
{
    NUMBER *qepsilon;
    VALUE epsilon, result;
    setup_math_error();

    result = cq_new();
    if (rb_scan_args(argc, argv, "01", &epsilon) == 0) {
        DATA_PTR(result) = (*f) (DATA_PTR(self), cq_default_epsilon);
    }
    else {
        qepsilon = value_to_number(epsilon, 0);
        DATA_PTR(result) = (*f) (DATA_PTR(self), qepsilon);
        qfree(qepsilon);
    }
    /* there are a few functions which can return NULL with invalid args
     * instead of calling math_error */
    if (!DATA_PTR(result)) {
        rb_raise(e_MathError, "Transcendental function returned NULL");
    }
    return result;
}

/* same as trans_function(), except for functions where there are 2 NUMBER*
 * arguments, eg atan2.  the first param is the receiver (self). */
static VALUE
trans_function2(int argc, VALUE * argv, VALUE self,
                NUMBER * (*f) (NUMBER *, NUMBER *, NUMBER *))
{
    NUMBER *qarg, *qepsilon;
    VALUE arg, epsilon, result;
    setup_math_error();

    result = cq_new();
    if (rb_scan_args(argc, argv, "11", &arg, &epsilon) == 1) {
        qarg = value_to_number(arg, 0);
        DATA_PTR(result) = (*f) (DATA_PTR(self), qarg, cq_default_epsilon);
        qfree(qarg);
    }
    else {
        qarg = value_to_number(arg, 0);
        qepsilon = value_to_number(epsilon, 0);
        DATA_PTR(result) = (*f) (DATA_PTR(self), qarg, qepsilon);
        qfree(qarg);
        qfree(qepsilon);
    }
    return result;
}

/*****************************************************************************
 * instance method implementations                                           *
 *****************************************************************************/

static VALUE
cq_uplus(VALUE self)
{
    return self;
}

static VALUE
cq_uminus(VALUE self)
{
    VALUE result;
    setup_math_error();

    result = cq_new();
    DATA_PTR(result) = qsub(&_qzero_, DATA_PTR(self));
    return result;
}

static VALUE
cq_add(VALUE self, VALUE other)
{
    /* fourth arg was &qaddi, but this segfaults with ruby 2.1.x */
    return numeric_op(self, other, &qqadd, NULL);
}

static VALUE
cq_subtract(VALUE self, VALUE other)
{
    return numeric_op(self, other, &qsub, NULL);
}

static VALUE
cq_multiply(VALUE self, VALUE other)
{
    return numeric_op(self, other, &qmul, &qmuli);
}

static VALUE
cq_divide(VALUE self, VALUE other)
{
    return numeric_op(self, other, &qqdiv, &qdivi);
}

static VALUE
cq_mod(VALUE self, VALUE other)
{
    NUMBER *qother;
    VALUE result;
    setup_math_error();

    qother = value_to_number(other, 0);
    result = cq_new();
    DATA_PTR(result) = qmod(DATA_PTR(self), qother, 0);
    return result;
}

static VALUE
cq_shift_left(VALUE self, VALUE other)
{
    return shift(self, other, 1);
}

static VALUE
cq_shift_right(VALUE self, VALUE other)
{
    return shift(self, other, -1);
}

/* compares a Calc::Q with another numeric value
 * returns:
 *  0 if values are the same
 *  -1 if self is < other
 *  +1 if self is > other
 *  nil if the other value is not a number
 */
static VALUE
cq_spaceship(VALUE self, VALUE other)
{
    NUMBER *qself, *qother;
    int result;
    setup_math_error();

    qself = DATA_PTR(self);
    if (TYPE(other) == T_FIXNUM) {
        result = qreli(qself, NUM2LONG(other));
    }
    else if (ISQVALUE(other)) {
        result = qrel(qself, DATA_PTR(other));
    }
    else if (TYPE(other) == T_BIGNUM || TYPE(other) == T_FLOAT || TYPE(other) == T_RATIONAL
             || ISZVALUE(other)) {
        qself = DATA_PTR(self);
        qother = value_to_number(other, 0);
        result = qrel(qself, qother);
        qfree(qother);
    }
    else {
        return Qnil;
    }

    return INT2FIX(result);
}

static VALUE
cq_denominator(VALUE self)
{
    VALUE result;
    setup_math_error();

    result = cq_new();
    DATA_PTR(result) = qden(DATA_PTR(self));

    return result;
}

static VALUE
cq_fact(VALUE self)
{
    VALUE result;
    setup_math_error();

    result = cq_new();
    DATA_PTR(result) = qfact(DATA_PTR(self));

    return result;
}

static VALUE
cq_numerator(VALUE self)
{
    VALUE result;
    setup_math_error();

    result = cq_new();
    DATA_PTR(result) = qnum(DATA_PTR(self));

    return result;
}

static VALUE
cq_to_i(VALUE self)
{
    NUMBER *qself;
    ZVALUE ztmp;
    VALUE string, result;
    char *s;
    setup_math_error();

    qself = DATA_PTR(self);
    if (qisint(qself)) {
        zcopy(qself->num, &ztmp);
    }
    else {
        zquo(qself->num, qself->den, &ztmp, 0);
    }
    if (zgtmaxlong(ztmp)) {
        /* too big to fit in a long, ztoi would return MAXLONG.  use a string
         * intermediary */
        math_divertio();
        zprintval(ztmp, 0, 0);
        s = math_getdivertedio();
        string = rb_str_new2(s);
        free(s);
        result = rb_funcall(string, rb_intern("to_i"), 0);
    }
    else {
        result = LONG2NUM(ztoi(ztmp));
    }
    zfree(ztmp);
    return result;
}

static VALUE
cq_to_s(VALUE self)
{
    NUMBER *qself = DATA_PTR(self);
    char *s;
    VALUE rs;
    setup_math_error();

    math_divertio();
    qprintnum(qself, MODE_FRAC);
    s = math_getdivertedio();
    rs = rb_str_new2(s);
    free(s);

    return rs;
}

static VALUE
cq_acos(int argc, VALUE * argv, VALUE self)
{
    return trans_function(argc, argv, self, &qacos);
}

static VALUE
cq_acosh(int argc, VALUE * argv, VALUE self)
{
    return trans_function(argc, argv, self, &qacosh);
}

static VALUE
cq_acot(int argc, VALUE * argv, VALUE self)
{
    return trans_function(argc, argv, self, &qacot);
}

static VALUE
cq_acoth(int argc, VALUE * argv, VALUE self)
{
    return trans_function(argc, argv, self, &qacoth);
}

static VALUE
cq_acsc(int argc, VALUE * argv, VALUE self)
{
    return trans_function(argc, argv, self, &qacsc);
}

static VALUE
cq_acsch(int argc, VALUE * argv, VALUE self)
{
    return trans_function(argc, argv, self, &qacsch);
}

static VALUE
cq_asec(int argc, VALUE * argv, VALUE self)
{
    return trans_function(argc, argv, self, &qasec);
}

static VALUE
cq_asech(int argc, VALUE * argv, VALUE self)
{
    return trans_function(argc, argv, self, &qasech);
}

static VALUE
cq_asin(int argc, VALUE * argv, VALUE self)
{
    return trans_function(argc, argv, self, &qasin);
}

static VALUE
cq_asinh(int argc, VALUE * argv, VALUE self)
{
    return trans_function(argc, argv, self, &qasinh);
}

static VALUE
cq_atan(int argc, VALUE * argv, VALUE self)
{
    return trans_function(argc, argv, self, &qatan);
}

static VALUE
cq_atan2(int argc, VALUE * argv, VALUE self)
{
    return trans_function2(argc, argv, self, &qatan2);
}

static VALUE
cq_atanh(int argc, VALUE * argv, VALUE self)
{
    return trans_function(argc, argv, self, &qatanh);
}

static VALUE
cq_cos(int argc, VALUE * argv, VALUE self)
{
    return trans_function(argc, argv, self, &qcos);
}

static VALUE
cq_cosh(int argc, VALUE * argv, VALUE self)
{
    return trans_function(argc, argv, self, &qcosh);
}

static VALUE
cq_cot(int argc, VALUE * argv, VALUE self)
{
    return trans_function(argc, argv, self, &qcot);
}

static VALUE
cq_coth(int argc, VALUE * argv, VALUE self)
{
    return trans_function(argc, argv, self, &qcoth);
}

static VALUE
cq_csc(int argc, VALUE * argv, VALUE self)
{
    return trans_function(argc, argv, self, &qcsc);
}

static VALUE
cq_csch(int argc, VALUE * argv, VALUE self)
{
    return trans_function(argc, argv, self, &qcsch);
}

static VALUE
cq_exp(int argc, VALUE * argv, VALUE self)
{
    return trans_function(argc, argv, self, &qexp);
}

static VALUE
cq_get_default_epsilon(VALUE klass)
{
    VALUE result;

    result = cq_new();
    DATA_PTR(result) = qlink(cq_default_epsilon);
    return result;
}

static VALUE
cq_ln(int argc, VALUE * argv, VALUE self)
{
    return trans_function(argc, argv, self, &qln);
}

static VALUE
cq_log(int argc, VALUE * argv, VALUE self)
{
    return trans_function(argc, argv, self, &qlog);
}

static VALUE
cq_pi(int argc, VALUE * argv, VALUE self)
{
    NUMBER *qepsilon;
    VALUE epsilon, result;
    setup_math_error();

    result = cq_new();
    if (rb_scan_args(argc, argv, "01", &epsilon) == 0) {
        DATA_PTR(result) = qpi(cq_default_epsilon);
    }
    else {
        qepsilon = value_to_number(epsilon, 0);
        DATA_PTR(result) = qpi(qepsilon);
        qfree(qepsilon);
    }

    return result;
}

static VALUE
cq_power(int argc, VALUE * argv, VALUE self)
{
    return trans_function2(argc, argv, self, &qpower);
}

static VALUE
cq_quomod(VALUE self, VALUE other)
{
    NUMBER *qother, *qquo, *qmod;
    VALUE quo, mod;
    setup_math_error();

    qother = value_to_number(other, 0);
    qquomod(DATA_PTR(self), qother, &qquo, &qmod, 0);
    qfree(qother);
    quo = cq_new();
    mod = cq_new();
    DATA_PTR(quo) = qquo;
    DATA_PTR(mod) = qmod;

    return rb_assoc_new(quo, mod);
}

static VALUE
cq_root(int argc, VALUE * argv, VALUE self)
{
    return trans_function2(argc, argv, self, &qroot);
}

static VALUE
cq_sec(int argc, VALUE * argv, VALUE self)
{
    return trans_function(argc, argv, self, &qsec);
}

static VALUE
cq_sech(int argc, VALUE * argv, VALUE self)
{
    return trans_function(argc, argv, self, &qsech);
}

static VALUE
cq_sin(int argc, VALUE * argv, VALUE self)
{
    return trans_function(argc, argv, self, &qsin);
}

static VALUE
cq_sinh(int argc, VALUE * argv, VALUE self)
{
    return trans_function(argc, argv, self, &qsinh);
}

static VALUE
cq_set_default_epsilon(VALUE klass, VALUE epsilon)
{
    cq_default_epsilon = value_to_number(epsilon, 1);

    return Qnil;
}

static VALUE
cq_tan(int argc, VALUE * argv, VALUE self)
{
    return trans_function(argc, argv, self, &qtan);
}

static VALUE
cq_tanh(int argc, VALUE * argv, VALUE self)
{
    return trans_function(argc, argv, self, &qtanh);
}

static VALUE
cq_iszero(VALUE self)
{
    NUMBER *qself;
    qself = DATA_PTR(self);
    return qiszero(qself) ? Qtrue : Qfalse;
}

/*****************************************************************************
 * class definition, called once from Init_calc when library is loaded       *
 *****************************************************************************/
void
define_calc_q(VALUE m)
{
    cQ = rb_define_class_under(m, "Q", rb_cData);
    rb_define_alloc_func(cQ, cq_alloc);
    rb_define_method(cQ, "initialize", cq_initialize, -1);
    rb_define_method(cQ, "initialize_copy", cq_initialize_copy, 1);

    rb_define_method(cQ, "%", cq_mod, 1);
    rb_define_method(cQ, "*", cq_multiply, 1);
    rb_define_method(cQ, "+", cq_add, 1);
    rb_define_method(cQ, "+@", cq_uplus, 0);
    rb_define_method(cQ, "-", cq_subtract, 1);
    rb_define_method(cQ, "-@", cq_uminus, 0);
    rb_define_method(cQ, "/", cq_divide, 1);
    rb_define_method(cQ, "<<", cq_shift_left, 1);
    rb_define_method(cQ, "<=>", cq_spaceship, 1);
    rb_define_method(cQ, ">>", cq_shift_right, 1);
    rb_define_method(cQ, "acos", cq_acos, -1);
    rb_define_method(cQ, "acosh", cq_acosh, -1);
    rb_define_method(cQ, "acot", cq_acot, -1);
    rb_define_method(cQ, "acoth", cq_acoth, -1);
    rb_define_method(cQ, "acsc", cq_acsc, -1);
    rb_define_method(cQ, "acsch", cq_acsch, -1);
    rb_define_method(cQ, "asec", cq_asec, -1);
    rb_define_method(cQ, "asech", cq_asech, -1);
    rb_define_method(cQ, "asin", cq_asin, -1);
    rb_define_method(cQ, "asinh", cq_asinh, -1);
    rb_define_method(cQ, "atan", cq_atan, -1);
    rb_define_method(cQ, "atan2", cq_atan2, -1);
    rb_define_method(cQ, "atanh", cq_atanh, -1);
    rb_define_method(cQ, "cos", cq_cos, -1);
    rb_define_method(cQ, "cosh", cq_cosh, -1);
    rb_define_method(cQ, "cot", cq_cot, -1);
    rb_define_method(cQ, "coth", cq_coth, -1);
    rb_define_method(cQ, "csc", cq_csc, -1);
    rb_define_method(cQ, "csch", cq_csch, -1);
    rb_define_method(cQ, "denominator", cq_denominator, 0);
    rb_define_method(cQ, "exp", cq_exp, -1);
    rb_define_method(cQ, "fact", cq_fact, 0);
    rb_define_method(cQ, "ln", cq_ln, -1);
    rb_define_method(cQ, "log", cq_log, -1);
    rb_define_method(cQ, "numerator", cq_numerator, 0);
    rb_define_method(cQ, "power", cq_power, -1);
    rb_define_method(cQ, "quomod", cq_quomod, 1);
    rb_define_method(cQ, "root", cq_root, -1);
    rb_define_method(cQ, "sec", cq_sec, -1);
    rb_define_method(cQ, "sech", cq_sech, -1);
    rb_define_method(cQ, "sin", cq_sin, -1);
    rb_define_method(cQ, "sinh", cq_sinh, -1);
    rb_define_method(cQ, "tan", cq_tan, -1);
    rb_define_method(cQ, "tanh", cq_tanh, -1);
    rb_define_method(cQ, "to_i", cq_to_i, 0);
    rb_define_method(cQ, "to_s", cq_to_s, 0);
    rb_define_method(cQ, "zero?", cq_iszero, 0);
    rb_define_module_function(cQ, "get_default_epsilon", cq_get_default_epsilon, 0);
    rb_define_module_function(cQ, "pi", cq_pi, -1);
    rb_define_module_function(cQ, "set_default_epsilon", cq_set_default_epsilon, 1);

    /* include Comparable */
    rb_include_module(cQ, rb_mComparable);

    rb_define_alias(cQ, "divmod", "quomod");
    rb_define_alias(cQ, "modulo", "%");

    /* default epsilon is 1e-20 */
    cq_default_epsilon = str2q((char *) "0.00000000000000000001");
}
