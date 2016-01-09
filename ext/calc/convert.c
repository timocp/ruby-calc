#include "calc.h"

/* attempt to convert a bignum a long then to Calc::Z using itoz().
 * NUM2LONG will raise an exception if arg doesn't fit in a long */
static VALUE
bignum_to_calc_z_via_long(VALUE arg)
{
    VALUE result;
    ZVALUE *zresult;

    result = cz_new();
    get_zvalue(result, zresult);
    itoz(NUM2LONG(arg), zresult);
    return result;
}

/* handles exceptions during via_long.  convert the arg to a string, then
 * Calc::Z using str2z */
static VALUE
bignum_to_calc_z_via_string(VALUE arg, VALUE e)
{
    ZVALUE *zresult;
    VALUE result;
    VALUE string;

    if (rb_obj_is_kind_of(e, rb_eRangeError)) {
        result = cz_new();
        get_zvalue(result, zresult);
        string = rb_funcall(arg, rb_intern("to_s"), 0);
        str2z(StringValueCStr(string), zresult);
    }
    else {
        /* something other than RangeError; re-raise it */
        rb_exc_raise(e);
    }

    return result;
}

/* convert a Bignum to Calc::Z
 * first tries to convert via a long; if that raises an exception, convert via
 * a string */
static VALUE
bignum_to_calc_z(VALUE arg)
{
    return rb_rescue(&bignum_to_calc_z_via_long, arg, &bignum_to_calc_z_via_string, arg);
}

/* converts a ruby value into a ZVALUE.  Allowed types:
 *  - Fixnum
 *  - Bignum
 *  - Calc::Z
 *  - String (using libcalc str2z)
 */
ZVALUE
value_to_zvalue(VALUE arg, int string_allowed)
{
    ZVALUE *zarg, *ztmp;
    ZVALUE result;
    VALUE tmp;
    setup_math_error();

    if (TYPE(arg) == T_FIXNUM) {
        itoz(NUM2LONG(arg), &result);
    }
    else if (TYPE(arg) == T_BIGNUM) {
        tmp = bignum_to_calc_z(arg);
        get_zvalue(tmp, ztmp);
        zcopy(*ztmp, &result);
    }
    else if (ISZVALUE(arg)) {
        get_zvalue(arg, zarg);
        zcopy(*zarg, &result);
    }
    else if (string_allowed && TYPE(arg) == T_STRING) {
        str2z(StringValueCStr(arg), &result);
    }
    else {
        if (string_allowed) {
            rb_raise(rb_eArgError, "expected Fixnum, Bignum, Calc::Z or String");
        }
        else {
            rb_raise(rb_eArgError, "expected Fixnum, Bignum or Calc::Z");
        }
    }

    return result;
}

/* convert a pair of ZVALUEs to a NUMBER*, ensuring reduced to common terms
 * and the sign in the numerator. */
NUMBER *
zz_to_number(ZVALUE znum, ZVALUE zden)
{
    NUMBER *q;
    ZVALUE z_gcd, zignored;

    if (ziszero(zden)) {
        rb_raise(rb_eZeroDivError, "division by zero");
    }
    zgcd(znum, zden, &z_gcd);
    q = qalloc();
    if (zisone(z_gcd)) {
        zcopy(znum, &q->num);
        zcopy(zden, &q->den);
    }
    else {
        zdiv(znum, z_gcd, &q->num, &zignored, 0);
        zfree(zignored);
        zdiv(zden, z_gcd, &q->den, &zignored, 0);
        zfree(zignored);
    }
    /* make sure sign is in numerator.  1 is negative, 0 is positive */
    if (zispos(q->num) && zisneg(q->den)) {
        q->num.sign = 1;
        q->den.sign = 0;
    }
    else if (zisneg(q->num) && zisneg(q->den)) {
        q->num.sign = 0;
        q->den.sign = 0;
    }
    return q;
}

/* convert a ruby Rational to a NUMBER*.  Since the denominator/numerator of
 * the rational number could be too big for long, they are converted to zvalues
 * first.
 */
