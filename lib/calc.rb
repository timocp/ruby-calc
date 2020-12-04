require "calc/version"
require "calc/calc"
require "calc/numeric"
require "calc/q"
require "calc/c"

module Calc
  # builtins implemented as instance methods on Calc::Q or Calc::C
  BUILTINS1 = %i[
    abs acos acosh acot acoth acsc acsch agd appr arg asec asech asin asinh
    atan atan2 atanh bernoulli bit bround btrunc catalan ceil cfappr cfsim char
    cmp comb conj cos cosh cot coth csc csch den digit digits estr euler exp
    fact factor fcnt fib floor frac frem gcd gcdrem gd highbit hypot ilog
    ilog10 ilog2 im int inverse iroot iseven isimag isint ismult isodd isprime
    isqrt isreal isrel issq jacobi lcm lcmfact lfactor ln log lowbit ltol meq
    minv mmin mne mod near nextcand nextprime norm num perm pfact pix places
    pmod popcnt power prevcand prevprime ptest quo quomod re root round scale
    sec sech sgn sin sinh sqrt tan tanh trunc xor
  ].freeze

  # builtins implemented as module methods on Calc
  BUILTINS2 = %i[
    avg config freebernoulli freeeuler hean hnrmod max min pi polar ssq sum
    version
  ].freeze

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
    args.flatten!
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
    args.flatten!
    return nil if args.none?
    return Q::ZERO if args.detect(&:zero?)
    args.size / args.map { |n| to_calc_x(n) }.map(&:inverse).inject(:+)
  end

  # Maximum from provided values.
  #
  # Each argument must be convertable to Calc::Q.  If no values, returns nil.
  #
  # @return [Calc::Q]
  # @example
  #  Calc.max(5, 3, 7, 2, 9) #=> Calc::Q(9)
  def self.max(*args)
    args.compact.map { |n| Calc::Q(n) }.max
  end

  # Minimum from provided values
  #
  # Each argument must be convertable to Calc::Q.  If no values, returns nil.
  #
  # @return [Calc::Q]
  # @example
  #  Calc.min(5, 3, 7, 2, 9) #=> Calc::Q(2)
  def self.min(*args)
    args.compact.map { |n| Calc::Q(n) }.min
  end

  # Evaluate a polynomial
  #
  # First case:
  #   poly(a_0, a_1, ..., a_n, x)
  # returns:
  #   a_n + (a_n-1 + ... + (a_1 + a_0 * x) * x ..) * x
  # In particular:
  #   poly(a, x) -> a
  #   poly(a, b, x) -> b + a * x
  #   poly(a, b, c, x) -> c + (b + a * x) * x
  #                    or a*x**2 + b*x + c
  #
  # In the second case, the first parameter is an array of coefficients, ie:
  #   poly([a_0, a_1, ... a_n], x)
  # returns:
  #   a_0 + (a_n-1 + (a_2 + ... a_n * x) * x)
  # Note that the order of coeffecients is reverse of the first case.
  #
  # If one or more elements of clist is another array, and there is more than
  # one argument (x, y, ...) the coefficient corresponding to such an element
  # is the value of the poly for that list and the next argument in x, y, ...
  # For example:
  #   poly([[a, b, c], [d, e], f], x, y)
  # Returns:
  #   (a + b * y + c * y^2) + (d + e * y) * x + f * x^2
  #
  # For more explanation and examples on how the nested arrays works, see
  # "help poly" bearning in mind that a calc list is equivament to a ruby
  # array.
  #
  # @return [Calc::Numeric]
  # @example
  #   # 2 * 7**2 + 3 * 7 + 5
  #   Calc.poly(2, 3, 5, 7) #=> Calc::Q(124)
  def self.poly(*args)
    raise ArgumentError, "Need at least one argument for poly" if args.none?
    if args.first.respond_to?(:each)
      # second case
      clist = args.shift
      evalpoly(clist, args.flatten, 0)
    else
      # first case
      x = to_calc_x(args.pop)
      return x if args.none?
      args.reverse.each_with_index.map { |coeff, i| to_calc_x(coeff) * x**i }.reduce(:+)
    end
  end

  # evalpoly and evp are modelled on functions of the same name in libcalc,
  # which we can't use because they use VALUE and LIST types.  because the
  # libcalc versions use doubly linked lists, the ruby versions has to pass
  # around an index to the coeffecients array instead.
  def self.evalpoly(clist, lp, x)
    return nil if clist.none?
    if lp[x].nil?
      if clist.first.respond_to?(:each)
        evalpoly(clist.first, lp, x + 1)
      else
        to_calc_x(clist.first)
      end
    else
      evp(clist, lp, x)
    end
  end
  private_class_method :evalpoly

  def self.evp(clist, lp, x)
    clist.reverse.reduce(Q::ZERO) do |vres, v|
      (vres * lp[x]) + if v.respond_to?(:each)
                         evalpoly(v, lp, x + 1) || Q::ZERO
                       else
                         to_calc_x(v)
                       end
    end
  end
  private_class_method :evp

  # Returns the sum of squares.
  #
  # Nil values are ignored.  If any argument is am array, it contributes
  # the sum of squares of its contents recursively.
  #
  # @return [Calc::C,Calc::Q]
  # @raise [ArgumentError] if any argument can't be converted to a Calc class
  # @example
  #  Calc.ssq(1, 2, 3)       #=> Calc::Q(14)
  #  Calc.ssq(1+2i, 3-4i, 5) #=> Calc::C(15-20i)
  def self.ssq(*args)
    args.flatten.map { |term| to_calc_x(term)**2 }.inject(:+)
  end

  def self.sum(*args)
    args.flatten.map { |t| to_calc_x(t) }.compact.inject(:+)
  end

 
  def self.fib(n)
    x, y = 0, 1
    list = Array.new
    while x < n
      list << x 
      x, y = y, x + y
     
    end
    print "#{list}\n"
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
