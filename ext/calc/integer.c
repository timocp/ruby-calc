#include "calc.h"

VALUE cZ;                       /* Calc::Z class */

/*****************************************************************************
 * functions related to memory allocation and object initialization          *
 *****************************************************************************/

/* p is a pointer to a ZVALUE which was allocated during cz_alloc.  we need to
 * use zfree() to dealloc the actual value, then xfree() on the pointer (since
 * that was allocated by ruby) */
static void
cz_free(void *p)
{
    zfree(*(ZVALUE *) p);
    xfree(p);
}

/* used to calculate the size used by this typed data object. */
static size_t
cz_memsize(const void *p)
{
    const ZVALUE *z = p;
    if (z) {
        return sizeof(*z) + z->len * sizeof(*z->v);
    }
    else {
        return 0;
    }
}

const rb_data_type_t calc_z_type = {
    "Calc::Z",
    {0, cz_free, cz_memsize,},
    0, 0
#ifdef RUBY_TYPED_FREE_IMMEDIATELY
        , RUBY_TYPED_FREE_IMMEDIATELY   /* flags is in 2.1+ */
#endif
};

/* tells ruby to allocate memory for a new object which wraps a ZVALUE */
VALUE
cz_alloc(VALUE klass)
{
    ZVALUE *z;
    return TypedData_Make_Struct(klass, ZVALUE, &calc_z_type, z);
}

/* Calc::Z.new(arg) */
static VALUE
cz_initialize(VALUE self, VALUE arg)
{
    ZVALUE *zself;
    get_zvalue(self, zself);
    *zself = value_to_zvalue(arg, 1);
    return self;
}

/* intialize_copy is used by dup/clone.  ZVALUE's can't share their internals
 * so we have to override the default copying. */
static VALUE
cz_initialize_copy(VALUE obj, VALUE orig)
{
    ZVALUE *zobj, *zorig;
    setup_math_error();

    if (obj == orig) {
        return obj;
    }
    if (!ISZVALUE(orig)) {
        rb_raise(rb_eTypeError, "wrong argument type");
    }

    get_zvalue(obj, zobj);
    get_zvalue(orig, zorig);
    zcopy(*zorig, zobj);

    return obj;
}

/*****************************************************************************
 * private functions used by instance methods                                *
 *****************************************************************************/

/* used to implement +, -, etc
 * f1 is compulsory, the normal form of numeric operations
 *      void f(ZVALUE, ZVALUE, ZVALUE *)
 */
static VALUE
numeric_op(VALUE self, VALUE other, void (*f1) (ZVALUE, ZVALUE, ZVALUE *))
{
    ZVALUE *zself, ztmp, *zresult;
    VALUE result;
    setup_math_error();

    result = cz_new();
    get_zvalue(self, zself);
    get_zvalue(result, zresult);
    ztmp = value_to_zvalue(other, 0);
    (*f1) (*zself, ztmp, zresult);
    zfree(ztmp);

    return result;
}

/* implements left shift (positive sign) and right shift (negative sign) */
static VALUE
shift(VALUE self, VALUE other, int sign)
{
    ZVALUE *zself, *zother, *zresult;
    VALUE result;
    setup_math_error();

    result = cz_new();
    get_zvalue(self, zself);
    get_zvalue(result, zresult);

    if (TYPE(other) == T_FIXNUM || TYPE(other) == T_BIGNUM) {
        zshift(*zself, NUM2LONG(other) * sign, zresult);
    }
    else if (ISZVALUE(other)) {
        get_zvalue(other, zother);
        zshift(*zself, ztoi(*zother) * sign, zresult);
    }
    else {
        rb_raise(rb_eArgError, "number expected");
    }

    return result;
}

/*****************************************************************************
 * instance method implementations                                           *
 *****************************************************************************/

static VALUE
cz_self(VALUE num)
{
    return num;
}

static VALUE
cz_uminus(VALUE num)
{
    ZVALUE *znum, *zresult;
    VALUE result;
    setup_math_error();

    result = cz_new();
    get_zvalue(num, znum);
    get_zvalue(result, zresult);
    zsub(_zero_, *znum, zresult);
    return result;
}

static VALUE
cz_add(VALUE self, VALUE other)
{
    return numeric_op(self, other, &zadd);
}

static VALUE
cz_subtract(VALUE self, VALUE other)
{
    return numeric_op(self, other, &zsub);
}