static NUMBER *
rational_to_number(VALUE arg)
{
    ZVALUE znum, zden;
    NUMBER *qresult;

    znum = value_to_zvalue(rb_funcall(arg, rb_intern("numerator"), 0), 0);
    zden = value_to_zvalue(rb_funcall(arg, rb_intern("denominator"), 0), 0);
    qresult = zz_to_number(znum, zden);
    zfree(znum);
    zfree(zden);
    return qresult;
}

/* converts a ruby value into a NUMBER*.  Allowed types:
 *  - Fixnum
 *  - Bignum
 *  - Calc::Z
 *  - Calc::Q
 *  - Rational
 *  - String (using libcalc str2q)
 *  - Float (will be converted to a Rational first)
 *
 * the caller is responsible for freeing the returned number.  storing it in
 * a Calc::Q is sufficient for the ruby GC to get it.
 */
NUMBER *
value_to_number(VALUE arg, int string_allowed)
{
    NUMBER *qresult;
    ZVALUE *zarg, *znum;
    VALUE num, tmp;
    setup_math_error();

    if (TYPE(arg) == T_FIXNUM) {
        qresult = itoq(NUM2LONG(arg));
    }
    else if (TYPE(arg) == T_BIGNUM) {
        num = bignum_to_calc_z(arg);
        get_zvalue(num, znum);
        qresult = zz_to_number(*znum, _one_);
    }
    else if (ISZVALUE(arg)) {
        get_zvalue(arg, zarg);
        qresult = qalloc();
        zcopy(*zarg, &qresult->num);
    }
    else if (ISQVALUE(arg)) {
        qresult = qlink((NUMBER *) DATA_PTR(arg));
    }
    else if (TYPE(arg) == T_RATIONAL) {
        qresult = rational_to_number(arg);
    }
    else if (TYPE(arg) == T_FLOAT) {
        tmp = rb_funcall(arg, rb_intern("to_r"), 0);
        qresult = rational_to_number(tmp);
    }
    else if (string_allowed && TYPE(arg) == T_STRING) {
        qresult = str2q(StringValueCStr(arg));
        /* libcalc str2q allows a 0 denominator */
        if (ziszero(qresult->den)) {
            qfree(qresult);
            rb_raise(rb_eZeroDivError, "division by zero");
        }
    }
    else {
        if (string_allowed) {
            rb_raise(rb_eArgError,
                     "expected number, Rational, Float, Calc::Z, Calc::Q or string");
        }
        else {
            rb_raise(rb_eArgError, "expected number, Rational, Float, Calc::Z or Calc::Q");
        }
    }
    return qresult;
}

VALUE
zvalue_to_f(ZVALUE * z)
{
    return rb_funcall(zvalue_to_i(z), rb_intern("to_f"), 0);
}

/* convert a ZVALUE to a ruby numeric (Fixnum or Bignum)
 */
VALUE
zvalue_to_i(ZVALUE * z)
{
    VALUE tmp;
    char *s;

    if (zgtmaxlong(*z)) {
        /* too big to fit in a long, ztoi would return MAXLONG.  use a string
         * intermediary. */
        math_divertio();
        zprintval(*z, 0, 0);
        s = math_getdivertedio();
        tmp = rb_str_new2(s);
        free(s);
        return rb_funcall(tmp, rb_intern("to_i"), 0);
    }
    else {
        return LONG2NUM(ztoi(*z));
    }
}

/* converts a ZVALUE to the nearest double.  libcalc doesn't use floats/doubles
 * at all so the simplest thing to do is convert to a Fixnum/Bignum, then use
 * ruby's Fixnum#to_f.
 */
double
zvalue_to_double(ZVALUE * z)
{
    return NUM2DBL(zvalue_to_i(z));
}

/* convert a NUMBER* to a new Calc::Q object */
VALUE
number_to_calc_q(NUMBER * n)
{
    VALUE q;
    q = cq_new();
    DATA_PTR(q) = qlink(n);
    return q;
}

