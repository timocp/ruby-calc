#include "calc.h"

/* freeh() is provided by libcalc, pointer version of zfree() */
void zvalue_free(void *p) {
  freeh(p);
}

VALUE zvalue_alloc(VALUE klass) {
  ZVALUE *z;
  VALUE obj;

  /* use Make, not Wrap.  Make will zero the space allocated.  Probably this
   * is just for ZVALUEs, since NUMBER and COMPLEX have their own allocation
   * functions */
  obj = Data_Make_Struct(klass, ZVALUE, 0, zvalue_free, z);

  return obj;
}

VALUE zvalue_init(VALUE self, VALUE param) {
  ZVALUE *z, *zother;

  Data_Get_Struct(self, ZVALUE, z);
  if (TYPE(param) == T_FIXNUM) {
    itoz(NUM2LONG(param), z);
  }
  else {
    rb_raise(rb_eTypeError, "expected Fixnum");
  }
  return self;
}

