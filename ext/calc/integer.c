#include "calc.h"

VALUE cZ;                       /* Calc::Z class */

/*****************************************************************************
 * functions related to memory allocation and object initialization          *
 *****************************************************************************/

/* freeh() is provided by libcalc, pointer version of zfree().  it is a macro,
 * so it can't be directly used in Data_Make_Struct */
void cz_free(void *p)
{
    freeh(p);
}

const rb_data_type_t calc_z_type = {
    "Calc::Z",
    {0, cz_free, 0},
    0, 0,
    RUBY_TYPED_FREE_IMMEDIATELY
};

/* tells ruby to allocate memory for a new object which wraps a ZVALUE */
VALUE cz_alloc(VALUE klass)
{
    ZVALUE *z;
    return TypedData_Make_Struct(klass, ZVALUE, &calc_z_type, z);
}

/* shorthand for creating a new uninitialized Calc::Z object */
#define cz_new() cz_alloc(cZ)

/* Calc::Z.new(arg) */
VALUE cz_initialize(VALUE self, VALUE arg)
{
    ZVALUE *zself;
    get_zvalue(self, zself);
    *zself = value_to_zvalue(arg);
    return self;
}

/* intialize_copy is used by dup/clone.  ZVALUE's can't share their internals
 * so we have to override the default copying. */
