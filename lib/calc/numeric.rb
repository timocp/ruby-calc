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

    # Returns the square of the absolute value
    #
    # This method exists for compatibility with ruby Complex/Numeric.
    #
    # @return [Calc::C,Calc::Q]
    # @example
    #   Calc::Q(5).abs2     #=> Calc::Q(25)
    #   Calc::C(3, -4).abs2 #=> Calc:c::Q(25)
    def abs2
      abs * abs
    end

    # Ceiling
    #
    # For real self, returns the least integer not less than self.
    #
    # For complex self, returns a complex number composed of the ceiling
    # of the real and imaginary parts separately.
    #
    # If ndigits is present, the ceiling is calculated at the nth digit instead
    # of returning an integer.
    #
    # @param ndigits [Integer]
    # @return [Calc::Q,Calc::C]
    # @example
    #   Calc::Q(1.23).ceil      #=> Calc::Q(2)
    #   Calc::Q(1.23).ceil(1)   #=> Calc::Q(1.3)
    #   Calc::C(7.8, 9.1).ceil  #=> Calc::C(8+10i)
    def ceil(ndigits = 0)
      appr(Q.new(10)**-ndigits, 1)
    end

    # Division
    #
    # This method exists for ruby compatibility.  Note that Integer#fdiv will
    # return a Float, however Q#div returns another Q.
    #
    # @param y [Numeric]
    # @return [Calc::C,Calc::Q]
    # @raise [Calc::MathError] if y is 0
    # @example
    #  Calc::Q(2, 3).fdiv(0.5) #=> Calc::Q(~1.33333333333333333333)
    #  Calc::C(11, 22).fdiv(3) #=> Calc::C(~3.66666666666666666667+~7.33333333333333333333i)
    def fdiv(y)
      self / y
    end

    # Floor
    #
    # For real self, returns the greatest integer not greater than self.
    #
    # For complex self, returns a complex number composed of the floor of the
    # real and imaginary parts separately.
    #
    # If ndigits is present, the floor is calculated at the nth digit instead
    # of returning an integer.
    #
    # @param ndigits [Integer]
    # @return [Calc::Q,Calc::C]
    # @example
    #   Calc::Q(1.23).floor     #=> Calc::Q(1)
    #   Calc::C(7.8, 9.1).floor #=> Calc::C(7+9i)
    def floor(ndigits = 0)
      appr(Q.new(10)**-ndigits, 0)
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

    # Base 2 logarithm
    #
    # @return [Calc::Q]
    # @example
    #  Calc::Q(1).log2    #=> Calc::Q(0)
    #  Calc::Q(2).log2    #=> Calc::Q(1)
    #  Calc::Q(10).log2   #=> Calc::Q(~3.32192809488736234786)
    #  Calc::Q(-2).log2   #=> Calc::C(1+~4.53236014182719380961i)
    #  Calc::C(1, 2).log2 #=> Calc::C(~1.16096404744368117393+~1.59727796468810880664i)
    def log2(*args)
      ln(*args) / Q::TWO.ln(*args)
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

    # Returns true if the number is not zero.  For complex `self`, this means
    # that either the real or imaginary parts are not zero.
    #
    # @return [Boolean]
    # @example
    #  Calc::Q(0).nonzero?    #=> false
    #  Calc::Q(1).nonzero?    #=> true
    #  Calc::C(0, 0).nonzero? #=> false
    #  Calc::C(1, 0).nonzero? #=> true
    #  Calc::C(0, 1).nonzero? #=> true
    def nonzero?
      !zero?
    end

    # Returns an array containing the absolute value and the argument (angle).
    # This method exists for compatiblity with ruby's Numeric class.
    #
    # Note that: Calc.polar(a, b).polar == [a, b]
    #
    # @return [Array]
    # @example
    #  Calc::Q(2).polar       #=> [Calc::Q(2), Calc::Q(0)]
    #  Calc::C(1, 2).polar    #=> [Calc::Q(2.23606797749978969641), Calc::Q(1.10714871779409050302)]
    #  Calc.polar(1, 2).polar #=> [Calc::Q(1), Calc::Q(2)]
    def polar
      [abs, arg]
    end

    # Rerurns an array containing the real and imaginary parts as elements.
    # This method exists for compatibility with ruby's Numeric class.
    #
    # @return [Array]
    # @example
    #   Calc::Q(2).rectangular    #=> [Calc::Q(2), Calc::Q(0)]
    #   Calc::C(1, 2).rectangular #=> [Calc::Q(1), Calc::Q(2)]
    def rectangular
      [re, im]
    end
    alias rect rectangular

    # Invokes the child class's `to_i` method to convert self to an integer.
    #
    # Note that the return value is a ruby Integer.  If you want to
    # convert to an integer but have the result be a `Calc::Q` object, use
    # `trunc` or `round`.
    #
    # @return [Integer]
    # @raise [RangeError] if self is complex with non-zero imaginary part
    # @example
    #  Calc::Q("5/2").to_int #=> 2
    #  Calc::C(2, 0).to_int  #=> 2
    def to_int
      to_i
    end

    # Provides support for Ruby type coercion.
    def coerce(other)
      [self.class.new(other), self]
    end
  end
end
