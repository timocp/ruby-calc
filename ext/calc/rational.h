#ifndef RATIONAL_H
#define RATIONAL_H 1

void define_calc_q();

extern const rb_data_type_t calc_q_type;

#define ISQVALUE(v) (rb_typeddata_is_kind_of((v), &calc_q_type))

#endif