static VALUE
cz_multiply(VALUE self, VALUE other)
{
    return numeric_op(self, other, &zmul);
}

static VALUE
cz_and(VALUE self, VALUE other)
{
    return numeric_op(self, other, &zand);
}

static VALUE
cz_or(VALUE self, VALUE other)
{
    return numeric_op(self, other, &zor);
}

static VALUE
cz_xor(VALUE self, VALUE other)
{
    return numeric_op(self, other, &zxor);
}

static VALUE
cz_power(VALUE self, VALUE other)
{
    return numeric_op(self, other, &zpowi);
}

static VALUE
cz_mod(VALUE self, VALUE other)
{
    ZVALUE *zself, *zother, ztmp, *zresult;
    VALUE result;
    long ltmp;
    setup_math_error();

    result = cz_new();
    get_zvalue(self, zself);
    get_zvalue(result, zresult);

    if (TYPE(other) == T_FIXNUM || TYPE(other) == T_BIGNUM) {
        ltmp = NUM2LONG(other);
        if (ltmp == 0) {
            rb_raise(rb_eZeroDivError, "division by zero in mod");
        }
        itoz(ltmp, &ztmp);
        zmod(*zself, ztmp, zresult, 0); /* remainder sign ignored */
        zfree(ztmp);
    }
    else if (ISZVALUE(other)) {
        get_zvalue(other, zother);
        if (ziszero(*zother)) {
            rb_raise(rb_eZeroDivError, "division by zero in mod");
        }
        zmod(*zself, *zother, zresult, 0);      /* remainder sign ignored */
    }
    else {
        rb_raise(rb_eArgError, "number expected");
    }

    return result;
}

static VALUE
cz_spaceship(VALUE self, VALUE other)
{
    ZVALUE *zself, zother;
    int result;
    double dself, dother;
    setup_math_error();

    get_zvalue(self, zself);

    /* check type first because don't want value_to_zvalue to raise an exception */
    if (TYPE(other) == T_FIXNUM || TYPE(other) == T_BIGNUM || ISZVALUE(other)) {
        zother = value_to_zvalue(other, 0);
        result = zrel(*zself, zother);
        zfree(zother);
    }
    else if (TYPE(other) == T_FLOAT) {
        dself = zvalue_to_double(zself);
        dother = NUM2DBL(other);
        if (dself == dother) {
            result = 0;
        }
        else if (dself < dother) {
            result = -1;
        }
        else {
            result = 1;
        }
    }
    else {
        return Qnil;
    }

    return INT2FIX(result);
}

static VALUE
cz_shift_left(VALUE self, VALUE other)
{
    return shift(self, other, 1);
}

static VALUE
cz_shift_right(VALUE self, VALUE other)
{
    return shift(self, other, -1);
}

static VALUE
cz_abs(VALUE self)
{
    ZVALUE *zself;

    get_zvalue(self, zself);

    if (zispos(*zself)) {
        return self;
    }
    else {
        return cz_uminus(self);
    }
}

static VALUE
cz_abs2(VALUE self)
{
    ZVALUE *zself, *zresult;
    VALUE result;
    setup_math_error();

    result = cz_new();
    get_zvalue(self, zself);
    get_zvalue(result, zresult);

    zsquare(*zself, zresult);

    return result;
}

static VALUE
cz_divmod(VALUE self, VALUE other)
{
    ZVALUE *zself, *zother, ztmp, *zquo, *zmod;
    VALUE quo, mod, arr;
    long ltmp;
    setup_math_error();

    quo = cz_new();
    mod = cz_new();
    arr = rb_ary_new2(2);
    get_zvalue(self, zself);
    get_zvalue(quo, zquo);
    get_zvalue(mod, zmod);

    if (TYPE(other) == T_FIXNUM || TYPE(other) == T_BIGNUM) {
        ltmp = NUM2LONG(other);
        if (ltmp == 0) {
            rb_raise(rb_eZeroDivError, "division by zero in divmod");
        }
        itoz(ltmp, &ztmp);
        zdiv(*zself, ztmp, zquo, zmod, 0);
        zfree(ztmp);
    }
    else if (ISZVALUE(other)) {
        get_zvalue(other, zother);
        if (ziszero(*zother)) {
            rb_raise(rb_eZeroDivError, "division by zero in divmod");
        }
        zdiv(*zself, *zother, zquo, zmod, 0);
    }
    else {
        rb_raise(rb_eArgError, "number expected");
    }
    rb_ary_store(arr, 0, quo);
    rb_ary_store(arr, 1, mod);

    return arr;
}

