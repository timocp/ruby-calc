require 'minitest_helper'

class TestRational < MiniTest::Test

  BIG  =  0x4000000000000000  # first BigNum
  BIG2 =  0x8000000000000000  # first Bignum that won't fit in a long
  BIG3 = -0x8000000000000001  # first negative bignum that won't fit in a long
  EPS20 = Calc::Q("1e-20")
  EPS5  = Calc::Q("1e-5")
  EPS4  = Calc::Q("1e-4")

  def test_class_exists
    refute_nil Calc::Q
  end

  def test_initialization
    # num/den versions
    assert_instance_of Calc::Q, Calc::Q.new(1, 3)           # Fixnum
    assert_instance_of Calc::Q, Calc::Q.new(BIG, BIG+1)     # Bignum
    assert_instance_of Calc::Q, Calc::Q.new(BIG2, BIG2+1)   # big Bignum
    assert_instance_of Calc::Q, Calc::Q.new(BIG3, BIG3-1)   # small Bignum
    assert_instance_of Calc::Q, Calc::Q.new("1", "3")       # strings
    assert_instance_of Calc::Q, Calc::Q("1e3", "1e-3")      # exponential string
    assert_instance_of Calc::Q, Calc::Q(0.3, 2.0)

    # single param version
    assert_instance_of Calc::Q, Calc::Q.new(1)
    assert_instance_of Calc::Q, Calc::Q.new(BIG)
    assert_instance_of Calc::Q, Calc::Q.new(BIG2)
    assert_instance_of Calc::Q, Calc::Q.new(BIG3)
    assert_instance_of Calc::Q, Calc::Q.new("1/3")
    assert_instance_of Calc::Q, Calc::Q.new("1e3")
    assert_instance_of Calc::Q, Calc::Q.new("1e-3")
    assert_instance_of Calc::Q, Calc::Q.new(Rational(1,3))
    assert_instance_of Calc::Q, Calc::Q.new(0.3)
  end

  def test_intialization_div_zero
    assert_raises(ZeroDivisionError) { Calc::Q.new(5, 0) }
    assert_raises(ZeroDivisionError) { Calc::Q.new(5, "0") }
    assert_raises(ZeroDivisionError) { Calc::Q.new("5/0") }
  end

  def test_concise_initialization
    assert_instance_of Calc::Q, Calc::Q(1, 3)
    assert_instance_of Calc::Q, Calc::Q(42)
  end
  
  def test_dup
    q1 = Calc::Q(13, 4)
    q2 = q1.dup
    assert_equal 3.25, q2
    refute_equal q1.object_id, q2.object_id
  end

  def test_equal
    assert Calc::Q.new(3) == Calc::Q.new(3)     # Q == Q
    assert Calc::Q.new(3) == Calc::Q.new(6, 2)  # Q == Q (reduced)
    assert Calc::Q.new(3) == 3                  # Q == Fixnum
    assert Calc::Q.new(BIG) == BIG              # Q == Bignum
    assert Calc::Q.new(BIG2) == BIG2            # large positive bignum
    assert Calc::Q.new(BIG3) == BIG3            # large negative bugnum
    assert Calc::Q.new(2,3) == Rational(2,3)    # Q == Rational
    assert Calc::Q.new(0.5) == 0.5              # Q == Float

    assert Calc::Q.new(3) != Calc::Q.new(4)
    assert Calc::Q.new(3) != Calc::Q.new(4, 2)
    assert Calc::Q.new(3) != 4
    assert Calc::Q.new(BIG) != BIG + 1
    assert Calc::Q.new(2,3) != Rational(3,4)
    assert Calc::Q.new(0.3) != 0.301
    assert Calc::Q.new(2,3) != "dog"
  end

  def test_reduction
    assert_equal 2, Calc::Q(4, 6).numerator
    assert_equal 3, Calc::Q(4, 6).denominator
    assert_equal 2, Calc::Q("4/6").numerator
    assert_equal 3, Calc::Q("4/6").denominator
    assert_equal 2, Calc::Q(Rational(4,6)).numerator
    assert_equal 3, Calc::Q(Rational(4,6)).denominator
    assert_equal 1, Calc::Q(0.5).numerator
    assert_equal 2, Calc::Q(0.5).denominator

    assert_equal 1, Calc::Q(1, 3).numerator
    assert_equal 3, Calc::Q(1, 3).denominator
    assert_equal 1, Calc::Q("1/3").numerator
    assert_equal 3, Calc::Q("1/3").denominator
    assert_equal 1, Calc::Q(Rational(1, 3)).numerator
    assert_equal 3, Calc::Q(Rational(1, 3)).denominator

    # check sign is always in numerator
    assert_equal  1, Calc::Q.new( 1,  3).numerator
    assert_equal  3, Calc::Q.new( 1,  3).denominator
    assert_equal -1, Calc::Q.new(-1,  3).numerator
    assert_equal  3, Calc::Q.new(-1,  3).denominator
    assert_equal -1, Calc::Q.new( 1, -3).numerator
    assert_equal  3, Calc::Q.new( 1, -3).denominator
    assert_equal  1, Calc::Q.new(-1, -3).numerator
    assert_equal  3, Calc::Q.new(-1, -3).denominator
  end

  def test_comparisons
    [
      [ Calc::Q(1,3), Calc::Q(1,4),  Calc::Q(1,3),  Calc::Q(1,2)  ],
      [ Calc::Q(3),   2,             3,             4             ],
      [ Calc::Q(1),   0,             1,             2             ],
      [ Calc::Q(1,3), Rational(1,4), Rational(1,3), Rational(1,2) ],
      [ Calc::Q(0.3), 0.299,         0.3,           0.301         ],
    ].each do |thing, other_lt, other_eq, other_gt|
      assert_equal -1, thing <=> other_gt
      assert_equal  0, thing <=> other_eq
      assert_equal  1, thing <=> other_lt

      assert_operator thing, :<,  other_gt
      assert_operator thing, :<=, other_gt
      assert_operator thing, :<=, other_eq
      assert_operator thing, :>=, other_lt
      assert_operator thing, :>=, other_eq
      assert_operator thing, :>,  other_lt

      refute_operator thing, :<,  other_lt
      refute_operator thing, :<,  other_eq
      refute_operator thing, :<=, other_lt
      refute_operator thing, :>=, other_gt
      refute_operator thing, :>,  other_gt
      refute_operator thing, :>,  other_eq

      assert thing.between?(other_lt, other_gt)
      assert thing.between?(other_lt, other_eq)
      assert thing.between?(other_eq, other_gt)
      refute thing.between?(other_eq, other_lt)
      refute thing.between?(other_gt, other_lt)
      refute thing.between?(other_gt, other_eq)
    end

    assert_nil Calc::Q(1,3) <=> "cat"
    assert_nil "cat" <=> Calc::Q(1,3)
    assert_raises(ArgumentError) { Calc::Q(1,3) <  "cat" }
    assert_raises(ArgumentError) { Calc::Q(1,3) <= "cat" }
    assert_raises(ArgumentError) { Calc::Q(1,3) >  "cat" }
    assert_raises(ArgumentError) { Calc::Q(1,3) >= "cat" }
  end

  def test_unary
    assert_rational_and_equal  42, +Calc::Q( 42)
    assert_rational_and_equal -42, +Calc::Q(-42)
    assert_rational_and_equal -42, -Calc::Q( 42)
    assert_rational_and_equal  42, -Calc::Q(-42)
  end

  def test_add
    assert_rational_and_equal Calc::Q(13, 3), Calc::Q.new(1, 3) + 4
    assert_rational_and_equal Calc::Q(7, 12), Calc::Q.new(1, 3) + Calc::Q.new(1, 4)
    assert_rational_and_equal Calc::Q(7, 12), Calc::Q.new(1, 3) + Rational(1, 4)
    assert_rational_and_equal 0x800000000000002a, Calc::Q(42) + BIG2
  end

  def test_subtract
    assert_rational_and_equal Calc::Q(-1,6), Calc::Q(1,3) - Calc::Q(1,2)
    assert_rational_and_equal Calc::Q(-2,3), Calc::Q(1,3) - 1
    assert_rational_and_equal Calc::Q(1,12), Calc::Q(1,3) - Rational(1,4)
    assert_rational_and_equal Rational(-0x17fffffffffffffff,3), Calc::Q(1,3) - BIG2
  end

  def test_multiply
    assert_rational_and_equal Calc::Q(1,12), Calc::Q(1,3) * Calc::Q(1,4)
    assert_rational_and_equal Calc::Q(4,3),  Calc::Q(1,3) * 4
    assert_rational_and_equal Calc::Q(1,5),  Calc::Q(1,3) * Rational(3,5)
  end

  def test_divide
    assert_rational_and_equal Calc::Q(4,3),  Calc::Q(1,3) / Calc::Q(1,4)
    assert_rational_and_equal Calc::Q(1,6),  Calc::Q(1,3) / 2
    assert_rational_and_equal Calc::Q(5,3),  Calc::Q(1,3) / Rational(1,5)
  end

  def test_mod
    assert_rational_and_equal Calc::Q( 3,28), Calc::Q( 1,4) % Calc::Q( 1,7)
    assert_rational_and_equal Calc::Q( 1,28), Calc::Q(-1,4) % Calc::Q( 1,7)
    assert_rational_and_equal Calc::Q(-1,28), Calc::Q( 1,4) % Calc::Q(-1,7)
    assert_rational_and_equal Calc::Q(-3,28), Calc::Q(-1,4) % Calc::Q(-1,7)

    # other arg types
    assert_rational_and_equal Calc::Q(3,4),  Calc::Q(11,4) % 2
    assert_rational_and_equal Calc::Q(1,12), Calc::Q(11,4) % Rational(1,3)
    assert_rational_and_equal Calc::Q(1,4), Calc::Q(1,4) % BIG2

    # unlike Z and ruby, q % 0 == q
    assert_rational_and_equal Calc::Q(1,4), Calc::Q(1,4) % 0
  end

  def test_abs
    assert_instance_of Calc::Q, Calc::Q(12).abs
    assert_equal 12, Calc::Q(12).abs
    assert_equal 12, Calc::Q(-12).abs
    assert_alias Calc::Q(12), :abs, :magnitude
  end

  def test_quomod
    [5, BIG2, Calc::Q(5), Rational(5,1), 5.0].each do |p|
      [Calc::Q(13).quomod(p)].each do |r|
        assert_instance_of Array, r
        assert_equal 2, r.size
        assert_instance_of Calc::Q, r.first
        assert_instance_of Calc::Q, r.last
      end
    end
    assert_equal [2, 3], Calc::Q(13).quomod(5)
    assert_equal [-4, -2], Calc::Q(10).quomod(-3)

    assert_equal [ 3,  1], Calc::Q( 13).quomod( 4)
    assert_equal [-4, -3], Calc::Q( 13).quomod(-4)
    assert_equal [-4,  3], Calc::Q(-13).quomod( 4)
    assert_equal [ 3, -1], Calc::Q(-13).quomod(-4)
    assert_equal [ 2, Calc::Q( 7,2)], Calc::Q( 23,2).quomod( 4)
    assert_equal [-3, Calc::Q(-1,2)], Calc::Q( 23,2).quomod(-4)
    assert_equal [-3, Calc::Q( 1,2)], Calc::Q(-23,2).quomod( 4)
    assert_equal [ 2, Calc::Q(-7,2)], Calc::Q(-23,2).quomod(-4)

    assert_alias Calc::Q(1), :quomod, :divmod
  end

  def test_modulo_and_remainder
    assert_equal  1, Calc::Q(13).modulo(4)
    assert_equal  1, Calc::Q(13).remainder(4)
    skip {
      # behaviour with negatives is not quite right
      assert_equal -3, Calc::Q(13).modulo(-4)
      assert_equal  1, Calc::Q(13).remainder(-4)
    }
    assert_equal 3.5, Calc::Q(11.5).modulo(4)
  end

  def test_power
    assert_rational_and_equal Calc::Q(3),    Calc::Q(81) ** Calc::Q(1,4)
    assert_in_epsilon Calc::Q(1,9).to_f,  (Calc::Q(1,3) ** 2).to_f
    assert_rational_and_equal Calc::Q(4),    Calc::Q(8) ** Rational(2,3)

    assert_rational_in_epsilon 8.2207405646327461795, Calc::Q(1.2345).power(10)
  end

  def test_shift
    # both arguments have to be integers
    assert_rational_and_equal  128, Calc::Q(4) << Calc::Q(5)
    assert_rational_and_equal    0, Calc::Q(4) >> 5
    assert_rational_and_equal   25, Calc::Q(100) >> Rational(2,1)
    assert_rational_and_equal -320, Calc::Q(-20) << 4
    assert_rational_and_equal   -1, Calc::Q(-20) >> 4
    assert_rational_and_equal    1, Calc::Q(20) << -4
    assert_rational_and_equal  320, Calc::Q(20) >> -4
    assert_rational_and_equal  -12, Calc::Q(-50) << -2
    assert_rational_and_equal -200, Calc::Q(-50) >> -2

    assert_raises(ArgumentError) { Calc::Q.new(2) << Calc::Q(1,3) }
    assert_raises(ArgumentError) { Calc::Q.new(2) << Rational(1,3) }
    assert_raises(Calc::MathError) { Calc::Q.new(1,3) << 1 }
    assert_raises(ArgumentError) { Calc::Q(2) << BIG }
    assert_raises(ArgumentError) { Calc::Q(2) << BIG2 }
  end

  def test_denominator
    assert_instance_of Calc::Q, Calc::Q(1, 2).denominator
    assert_equal 4, Calc::Q( 13,  4).denominator
    assert_equal 4, Calc::Q( 13, -4).denominator
    assert_equal 4, Calc::Q(-13, -4).denominator
    assert_equal 4, Calc::Q(-13, -4).denominator
  end

  def test_numerator
    assert_instance_of Calc::Q, Calc::Q(1, 2).numerator
    assert_equal  13, Calc::Q( 13,  4).numerator
    assert_equal -13, Calc::Q(-13,  4).numerator
    assert_equal -13, Calc::Q( 13, -4).numerator
    assert_equal  13, Calc::Q(-13, -4).numerator
  end

  def test_fact
    assert_instance_of Calc::Q, Calc::Q(42).fact
    assert_equal 1, Calc::Q(0).fact
    assert_equal 1, Calc::Q(1).fact
    assert_equal 2, Calc::Q(2).fact
    assert_equal 120, Calc::Q(5).fact
    assert_equal 3628800, Calc::Q(10).fact
    assert_raises(Calc::MathError) { Calc::Q(-1).fact }
    assert_raises(Calc::MathError) { Calc::Q(1,4).fact }
  end

  def test_to_f
    assert_instance_of Float, Calc::Q(99,2).to_f
    assert_equal 49.5, Calc::Q(99,2).to_f
  end

  def test_to_i
    assert_instance_of Fixnum, Calc::Q(1,4).to_i
    assert_instance_of Fixnum, Calc::Q(5,1).to_i
    assert_equal 0, Calc::Q(1,4).to_i
    assert_equal 5, Calc::Q(5,1).to_i

    # numbers larger than MAXLONG
    assert_equal 90438207500880449001, (Calc::Q(99,2) ** 10).numerator.to_i
    assert_equal 1024,                 (Calc::Q(99,2) ** 10).denominator.to_i
  end

  def test_to_r
    assert_instance_of Rational, Calc::Q(1,4).to_r
    assert_equal 1, Calc::Q(1,4).to_r.numerator
    assert_equal 4, Calc::Q(1,4).to_r.denominator
  end

  def test_to_s
    # default (real)
    assert_equal "42", Calc::Q.new(42).to_s
    assert_equal "0.05", Calc::Q(1,20).to_s
    assert_equal "4611686018427387904", Calc::Q.new(BIG).to_s
    assert_equal "9223372036854775808", Calc::Q(BIG2).to_s

    # other modes
    assert_equal "42",        Calc::Q(42).to_s(:frac)
    assert_equal "42",        Calc::Q(42).to_s(:int)
    assert_equal "42",        Calc::Q(42).to_s(:real)
    assert_equal "4.2e1",     Calc::Q(42).to_s(:sci)
    assert_equal "0x2a",      Calc::Q(42).to_s(:hex)
    assert_equal "052",       Calc::Q(42).to_s(:oct)
    assert_equal "0b101010",  Calc::Q(42).to_s(:bin)

    assert_equal "1/20",      Calc::Q(1,20).to_s(:frac)
    assert_equal "~0",        Calc::Q(1,20).to_s(:int)
    assert_equal "0.05",      Calc::Q(1,20).to_s(:real)
    assert_equal "5e-2",      Calc::Q(1,20).to_s(:sci)
    assert_equal "1/0x14",    Calc::Q(1,20).to_s(:hex)
    assert_equal "1/024",     Calc::Q(1,20).to_s(:oct)
    assert_equal "1/0b10100", Calc::Q(1,20).to_s(:bin)

  end

  def test_pi
    pi = Calc::Q.pi(EPS20)
    assert_instance_of Calc::Q, pi
    assert_equal Rational(157079632679489661923,50000000000000000000), pi

    pi = Calc::Q.pi(EPS5)
    assert_equal Rational(314159,100000), pi
  end

  def test_trig
    # test trig functions which are also in ruby Math by comparing our result
    # to theirs.  note that our results lose precision when converting to
    # float, so this is just testing values are roughly right.
    %i(sin sinh tan tanh).each do |method|
      [-1, 0, 1].each do |input|
        assert_in_epsilon(Math.send(method, input), Calc::Q(input).send(method).to_f)
      end
    end
  end

  def test_acos
    assert_rational_in_epsilon 1.04719755119659774615, Calc::Q(0.5).acos
    assert_complex_parts Calc::Q(2).acos, 0, 1.31695789692481670863
  end

  def test_acosh
    assert_rational_and_equal 0, Calc::Q(1).acosh
    assert_rational_in_epsilon 1.31695789692481670862, Calc::Q(2).acosh
    assert_complex_parts Calc::Q(0).acosh, 0, 1.57079632679489661923
  end

  def test_acot
    assert_rational_in_epsilon 2.35619449019234492885, Calc::Q(-1).acot
    assert_rational_in_epsilon 1.57079632679489661923, Calc::Q(0).acot
    assert_rational_in_epsilon 0.78539816339744830962, Calc::Q(1).acot
  end

  def test_acoth
    assert_rational_in_epsilon 0.5493061443340548457, Calc::Q(2).acoth
    assert_complex_parts Calc::Q(0.5).acoth, 0.5493061443340548457, 1.57079632679489661923
    assert_raises(Calc::MathError) { Calc::Q(0).acoth }
    assert_raises(Calc::MathError) { Calc::Q(1).acoth }
  end

  def test_acsc
    assert_rational_in_epsilon 1.57079632679489661923, Calc::Q(1).acsc
    assert_complex_parts Calc::Q(0.5).acsc, 1.57079632679489661923, -1.31695789692481670863
    assert_raises(Calc::MathError) { Calc::Q(0).acsc }
  end

  def test_acsch
    assert_rational_in_epsilon 0.88137358701954302523, Calc::Q(1).acsch
    assert_raises(Calc::MathError) { Calc::Q(0).acsch }
  end

  def test_asec
    assert_rational_in_epsilon 3.14159265358979323846, Calc::Q(-1).asec
    assert_rational_and_equal 0, Calc::Q(1).asec
    assert_complex_parts Calc::Q(0.5).asec, 0, 1.31695789692481670863
    assert_raises(Calc::MathError) { Calc::Q(0).asec }
  end

  def test_asech
    assert_rational_and_equal 0, Calc::Q(1).asech
    assert_rational_in_epsilon 1.31695789692481670862, Calc::Q(0.5).asech
    assert_complex_parts Calc::Q(-0.5).asech, -1.31695789692481670863, 3.14159265358979323846
    assert_raises(Calc::MathError) { Calc::Q(0).asech }
  end

  def test_asin
    assert_rational_and_equal 0, Calc::Q(0).asin
    assert_rational_in_epsilon 1.57079632679489661923, Calc::Q(1).asin
    assert_complex_parts Calc::Q(2).asin, 1.57079632679489661923, -1.3169578969248167086
  end

  def test_asinh
    assert_rational_in_epsilon -0.88137358701954302523, Calc::Q(-1).asinh
    assert_rational_and_equal 0, Calc::Q(0).asinh
    assert_rational_in_epsilon 0.88137358701954302523, Calc::Q(1).asinh
  end

  def test_atan
    assert_rational_in_epsilon -0.78539816339744830962, Calc::Q(-1).atan
    assert_rational_and_equal 0, Calc::Q(0).atan
    assert_rational_in_epsilon 0.78539816339744830962, Calc::Q(1).atan
  end

  def test_atan2
    [-1,0,1].each do |y|
      [-1,0,1].each do |x|
        assert_rational_in_epsilon Math.atan2(y,x), Calc::Q(y).atan2(x)
      end
    end
  end

  def test_atanh
    assert_rational_and_equal 0, Calc::Q(0).atanh
    assert_rational_in_epsilon 0.5493061443340548457, Calc::Q(0.5).atanh
    assert_raises(Calc::MathError) { Calc::Q(1).atanh }
    assert_complex_parts Calc::Q(2).atanh, 0.5493061443340548457, 1.57079632679489661923
  end

  def test_cos
    assert_rational_in_epsilon 0.5403023058681397174, Calc::Q(-1).cos
    assert_rational_and_equal 1, Calc::Q(0).cos
  end

  def test_cosh
    assert_rational_in_epsilon 1.54308063481524377848, Calc::Q(1).cosh
    assert_rational_and_equal 1, Calc::Q(0).cosh
  end

  def test_cot
    assert_rational_in_epsilon 0.64209261593433070301, Calc::Q(1).cot
    assert_raises(Calc::MathError) { Calc::Q(0).cot }
  end

  def test_coth
    assert_rational_in_epsilon 1.31303528549933130364, Calc::Q(1).coth
    assert_raises(Calc::MathError) { Calc::Q(0).coth }
  end

  def test_csc
    assert_rational_in_epsilon 1.18839510577812121626, Calc::Q(1).csc
    assert_raises(Calc::MathError) { Calc::Q(0).csc }
  end

  def test_csch
    assert_rational_in_epsilon 0.85091812823932154513, Calc::Q(1).csch
    assert_raises(Calc::MathError) { Calc::Q(0).csch }
  end

  def test_exp
    assert_rational_in_epsilon 0.3678794411714423216, Calc::Q(-1).exp
    assert_rational_and_equal 1, Calc::Q(0).exp
    assert_rational_in_epsilon Math::E, Calc::Q(1).exp
    assert_rational_in_epsilon 7.38905609893065022723, Calc::Q(2).exp
  end

  # libcalc ln is equivalent to Math.log
  def test_ln
    assert_raises(Calc::MathError) { Calc::Q(0).ln }
    assert_rational_and_equal 0, Calc::Q(1).ln
    assert_rational_in_epsilon Math.log(2), Calc::Q(2).ln
    assert_complex_parts Calc::Q(-1).ln, 0, 3.14159265358979323846
    assert_complex_parts Calc::Q(-2).ln, 0.69314718055994530942, 3.14159265358979323846
  end

  # libcalc log is equivalent to Math.log10 or Math.log(x, 10)
  def test_log
    assert_raises(Calc::MathError) { Calc::Q(0).log }
    assert_rational_and_equal 0, Calc::Q(1).log
    assert_in_epsilon Math.log10(2), Calc::Q(2).log
    assert_complex_parts Calc::Q(-1).log, 0, 1.36437635384184134748
    assert_complex_parts Calc::Q(-2).log, 0.30102999566398119521, 1.36437635384184134748
  end

  def test_root
    assert_instance_of Calc::Q, Calc::Q(7).root(4)
    assert_in_epsilon 1.62658, Calc::Q(7).root(4)

    assert_raises(Calc::MathError) { Calc::Q(1).root(0) }
    assert_raises(Calc::MathError) { Calc::Q(0).root(-1) }
    assert_raises(Calc::MathError) { Calc::Q(-2).root(4) }

    # these are currently implemented in terms of Q#root
    # calc actually has a sqrt with many options, we're not exposing yet
    assert_instance_of Calc::Q, Calc::Q(4).sqrt
    assert_instance_of Calc::Q, Calc::Q(8).cbrt
    assert_equal 2, Calc::Q(4).sqrt
    assert_equal 2, Calc::Q(8).cbrt
  end

  def test_sec
    assert_instance_of Calc::Q, Calc::Q(0).sec
    assert_in_epsilon 1.85081571768092561791, Calc::Q(1).sec
    assert_equal 1, Calc::Q(0).sec
  end

  def test_sech
    assert_instance_of Calc::Q, Calc::Q(0).sech
    assert_equal 1, Calc::Q(0).sech
    assert_in_epsilon 0.64805427366388539958, Calc::Q(1).sech
  end

  def test_coerce
    assert_instance_of Calc::Q, Rational(1,2) + Calc::Q(3,4)
    assert_equal Calc::Q(5,4), Rational(1,2) + Calc::Q(3,4)
    assert_equal Calc::Q(5,4), 0.5 + Calc::Q(3,4)
    assert_equal Calc::Q(7,4), 1 + Calc::Q(3,4)
  end

  def test_hypot
    assert_rational_and_equal 5, Calc::Q(3).hypot(4)
    assert_rational_in_epsilon 3.60555127546398929312, Calc::Q(2).hypot(-3)
  end

  def test_arg
    assert_instance_of Calc::Q, Calc::Q(1).arg
    assert_in_epsilon Calc::Q.pi, Calc::Q(-1).arg
    assert_equal 0, Calc::Q(1).arg
  end

  def test_bernoulli
    assert_instance_of Calc::Q, Calc::Q(6).bernoulli
    [1, "-1/2", "1/6", 0, "-1/30", 0, "1/42"].each_with_index do |expected, n|
      assert_equal Calc::Q(expected), Calc::Q(n).bernoulli
    end

    # even >= 2^31 is error.  odd >= 2^31 is 0
    assert_raises(Calc::MathError) { Calc::Q("1/2").bernoulli }
    assert_raises(Calc::MathError) { (Calc::Q(2) ** 31).bernoulli }
    assert_equal 0, (Calc::Q(2) ** 31 + 1).bernoulli

    assert_nil Calc.freebernoulli
  end

  def test_agd
    assert_equal 0, Calc::Q(0).agd
    assert_instance_of Calc::Q, Calc::Q(1).agd
    assert_instance_of Calc::C, Calc::Q(2).agd
    assert_in_epsilon 1.22619117088351707081, Calc::Q(1).agd
    assert_in_epsilon 1.5234524435626735209, Calc::Q(2).agd.re
    assert_in_epsilon -3.14159265358979323846, Calc::Q(2).agd.im
  end

  def test_gd
    assert_equal 0, Calc::Q(0).agd
    assert_instance_of Calc::Q, Calc::Q(1).gd
    assert_in_epsilon 0.86576948323965862429, Calc::Q(1).gd
  end

  def test_isreal
    assert_instance_of TrueClass, Calc::Q(1).isreal
    assert_alias Calc::Q(1), :isreal, :real?
  end

  def test_isimag
    assert_instance_of FalseClass, Calc::Q(1).isimag
    assert_alias Calc::Q(1), :isimag, :imag?
  end

  def test_re
    assert_rational_and_equal 5, Calc::Q(5).re
    assert_alias Calc::Q(5), :re, :real
  end

  def test_im
    assert_rational_and_equal 0, Calc::Q(5).im
    assert_alias Calc::Q(5), :im, :imag
  end

end
