module Calc
  class Numeric
    # Modulo operator
    #
    # x % y is equivalent to x.mod(y).  Rounding mode is determined by
    # Calc.config(:mod).
    #
    # @param y [Integer]
    # @return [Calc::Numeric]
    # @example
    #   Calc::Q(11).mod(5)     #=> Calc::Q(1)
    #   Calc::C(11, 11).mod(5) #=> Calc::C(1+1i)
    def %(other)
      mod other
    end

    # Unary plus.  Returns the receiver's value.
    #
    # @return [Calc::Numeric]
    # @example
    #  +Calc::C(1,1) #=> Calc::C(1,1)
    #  +Calc::Q(1)   #=> Calc::Q(1)
    def +@
      self
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
      appr(1, 1)
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
      appr(1, 0)
    end

    # Floor of logarithm to base 10
    #
    # Returns the greatest integer n for which 10^n <= self.
    #
    # @return [Calc::Q]
    # @raise [Calc::MathError] if self is zero
    # @example
    #   Calc::Q("1/15").ilog10 #=> Calc::Q(-2)
    #   Calc::Q(777).ilog10    #=> Calc::Q(2)
    #   Calc::C(10, 10).ilog10 #=> Calc::Q(1)
    def ilog10
      ilog 10
    end

    # Floor of logarithm to base 2
    #
    # Returns the greatest integer n for which 2^n <= self
    #
    # @return [Calc::Q]
    # @raise [Calc::MathError] if self is zero
    # @example
    #   Calc::Q("1/15").ilog2 #=> Calc::Q(-4)
    #   Calc::Q(777).ilog2    #=> Calc::Q(9)
    #   Calc::C(10, 10).ilog2 #=> Calc::Q(3)
    def ilog2
      ilog 2
    end

    # Returns 1 if self is an integer, otherwise 0.
    #
    # @return [Calc::Q]
    # @example
    #   Calc::Q(1).isint    #=> Calc::Q(1)
    #   Calc::Q(0.5).isint  #=> Calc::Q(0)
    def isint
      int? ? Q::ONE : Q::ZERO
    end

    # least-absol;ute-value residues modulo a specified number
    #
    # x.mmin(md) is equivalent to x.mod(md, 16)
    #
    # @param md [Numeric]
    # @return [Calc::Numeric]
    # @example
    #  Calc::Q(3).mmin(6)    #=> Calc::Q(3)
    #  Calc::C(0, 3).mmin(6) #=> Calc::C(3i)
    def mmin(md)
      mod md, 16
    end

    def remainder(y)
      z = self % y
      if !z.zero? && ((self < 0 && y > 0) || (self > 0 && y < 0))
        z - y
      else
        z
      end
    end

    # Provides support for Ruby type coercion.
    def coerce(other)
      [self.class.new(other), self]
    end
  end
end
