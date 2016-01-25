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

  def self.Q(*args)
    Q.new(*args)
  end
  
  def self.C(*args)
    C.new(*args)
  end

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
      %i(abs acos acosh acot acoth acsc acsch agd arg asec asech asin asinh
         atan atan2 atanh bernoulli cbrt cos cosh cot coth csc csch exp fact gd
         hypot ln log power quomod root sec sech sin sinh sqrt tan
         tanh).each do |f|
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
    #   Calc::C(4,5).abs("1e-5") #=> Calc::Q(6.40312)
    def abs(*args)
      # see absvalue() in value.c
      re.hypot(im, *args)
    end

    # Returns the argument (the angle or phase) of a complex number in radians.
    #
    # @param eps [Calc::Q] (optional) calculation accuracy
    # @return [Calc::Q]
    # @example
    #  Calc::C(1,0)  #=> 0
    #  Calc::C(-1,0) #=> -pi
    #  Calc::C(1,1)  #=> Calc::Q(0.78539816339744830962)
    def arg(*args)
      # see f_arg() in func.c
      Q.atan2(im, re, *args)
    end

    # Trigonometric cotangent
    #
    # @param eps [Calc::Q] (optional) calculation accuracy
    # @return [Calc::C]
    # @example
    #  Calc::C(2,3).cot #=> Calc::C(~-0.00373971037633695666-~0.99675779656935831046i)
    def cot(*args)
      # see f_cot() in func.c
      cos(*args) / sin(*args)
    end

    # Hyperbolic cotangent
    #
    # @param eps [Calc::Q] (optional) calculation accuracy
    # @return [Calc::C]
    # @example
    #  Calc::C(2,3).coth #=> Calc::C(~1.03574663776499539611+~0.01060478347033710175i)
    def coth(*args)
      # see f_coth() in func.c
      cosh(*args) / sinh(*args)
    end

    # Trigonometric cosecant
    #
    # @param eps [Calc::Q] (optional) calculation accuracy
    # @return [Calc::C]
    # @example
    #  Calc::C(2,3).csc #=> Calc::C(~0.09047320975320743981+~0.04120098628857412646i)
    def csc(*args)
      # see f_csc() in func.c
      sin(*args).invert
    end

    # Hyperbolic cosecant
    #
    # @param eps [Calc::Q] (optional) calculation accuracy
    # @return [Calc::C]
    # @example
    #  Calc::C(2,3).csch #=> Calc::C(~-0.27254866146294019951-~0.04030057885689152187i)
    def csch(*args)
      # see f_csch() in func.c
      sinh(*args).invert
    end

    # Trigonometric secant
    #
    # @param eps [Calc::Q] (optional) calculation accuracy
    # @return [Calc::C]
    # @example
    #  Calc::C(2,3).sec #=> Calc::C(~-0.04167496441114427005+~0.09061113719623759653i)
    def sec(*args)
      # see f_sec() in func.c
      cos(*args).invert
    end

    # Hyperbolic secant
    #
    # @param eps [Calc::Q] (optional) calculation accuracy
    # @return [Calc::C]
    # @example
    #  Calc::C(2,3).sech #=> Calc::C(~-0.26351297515838930964-~0.03621163655876852087i)
    def sech(*args)
      # see f_sech() in func.c
      cosh(*args).invert
    end

    # Trigonometric tangent
    #
    # @param eps [Calc::Q] (optional) calculation accuracy
    # @return [Calc::C]
    # @example
    #  Calc::C(1,2).tan #=> Calc::C(~-0.00376402564150424829+~1.00323862735360980145i)
    def tan(*args)
      # see f_tan() in func.c
      sin(*args) / cos(*args)
    end

    # Hyperbolic tangent
    #
    # @param eps [Calc::Q] (optional) calculation accuracy
    # @return [Calc::C]
    # @example
    #  Calc::C(1,2).tanh #=> Calc::C(~0.96538587902213312428-~0.00988437503832249372i)
    def tanh(*args)
      # see f_tanh() in func.c
      sinh(*args) / cosh(*args)
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
      %i(abs acos acosh acot acoth acsc acsch agd arg asec asech asin asinh
         atan atanh cos cosh cot coth csc csch gd power sec sech sin sinh tan
         tanh).each do |f|
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
