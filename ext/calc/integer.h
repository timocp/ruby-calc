#ifndef INTEGER_H
#define INTEGER_H 1

void define_calc_z();

/* macro to test if a ruby VALUE is a ZVALUE */
#define ISZVALUE(v) (TYPE(v) == T_DATA && RDATA(v)->dfree == cz_free)

#endif                          /* INTEGER_H */
