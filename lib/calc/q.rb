module Calc
  class Q
    def **(other)
      power(other)
    end

    # Inverse gudermannian function
    #
    # @param eps [Calc::Q] (optional) calculation accuracy
    # @return [Calc::Q,Calc::C]
    # @example
    #  Calc::Q(1).agd #=> Calc::Q(1.22619117088351707081)
    #  Calc::Q(2).agd #=> Calc::C(1.5234524435626735209-3.14159265358979323846i)
    def agd(*args)
      r = Calc::C(self).agd(*args)
      r.real? ? r.re : r
    end

    # Returns 1 if binary bit y is set in self, otherwise 0.
    #
    # @param y [Numeric] bit position
    # @return [Calc::Q]
    # @example
    #  Calc::Q(9).bit(0) #=> Calc::Q(1)
    #  Calc::Q(9).bit(1) #=> Calc::Q(0)
    # @see bit?
    def bit(y)
      self.class.new(bit?(y) ? 1 : 0)
    end

    # Gudermannian function
    # 
    # @param eps [Calc::Q] (optional) calculation accuracy
    # @return [Calc::Q]
    # @example
    #  Calc::Q(1).gd #=> Calc::Q(0.86576948323965862429)
    def gd(*args)
      r = Calc::C(self).gd(*args)
      r.real? ? r.re : r
    end

    def im
      Calc::Q(0)
    end

    # Returns true if the number is imaginary.  Instances of this class always
    # return false.
    #
    # @return [Boolean]
    # @example
    #  Calc::Q(1).imag? #=> false
    def imag?
      false
    end

    def inspect
      "Calc::Q(#{ to_s })"
    end

    def iseven
      even? ? Calc::Q(1) : Calc::Q(0)
    end

    # Returns 1 if the number is imaginary, otherwise returns 0.  Instance of
    # this class always return 0.
    #
    # @return [Calc::Q]
    # @example
    #  Calc::Q(1).isimag #=> Calc::Q(0)
    def isimag
      Calc::Q(0)
    end

    def isodd
      odd? ? Calc::Q(1) : Calc::Q(0)
    end

    # Returns 1 if this number has zero imaginary part, otherwise returns 0.
    # Instances of this class always return 1.
    #
    # @return [Calc::Q]
    # @example
    #  Calc::Q(1).isreal #=> Calc::Q(1)
    def isreal
      Calc::Q(1)
    end

    def re
      self
    end

    # Returns true if this number has zero imaginary part.  Instances of this
    # class always return true.
    #
    # @return [Boolean]
    # @example
    #  Calc::Q(1).real? #=> true
    def real?
      true
    end

    # libcalc has no concept of floating point numbers.  so we use ruby's
    # Rational#to_f
    def to_f
      self.to_r.to_f
    end

    # convert to a core ruby Rational
    def to_r
      Rational(self.numerator.to_i, self.denominator.to_i)
    end

    alias imag im
    alias real re
  end
end
