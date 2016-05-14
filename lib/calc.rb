require "calc/version"
require "calc/calc"
require "calc/numeric"
require "calc/q"
require "calc/c"

module Calc
  # builtins implemented as instance methods on Calc::Q or Calc::C
  BUILTINS1 = %i(
    abs acos acosh acot acoth acsc acsch agd appr arg asec asech asin asinh
    atan atan2 atanh bit bernoulli bround catalan ceil char cfappr cfsim cmp
    comb conj cos cosh cot coth csc csch den digit digits estr euler exp fact
    factor fcnt frac frem fib floor gcd gcdrem gd highbit hypot im inverse
    iseven isimag isint isodd isreal num perm power quomod re round sec sech
    sin sinh sqrt tan tanh
  ).freeze

  # builtins implemented as module methods on Calc
  BUILTINS2 = %i(
    avg config freebernoulli freeeuler hean hnrmod pi polar
  ).freeze

  ALL_BUILTINS = BUILTINS1 + BUILTINS2

  # module versions of instance builtins; implemented by turning the first
  # argument into the right class and calling the instance method
  class << self
    BUILTINS1.each do |f|
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

  def self.Q(*args) # rubocop:disable Style/MethodName
    Q.new(*args)
  end

  def self.C(*args) # rubocop:disable Style/MethodName
    C.new(*args)
  end

  # Average (arithmetic mean)
  #
  # Any number of numeric arguments can be provided.  Returns the sum of all
  # values divided by the number of values.  If no values are provided, returns
  # nil.
  #
  # @return [Calc::Q,Calc::C]
  # @example
  #   Calc.avg(1, 2, 3)          #=> Calc::Q(2)
  #   Calc.avg(4, Calc::C(2, 2)) #=> Calc::C(3+1i)
  def self.avg(*args)
    return nil if args.none?
    args.map { |n| to_calc_x(n) }.inject(:+) / args.size
  end

  # Harmonic mean
  #
  # Returns zero if any of the provded values is zero.  Returns nil if no
  # values are provided.  Otherwise returns the harmonic mean of the given
  # values.
  #
  # @return [Calc::Q,Calc::C]
  #   Calc.hmean(1, 2, 4)          #=> Calc::Q(12/7)
  #   Calc.hmean(2, Complex(0, 2)) #=> Calc::C(2+2i)
  def self.hmean(*args)
    return nil if args.none?
    return Calc::Q(0) if args.detect(&:zero?)
    args.size / args.map { |n| to_calc_x(n) }.map(&:inverse).inject(:+)
  end

  # returns a Calc::Q or Calc::C object, converting if necessary
  def self.to_calc_x(n)
    if n.is_a?(Calc::Q) || n.is_a?(Calc::C)
      n
    elsif n.is_a?(Complex)
      Calc::C(n)
    else
      Calc::Q(n)
    end
  end
  private_class_method :to_calc_x
end
