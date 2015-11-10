#ifndef RATIONAL_H
#define RATIONAL_H 1

extern void define_calc_q(VALUE m);

extern VALUE cQ;
extern const rb_data_type_t calc_q_type;

/* macro to test if a ruby VALUE is a Calc::Q object */
#define ISQVALUE(v) (rb_typeddata_is_kind_of((v), &calc_q_type))

#endif
