#ifndef INTEGER_H
#define INTEGER_H 1

void define_calc_z();
ZVALUE value_to_zvalue(VALUE arg);

/* macro to test if a ruby VALUE is a ZVALUE */
#define ISZVALUE(v) (TYPE(v) == T_DATA && RDATA(v)->dfree == cz_free)

/* shortcut for getting pointer to Calc::Z's ZVALUE */
#define get_zvalue(ruby_var,c_var) { Data_Get_Struct(ruby_var, ZVALUE, c_var); }

#endif                          /* INTEGER_H */
