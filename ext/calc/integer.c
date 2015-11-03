#include "calc.h"

VALUE cZ;                       /* Calc::Z class */

/* freeh() is provided by libcalc, pointer version of zfree() */
void cz_free(void *p)
{
    freeh(p);
}

VALUE cz_alloc(VALUE klass)
{
    ZVALUE *z;
    VALUE obj;

    /* use Make, not Wrap.  Make will zero the space allocated.  Probably this
     * is just for ZVALUEs, since NUMBER and COMPLEX have their own allocation
     * functions */
    obj = Data_Make_Struct(klass, ZVALUE, 0, cz_free, z);

    return obj;
}

VALUE cz_initialize(VALUE self, VALUE param)
{
    ZVALUE *z, *zother;

    Data_Get_Struct(self, ZVALUE, z);
    if (TYPE(param) == T_FIXNUM) {
        itoz(NUM2LONG(param), z);
    }
    else if (TYPE(param) == T_BIGNUM) {
        itoz(NUM2LONG(param), z);
    }
    else if (ISZVALUE(param)) {
        Data_Get_Struct(param, ZVALUE, zother);
        zcopy(*zother, z);
    }
    else {
        rb_raise(rb_eTypeError, "expected Fixnum or Bignum");
    }

    return self;
}

/* intialize_copy is used by dupp/clone.  ruby provided version won't work
 * because the underlying ZVALUEs can't be shared. */
VALUE cz_initialize_copy(VALUE copy, VALUE orig)
{
    ZVALUE *z1, *z2;

    if (copy == orig) {
        return copy;
    }
    if (!ISZVALUE(orig)) {
        rb_raise(rb_eTypeError, "wrong argument type");
    }

    Data_Get_Struct(orig, ZVALUE, z1);
    Data_Get_Struct(copy, ZVALUE, z2);
    zcopy(*z1, z2);

    return copy;
}

VALUE cz_self(VALUE num)
{
    return num;
}

VALUE cz_uminus(VALUE num)
{
    ZVALUE *znum, *zresult;
    VALUE result;

    result = cz_alloc(cZ);
    Data_Get_Struct(num, ZVALUE, znum);
    Data_Get_Struct(result, ZVALUE, zresult);
    zsub(_zero_, *znum, zresult);
    return result;
}

/* used to implement +, -, etc
 * f1 is compulsory, the normal form of numeric operations
 *      void f(ZVALUE, ZVALUE, ZVALUE *)
 * f2 is optional, when libcalc provides a "short" version that allows
 * a long parameter instead of a ZVALUE
 *      void f(ZVALUE, long, ZVALUE *)
 */
VALUE numeric_operation(VALUE self, VALUE other,
                        void (*f1) (ZVALUE, ZVALUE, ZVALUE *),
                        void (*f2) (ZVALUE, long, ZVALUE *))
{
    ZVALUE *zself, *zother, ztmp, *zresult;
    VALUE result;

    result = cz_alloc(cZ);
    Data_Get_Struct(self, ZVALUE, zself);
    Data_Get_Struct(result, ZVALUE, zresult);

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
        Data_Get_Struct(other, ZVALUE, zother);
        (*f1) (*zself, *zother, zresult);
    }
    else {
        rb_raise(rb_eArgError, "expected number");
    }

    return result;
}

VALUE cz_add(VALUE self, VALUE other)
{
    return numeric_operation(self, other, &zadd, NULL);
}

VALUE cz_subtract(VALUE self, VALUE other)
{
    return numeric_operation(self, other, &zsub, NULL);
}

VALUE cz_multiply(VALUE self, VALUE other)
{
    return numeric_operation(self, other, &zmul, &zmuli);
}

VALUE cz_and(VALUE self, VALUE other)
{
    return numeric_operation(self, other, &zand, NULL);
}

VALUE cz_or(VALUE self, VALUE other)
{
    return numeric_operation(self, other, &zor, NULL);
}

VALUE cz_xor(VALUE self, VALUE other)
{
    return numeric_operation(self, other, &zxor, NULL);
}

VALUE cz_divide(VALUE self, VALUE other)
{
    rb_raise(rb_eNotImpError, "division not implemented yet");
}

VALUE cz_power(VALUE self, VALUE other)
{
    return numeric_operation(self, other, &zpowi, NULL);
}

VALUE cz_mod(VALUE self, VALUE other)
{
    ZVALUE *zself, *zother, ztmp, *zresult;
    VALUE result;

    result = cz_alloc(cZ);
    Data_Get_Struct(self, ZVALUE, zself);
    Data_Get_Struct(result, ZVALUE, zresult);

    if (TYPE(other) == T_FIXNUM || TYPE(other) == T_BIGNUM) {
        itoz(NUM2LONG(other), &ztmp);
        zmod(*zself, ztmp, zresult, 0); /* remainder sign ignored */
        zfree(ztmp);
    }
    else if (ISZVALUE(other)) {
        Data_Get_Struct(other, ZVALUE, zother);
        zmod(*zself, *zother, zresult, 0);      /* remainder sign ignored */
    }
    else {
        rb_raise(rb_eArgError, "number expected");
    }

    return result;
}

/* used to implement <=>, ==, < and >
 * TODO: won't work if bignum param is > MAX_LONG
 * returns:
 *  0 if values are the same
 *  -1 if self is < other
 *  +1 if self is > other
 *
 * returns -2 if 'other' is not a number.
 */
