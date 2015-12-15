require "calc/version"
require "calc/calc"

module Calc
  def self.Z(p)
    Z.new(p)
  end

  def self.Q(*args)
    Q.new(*args)
  end

  class Z
    def inspect
      "Calc::Z(#{ to_s })"
    end

    def /(y)
      self.divmod(y).first
    end

    def remainder(y)
      z = self % y
      if ((!z.zero?) && ((self < 0 && y > 0) || (self > 0 && y < 0)))
        return z - y
      end
      return z
    end

    def to_f
      self.to_r.to_f
    end

    def to_r
      Rational(self.to_i, 1)
    end
  end

  class Q
    def **(other)
      Calc::Q.power(self, other)
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

    # instance versions of trans functions
    %i(acos acosh acot acsc asec asin asinh atan cbrt cos cosh cot coth csc
       csch exp ln log root sec sech sin sinh sqrt tan tanh).each do |f|
      define_method f do |*args|
        Calc::Q.__send__(f, self, *args)
      end
    end

    def self.cbrt(x)
      self.root(x, 3)
    end

    def self.sqrt(x)
      self.root(x, 2)
    end
  end
end
