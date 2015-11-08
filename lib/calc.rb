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
  end
end
