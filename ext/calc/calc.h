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
VALUE cz_init(VALUE self, VALUE param);

#endif /* CALC_H */
