#include "calc.h"

/* Frees memory used to store calculated bernoulli numbers.
 * 
 * @return [nil]
 * @example
 *  Calc.freebernoulli  #=> nil
 */
static VALUE
calc_freebernoulli(VALUE self)
{
    setup_math_error();
    qfreebern();
    return Qnil;
}

/* Frees memory used to store calculated euler numbers.
 *
 * @return [nil]
 * @example
 *  Calc.freeeuler  #=> nil
 */
static VALUE
calc_freeeuler(VALUE self)
{
    setup_math_error();
    qfreeeuler();
    return Qnil;
}

/* Computer mod h * 2^n + r
 *
 * hnrmod(v, h, n, r) computes the value:
 *   v % (h * 2^n + r)
 * where all parameters are integers and:
 *   h > 0
 *   n > 0
 *   r == -1, 0 or 1
 * 
 * This is faster than standard mod.
 *
 * @param v [Integer]
 * @param h [Integer]
 * @param n [Integer]
 * @param r [Integer]
 * @return [Calc::Q]
 * @example
 *   Calc.hnrmod(2**177 - 1, 1, 177, -1) #=> Calc::Q(0)
 *   Calc.hnrmod(10**40, 17, 51, 1)      #=> Calc::Q(33827019788296445)
 */
static VALUE
calc_hnrmod(VALUE self, VALUE v, VALUE h, VALUE n, VALUE r)
{
    NUMBER *qv, *qh, *qn, *qr, *qresult;
    ZVALUE zresult;
    setup_math_error();

    qv = value_to_number(v, 0);
    if (qisfrac(qv)) {
        qfree(qv);
        rb_raise(e_MathError, "1st arg of hnrmod (v) must be an integer");
    }
    qh = value_to_number(h, 0);
    if (qisfrac(qh) || qisneg(qh) || qiszero(qh)) {
        qfree(qv);
        qfree(qh);
        rb_raise(e_MathError, "2nd arg of hnrmod (h) must be an integer > 0");
    }
    qn = value_to_number(n, 0);
    if (qisfrac(qn) || qisneg(qn) || qiszero(qn)) {
        qfree(qv);
        qfree(qh);
        qfree(qn);
        rb_raise(e_MathError, "3rd arg of hnrmod (n) must be an integer > 0");
    }
    qr = value_to_number(r, 0);
    if (qisfrac(qr) || !zisabsleone(qr->num)) {
        qfree(qv);
        qfree(qh);
        qfree(qn);
        qfree(qr);
        rb_raise(e_MathError, "4th arg of hnrmod (r) must be -1, 0 or 1");
    }
    zhnrmod(qv->num, qh->num, qn->num, qr->num, &zresult);
    qresult = qalloc();
    qresult->num = zresult;
    return wrap_number(qresult);
}

/* Evaluates п (pi) to a specified accuracy
 *
 * @param eps [Numeric,Calc::Q] (optional) calculation accuracy
 * @return [Calc::Q]
 * @raise [Calc::MathError] if v, h, n or r are non-integer or h or v < 1
 * @raise [Calc::MathError] if r is not -1, 0 or 1
 * @example
 *  Calc.pi          #=> Calc::Q(3.14159265358979323846)
 *  Calc.pi("1e-40") #=> Calc::Q(3.1415926535897932384626433832795028841972)
 */
static VALUE
calc_pi(int argc, VALUE * argv, VALUE self)
{
    NUMBER *qepsilon, *qresult;
    VALUE epsilon;
    setup_math_error();

    if (rb_scan_args(argc, argv, "01", &epsilon) == 0) {
        qresult = qpi(conf->epsilon);
    }
    else {
        qepsilon = value_to_number(epsilon, 1);
        qresult = qpi(qepsilon);
        qfree(qepsilon);
    }
    return wrap_number(qresult);
}

/* Returns a new complex (or real) number specified by modulus (radius) and
 * argument (angle, in radians).
 *
 * @param radius [Numeric,Calc::Numeric]
 * @param angle [Numeric,Calc::Numeric]
 * @param eps [Numeric] (optional) calculation accuracy
 * @return [Calc::Numeric]
 * @example
 *  Calc.polar(1,2)        #=> Calc::C(-0.416146836547142387+0.9092974268256816954i)
 *  Calc.polar(1,2,"0.01") #=> Calc::C(-0.42+0.91i)
 *  Calc.polar(2,0)        #=> Calc::Q(2)
 */
static VALUE
calc_polar(int argc, VALUE * argv, VALUE self)
{
    VALUE radius, angle, epsilon, result;
    NUMBER *qradius, *qangle, *qepsilon;
    setup_math_error();

    if (rb_scan_args(argc, argv, "21", &radius, &angle, &epsilon) == 3) {
        qepsilon = value_to_number(epsilon, 1);
        if (qisneg(qepsilon) || qiszero(qepsilon)) {
            rb_raise(e_MathError, "Negative or zero epsilon for polar");
        }
    }
    else {
        qepsilon = NULL;
    }
    qradius = value_to_number(radius, 0);
    qangle = value_to_number(angle, 0);
    result = wrap_complex(c_polar(qradius, qangle, qepsilon ? qepsilon : conf->epsilon));
    if (qepsilon) {
        qfree(qepsilon);
    }
    qfree(qradius);
    qfree(qangle);
    return result;
}

void
Init_calc(void)
{
    VALUE m;
    libcalc_call_me_first();

    m = rb_define_module("Calc");
    rb_define_module_function(m, "config", calc_config, -1);
    rb_define_module_function(m, "freebernoulli", calc_freebernoulli, 0);
    rb_define_module_function(m, "freeeuler", calc_freeeuler, 0);
    rb_define_module_function(m, "hnrmod", calc_hnrmod, 4);
    rb_define_module_function(m, "pi", calc_pi, -1);
    rb_define_module_function(m, "polar", calc_polar, -1);
    define_calc_math_error(m);
    define_calc_numeric(m);
    define_calc_q(m);
    define_calc_c(m);
}
