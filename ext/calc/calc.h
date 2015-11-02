#ifndef CALC_H
#define CALC_H 1

#include "ruby.h"

/* cannot include calc/calc.h, which contains many things we need, because it
 * includes calc/value.h which defines VALUE, a name already used by ruby.
 * copying things we need here for now. */
extern void libcalc_call_me_first(void);

#include <calc/cmath.h>
#include <calc/lib_calc.h>

/* functions in integer.c */
VALUE cz_alloc(VALUE klass);
VALUE cz_initialize(VALUE self, VALUE param);
VALUE cz_initialize_copy(VALUE copy, VALUE orig);
void cz_free(void *p);

VALUE cz_comparison(VALUE self, VALUE other);
VALUE cz_equal(VALUE self, VALUE other);
VALUE cz_to_s(VALUE self);

/* macro to test if a ruby VALUE is a ZVALUE */
#define ISZVALUE(v) (TYPE(v) == T_DATA && RDATA(v)->dfree == cz_free)

#endif /* CALC_H */
