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
    ZVALUE znum, zden, z_gcd, zignored;

    if (rb_scan_args(argc, argv, "11", &arg1, &arg2) == 1) {
        /* single param */
        qself = value_to_number(arg1, 1);
    }
    else {
        /* 2 params. both can be anything Calc::Z.new would allow */
        zden = value_to_zvalue(arg2, 1);
        if (ziszero(zden)) {
            rb_raise(rb_eZeroDivError, "division by zero");
        }
        znum = value_to_zvalue(arg1, 1);
        zgcd(znum, zden, &z_gcd);
        qself = qalloc();
        if (zisone(z_gcd)) {
            qself->num = znum;
            qself->den = zden;
        }
        else {
            /* divide both by common greatest divisor */
            zdiv(znum, z_gcd, &qself->num, &zignored, 0);
            zfree(znum);
            zfree(zignored);
            zdiv(zden, z_gcd, &qself->den, &zignored, 0);
            zfree(zden);
            zfree(zignored);
        }
        /* make sure sign is in numerator */
        /* sign: 1 is negative, 0 is positive (is this actually safe to do?) */
        if (zispos(qself->num) && zisneg(qself->den)) {
            /* only denominator negative - swap them */
            qself->num.sign = 1;
            qself->den.sign = 0;
        }
        else if (zisneg(qself->num) && zisneg(qself->den)) {
            /* both negative - make both positive */
            qself->num.sign = 0;
            qself->den.sign = 0;
        }
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

/* compares a Calc::Q with another numeric value
 * returns:
 *  0 if values are the same
 *  -1 if self is < other
 *  +1 if self is > other
 *  -2 if 'other' is not a number
 *XXX qcmp and qrel
 */
static int
compare(VALUE self, VALUE other)
{
    NUMBER *qself, *qother;
    ZVALUE *zother;
    int result;

    qself = DATA_PTR(self);
    if (TYPE(other) == T_FIXNUM || TYPE(other) == T_BIGNUM) {
        result = qreli(qself, NUM2LONG(other));
    }
    else if (ISZVALUE(other)) {
        /* if it is a small ZVALUE, convert it to a long and use qreli.
         * otherwise make a new NUMBER. */
        get_zvalue(other, zother);
        if (zgtmaxlong(*zother)) {
            /* TODO too big for long, convert to a NUMBER */
            rb_notimplement();
        }
        else {
            result = qreli(qself, ztolong(*zother));
        }
    }
    else if (TYPE(other) == T_RATIONAL) {
        qother = iitoq(NUM2LONG(rb_funcall(other, rb_intern("numerator"), 0)),
                       NUM2LONG(rb_funcall(other, rb_intern("denominator"), 0)));
        result = qrel(qself, qother);
        qfree(qother);
    }
    else if (ISQVALUE(other)) {
        result = qrel(qself, DATA_PTR(other));
    }
    else {
        result = -2;
    }

    return result;
}

static int
compare_check_arg(VALUE self, VALUE other)
{
    int result = compare(self, other);
    if (result == -2) {
        rb_raise(rb_eArgError, "comparison of Calc::Q to non-numeric failed");
    }
    return result;
}

static VALUE
numeric_op(VALUE self, VALUE other,
           NUMBER * (*fqq) (NUMBER *, NUMBER *), NUMBER * (*fql) (NUMBER *, long))
{
    NUMBER *qself, *qresult, *qtmp;
    ZVALUE *zother;
    VALUE result;

    qself = DATA_PTR(self);
    if (TYPE(other) == T_FIXNUM || TYPE(other) == T_BIGNUM) {
        if (fql) {
            qresult = (*fql) (qself, NUM2LONG(other));
        }
        else {
            qtmp = itoq(NUM2LONG(other));
            qresult = (*fqq) (qself, qtmp);
            qfree(qtmp);
        }
    }
    else if (ISZVALUE(other)) {
        get_zvalue(other, zother);
        qtmp = qalloc();
        zcopy(*zother, &qtmp->num);
        qresult = (*fqq) (qself, qtmp);
        qfree(qtmp);
    }
    else if (ISQVALUE(other)) {
        qresult = (*fqq) (qself, DATA_PTR(other));
    }
    else if (TYPE(other) == T_RATIONAL) {
        qtmp = iitoq(NUM2LONG(rb_funcall(other, rb_intern("numerator"), 0)),
                     NUM2LONG(rb_funcall(other, rb_intern("denominator"), 0)));
        qresult = (*fqq) (qself, qtmp);
        qfree(qtmp);
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
    NUMBER *qself, *qother;
    ZVALUE *zother;
    VALUE result;
    long n;

    qself = DATA_PTR(self);
    if (TYPE(other) == T_FIXNUM || TYPE(other) == T_BIGNUM) {
        n = NUM2LONG(other);
    }
    else if (ISZVALUE(other)) {
        get_zvalue(other, zother);
        n = ztoi(*zother);
    }
    else if (ISQVALUE(other)) {
        qother = DATA_PTR(other);
        if (!qisint(qother)) {
            rb_raise(rb_eArgError, "shift by non-integer");
        }
        n = ztoi(qother->num);
    }
    else if (TYPE(other) == T_RATIONAL) {
        n = NUM2LONG(rb_funcall(other, rb_intern("denominator"), 0));
        if (n != 1) {
            rb_raise(rb_eArgError, "shift by non-integer");
        }
        n = NUM2LONG(rb_funcall(other, rb_intern("numerator"), 0));
    }
    else {
        rb_raise(rb_eArgError, "integer number expected");
    }

    result = cq_new();
    DATA_PTR(result) = qshift(qself, n * sign);
    return result;
}

static VALUE
trig_function(int argc, VALUE * argv, VALUE self, NUMBER * (*f) (NUMBER *, NUMBER *))
{
    NUMBER *qepsilon, *qnumber;
    VALUE number, epsilon, result;
    int epsilon_given;

    result = cq_new();
    if (rb_scan_args(argc, argv, "11", &number, &epsilon) == 1) {
        epsilon_given = 0;
    }
    else {
        epsilon_given = 1;
        qepsilon = value_to_number(epsilon, 0);
    }
    qnumber = value_to_number(number, 0);
    if (epsilon_given) {
        qepsilon = value_to_number(epsilon, 0);
    }
    DATA_PTR(result) = (*f) (qnumber, epsilon_given ? qepsilon : cq_default_epsilon);
    qfree(qnumber);
    if (epsilon_given) {
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
cq_power(VALUE self, VALUE other)
{
    return numeric_op(self, other, &qpowi, NULL);
}

static VALUE
cq_divide(VALUE self, VALUE other)
{
    return numeric_op(self, other, &qqdiv, &qdivi);
}

static VALUE
cq_mod(VALUE self, VALUE other)
{
    NUMBER *qself, *qother;
    ZVALUE *zother;
    VALUE result;

    qself = DATA_PTR(self);
    result = cq_new();
    if (TYPE(other) == T_FIXNUM || TYPE(other) == T_BIGNUM) {
        qother = itoq(NUM2LONG(other));
        DATA_PTR(result) = qmod(qself, qother, 0);
        qfree(qother);
    }
    else if (ISZVALUE(other)) {
        get_zvalue(other, zother);
        qother = qalloc();
        zcopy(*zother, &qother->num);
        DATA_PTR(result) = qmod(qself, qother, 0);
        qfree(qother);
    }
    else if (ISQVALUE(other)) {
        DATA_PTR(result) = qmod(qself, DATA_PTR(other), 0);
    }
    else if (TYPE(other) == T_RATIONAL) {
        qother = iitoq(NUM2LONG(rb_funcall(other, rb_intern("numerator"), 0)),
                       NUM2LONG(rb_funcall(other, rb_intern("denominator"), 0)));
        DATA_PTR(result) = qmod(qself, qother, 0);
        qfree(qother);
    }
    else {
        rb_raise(rb_eArgError, "number expected");
    }

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

static VALUE
cq_equal(VALUE self, VALUE other)
{
    return compare(self, other) == 0 ? Qtrue : Qfalse;
}

static VALUE
cq_comparison(VALUE self, VALUE other)
{
    int result = compare(self, other);
    return result == -2 ? Qnil : INT2FIX(result);
}

static VALUE
cq_lt(VALUE self, VALUE other)
{
    return compare_check_arg(self, other) == -1 ? Qtrue : Qfalse;
}

static VALUE
cq_lte(VALUE self, VALUE other)
{
    return compare_check_arg(self, other) == 1 ? Qfalse : Qtrue;
}

static VALUE
cq_gt(VALUE self, VALUE other)
{
    return compare_check_arg(self, other) == 1 ? Qtrue : Qfalse;
}

static VALUE
cq_gte(VALUE self, VALUE other)
{
    return compare_check_arg(self, other) == -1 ? Qfalse : Qtrue;
}

static VALUE
cq_denominator(VALUE self)
{
    VALUE result;

    result = cq_new();
    DATA_PTR(result) = qden(DATA_PTR(self));

    return result;
}

static VALUE
cq_numerator(VALUE self)
{
    VALUE result;

    result = cq_new();
    DATA_PTR(result) = qnum(DATA_PTR(self));

    return result;
}

static VALUE
cq_to_s(VALUE self)
{
    NUMBER *qself = DATA_PTR(self);
    char *s;
    VALUE rs;

    math_divertio();
    qprintnum(qself, MODE_FRAC);
    s = math_getdivertedio();
    rs = rb_str_new2(s);
    free(s);

    return rs;
}

/*****************************************************************************
 * module method implementations                                             *
 *****************************************************************************/

static VALUE
cq_cos(int argc, VALUE * argv, VALUE self)
{
    return trig_function(argc, argv, self, &qcos);
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
cq_pi(int argc, VALUE * argv, VALUE self)
{
    NUMBER *qepsilon;
    VALUE epsilon, result;

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
cq_set_default_epsilon(VALUE klass, VALUE epsilon)
{
    cq_default_epsilon = value_to_number(epsilon, 1);

    return Qnil;
}

static VALUE
cq_sin(int argc, VALUE * argv, VALUE self)
{
    return trig_function(argc, argv, self, &qsin);
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
    rb_define_method(cQ, "**", cq_power, 1);
    rb_define_method(cQ, "+", cq_add, 1);
    rb_define_method(cQ, "+@", cq_uplus, 0);
    rb_define_method(cQ, "-", cq_subtract, 1);
    rb_define_method(cQ, "-@", cq_uminus, 0);
    rb_define_method(cQ, "/", cq_divide, 1);
    rb_define_method(cQ, "<", cq_lt, 1);
    rb_define_method(cQ, "<<", cq_shift_left, 1);
    rb_define_method(cQ, "<=", cq_lte, 1);
    rb_define_method(cQ, "<=>", cq_comparison, 1);
    rb_define_method(cQ, "==", cq_equal, 1);
    rb_define_method(cQ, ">", cq_gt, 1);
    rb_define_method(cQ, ">=", cq_gte, 1);
    rb_define_method(cQ, ">>", cq_shift_right, 1);
    rb_define_method(cQ, "denominator", cq_denominator, 0);
    rb_define_method(cQ, "numerator", cq_numerator, 0);
    rb_define_method(cQ, "to_s", cq_to_s, 0);

    rb_define_module_function(cQ, "cos", cq_cos, -1);
    rb_define_module_function(cQ, "get_default_epsilon", cq_get_default_epsilon, 0);
    rb_define_module_function(cQ, "pi", cq_pi, -1);
    rb_define_module_function(cQ, "set_default_epsilon", cq_set_default_epsilon, 1);
    rb_define_module_function(cQ, "sin", cq_sin, -1);

    /* default epsilon is 1e-20 */
    cq_default_epsilon = str2q((char *) "0.00000000000000000001");
}
