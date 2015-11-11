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

    # TODO: implement in C

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
  end

  class Q
    def inspect
      "Calc::Q(#{ to_s })"
    end

    # instance versions of trig functions
    %i(sin cos tan).each do |f|
      define_method f do |*args|
        Calc::Q.__send__(f, self, *args)
      end
    end
  end
end
