require "calc/version"
require "calc/calc"

module Calc

  class Numeric
    # Unary plus.  Returns the receiver's value.
    #
    # @return [Calc::Numeric]
    # @example
    #  +Calc::C(1,1) #=> Calc::C(1,1)
    #  +Calc::Q(1)   #=> Calc::Q(1)
    #  +Calc::Z(1)   #=> Calc::Z(1)
    def +@
      self
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

  def self.Z(p)
    Z.new(p)
  end

  def self.Q(*args)
    Q.new(*args)
  end
  
  def self.C(*args)
    C.new(*args)
  end

  class Z
    def inspect
      "Calc::Z(#{ to_s })"
    end

    def /(y)
      self.divmod(y).first
    end

    def %(y)
      self.divmod(y).last
    end

    alias modulo %

    def to_r
      Rational(self.to_i, 1)
    end
  end

  class Q
    def **(other)
      power(other)
    end

    def inspect
      "Calc::Q(#{ to_s })"
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

    def cbrt
      root(3)
    end

    def sqrt
      root(2)
    end

    class << self
      # module versions of some methods for convenience
      %i(acos acosh acot acoth acsc acsch asec asech asin asinh atan atan2
         atanh cbrt cos cosh cot coth csc csch exp hypot ln log power root sec
         sech sin sinh sqrt tan tanh).each do |f|
        define_method f do |*args|
          Calc::Q(args.first).__send__(f, *args[1..-1])
        end
      end
    end

  end

  class C
    # Returns the absolute value of a complex number.  For purely real or
    # purely imaginary values, returns the absolute value of the non-zero
    # part.  Otherwise returns the absolute part of its complex form within
    # the specified accuracy.
    #
    # @param eps [Calc::Q] (optional) calculation accuracy
    # @return [Calc::Q]
    # @example
    #   Calc::C(-1).abs          #=> Calc::Q(1)
    #   Calc::C(3,-4).abs        #=> Calc::Q(5)
    #   Calc::C(4,5).abs("1e-5") #=> Calc::Q(6.40312) XXX
    def abs(*args)
      if real?
        re.abs
      elsif imag?
        im.abs
      else
        re.hypot(im, *args)
      end
    end

    def to_s(*args)
      r = self.re
      i = self.im
      if i.zero?
        r.to_s(*args)
      elsif r.zero?
        imag_part(i, *args)
      elsif i > 0
        r.to_s(*args) + "+" + imag_part(i, *args)
      else
        r.to_s(*args) + "-" + imag_part(i.abs, *args)
      end
    end

    def inspect
      "Calc::C(#{ to_s })"
    end

    class << self
      # module versions of some methods for convenience
      %i(power).each do |f|
        define_method f do |*args|
          Calc::C(args.first).__send__(f, *args[1..-1])
        end
      end
    end

    private

    # for formatting imaginary parts; if a fraction, put the "i" after the
    # denominator (eg 2i/3).  otherwise it goes at the end (eg 0.5i).
    def imag_part(number, *args)
      string = number.to_s(*args)
      string.insert(string.index("/") || -1, "i")
    end

  end
end
