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

VALUE cq_initialize(VALUE self, VALUE num, VALUE den)
{
    NUMBER *qself;
    ZVALUE znum, zden;

    znum = value_to_zvalue(num);
    zden = value_to_zvalue(den);
    qself = qalloc();
    qself->num = znum;
    qself->den = zden;
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
        qresult = qqadd(qself, itoq(NUM2LONG(other)));
    }
    else if (TYPE(other) == T_BIGNUM) {
        qresult = qqadd(qself, itoq(NUM2LONG(other)));
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
    rb_define_method(cQ, "initialize", cq_initialize, 2);       /* TODO: change to -1 */

    rb_define_method(cQ, "+", cq_add, 1);
    rb_define_method(cQ, "to_s", cq_to_s, 0);
}
