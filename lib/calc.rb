require "calc/version"
require "calc/calc"

module Calc

  class Z
    def modulo(other)
      divmod(other)[1]
    end
  end

end