/* "mode" conversions.  this is based on code in config.c */

typedef struct {
    const char *name;
    long type;
} nametype2;

static nametype2 modes[] = {
    {"fraction", MODE_FRAC},
    {"frac", MODE_FRAC},
    {"integer", MODE_INT},
    {"int", MODE_INT},
    {"real", MODE_REAL},
    {"float", MODE_REAL},
    {"default", MODE_INITIAL},  /* MODE_REAL */
    {"scientific", MODE_EXP},
    {"sci", MODE_EXP},
    {"exp", MODE_EXP},
    {"hexadecimal", MODE_HEX},
    {"hex", MODE_HEX},
    {"octal", MODE_OCTAL},
    {"oct", MODE_OCTAL},
    {"binary", MODE_BINARY},
    {"bin", MODE_BINARY},
    {"off", MODE2_OFF},
    {NULL, 0}
};

/* config types we support - a subset of "configs[]" in calc's config.c */

static nametype2 configs[] = {
    {"mode", CONFIG_MODE},
    {"display", CONFIG_DISPLAY},
    {"epsilon", CONFIG_EPSILON},
    {NULL, 0}
};

static long
lookup_long(nametype2 * set, const char *name)
{
    nametype2 *cp;

    for (cp = set; cp->name; cp++) {
        if (strcmp(cp->name, name) == 0)
            return cp->type;
    }
    return -1;
}

static const char *
lookup_name(nametype2 * set, long val)
{
    nametype2 *cp;

    for (cp = set; cp->name; cp++) {
        if (val == cp->type)
            return cp->name;
    }
    return NULL;
}

/* given a String or Symbol, returns the index into a nameset
 * or -1 if not found */
static long
value_to_nametype_long(VALUE v, nametype2 * set)
{
    VALUE tmp;
    char *str;

    if (TYPE(v) == T_STRING) {
        str = StringValueCStr(v);
    }
    else if (TYPE(v) == T_SYMBOL) {
        tmp = rb_funcall(v, rb_intern("to_s"), 0);
        str = StringValueCStr(tmp);
    }
    else {
        rb_raise(rb_eArgError, "expected String or Symbol");
    }
    return lookup_long(set, str);
}

/* convert value to a libcalc mode flag.  value may be a string or a symbol.
 * raises an exception if the mode in invalid. */
long
value_to_mode(VALUE v)
{
    int n;

    n = value_to_nametype_long(v, modes);
    if (n < 0) {
        rb_raise(rb_eArgError, "invalid output mode");
    }
    return n;
}

VALUE
mode_to_string(long n)
{
    const char *p;

    p = lookup_name(modes, n);
    if (p == NULL) {
        rb_raise(e_MathError, "invalid output mode: %ld", n);
    }
    return rb_str_new2(p);
}

/* convert a string or symbol to the libcalc CALC_* enum
 * returns -1 if the name is invalid/unsupported in ruby-calc */
long
value_to_config(VALUE v)
{
    return value_to_nametype_long(v, configs);
}

/* convert a ruby value into a COMPLEX*.  Allowed types:
 * - Complex
 * - Any type allowed by value_to_number (except string).
 *
 * libcalc doesn't provide any way to convert a string to a complex number.
 *
 * caller is responseible for freeing the returned complex.  storing it in
 * a Calc::C is sufficient for the ruby GC to get it.
 */
COMPLEX *
value_to_complex(VALUE arg)
{
    COMPLEX *cresult;
    VALUE real, imag;

    if (ISCVALUE(arg)) {
        cresult = clink((COMPLEX *) DATA_PTR(arg));
    }
    else if (TYPE(arg) == T_COMPLEX) {
        real = rb_funcall(arg, rb_intern("real"), 0);
        imag = rb_funcall(arg, rb_intern("imag"), 0);
        cresult = qqtoc(value_to_number(real, 0), value_to_number(imag, 0));
    }
    else {
        rb_raise(rb_eArgError, "expected number or complex number");
    }

    return cresult;
}
