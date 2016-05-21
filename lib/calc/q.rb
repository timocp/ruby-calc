module Calc
  class Q
    ZERO = new(0)
    ONE = new(1)

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
        ZERO
      end
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
      bit?(y) ? ONE : ZERO
    end

    # Returns a string containing the character corresponding to a value
    #
    # Note that this is for compatibility with calc, normally in ruby you
    # should just #chr
    #
    # @return [String]
    # @example
    #  Calc::Q(88).char #=> "X"
    def char
      raise MathError, "Non-integer for char" unless int?
      raise MathError, "Out of range for char" unless between?(0, 255)
      if zero?
        ""
      else
        to_i.chr
      end
    end

    # Complex conjugate
    #
    # As the conjugate of real x is x, this method returns self.
    #
    # @return [Calc::Q]
    # @example
    #  Calc::Q(3).conj #=> 3
    def conj
      self
    end

    # Returns a string which if evaluated creates a new object with the original value
    #
    # @return [String]
    # @example
    #  Calc::Q(0.5).estr #=> "Calc::Q(1,2)"
    def estr
      s = self.class.name
      s << "("
      s << (int? ? num.to_s : "#{ num },#{ den }")
      s << ")"
      s
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
      ZERO
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
      "Calc::Q(#{ self })"
    end

    def iseven
      even? ? ONE : ZERO
    end

    # Returns 1 if the number is imaginary, otherwise returns 0.  Instance of
    # this class always return 0.
    #
    # @return [Calc::Q]
    # @example
    #  Calc::Q(1).isimag #=> Calc::Q(0)
    def isimag
      ZERO
    end

    # Returns 1 if self exactly divides y, otherwise return 0.
    #
    # @return [Calc::Q]
    # @example
    #  Calc::Q(6).ismult(2) #=> Calc::Q(1)
    #  Calc::Q(2).ismult(6) #=> Calc::Q(0)
    # @see Calc::Q#mult?
    def ismult(y)
      mult?(y) ? ONE : ZERO
    end

    def isodd
      odd? ? ONE : ZERO
    end

    # Returns 1 if self is prime, 0 if it is not prime.  This function can't
    # be used for odd numbers > 2^32.
    #
    # @return [Calc::Q]
    # @raise [Calc::MathError] if self is odd and > 2^32
    # @example
    #  Calc::Q(2**31 - 9).isprime #=> Calc::Q(0)
    #  Calc::Q(2**31 - 1).isprime #=> Calc::Q(1)
    def isprime
      prime? ? ONE : ZERO
    end

    # Returns 1 if this number has zero imaginary part, otherwise returns 0.
    # Instances of this class always return 1.
    #
    # @return [Calc::Q]
    # @example
    #  Calc::Q(1).isreal #=> Calc::Q(1)
    def isreal
      ONE
    end

    # Returns 1 if both values are relatively prime
    #
    # @param other [Integer]
    # @return [Calc::Q]
    # @raise [Calc::MathError] if either values are non-integers
    # @example
    #  Calc::Q(6).isrel(5) #=> Calc::Q(1)
    #  Calc::Q(6).isrel(2) #=> Calc::Q(0)
    # @see Calc::Q#rel?
    def isrel(y)
      rel?(y) ? ONE : ZERO
    end

    # Returns 1 if this value is a square
    #
    # @return [Calc::Q]
    # @example
    #  Calc::Q(25).issq     #=> Calc::Q(1)
    #  Calc::Q(3).issq      #=> Calc::Q(0)
    #  Calc::Q("4/25").issq #=> Calc::Q(1)
    # @see Calc::Q#sq?
    def issq
      sq? ? ONE : ZERO
    end

    # test for equaility modulo a specific number
    #
    # Returns 1 if self is congruent to y modulo md, otherwise 0.
    #
    # @param y [Numeric]
    # @param md [Numeric]
    # @return [Calc::Q]
    # @example
    #  Calc::Q(5).meq(33, 7) #=> Calc::Q(1)
    #  Calc::Q(5).meq(32, 7) #=> Calc::Q(0)
    # @see Calc::Q#meq?
    def meq(y, md)
      meq?(y, md) ? ONE : ZERO
    end

    # test for inequality modulo a specific number
    #
    # Reurns 1 if self is not congruent to y modulo md, otherwise 0.
    # This is the opposite of #meq.
    #
    # @param y [Numeric]
    # @param md [Numeric]
    # @return [Calc::Q]
    # @example
    #  Calc::Q(5).mne(33, 7) #=> Calc::Q(0)
    #  Calc::Q(5).mne(32, 7) #=> Calc::Q(1)
    # @see Calc::Q#mne?
    def mne(y, md)
      meq?(y, md) ? ZERO : ONE
    end

    # test for inequality modulo a specific number
    #
    # Returns true of self is not congruent to y modulo md.
    # This is the opposiute of #meq?.
    #
    # @param y [Numeric]
    # @param md [Numeric]
    # @return [Boolean]
    # @example
    #   Calc::Q(5).mne?(33, 7) #=> false
    #   Calc::Q(5).mne?(32, 6) #=> true
    def mne?(y, md)
      !meq?(y, md)
    end

    # Probabilistic primacy test
    #
    # Returns 1 if ptest? would have returned true, otherwise 0.
    #
    # @param count [Integer]
    # @param skip [Integer]
    # @return [Calc::Q]
    # @see Calc::Q#ptest?
    def ptest(*args)
      ptest?(*args) ? ONE : ZERO
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

    # Returns a ruby Complex number with self as the real part and zero
    # imaginary part.
    #
    # @return [Complex]
    # @example
    #  Calc::Q(2).to_c    #=> (2+0i)
    #  Calc::Q(2.5).to_c  #=> ((5/2)+0i)
    def to_c
      Complex(int? ? to_i : to_r, 0)
    end

    # Returns a Calc::C complex number with self as the real part and zero
    # imaginary part.
    #
    # @return [Calc::C]
    # @example
    #   Calc::Q(2).to_complex #=> Calc::C(2)
    def to_complex
      C.new(self, 0)
    end

    # libcalc has no concept of floating point numbers.  so we use ruby's
    # Rational#to_f
    def to_f
      to_r.to_f
    end

    # convert to a core ruby Rational
    def to_r
      Rational(numerator.to_i, denominator.to_i)
    end

    # Bitwise exclusive or of a set of integers
    #
    # xor(a, b, c, ...) is equivalent to (((a ^ b) ^ c) ... )
    # note that ^ is the ruby xor operator, not the calc power operator.
    #
    # @return [Calc::Q]
    # @example
    #   Calc::Q(3).xor(5)           #=> Calc::Q(6)
    #   Calc::Q(5).xor(3, -7, 2, 9) #=> Calc::Q(-12)
    def xor(*args)
      args.inject(self, :^)
    end

    # aliases for compatibility with ruby Fixnum/Bignum/Rational
    alias imag im
    alias integer? int?
    alias real re
  end
end
