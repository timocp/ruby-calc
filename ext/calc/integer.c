#include "calc.h"

/* freeh() is provided by libcalc, pointer version of zfree() */
void cz_free(void *p) {
  freeh(p);
}

VALUE cz_alloc(VALUE klass) {
  ZVALUE *z;
  VALUE obj;

  /* use Make, not Wrap.  Make will zero the space allocated.  Probably this
   * is just for ZVALUEs, since NUMBER and COMPLEX have their own allocation
   * functions */
  obj = Data_Make_Struct(klass, ZVALUE, 0, cz_free, z);

  return obj;
}

VALUE cz_initialize(VALUE self, VALUE param) {
  ZVALUE *z, *zother;

  Data_Get_Struct(self, ZVALUE, z);
  if (TYPE(param) == T_FIXNUM) {
    itoz(NUM2LONG(param), z);
  }
  else if (TYPE(param) == T_BIGNUM) {
    itoz(NUM2LONG(param), z);
  }
  else if (ISZVALUE(param)) {
    Data_Get_Struct(param, ZVALUE, zother);
    zcopy(*zother, z);
  }
  else {
    rb_raise(rb_eTypeError, "expected Fixnum or Bignum");
  }

  return self;
}

/* intialize_copy is used by dupp/clone.  ruby provided version won't work
 * because the underlying ZVALUEs can't be shared. */
VALUE cz_initialize_copy(VALUE copy, VALUE orig) {
  ZVALUE *z1, *z2;

  if (copy == orig) {
    return copy;
  }
  if (!ISZVALUE(orig)) {
    rb_raise(rb_eTypeError, "wrong argument type");
  }

  Data_Get_Struct(orig, ZVALUE, z1);
  Data_Get_Struct(copy, ZVALUE, z2);
  zcopy(*z1, z2);

  return copy;
}

/* used to implement <=>, ==, < and >
 * TODO: won't work if bignum param is > MAX_LONG
 * returns:
 *  0 if values are the same
 *  -1 if self is < other
 *  +1 if self is > other
 *
 * returns -2 if 'other' is not a number.
 */
int _cz_zrel(VALUE self, VALUE other) {
  ZVALUE *zv_self, *zv_tmp, zv_other;
  int result;

  Data_Get_Struct(self, ZVALUE, zv_self);
  if (TYPE(other) == T_FIXNUM || TYPE(other) == T_BIGNUM) {
    itoz(NUM2LONG(other), &zv_other);
    result = zrel(*zv_self, zv_other);
    zfree(zv_other);
  }
  else if (ISZVALUE(other)) {
    Data_Get_Struct(other, ZVALUE, zv_tmp);
    result = zrel(*zv_self, *zv_tmp);
  }
  else {
    result = -2;
  }

  return result;
}

VALUE cz_comparison(VALUE self, VALUE other) {
  int result = _cz_zrel(self, other);
  return result == -2 ? Qnil : INT2FIX(result);
}

VALUE cz_equal(VALUE self, VALUE other) {
  return _cz_zrel(self, other) == 0 ? Qtrue : Qfalse;
}

VALUE cz_gte(VALUE self, VALUE other) {
  return _cz_zrel(self, other) == -1 ? Qfalse : Qtrue;
}

VALUE cz_gt(VALUE self, VALUE other) {
  return _cz_zrel(self, other) == 1 ? Qtrue : Qfalse;
}

VALUE cz_lte(VALUE self, VALUE other) {
  return _cz_zrel(self, other) == 1 ? Qfalse : Qtrue;
}

VALUE cz_lt(VALUE self, VALUE other) {
  return _cz_zrel(self, other) == -1 ? Qtrue : Qfalse;
}

VALUE cz_to_s(VALUE self) {
  ZVALUE *z;
  char *s;
  VALUE rs;

  Data_Get_Struct(self, ZVALUE, z);
  math_divertio();
  zprintval(*z, 0, 0);
  s = math_getdivertedio();
  rs = rb_str_new2(s);
  free(s);

  return rs;
}