static VALUE
cz_fact(VALUE self)
{
    ZVALUE *zself, *zresult;
    VALUE result;
    setup_math_error();

    result = cz_new();
    get_zvalue(self, zself);
    get_zvalue(result, zresult);

    zfact(*zself, zresult);

    return result;
}

static VALUE
cz_iseven(VALUE self)
{
    ZVALUE *zself;
    get_zvalue(self, zself);
    return ziseven(*zself) ? Qtrue : Qfalse;
}

static VALUE
cz_isodd(VALUE self)
{
    ZVALUE *zself;
    get_zvalue(self, zself);
    return zisodd(*zself) ? Qtrue : Qfalse;
}

static VALUE
cz_iszero(VALUE self)
{
    ZVALUE *zself;
    get_zvalue(self, zself);
    return ziszero(*zself) ? Qtrue : Qfalse;
}

static VALUE
cz_next(VALUE self)
{
    return cz_add(self, INT2FIX(1));
}

static VALUE
cz_to_i(VALUE self)
{
    ZVALUE *zself;
    setup_math_error();
    get_zvalue(self, zself);
    return zvalue_to_i(zself);
}

static VALUE
cz_to_f(VALUE self)
{
    ZVALUE *zself;
    setup_math_error();
    get_zvalue(self, zself);
    return zvalue_to_f(zself);
}

static VALUE
cz_to_s(VALUE self)
{
    ZVALUE *zself;
    char *s;
    VALUE rs;
    setup_math_error();

    get_zvalue(self, zself);
    math_divertio();
    zprintval(*zself, 0, 0);
    s = math_getdivertedio();
    rs = rb_str_new2(s);
    free(s);

    return rs;
}

/*****************************************************************************
 * class definition, called once from Init_calc when library is loaded       *
 *****************************************************************************/
void
define_calc_z(VALUE m)
{
    cZ = rb_define_class_under(m, "Z", rb_cData);
    rb_define_alloc_func(cZ, cz_alloc);
    rb_define_method(cZ, "initialize", cz_initialize, 1);
    rb_define_method(cZ, "initialize_copy", cz_initialize_copy, 1);

    /* instance methods on Calc::Z */
    rb_define_method(cZ, "%", cz_mod, 1);
    rb_define_method(cZ, "&", cz_and, 1);
    rb_define_method(cZ, "*", cz_multiply, 1);
    rb_define_method(cZ, "**", cz_power, 1);
    rb_define_method(cZ, "+", cz_add, 1);
    rb_define_method(cZ, "+@", cz_self, 0);
    rb_define_method(cZ, "-", cz_subtract, 1);
    rb_define_method(cZ, "-@", cz_uminus, 0);
    rb_define_method(cZ, "<<", cz_shift_left, 1);
    rb_define_method(cZ, "<=>", cz_spaceship, 1);
    rb_define_method(cZ, ">>", cz_shift_right, 1);
    rb_define_method(cZ, "^", cz_xor, 1);
    rb_define_method(cZ, "abs", cz_abs, 0);
    rb_define_method(cZ, "abs2", cz_abs2, 0);
    rb_define_method(cZ, "ceil", cz_self, 0);
    rb_define_method(cZ, "divmod", cz_divmod, 1);
    rb_define_method(cZ, "even?", cz_iseven, 0);
    rb_define_method(cZ, "fact", cz_fact, 0);
    rb_define_method(cZ, "floor", cz_self, 0);
    rb_define_method(cZ, "next", cz_next, 0);
    rb_define_method(cZ, "odd?", cz_isodd, 0);
    rb_define_method(cZ, "to_i", cz_to_i, 0);
    rb_define_method(cZ, "to_f", cz_to_f, 0);
    rb_define_method(cZ, "to_s", cz_to_s, 0);
    rb_define_method(cZ, "truncate", cz_self, 0);
    rb_define_method(cZ, "zero?", cz_iszero, 0);
    rb_define_method(cZ, "|", cz_or, 1);

    /* include Comparable */
    rb_include_module(cZ, rb_mComparable);

    rb_define_alias(cZ, "magnitude", "abs");
    rb_define_alias(cZ, "modulo", "%");
    rb_define_alias(cZ, "to_int", "to_i");
    rb_define_alias(cZ, "succ", "next");
}