int _cz_zrel(VALUE self, VALUE other)
{
    ZVALUE *zv_self, *zv_tmp, zv_other;
    int result;

    Data_Get_Struct(self, ZVALUE, zv_self);
    if (TYPE(other) == T_FIXNUM || TYPE(other) == T_BIGNUM) {
        itoz(NUM2LONG(other), &zv_other);
        result = zrel(*zv_self, zv_other);
        zfree(zv_other);
    }
    else if (ISZVALUE(other)) {
        Data_Get_Struct(other, ZVALUE, zv_tmp);
        result = zrel(*zv_self, *zv_tmp);
    }
    else {
        result = -2;
    }

    return result;
}

/* calls _cz_zrel but raises an exception of other is non-numeric */
int _cz_zrel_check_arg(VALUE self, VALUE other)
{
    int result = _cz_zrel(self, other);
    if (result == -2) {
        rb_raise(rb_eArgError, "comparison of Calc::Z to non-numeric failed");
    }
    return result;
}

VALUE cz_comparison(VALUE self, VALUE other)
{
    int result = _cz_zrel(self, other);
    return result == -2 ? Qnil : INT2FIX(result);
}

VALUE cz_equal(VALUE self, VALUE other)
{
    return _cz_zrel(self, other) == 0 ? Qtrue : Qfalse;
}

VALUE cz_gte(VALUE self, VALUE other)
{
    return _cz_zrel_check_arg(self, other) == -1 ? Qfalse : Qtrue;
}

VALUE cz_gt(VALUE self, VALUE other)
{
    return _cz_zrel_check_arg(self, other) == 1 ? Qtrue : Qfalse;
}

VALUE cz_lte(VALUE self, VALUE other)
{
    return _cz_zrel_check_arg(self, other) == 1 ? Qfalse : Qtrue;
}

VALUE cz_lt(VALUE self, VALUE other)
{
    return _cz_zrel_check_arg(self, other) == -1 ? Qtrue : Qfalse;
}

VALUE shift(VALUE self, VALUE other, int sign)
{
    ZVALUE *zself, *zother, *zresult;
    VALUE result;

    result = cz_alloc(cZ);
    Data_Get_Struct(self, ZVALUE, zself);
    Data_Get_Struct(result, ZVALUE, zresult);

    if (TYPE(other) == T_FIXNUM || TYPE(other) == T_BIGNUM) {
        zshift(*zself, NUM2LONG(other) * sign, zresult);
    }
    else if (ISZVALUE(other)) {
        Data_Get_Struct(other, ZVALUE, zother);
        zshift(*zself, ztoi(*zother) * sign, zresult);
    }
    else {
        rb_raise(rb_eArgError, "number expected");
    }

    return result;
}

VALUE cz_shift_left(VALUE self, VALUE other)
{
    return shift(self, other, 1);
}

VALUE cz_shift_right(VALUE self, VALUE other)
{
    return shift(self, other, -1);
}

VALUE cz_abs(VALUE self) {
    ZVALUE *zself;

    Data_Get_Struct(self, ZVALUE, zself);

    if (zispos(*zself)) {
        return self;
    }
    else {
        return cz_uminus(self);
    }
}

VALUE cz_abs2(VALUE self) {
    ZVALUE *zself, *zresult;
    VALUE result;

    result = cz_alloc(cZ);
    Data_Get_Struct(self, ZVALUE, zself);
    Data_Get_Struct(result, ZVALUE, zresult);

    zsquare(*zself, zresult);

    return result;
}

VALUE cz_divmod(VALUE self, VALUE other)
{
    ZVALUE *zself, *zother, ztmp, *zquo, *zmod;
    VALUE quo, mod, arr;

    quo = cz_alloc(cZ);
    mod = cz_alloc(cZ);
    arr = rb_ary_new2(2);
    Data_Get_Struct(self, ZVALUE, zself);
    Data_Get_Struct(quo, ZVALUE, zquo);
    Data_Get_Struct(mod, ZVALUE, zmod);

    if (TYPE(other) == T_FIXNUM || TYPE(other) == T_BIGNUM) {
        itoz(NUM2LONG(other), &ztmp);
        zdiv(*zself, ztmp, zquo, zmod, 0);
        zfree(ztmp);
    }
    else if (ISZVALUE(other)) {
        Data_Get_Struct(other, ZVALUE, zother);
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
    Data_Get_Struct(self, ZVALUE, zself);
    return ziseven(*zself) ? Qtrue : Qfalse;
}

VALUE cz_isodd(VALUE self)
{
    ZVALUE *zself;
    Data_Get_Struct(self, ZVALUE, zself);
    return zisodd(*zself) ? Qtrue : Qfalse;
}

VALUE cz_to_s(VALUE self)
{
    ZVALUE *z;
    char *s;
    VALUE rs;

    Data_Get_Struct(self, ZVALUE, z);
    math_divertio();
    zprintval(*z, 0, 0);
    s = math_getdivertedio();
    rs = rb_str_new2(s);
    free(s);

    return rs;
}

/* called from Init_calc, defines the Calc::Z class */
void define_calc_z(VALUE m)
{
    cZ = rb_define_class_under(m, "Z", rb_cObject);
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
    rb_define_method(cZ, "odd?", cz_isodd, 0);
    rb_define_method(cZ, "to_s", cz_to_s, 0);
    rb_define_method(cZ, "|", cz_or, 1);

    rb_define_alias(cZ, "modulo", "%");
}