VALUE cz_initialize_copy(VALUE obj, VALUE orig)
{
    ZVALUE *zobj, *zorig;

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

/* used to implement <=>, ==, < and >
 * TODO: won't work if bignum param is > MAXLONG (9223372036854775807L)
 * returns:
 *  0 if values are the same
 *  -1 if self is < other
 *  +1 if self is > other
 *
 * returns -2 if 'other' is not a number.
 */
int _compare(VALUE self, VALUE other)
{
    ZVALUE *zself, *zother, ztmp;
    int result;

    get_zvalue(self, zself);
    if (TYPE(other) == T_FIXNUM || TYPE(other) == T_BIGNUM) {
        itoz(NUM2LONG(other), &ztmp);
        result = zrel(*zself, ztmp);
        zfree(ztmp);
    }
    else if (ISZVALUE(other)) {
        get_zvalue(other, zother);
        result = zrel(*zself, *zother);
    }
    else {
        result = -2;
    }

    return result;
}

/* calls _compare but raises an exception of other is non-numeric */
int _compare_check_arg(VALUE self, VALUE other)
{
    int result = _compare(self, other);
    if (result == -2) {
        rb_raise(rb_eArgError, "comparison of Calc::Z to non-numeric failed");
    }
    return result;
}

/* used to implement +, -, etc
 * f1 is compulsory, the normal form of numeric operations
 *      void f(ZVALUE, ZVALUE, ZVALUE *)
 * f2 is optional, when libcalc provides a "short" version that allows
 * a long parameter instead of a ZVALUE
 *      void f(ZVALUE, long, ZVALUE *)
 */
VALUE _numeric_op(VALUE self, VALUE other,
                  void (*f1) (ZVALUE, ZVALUE, ZVALUE *), void (*f2) (ZVALUE, long, ZVALUE *))
{
    ZVALUE *zself, *zother, ztmp, *zresult;
    VALUE result;

    result = cz_new();
    get_zvalue(self, zself);
    get_zvalue(result, zresult);

    if (TYPE(other) == T_FIXNUM || TYPE(other) == T_BIGNUM) {
        if (f2) {
            (*f2) (*zself, NUM2LONG(other), zresult);
        }
        else {
            itoz(NUM2LONG(other), &ztmp);
            (*f1) (*zself, ztmp, zresult);
            zfree(ztmp);
        }
    }
    else if (ISZVALUE(other)) {
        get_zvalue(other, zother);
        (*f1) (*zself, *zother, zresult);
    }
    else {
        rb_raise(rb_eArgError, "expected number");
    }

    return result;
}

/* implements left shift (positive sign) and right shift (negative sign) */
VALUE _shift(VALUE self, VALUE other, int sign)
{
    ZVALUE *zself, *zother, *zresult;
    VALUE result;

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

VALUE cz_self(VALUE num)
{
    return num;
}

VALUE cz_uminus(VALUE num)
{
    ZVALUE *znum, *zresult;
    VALUE result;

    result = cz_new();
    get_zvalue(num, znum);
    get_zvalue(result, zresult);
    zsub(_zero_, *znum, zresult);
    return result;
}

VALUE cz_add(VALUE self, VALUE other)
{
    return _numeric_op(self, other, &zadd, NULL);
}

VALUE cz_subtract(VALUE self, VALUE other)
{
    return _numeric_op(self, other, &zsub, NULL);
}

VALUE cz_multiply(VALUE self, VALUE other)
{
    return _numeric_op(self, other, &zmul, &zmuli);
}

VALUE cz_and(VALUE self, VALUE other)
{
    return _numeric_op(self, other, &zand, NULL);
}

VALUE cz_or(VALUE self, VALUE other)
{
    return _numeric_op(self, other, &zor, NULL);
}

VALUE cz_xor(VALUE self, VALUE other)
{
    return _numeric_op(self, other, &zxor, NULL);
}

VALUE cz_divide(VALUE self, VALUE other)
{
    return rb_funcall(cQ, rb_intern("new"), 2, self, other);
}

VALUE cz_power(VALUE self, VALUE other)
{
    return _numeric_op(self, other, &zpowi, NULL);
}

VALUE cz_mod(VALUE self, VALUE other)
{
    ZVALUE *zself, *zother, ztmp, *zresult;
    VALUE result;
    long ltmp;

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

VALUE cz_comparison(VALUE self, VALUE other)
{
    int result = _compare(self, other);
    return result == -2 ? Qnil : INT2FIX(result);
}

VALUE cz_equal(VALUE self, VALUE other)
{
    return _compare(self, other) == 0 ? Qtrue : Qfalse;
}

VALUE cz_gte(VALUE self, VALUE other)
{
    return _compare_check_arg(self, other) == -1 ? Qfalse : Qtrue;
}

VALUE cz_gt(VALUE self, VALUE other)
{
    return _compare_check_arg(self, other) == 1 ? Qtrue : Qfalse;
}

VALUE cz_lte(VALUE self, VALUE other)
{
    return _compare_check_arg(self, other) == 1 ? Qfalse : Qtrue;
}

VALUE cz_lt(VALUE self, VALUE other)
{
    return _compare_check_arg(self, other) == -1 ? Qtrue : Qfalse;
}

VALUE cz_shift_left(VALUE self, VALUE other)
{
    return _shift(self, other, 1);
}

VALUE cz_shift_right(VALUE self, VALUE other)
{
    return _shift(self, other, -1);
}

VALUE cz_abs(VALUE self)
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

VALUE cz_abs2(VALUE self)
{
    ZVALUE *zself, *zresult;
    VALUE result;

    result = cz_new();
    get_zvalue(self, zself);
    get_zvalue(result, zresult);

    zsquare(*zself, zresult);

    return result;
}

VALUE cz_divmod(VALUE self, VALUE other)
{
    ZVALUE *zself, *zother, ztmp, *zquo, *zmod;
    VALUE quo, mod, arr;
    long ltmp;

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

VALUE cz_iseven(VALUE self)
{
    ZVALUE *zself;
    get_zvalue(self, zself);
    return ziseven(*zself) ? Qtrue : Qfalse;
}

VALUE cz_isodd(VALUE self)
{
    ZVALUE *zself;
    get_zvalue(self, zself);
    return zisodd(*zself) ? Qtrue : Qfalse;
}

VALUE cz_iszero(VALUE self)
{
    ZVALUE *zself;
    get_zvalue(self, zself);
    return ziszero(*zself) ? Qtrue : Qfalse;
}

VALUE cz_next(VALUE self)
{
    return cz_add(self, INT2FIX(1));
}

VALUE cz_to_i(VALUE self)
{
    ZVALUE *zself;
    VALUE tmp;
    char *s;

    get_zvalue(self, zself);

    if (zgtmaxlong(*zself)) {
        /* too big to fit in a long, ztoi would return MAXLONG.  use a string
         * intermediary. */
        math_divertio();
        zprintval(*zself, 0, 0);
        s = math_getdivertedio();
        tmp = rb_str_new2(s);
        free(s);
        return rb_funcall(tmp, rb_intern("to_i"), 0);
    }
    else {
        return LONG2NUM(ztoi(*zself));
    }
}

VALUE cz_to_s(VALUE self)
{
    ZVALUE *zself;
    char *s;
    VALUE rs;

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
void define_calc_z(VALUE m)
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
    rb_define_method(cZ, "/", cz_divide, 1);
    rb_define_method(cZ, "<", cz_lt, 1);
    rb_define_method(cZ, "<<", cz_shift_left, 1);
    rb_define_method(cZ, "<=", cz_lte, 1);
    rb_define_method(cZ, "<=>", cz_comparison, 1);
    rb_define_method(cZ, "==", cz_equal, 1);
    rb_define_method(cZ, ">", cz_gt, 1);
    rb_define_method(cZ, ">=", cz_gte, 1);
    rb_define_method(cZ, ">>", cz_shift_right, 1);
    rb_define_method(cZ, "^", cz_xor, 1);
    rb_define_method(cZ, "abs", cz_abs, 0);
    rb_define_method(cZ, "abs2", cz_abs2, 0);
    rb_define_method(cZ, "ceil", cz_self, 0);
    rb_define_method(cZ, "divmod", cz_divmod, 1);
    rb_define_method(cZ, "even?", cz_iseven, 0);
    rb_define_method(cZ, "floor", cz_self, 0);
    rb_define_method(cZ, "next", cz_next, 0);
    rb_define_method(cZ, "odd?", cz_isodd, 0);
    rb_define_method(cZ, "to_i", cz_to_i, 0);
    rb_define_method(cZ, "to_s", cz_to_s, 0);
    rb_define_method(cZ, "truncate", cz_self, 0);
    rb_define_method(cZ, "zero?", cz_iszero, 0);
    rb_define_method(cZ, "|", cz_or, 1);

    rb_define_alias(cZ, "magnitude", "abs");
    rb_define_alias(cZ, "modulo", "%");
    rb_define_alias(cZ, "to_int", "to_i");
    rb_define_alias(cZ, "succ", "next");
}

/* returns a ZVALUE given a fixnum/bignum/string param.  this is public
 * bacuse Calc::Q initialization uses it too. */
ZVALUE value_to_zvalue(VALUE arg)
{
    ZVALUE *zarg;
    ZVALUE result;

    if (TYPE(arg) == T_FIXNUM) {
        itoz(NUM2LONG(arg), &result);
    }
    else if (TYPE(arg) == T_BIGNUM) {
        itoz(NUM2LONG(arg), &result);
    }
    else if (TYPE(arg) == T_STRING) {
        str2z(StringValueCStr(arg), &result);
    }
    else if (ISZVALUE(arg)) {
        get_zvalue(arg, zarg);
        zcopy(*zarg, &result);
    }
    else {
        rb_raise(rb_eTypeError, "expected Fixnum, Bignum, Calc::Z or String");
    }

    return result;
}
