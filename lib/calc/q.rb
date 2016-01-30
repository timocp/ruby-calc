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

    def cbrt
      root(3)
    end

    def inspect
      "Calc::Q(#{ to_s })"
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

    def sqrt
      root(2)
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

    class << self
      # module versions of some methods for convenience
      %i(acos acosh acot acoth acsc acsch agd arg asec asech asin asinh
         atan atan2 atanh bernoulli cbrt cos cosh cot coth csc csch exp fact gd
         hypot ln log power quomod root sec sech sin sinh sqrt tan
         tanh).each do |f|
        define_method f do |*args|
          Calc::Q(args.first).__send__(f, *args[1..-1])
        end
      end
    end
  end
end
