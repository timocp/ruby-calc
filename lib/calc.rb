require "calc/version"
require "calc/calc"
require "calc/numeric"
require "calc/q"
require "calc/c"

module Calc

  # module versions of calc builtins; implemented by turning the argument
  # into the right class and calling the class method
  class << self
    %i(abs acos acosh acot acoth acsc acsch agd arg asec asech asin asinh atan
    atan2 atanh cos cosh cot coth csc csch fact gd im inverse isreal pi quomod
    re sec sech sin sinh tan tanh).each do |f|
      define_method f do |*args|
        x = args.shift
        if x.is_a?(Calc::Q) || x.is_a?(Calc::C)
          x.__send__(f, *args)
        elsif x.is_a?(Complex)
          Calc::C(x).__send__(f, *args)
        else
          Calc::Q(x).__send__(f, *args)
        end
      end
    end
  end

  def self.Q(*args)
    Q.new(*args)
  end
  
  def self.C(*args)
    C.new(*args)
  end
end
