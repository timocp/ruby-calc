require "calc/version"
require "calc/calc"

module Calc
  class Z
    def inspect
      "Calc::Z(#{ to_s })"
    end

    # TODO: implement in C
    def remainder(y)
      z = self % y
      if ((!z.zero?) && ((self < 0 && y > 0) || (self > 0 && y < 0)))
        return z - y
      end
      return z
    end
  end
end
