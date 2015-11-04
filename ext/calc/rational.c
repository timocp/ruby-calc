#include "calc.h"

VALUE cQ;                       /* Calc::Q class */

/*****************************************************************************
 * functions related to memory allocation and object initialization          *
 *****************************************************************************/

void cq_free(void *p)
{
    qfree((NUMBER *) p);
}

const rb_data_type_t calc_q_type = {
    "Calc::Q",
    {0, cq_free, 0},            /* TODO: 3rd param is optional dsize */
    0, 0,
    RUBY_TYPED_FREE_IMMEDIATELY
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
VALUE cq_alloc(VALUE klass)
{
    return TypedData_Wrap_Struct(klass, &calc_q_type, 0);
}

#define cq_new() cq_alloc(cQ)

VALUE cq_initialize(int argc, VALUE * argv, VALUE self)
{
    NUMBER *qself;
    VALUE arg1, arg2;
    ZVALUE znum, zden;
    ZVALUE *zarg1;

    if (rb_scan_args(argc, argv, "11", &arg1, &arg2) == 1) {
        /* single param */
        if (TYPE(arg1) == T_FIXNUM) {
            qself = itoq(NUM2LONG(arg1));
        }
        else if (TYPE(arg1) == T_BIGNUM) {
            qself = itoq(NUM2LONG(arg1));
        }
        else if (ISZVALUE(arg1)) {
            get_zvalue(arg1, zarg1);
            qself = qalloc();
            zcopy(*zarg1, &qself->num);
        }
        else if (TYPE(arg1) == T_STRING) {
            qself = str2q(StringValueCStr(arg1));
        }
        else if (TYPE(arg1) == T_RATIONAL) {
            qself = iitoq(rb_funcall(arg1, rb_intern("numerator"), 0),
                          rb_funcall(arg1, rb_intern("denominator"), 0));

        }
        else {
            rb_raise(rb_eArgError, "expected number");
        }
    }
    else {
        /* 2 params. both can be anything Calc::Z.new would allow */
        znum = value_to_zvalue(arg1);
        zden = value_to_zvalue(arg2);
        qself = qalloc();
        qself->num = znum;
        qself->den = zden;
    }
    DATA_PTR(self) = qself;

    return self;
}

/*****************************************************************************
 * private functions used by instance methods                                *
 *****************************************************************************/

/*****************************************************************************
 * instance method implementations                                           *
 *****************************************************************************/

VALUE cq_add(VALUE self, VALUE other)
{
    NUMBER *qself, *qresult, *qtmp;
    ZVALUE *zother;
    VALUE result;

    qself = DATA_PTR(self);

    if (TYPE(other) == T_FIXNUM) {
        /* got strange results using qaddi, use qqadd instead */
        qtmp = itoq(NUM2LONG(other));
        qresult = qqadd(qself, qtmp);
        qfree(qtmp);
    }
    else if (TYPE(other) == T_BIGNUM) {
        qtmp = itoq(NUM2LONG(other));
        qresult = qqadd(qself, qtmp);
        qfree(qtmp);
    }
    else if (ISZVALUE(other)) {
        get_zvalue(other, zother);
        qtmp = qalloc();
        zcopy(*zother, &qtmp->num);
        qresult = qqadd(qself, qtmp);
        qfree(qtmp);
    }
    else if (ISQVALUE(other)) {
        qresult = qqadd(qself, DATA_PTR(other));
    }
    else {
        rb_raise(rb_eArgError, "expected number");
    }

    result = cq_new();
    DATA_PTR(result) = qresult;

    return result;
}

VALUE cq_to_s(VALUE self)
{
    NUMBER *qself = DATA_PTR(self);
    char *s;
    VALUE rs;

    math_divertio();
    qprintnum(qself, MODE_DEFAULT);
    s = math_getdivertedio();
    rs = rb_str_new2(s);
    free(s);

    return rs;
}

/*****************************************************************************
 * class definition, called once from Init_calc when library is loaded       *
 *****************************************************************************/
void define_calc_q(VALUE m)
{
    cQ = rb_define_class_under(m, "Q", rb_cData);
    rb_define_alloc_func(cQ, cq_alloc);
    rb_define_method(cQ, "initialize", cq_initialize, -1);

    rb_define_method(cQ, "+", cq_add, 1);
    rb_define_method(cQ, "to_s", cq_to_s, 0);
}
