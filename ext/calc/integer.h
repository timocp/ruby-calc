#ifndef INTEGER_H
#define INTEGER_H 1

extern void define_calc_z();
extern ZVALUE value_to_zvalue(VALUE arg);

extern const rb_data_type_t calc_z_type;

/* macro to test if a ruby VALUE is a Calc::Z object */
#define ISZVALUE(v) (rb_typeddata_is_kind_of((v), &calc_z_type))

/* shortcut for getting pointer to Calc::Z's ZVALUE */
#define get_zvalue(ruby_var,c_var) { TypedData_Get_Struct(ruby_var, ZVALUE, &calc_z_type, c_var); }

#endif                          /* INTEGER_H */
