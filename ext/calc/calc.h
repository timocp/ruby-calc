#ifndef CALC_H
#define CALC_H 1

#include "ruby.h"

/* cannot include calc/calc.h, which contains some things we need, because it
 * includes calc/value.h which defines VALUE, a name already used by ruby.
 * copying things we need here for now. */
extern void libcalc_call_me_first(void);
extern void reinitialize(void);
extern char *version(void);

#include <calc/cmath.h>
#include <calc/config.h>
#include <calc/lib_calc.h>

/* config.c */
extern VALUE calc_config(int argc, VALUE * argv, VALUE klass);
extern long value_to_mode(VALUE v);

/* convert.c */
extern NUMBER *value_to_number(VALUE arg, int string_allowed);
extern COMPLEX *value_to_complex(VALUE arg);
extern long value_to_long(VALUE n);
extern VALUE wrap_complex(COMPLEX * c);
extern VALUE wrap_number(NUMBER * n);

/* math_error.c */
extern VALUE e_MathError;       /* Calc::MathError class (exception) */
extern void define_calc_math_error();

#ifdef JUMP_ON_MATH_ERROR
extern void setup_math_error();
#else
#define setup_math_error()
#endif

/* numeric.c */
extern VALUE cNumeric;          /* Calc::Numeric module */
extern void define_calc_numeric(VALUE m);

/* q.c (rational numbers) */
extern const rb_data_type_t calc_q_type;
extern VALUE cQ;                /* Calc::Q class */

extern VALUE cq_alloc(VALUE klass);
extern void define_calc_q(VALUE m);

/* c.c (complex numbers) */
extern const rb_data_type_t calc_c_type;
extern VALUE cC;                /* Calc::C class */

extern VALUE cc_alloc(VALUE klass);
extern void define_calc_c(VALUE m);

/*** macros ***/

/* initialize new ruby values */
#define cq_new() cq_alloc(cQ)
#define cc_new() cc_alloc(cC)

/* test ruby values match our TypedData classes */
#define CALC_Q_P(v) (rb_typeddata_is_kind_of((v), &calc_q_type))
#define CALC_C_P(v) (rb_typeddata_is_kind_of((v), &calc_c_type))

/* ruby before 2.1 doesn't have RARRAY_AREF */
#ifndef RARRAY_AREF
#define RARRAY_AREF(a, i) (RARRAY_PTR(a)[i])
#endif

#endif                          /* CALC_H */
