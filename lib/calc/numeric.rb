module Calc
  class Numeric
    # Unary plus.  Returns the receiver's value.
    #
    # @return [Calc::Numeric]
    # @example
    #  +Calc::C(1,1) #=> Calc::C(1,1)
    #  +Calc::Q(1)   #=> Calc::Q(1)
    def +@
      self
    end

    # Returns the argument (the angle or phase) of a complex number in radians.
    #
    # This this method is used by non-complex classes, it will be 0 for
    # positive values, pi() otherwise
    #
    # @param eps [Calc::Q] (optional) calculation accuracy
    # @return [Calc::Q]
    # @example
    #  Calc::Q(-1).arg #=> Calc::Q(3.14159265358979323846)
    #  Calc::Q(1).arg  #=> Calc::Q(0)
    def arg(*args)
      if self < 0
        Q.pi(*args)
      else
        self.class.new(0)
      end
    end

    def remainder(y)
      z = self % y
      if ((!z.zero?) && ((self < 0 && y > 0) || (self > 0 && y < 0)))
        return z - y
      end
      return z
    end

    # Provides support for Ruby type coercion.
    def coerce(other)
      [self.class.new(other), self]
    end

  end
end
