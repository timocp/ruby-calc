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
        Calc.pi(*args)
      else
        self.class.new(0)
      end
    end

    # Ceiling
    #
    # For real self, returns the least integer not less than self.
    #
    # For complex self, returns a complex number composed of the ceiling
    # of the real and imaginary parts separately.
    #
    # @return [Calc::Q,Calc::C]
    # @example
    #   Calc::Q(1.23).ceil      #=> Calc::Q(2)
    #   Calc::C(7.8, 9.1).ceil  #=> Calc::C(8+10i)
    def ceil
      appr(1,1)
    end

    # Returns 1 if self is an integer, otherwise 0.
    #
    # @return [Calc::Q]
    # @example
    #   Calc::Q(1).isint    #=> Calc::Q(1)
    #   Calc::Q(0.5).isint  #=> Calc::Q(0)
    def isint
      int? ? Calc::Q(1) : Calc::Q(0)
    end

    # Floor
    # 
    # For real self, returns the greatest integer not greater than self.
    #
    # For complex self, returns a complex number composed of the floor of the
    # real and imaginary parts separately.
    #
    # @return [Calc::Q,Calc::C]
    # @example
    #   Calc::Q(1.23).floor     #=> Calc::Q(1)
    #   Calc::C(7.8, 9.1).floor #=> Calc::C(7+9i)
    def floor
      appr(1,0)
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
