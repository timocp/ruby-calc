module Calc
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

    # Approximate numbers of multiples of a specific number.
    #
    # c.appr(y,z) is equivalent to c.re.appr(y,z) + c.im.appr(y,z) * Calc::C(0,1)
    def appr(*args)
      q1 = re.appr(*args)
      q2 = im.appr(*args)
      if q2.zero?
        q1
      else
        self.class.new(q1, q2)
      end
    end

    # Returns the argument (the angle or phase) of a complex number in radians.
    #
    # @param eps [Calc::Q] (optional) calculation accuracy
    # @return [Calc::Q]
    # @example
    #  Calc::C(1,0).arg  #=> 0
    #  Calc::C(-1,0).arg #=> -pi
    #  Calc::C(1,1).arg  #=> Calc::Q(0.78539816339744830962)
    def arg(*args)
      # see f_arg() in func.c
      im.atan2(re, *args)
    end
    alias angle arg

    # Round real and imaginary parts to the specified number of binary digits
    #
    # @return [Calc::C,Calc::Q]
    # @param places [Integer] number of binary places to round to (default 0)
    # @param rns [Integer] rounding flags (default Calc.config(:round))
    # @example
    #   Calc::C("7/32","-7/32").bround(3) #=> Calc::C(0.25-0.25i)
    def bround(*args)
      q1 = re.bround(*args)
      q2 = im.bround(*args)
      if q2.zero?
        q1
      else
        Calc::C.new(q1, q2)
      end
    end

    # Complex conjugate
    #
    # Returns the complex conjugate of self (same real part and same imaginary
    # part but with opposite sign)
    #
    # @return [Calc::C]
    # @example
    #  Calc::C(3,3).conj #=> Calc::C(3-3i)
    def conj
      Calc::C.new(re, -im)
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
      sin(*args).inverse
    end

    # Hyperbolic cosecant
    #
    # @param eps [Calc::Q] (optional) calculation accuracy
    # @return [Calc::C]
    # @example
    #  Calc::C(2,3).csch #=> Calc::C(~-0.27254866146294019951-~0.04030057885689152187i)
    def csch(*args)
      # see f_csch() in func.c
      sinh(*args).inverse
    end

    # Returns a string which if evaluated creates a new object with the original value
    #
    # @return [String]
    # @example
    #   Calc::C(0.5,-2).estr #=> "Calc::C(Calc::Q(1,2),-2)"
    def estr
      s = self.class.name
      s << "("
      s << (re.int? ? re.to_s : re.estr)
      s << "," + (im.int? ? im.to_s : im.estr) unless im.zero?
      s << ")"
      s
    end

    # Returns true if self has integer real part and zero imaginary part
    #
    # @return [Boolean]
    # @example
    #   Calc::C(1,1).int?  #=> false
    #   Calc::C(1,0).int?  #=> true
    def int?
      im.zero? ? re.int? : false
    end

    def iseven
      even? ? Q::ONE : Q::ZERO
    end

    # Returns 1 if the number is imaginary (zero real part and non-zero
    # imaginary part) otherwise returns 0.  See also [imag?].
    #
    # @return [Calc::Q]
    # @example
    #  Calc::C(0,1).isimag #=> Calc::Q(1)
    #  Calc::C(1,1).isimag #=> Calc::Q(0)
    def isimag
      imag? ? Q::ONE : Q::ZERO
    end

    def isodd
      odd? ? Q::ONE : Q::ZERO
    end

    # Returns 1 if the number has zero imaginary part, otherwise returns 0.
    # See also [real?].
    #
    # @return [Calc::Q]
    # @example
    #  Calc::C(1,1).isreal #=> Calc::Q(0)
    #  Calc::C(1,0).isreal #=> Calc::Q(1)
    def isreal
      real? ? Q::ONE : Q::ZERO
    end

    # Computes the remainder for an integer quotient
    #
    # Result is equivalent to applying the mod function separately to the real
    # and imaginary parts.
    #
    # @param y [Integer]
    # @param r [Integer] (optional) rounding mode (see "help mod")
    # @return [Calc::C]
    # @example
    #   Calc::C(0, 11).mod(5) #=> Calc::C(1i)
    def mod(*args)
      q1 = re.mod(*args)
      q2 = im.mod(*args)
      if q2.zero?
        q1
      else
        Calc::C(q1, q2)
      end
    end

    # Round real and imaginary parts to the specified number of decimal digits
    #
    # @return [Calc::C,Calc::Q]
    # @param places [Integer] number of decimal places to round to (default 0)
    # @param rns [Integer] rounding flags (default Calc.config(:round))
    #   Calc::C("7/32","-7/32").round(3) #=> Calc::C(0.218-0.219i)
    def round(*args)
      q1 = re.round(*args)
      q2 = im.round(*args)
      if q2.zero?
        q1
      else
        Calc::C.new(q1, q2)
      end
    end

    # Trigonometric secant
    #
    # @param eps [Calc::Q] (optional) calculation accuracy
    # @return [Calc::C]
    # @example
    #  Calc::C(2,3).sec #=> Calc::C(~-0.04167496441114427005+~0.09061113719623759653i)
    def sec(*args)
      # see f_sec() in func.c
      cos(*args).inverse
    end

    # Hyperbolic secant
    #
    # @param eps [Calc::Q] (optional) calculation accuracy
    # @return [Calc::C]
    # @example
    #  Calc::C(2,3).sech #=> Calc::C(~-0.26351297515838930964-~0.03621163655876852087i)
    def sech(*args)
      # see f_sech() in func.c
      cosh(*args).inverse
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
      if im.zero?
        re.to_s(*args)
      elsif re.zero?
        imag_part(im, *args)
      elsif im > 0
        re.to_s(*args) + "+" + imag_part(im, *args)
      else
        re.to_s(*args) + "-" + imag_part(im.abs, *args)
      end
    end

    def inspect
      "Calc::C(#{ self })"
    end

    # aliases for compatibility with ruby Complex
    alias integer? int?

    private

    # for formatting imaginary parts; if a fraction, put the "i" after the
    # denominator (eg 2i/3).  otherwise it goes at the end (eg 0.5i).
    def imag_part(number, *args)
      string = number.to_s(*args)
      string.insert(string.index("/") || -1, "i")
    end
  end
end
