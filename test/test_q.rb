require "minitest_helper"

class TestQ < MiniTest::Test
  BIG  =  0x4000000000000000  # first BigNum
  BIG2 =  0x8000000000000000  # first Bignum that won't fit in a long
  BIG3 = -0x8000000000000001  # first negative bignum that won't fit in a long

  def test_class_exists
    refute_nil Calc::Q
  end

  def test_initialization
    # num/den versions
    assert_instance_of Calc::Q, Calc::Q.new(1, 3)           # Fixnum
    assert_instance_of Calc::Q, Calc::Q.new(BIG, BIG + 1)   # Bignum
    assert_instance_of Calc::Q, Calc::Q.new(BIG2, BIG2 + 1) # big Bignum
    assert_instance_of Calc::Q, Calc::Q.new(BIG3, BIG3 - 1) # small Bignum
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
    assert_instance_of Calc::Q, Calc::Q.new(Rational(1, 3))
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
    assert Calc::Q.new(3) == Calc::Q.new(3)     # rubocop:disable Lint/UselessComparison
    assert Calc::Q.new(3) == Calc::Q.new(6, 2)  # Q == Q (reduced)
    assert Calc::Q.new(3) == 3                  # Q == Fixnum
    assert Calc::Q.new(BIG) == BIG              # Q == Bignum
    assert Calc::Q.new(BIG2) == BIG2            # large positive bignum
    assert Calc::Q.new(BIG3) == BIG3            # large negative bugnum
    assert Calc::Q.new(2, 3) == Rational(2, 3)  # Q == Rational
    assert Calc::Q.new(0.5) == 0.5              # Q == Float
    assert Calc::Q.new(2) == Complex(2, 0)      # Q == Complex
    assert Calc::Q.new(2) == Calc::C(2, 0)      # Q == Calc::C

    assert Calc::Q.new(3) != Calc::Q.new(4)
    assert Calc::Q.new(3) != Calc::Q.new(4, 2)
    assert Calc::Q.new(3) != 4
    assert Calc::Q.new(BIG) != BIG + 1
    assert Calc::Q.new(2, 3) != Rational(3, 4)
    assert Calc::Q.new(0.3) != 0.301
    assert Calc::Q.new(2, 3) != "dog"
    assert Calc::Q.new(2) != Complex(2, 1)
    assert Calc::Q.new(2) != Calc::C(2, 1)
  end

  def test_reduction
    assert_equal 2, Calc::Q(4, 6).numerator
    assert_equal 3, Calc::Q(4, 6).denominator
    assert_equal 2, Calc::Q("4/6").numerator
    assert_equal 3, Calc::Q("4/6").denominator
    assert_equal 2, Calc::Q(Rational(4, 6)).numerator
    assert_equal 3, Calc::Q(Rational(4, 6)).denominator
    assert_equal 1, Calc::Q(0.5).numerator
    assert_equal 2, Calc::Q(0.5).denominator

    assert_equal 1, Calc::Q(1, 3).numerator
    assert_equal 3, Calc::Q(1, 3).denominator
    assert_equal 1, Calc::Q("1/3").numerator
    assert_equal 3, Calc::Q("1/3").denominator
    assert_equal 1, Calc::Q(Rational(1, 3)).numerator
    assert_equal 3, Calc::Q(Rational(1, 3)).denominator

    # check sign is always in numerator
    assert_equal 1, Calc::Q.new(1, 3).numerator
    assert_equal 3, Calc::Q.new(1, 3).denominator
    assert_equal(-1, Calc::Q.new(-1, 3).numerator)
    assert_equal 3, Calc::Q.new(-1, 3).denominator
    assert_equal(-1, Calc::Q.new(1, -3).numerator)
    assert_equal 3, Calc::Q.new(1, -3).denominator
    assert_equal 1, Calc::Q.new(-1, -3).numerator
    assert_equal 3, Calc::Q.new(-1, -3).denominator
  end

  def test_comparisons
    [
      [Calc::Q(1, 3), Calc::Q(1, 4),  Calc::Q(1, 3),  Calc::Q(1, 2)],
      [Calc::Q(3),    2,              3,              4],
      [Calc::Q(1),    0,              1,              2],
      [Calc::Q(1, 3), Rational(1, 4), Rational(1, 3), Rational(1, 2)],
      [Calc::Q(0.3),  0.299,          0.3,            0.301]
    ].each do |thing, other_lt, other_eq, other_gt|
      assert_equal(-1, thing <=> other_gt)
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

    assert_nil Calc::Q(1, 3) <=> "cat"
    assert_nil "cat" <=> Calc::Q(1, 3)
    assert_raises(ArgumentError) { Calc::Q(1, 3) <  "cat" }
    assert_raises(ArgumentError) { Calc::Q(1, 3) <= "cat" }
    assert_raises(ArgumentError) { Calc::Q(1, 3) >  "cat" }
    assert_raises(ArgumentError) { Calc::Q(1, 3) >= "cat" }
  end

  def test_unary
    assert_rational_and_equal  42, +Calc::Q(42)
    assert_rational_and_equal(-42, +Calc::Q(-42))
    assert_rational_and_equal(-42, -Calc::Q(42))
    assert_rational_and_equal  42, -Calc::Q(-42)
  end

  def test_add
    assert_rational_and_equal Calc::Q(13, 3), Calc::Q.new(1, 3) + 4
    assert_rational_and_equal Calc::Q(7, 12), Calc::Q.new(1, 3) + Calc::Q.new(1, 4)
    assert_rational_and_equal Calc::Q(7, 12), Calc::Q.new(1, 3) + Rational(1, 4)
    assert_rational_and_equal 0x800000000000002a, Calc::Q(42) + BIG2
    assert_complex_parts [2, 2], Calc::Q(2) + Complex(0, 2)
    assert_complex_parts [2, 2], Calc::Q(2) + Calc::C(0, 2)
  end

  def test_subtract
    assert_rational_and_equal Calc::Q(-1, 6), Calc::Q(1, 3) - Calc::Q(1, 2)
    assert_rational_and_equal Calc::Q(-2, 3), Calc::Q(1, 3) - 1
    assert_rational_and_equal Calc::Q(1, 12), Calc::Q(1, 3) - Rational(1, 4)
    assert_rational_and_equal Rational(-0x17fffffffffffffff, 3), Calc::Q(1, 3) - BIG2
    assert_complex_parts [2, -2], Calc::Q(2) - Complex(0, 2)
    assert_complex_parts [2, -2], Calc::Q(2) - Calc::C(0, 2)
  end

  def test_multiply
    assert_rational_and_equal Calc::Q(1, 12), Calc::Q(1, 3) * Calc::Q(1, 4)
    assert_rational_and_equal Calc::Q(4, 3),  Calc::Q(1, 3) * 4
    assert_rational_and_equal Calc::Q(1, 5),  Calc::Q(1, 3) * Rational(3, 5)
    assert_complex_parts [0, 4], Calc::Q(2) * Complex(0, 2)
    assert_complex_parts [0, 4], Calc::Q(2) * Calc::C(0, 2)
  end

  def test_divide
    assert_rational_and_equal Calc::Q(4, 3),  Calc::Q(1, 3) / Calc::Q(1, 4)
    assert_rational_and_equal Calc::Q(1, 6),  Calc::Q(1, 3) / 2
    assert_rational_and_equal Calc::Q(5, 3),  Calc::Q(1, 3) / Rational(1, 5)
    assert_complex_parts [0, -1], Calc::Q(2) / Complex(0, 2)
    assert_complex_parts [0, -1], Calc::Q(2) / Calc::C(0, 2)
  end

  def test_mod
    assert_rational_and_equal Calc::Q(3, 28), Calc::Q(1, 4) % Calc::Q(1, 7)
    assert_rational_and_equal Calc::Q(1, 28), Calc::Q(-1, 4) % Calc::Q(1, 7)
    assert_rational_and_equal Calc::Q(-1, 28), Calc::Q(1, 4) % Calc::Q(-1, 7)
    assert_rational_and_equal Calc::Q(-3, 28), Calc::Q(-1, 4) % Calc::Q(-1, 7)

    # other arg types
    assert_rational_and_equal Calc::Q(3, 4),  Calc::Q(11, 4) % 2
    assert_rational_and_equal Calc::Q(1, 12), Calc::Q(11, 4) % Rational(1, 3)
    assert_rational_and_equal Calc::Q(1, 4), Calc::Q(1, 4) % BIG2

    # unlike Z and ruby, q % 0 == q
    assert_rational_and_equal Calc::Q(1, 4), Calc::Q(1, 4) % 0
  end

  def test_abs
    assert_instance_of Calc::Q, Calc::Q(12).abs
    assert_equal 12, Calc::Q(12).abs
    assert_equal 12, Calc::Q(-12).abs
    assert_alias Calc::Q(12), :abs, :magnitude
  end

  def test_quomod
    [5, BIG2, Calc::Q(5), Rational(5, 1), 5.0].each do |p|
      [Calc::Q(13).quomod(p)].each do |r|
        assert_instance_of Array, r
        assert_equal 2, r.size
        assert_instance_of Calc::Q, r.first
        assert_instance_of Calc::Q, r.last
      end
    end
    assert_equal [2, 3], Calc::Q(13).quomod(5)
    assert_equal [-4, -2], Calc::Q(10).quomod(-3)

    assert_equal [3, 1], Calc::Q(13).quomod(4)
    assert_equal [-4, -3], Calc::Q(13).quomod(-4)
    assert_equal [-4, 3], Calc::Q(-13).quomod(4)
    assert_equal [3, -1], Calc::Q(-13).quomod(-4)
    assert_equal [2, Calc::Q(7, 2)], Calc::Q(23, 2).quomod(4)
    assert_equal [-3, Calc::Q(-1, 2)], Calc::Q(23, 2).quomod(-4)
    assert_equal [-3, Calc::Q(1, 2)], Calc::Q(-23, 2).quomod(4)
    assert_equal [2, Calc::Q(-7, 2)], Calc::Q(-23, 2).quomod(-4)

    assert_alias Calc::Q(1), :quomod, :divmod
  end

  def test_modulo_and_remainder
    assert_equal  1, Calc::Q(13).modulo(4)
    assert_equal  1, Calc::Q(13).remainder(4)
    skip do
      # behaviour with negatives is not quite right
      assert_equal(-3, Calc::Q(13).modulo(-4))
      assert_equal 1, Calc::Q(13).remainder(-4)
    end
    assert_equal 3.5, Calc::Q(11.5).modulo(4)
  end

  def test_power
    assert_rational_and_equal Calc::Q(3), Calc::Q(81)**Calc::Q(1, 4)
    assert_rational_in_epsilon Calc::Q(1, 9), Calc::Q(1, 3)**2
    assert_rational_and_equal Calc::Q(4), Calc::Q(8)**Rational(2, 3)

    assert_rational_in_epsilon 8.2207405646327461795, Calc::Q(1.2345).power(10)
    assert_rational_and_equal(-8, Calc::Q(-2)**3)
    assert_complex_parts [0.95105651629515357212, 0.3090169943749474241], Calc::Q(-1)**"0.1"
    assert_complex_parts [0.18345697474330167684, 0.98302774041124372059], Calc::Q(2)**Complex(0, 2)
    assert_complex_parts [0.18345697474330167684, 0.98302774041124372059], Calc::Q(2)**Calc::C(0, 2)
  end

  def test_shift
    # both arguments have to be integers
    assert_rational_and_equal 128, Calc::Q(4) << Calc::Q(5)
    assert_rational_and_equal 0, Calc::Q(4) >> 5
    assert_rational_and_equal 25, Calc::Q(100) >> Rational(2, 1)
    assert_rational_and_equal(-320, Calc::Q(-20) << 4)
    assert_rational_and_equal(-1, Calc::Q(-20) >> 4)
    assert_rational_and_equal 1, Calc::Q(20) << -4
    assert_rational_and_equal 320, Calc::Q(20) >> -4
    assert_rational_and_equal(-12, Calc::Q(-50) << -2)
    assert_rational_and_equal(-200, Calc::Q(-50) >> -2)

    assert_raises(ArgumentError) { Calc::Q.new(2) << Calc::Q(1, 3) }
    assert_raises(ArgumentError) { Calc::Q.new(2) << Rational(1, 3) }
    assert_raises(Calc::MathError) { Calc::Q.new(1, 3) << 1 }
    assert_raises(ArgumentError) { Calc::Q(2) << BIG }
    assert_raises(ArgumentError) { Calc::Q(2) << BIG2 }
  end

  def test_denominator
    assert_instance_of Calc::Q, Calc::Q(1, 2).den
    assert_equal 4, Calc::Q(13, 4).den
    assert_equal 4, Calc::Q(13, -4).den
    assert_equal 4, Calc::Q(-13, 4).den
    assert_equal 4, Calc::Q(-13, -4).den
    assert_alias Calc::Q(1), :denominator, :den
  end

  def test_numerator
    assert_instance_of Calc::Q, Calc::Q(1, 2).num
    assert_equal 13, Calc::Q(13, 4).num
    assert_equal(-13, Calc::Q(-13, 4).num)
    assert_equal(-13, Calc::Q(13, -4).num)
    assert_equal 13, Calc::Q(-13, -4).num
    assert_alias Calc::Q(1), :numerator, :num
  end

  def test_fact
    assert_instance_of Calc::Q, Calc::Q(42).fact
    assert_equal 1, Calc::Q(0).fact
    assert_equal 1, Calc::Q(1).fact
    assert_equal 2, Calc::Q(2).fact
    assert_equal 120, Calc::Q(5).fact
    assert_equal 3628800, Calc::Q(10).fact
    assert_raises(Calc::MathError) { Calc::Q(-1).fact }
    assert_raises(Calc::MathError) { Calc::Q(1, 4).fact }
  end

  def test_to_f
    assert_instance_of Float, Calc::Q(99, 2).to_f
    assert_equal 49.5, Calc::Q(99, 2).to_f
  end

  def test_to_i
    assert_instance_of Fixnum, Calc::Q(1, 4).to_i
    assert_instance_of Fixnum, Calc::Q(5, 1).to_i
    assert_equal 0, Calc::Q(1, 4).to_i
    assert_equal 5, Calc::Q(5, 1).to_i

    # numbers larger than MAXLONG
    assert_equal 90438207500880449001, (Calc::Q(99, 2)**10).numerator
    assert_equal 1024,                 (Calc::Q(99, 2)**10).denominator
  end

  def test_to_r
    assert_instance_of Rational, Calc::Q(1, 4).to_r
    assert_equal 1, Calc::Q(1, 4).to_r.numerator
    assert_equal 4, Calc::Q(1, 4).to_r.denominator
  end

  def test_to_s
    # default (real)
    assert_equal "42", Calc::Q.new(42).to_s
    assert_equal "0.05", Calc::Q(1, 20).to_s
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

    assert_equal "1/20",      Calc::Q(1, 20).to_s(:frac)
    assert_equal "~0",        Calc::Q(1, 20).to_s(:int)
    assert_equal "0.05",      Calc::Q(1, 20).to_s(:real)
    assert_equal "5e-2",      Calc::Q(1, 20).to_s(:sci)
    assert_equal "1/0x14",    Calc::Q(1, 20).to_s(:hex)
    assert_equal "1/024",     Calc::Q(1, 20).to_s(:oct)
    assert_equal "1/0b10100", Calc::Q(1, 20).to_s(:bin)
  end

  def test_acos
    assert_rational_in_epsilon 1.04719755119659774615, Calc::Q(0.5).acos
    assert_complex_parts [0, 1.31695789692481670863], Calc::Q(2).acos
  end

  def test_acosh
    assert_rational_and_equal 0, Calc::Q(1).acosh
    assert_rational_in_epsilon 1.31695789692481670862, Calc::Q(2).acosh
    assert_complex_parts [0, 1.57079632679489661923], Calc::Q(0).acosh
  end

  def test_acot
    assert_rational_in_epsilon 2.35619449019234492885, Calc::Q(-1).acot
    assert_rational_in_epsilon 1.57079632679489661923, Calc::Q(0).acot
    assert_rational_in_epsilon 0.78539816339744830962, Calc::Q(1).acot
  end

  def test_acoth
    assert_rational_in_epsilon 0.5493061443340548457, Calc::Q(2).acoth
    assert_complex_parts [0.5493061443340548457, 1.57079632679489661923], Calc::Q(0.5).acoth
    assert_raises(Calc::MathError) { Calc::Q(0).acoth }
    assert_raises(Calc::MathError) { Calc::Q(1).acoth }
  end

  def test_acsc
    assert_rational_in_epsilon 1.57079632679489661923, Calc::Q(1).acsc
    assert_complex_parts [1.57079632679489661923, -1.31695789692481670863], Calc::Q(0.5).acsc
    assert_raises(Calc::MathError) { Calc::Q(0).acsc }
  end

  def test_acsch
    assert_rational_in_epsilon 0.88137358701954302523, Calc::Q(1).acsch
    assert_raises(Calc::MathError) { Calc::Q(0).acsch }
  end

  def test_asec
    assert_rational_in_epsilon 3.14159265358979323846, Calc::Q(-1).asec
    assert_rational_and_equal 0, Calc::Q(1).asec
    assert_complex_parts [0, 1.31695789692481670863], Calc::Q(0.5).asec
    assert_raises(Calc::MathError) { Calc::Q(0).asec }
  end

  def test_asech
    assert_rational_and_equal 0, Calc::Q(1).asech
    assert_rational_in_epsilon 1.31695789692481670862, Calc::Q(0.5).asech
    assert_complex_parts [-1.31695789692481670863, 3.14159265358979323846], Calc::Q(-0.5).asech
    assert_raises(Calc::MathError) { Calc::Q(0).asech }
  end

  def test_asin
    assert_rational_and_equal 0, Calc::Q(0).asin
    assert_rational_in_epsilon 1.57079632679489661923, Calc::Q(1).asin
    assert_complex_parts [1.57079632679489661923, -1.3169578969248167086], Calc::Q(2).asin
  end

  def test_asinh
    assert_rational_in_epsilon(-0.88137358701954302523, Calc::Q(-1).asinh)
    assert_rational_and_equal 0, Calc::Q(0).asinh
    assert_rational_in_epsilon 0.88137358701954302523, Calc::Q(1).asinh
  end

  def test_atan
    assert_rational_in_epsilon(-0.78539816339744830962, Calc::Q(-1).atan)
    assert_rational_and_equal 0, Calc::Q(0).atan
    assert_rational_in_epsilon 0.78539816339744830962, Calc::Q(1).atan
  end

  def test_atan2
    [-1, 0, 1].each do |y|
      [-1, 0, 1].each do |x|
        assert_rational_in_epsilon Math.atan2(y, x), Calc::Q(y).atan2(x)
      end
    end
  end

  def test_atanh
    assert_rational_and_equal 0, Calc::Q(0).atanh
    assert_rational_in_epsilon 0.5493061443340548457, Calc::Q(0.5).atanh
    assert_raises(Calc::MathError) { Calc::Q(1).atanh }
    assert_complex_parts [0.5493061443340548457, 1.57079632679489661923], Calc::Q(2).atanh
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
    assert_complex_parts [0, 3.14159265358979323846], Calc::Q(-1).ln
    assert_complex_parts [0.69314718055994530942, 3.14159265358979323846], Calc::Q(-2).ln
  end

  # libcalc log is equivalent to Math.log10 or Math.log(x, 10)
  def test_log
    assert_raises(Calc::MathError) { Calc::Q(0).log }
    assert_rational_and_equal 0, Calc::Q(1).log
    assert_in_epsilon Math.log10(2), Calc::Q(2).log
    assert_complex_parts [0, 1.36437635384184134748], Calc::Q(-1).log
    assert_complex_parts [0.30102999566398119521, 1.36437635384184134748], Calc::Q(-2).log
  end

  def test_root
    assert_instance_of Calc::Q, Calc::Q(7).root(4)
    assert_in_epsilon 1.62658, Calc::Q(7).root(4)

    assert_raises(Calc::MathError) { Calc::Q(1).root(0) }
    assert_raises(Calc::MathError) { Calc::Q(0).root(-1) }
    assert_raises(Calc::MathError) { Calc::Q(-2).root(4) }
  end

  def test_sec
    assert_rational_in_epsilon 1.85081571768092561791, Calc::Q(1).sec
    assert_rational_and_equal 1, Calc::Q(0).sec
  end

  def test_sech
    assert_rational_and_equal 1, Calc::Q(0).sech
    assert_rational_in_epsilon 0.64805427366388539958, Calc::Q(1).sech
  end

  def test_sin
    assert_rational_and_equal 0, Calc::Q(0).sin
    assert_rational_in_epsilon 0.84147098480789650665, Calc::Q(1).sin
  end

  def test_sinh
    assert_rational_and_equal 0, Calc::Q(0).sinh
    assert_rational_in_epsilon 1.17520119364380145688, Calc::Q(1).sinh
  end

  def test_tan
    assert_rational_and_equal 0, Calc::Q(0).tan
    assert_rational_in_epsilon 1.55740772465490223051, Calc::Q(1).tan
  end

  def test_tanh
    assert_rational_and_equal 0, Calc::Q(0).tanh
    assert_rational_in_epsilon 0.76159415595576488812, Calc::Q(1).tanh
  end

  def test_coerce
    assert_instance_of Calc::Q, Rational(1, 2) + Calc::Q(3, 4)
    assert_equal Calc::Q(5, 4), Rational(1, 2) + Calc::Q(3, 4)
    assert_equal Calc::Q(5, 4), 0.5 + Calc::Q(3, 4)
    assert_equal Calc::Q(7, 4), 1 + Calc::Q(3, 4)
  end

  def test_hypot
    assert_rational_and_equal 5, Calc::Q(3).hypot(4)
    assert_rational_in_epsilon 3.60555127546398929312, Calc::Q(2).hypot(-3)
  end

  def test_arg
    assert_instance_of Calc::Q, Calc::Q(1).arg
    assert_in_epsilon Calc.pi, Calc::Q(-1).arg
    assert_equal 0, Calc::Q(1).arg
  end

  def test_bernoulli
    assert_instance_of Calc::Q, Calc::Q(6).bernoulli
    [1, "-1/2", "1/6", 0, "-1/30", 0, "1/42"].each_with_index do |expected, n|
      assert_equal Calc::Q(expected), Calc::Q(n).bernoulli
    end

    # even >= 2^31 is error.  odd >= 2^31 is 0
    assert_raises(Calc::MathError) { Calc::Q("1/2").bernoulli }
    assert_raises(Calc::MathError) { (Calc::Q(2)**31).bernoulli }
    assert_equal 0, (Calc::Q(2)**31 + 1).bernoulli

    assert_nil Calc.freebernoulli
  end

  def test_agd
    assert_equal 0, Calc::Q(0).agd
    assert_instance_of Calc::Q, Calc::Q(1).agd
    assert_instance_of Calc::C, Calc::Q(2).agd
    assert_in_epsilon 1.22619117088351707081, Calc::Q(1).agd
    assert_in_epsilon 1.5234524435626735209, Calc::Q(2).agd.re
    assert_in_epsilon(-3.14159265358979323846, Calc::Q(2).agd.im)
  end

  def test_gd
    assert_equal 0, Calc::Q(0).agd
    assert_instance_of Calc::Q, Calc::Q(1).gd
    assert_in_epsilon 0.86576948323965862429, Calc::Q(1).gd
  end

  def test_real
    check_truthy Calc::Q(1), :isreal, :real?
  end

  def test_imag
    check_falsey Calc::Q(1), :isimag, :imag?
  end

  def test_re
    assert_rational_and_equal 5, Calc::Q(5).re
    assert_alias Calc::Q(5), :re, :real
  end

  def test_im
    assert_rational_and_equal 0, Calc::Q(5).im
    assert_alias Calc::Q(5), :im, :imag
  end

  def test_inverse
    assert_rational_and_equal Calc::Q(4, 5), Calc::Q(5, 4).inverse
    assert_rational_and_equal Calc::Q(-7, 2), Calc::Q(-2, 7).inverse
    assert_raises(Calc::MathError) { Calc::Q(0).inverse }
  end

  def test_bit
    check_truthy Calc::Q(9), :bit, :bit?, 0
    check_falsey Calc::Q(9), :bit, :bit?, 1
    check_falsey Calc::Q(9), :bit, :bit?, 2
    check_truthy Calc::Q(9), :bit, :bit?, 3
    check_falsey Calc::Q(9), :bit, :bit?, 4
    check_falsey Calc::Q(0), :bit, :bit?, 0
    check_falsey Calc::Q(9), :bit, :bit?, -1
    check_truthy Calc::Q("1.25"), :bit, :bit?, -2
    check_falsey Calc::Q("1.25"), :bit, :bit?, -1
    check_truthy Calc::Q("1.25"), :bit, :bit?, 0
    check_truthy Calc.pi, :bit, :bit?, 1
    check_falsey Calc.pi, :bit, :bit?, -2
    check_truthy Calc.pi, :bit, :bit?, -3
    assert_raises(Calc::MathError) { Calc::Q(9).bit?(0.5) }
  end

  def test_even
    check_truthy Calc::Q(0), :iseven, :even?
    check_falsey Calc::Q(1), :iseven, :even?
    check_truthy Calc::Q(2), :iseven, :even?
    check_falsey Calc::Q(0.5), :iseven, :even?
  end

  def test_odd
    check_falsey Calc::Q(0), :isodd, :odd?
    check_truthy Calc::Q(1), :isodd, :odd?
    check_falsey Calc::Q(0), :isodd, :odd?
    check_falsey Calc::Q(0.5), :isodd, :odd?
  end

  def test_catalan
    assert_rational_and_equal 0, Calc::Q(-1).catalan
    assert_rational_and_equal 2, Calc::Q(2).catalan
    assert_rational_and_equal 5, Calc::Q(3).catalan
    assert_rational_and_equal 14, Calc::Q(4).catalan
    assert_rational_and_equal 6564120420, Calc::Q(20).catalan

    assert_raises(Calc::MathError) { Calc::Q(0.5).catalan }
    assert_raises(Calc::MathError) { Calc::Q(2**31).catalan }
  end

  def test_fib
    assert_rational_and_equal(-55, Calc::Q(-10).fib)
    assert_rational_and_equal 34, Calc::Q(-9).fib
    assert_rational_and_equal(-1, Calc::Q(-2).fib)
    assert_rational_and_equal 1, Calc::Q(-1).fib
    assert_rational_and_equal 0, Calc::Q(0).fib
    assert_rational_and_equal 1, Calc::Q(1).fib
    assert_rational_and_equal 1, Calc::Q(2).fib
    assert_rational_and_equal 2, Calc::Q(3).fib
    assert_rational_and_equal 3, Calc::Q(4).fib
    assert_rational_and_equal 5, Calc::Q(5).fib
    assert_rational_and_equal 34, Calc::Q(9).fib
    assert_rational_and_equal 55, Calc::Q(10).fib

    assert_raises(Calc::MathError) { Calc::Q(0.5).fib }
  end

  def test_appr
    # test cases here are from examples in "help appr" - there are some
    # mistakes in the help file, these match what calc actually does
    assert_rational_and_equal Calc::Q("-5.5"), Calc::Q("-5.44").appr("0.1", 0)
    assert_rational_and_equal Calc::Q("5.4"), Calc::Q("5.44").appr("0.1", 0)
    assert_rational_and_equal 5, Calc::Q("5.7").appr(1, 0)
    assert_rational_and_equal(-6, Calc::Q("-5.7").appr(1, 0))

    assert_rational_and_equal Calc::Q("-5.4"), Calc::Q("-5.44").appr("-.1", 0)
    assert_rational_and_equal Calc::Q("5.5"), Calc::Q("5.44").appr("-.1", 0)
    assert_rational_and_equal 6, Calc::Q("5.7").appr(-1, 0)
    assert_rational_and_equal(-5, Calc::Q("-5.7").appr(-1, 0))

    assert_rational_and_equal Calc::Q("-5.5"), Calc::Q("-5.44").appr("0.1", 3)
    assert_rational_and_equal Calc::Q("5.5"), Calc::Q("5.44").appr("0.1", 3)
    assert_rational_and_equal 6, Calc::Q("5.7").appr(1, 3)
    assert_rational_and_equal(-6, Calc::Q("-5.7").appr(1, 3))

    assert_rational_and_equal Calc::Q("-5.5"), Calc::Q("-5.44").appr("0.1", 4)
    assert_rational_and_equal Calc::Q("5.4"), Calc::Q("5.44").appr("0.1", 4)
    assert_rational_and_equal 5, Calc::Q("5.7").appr(1, 4)
    assert_rational_and_equal(-6, Calc::Q("-5.7").appr(1, 4))

    assert_rational_and_equal Calc::Q("-5.4"), Calc::Q("-5.44").appr("0.1", 6)
    assert_rational_and_equal Calc::Q("5.4"), Calc::Q("5.44").appr("0.1", 6)
    assert_rational_and_equal 5, Calc::Q("5.7").appr(1, 6)
    assert_rational_and_equal(-5, Calc::Q("-5.7").appr(1, 6))

    assert_rational_and_equal Calc::Q("-5.5"), Calc::Q("-5.44").appr("-.1", 6)
    assert_rational_and_equal Calc::Q("5.5"), Calc::Q("5.44").appr("-.1", 6)
    assert_rational_and_equal 6, Calc::Q("5.7").appr(-1, 6)
    assert_rational_and_equal(-6, Calc::Q("-5.7").appr(-1, 6))

    assert_rational_and_equal Calc::Q("-5.5"), Calc::Q("-5.44").appr("0.1", 9)
    assert_rational_and_equal Calc::Q("5.5"), Calc::Q("5.44").appr("0.1", 9)
    assert_rational_and_equal 5, Calc::Q("5.7").appr(1, 9)
    assert_rational_and_equal(-5, Calc::Q("-5.7").appr(1, 9))

    assert_rational_and_equal Calc::Q("-.4"), Calc::Q("-.44").appr("0.1", 11)
    assert_rational_and_equal Calc::Q(".5"), Calc::Q(".44").appr("0.1", 11)
    assert_rational_and_equal 5, Calc::Q("5.7").appr(1, 11)
    assert_rational_and_equal(-6, Calc::Q("-5.7").appr(1, 11))

    assert_rational_and_equal Calc::Q("-.5"), Calc::Q("-.44").appr("-.1", 11)
    assert_rational_and_equal Calc::Q(".4"), Calc::Q(".44").appr("-.1", 11)
    assert_rational_and_equal 6, Calc::Q("5.7").appr(-1, 11)
    assert_rational_and_equal(-5, Calc::Q("-5.7").appr(-1, 11))

    assert_rational_and_equal Calc::Q("-.4"), Calc::Q("-.44").appr("0.1", 12)
    assert_rational_and_equal Calc::Q(".4"), Calc::Q(".44").appr("0.1", 12)
    assert_rational_and_equal 6, Calc::Q("5.7").appr(1, 12)
    assert_rational_and_equal(-6, Calc::Q("-5.7").appr(1, 12))

    assert_rational_and_equal Calc::Q("-.5"), Calc::Q("-.44").appr("-.1", 12)
    assert_rational_and_equal Calc::Q(".5"), Calc::Q(".44").appr("-.1", 12)
    assert_rational_and_equal 5, Calc::Q("5.7").appr(-1, 12)
    assert_rational_and_equal(-5, Calc::Q("-5.7").appr(-1, 12))

    assert_rational_and_equal Calc::Q("-.4"), Calc::Q("-.44").appr("0.1", 15)
    assert_rational_and_equal Calc::Q(".5"), Calc::Q(".44").appr("0.1", 15)
    assert_rational_and_equal 5, Calc::Q("5.7").appr(1, 15)
    assert_rational_and_equal(-6, Calc::Q("-5.7").appr(1, 15))

    assert_rational_and_equal Calc::Q("-.4"), Calc::Q("-.44").appr("-.1", 15)
    assert_rational_and_equal Calc::Q(".5"), Calc::Q(".44").appr("-.1", 15)
    assert_rational_and_equal 5, Calc::Q("5.7").appr(-1, 15)
    assert_rational_and_equal(-6, Calc::Q("-5.7").appr(-1, 15))
  end

  def test_sqrt
    assert_rational_and_equal 2, Calc::Q(4).sqrt
    assert_complex_parts [0, 2], Calc::Q(-4).sqrt
    eps = Calc::Q("1e-4")
    assert_rational_and_equal 2, Calc::Q(4).sqrt(eps, 0)
    assert_rational_and_equal(-2, Calc::Q(4).sqrt(eps, 64))
    assert_rational_and_equal Calc::Q("1.4142"), Calc::Q(2).sqrt(eps, 0)
    assert_rational_and_equal Calc::Q("1.4143"), Calc::Q(2).sqrt(eps, 1)
    assert_rational_and_equal Calc::Q("1.4142"), Calc::Q(2).sqrt(eps, 24)
    x = Calc::Q("1.2345678")**2
    assert_rational_and_equal Calc::Q("1.2346"), x.sqrt(eps, 24)
    assert_rational_and_equal Calc::Q("1.2345678"), x.sqrt(eps, 32)
    assert_rational_and_equal Calc::Q("-1.2345678"), x.sqrt(eps, 96)
    assert_rational_and_equal 0, (Calc::Q(".00005")**2).sqrt(eps, 24)
    assert_rational_and_equal Calc::Q(".0002"), (Calc::Q(".00015")**2).sqrt(eps, 24)
  end

  def test_ceil
    assert_rational_and_equal 27, Calc::Q(27).ceil
    assert_rational_and_equal 2, Calc::Q(1.23).ceil
    assert_rational_and_equal(-4, Calc::Q(-4.56).ceil)
  end

  def test_floor
    assert_rational_and_equal 27, Calc::Q(27).floor
    assert_rational_and_equal 1, Calc::Q(1.23).floor
    assert_rational_and_equal(-5, Calc::Q(-4.56).floor)
  end

  def test_isint
    check_truthy Calc::Q(-1), :isint, :int?
    check_truthy Calc::Q(0), :isint, :int?
    check_truthy Calc::Q(1), :isint, :int?
    check_falsey Calc::Q(0.5), :isint, :int?
    assert_alias Calc::Q(5), :int?, :integer?
  end

  def test_to_c
    assert_instance_of Complex, Calc::Q(2).to_c
    assert_equal Complex(2, 0), Calc::Q(2).to_c
    assert_equal Complex(2.5, 0), Calc::Q(2.5).to_c
  end

  def test_to_complex
    assert_complex_parts [2, 0], Calc::Q(2).to_complex
    assert_complex_parts [2.5, 0], Calc::Q(2.5).to_complex
  end

  def test_bround
    a = Calc::Q(7, 32)
    b = Calc::Q(-7, 32)
    assert_rational_and_equal 0, a.bround
    assert_rational_and_equal Calc::Q(".25"), a.bround(3)
    assert_rational_and_equal Calc::Q(".25"), a.bround(4)
    assert_rational_and_equal Calc::Q(".21875"), a.bround(5)
    assert_rational_and_equal Calc::Q(".1875"), a.bround(4, 0)
    assert_rational_and_equal Calc::Q(".25"), a.bround(4, 1)
    assert_rational_and_equal Calc::Q(".1875"), a.bround(4, 2)
    assert_rational_and_equal Calc::Q(".25"), a.bround(4, 3)
    assert_rational_and_equal 0, b.bround
    assert_rational_and_equal Calc::Q("-.25"), b.bround(3)
    assert_rational_and_equal Calc::Q("-.25"), b.bround(4)
    assert_rational_and_equal Calc::Q("-.21875"), b.bround(5)
    assert_rational_and_equal Calc::Q("-.25"), b.bround(4, 0)
    assert_rational_and_equal Calc::Q("-.1875"), b.bround(4, 1)
    assert_rational_and_equal Calc::Q("-.1875"), b.bround(4, 2)
    assert_rational_and_equal Calc::Q("-.25"), b.bround(4, 3)
  end

  def test_round
    a = Calc::Q(7, 32)
    b = Calc::Q(-7, 32)
    assert_rational_and_equal 0, a.round
    assert_rational_and_equal Calc::Q(".219"), a.round(3)
    assert_rational_and_equal Calc::Q(".218"), a.round(3, 0)
    assert_rational_and_equal Calc::Q(".219"), a.round(3, 1)
    assert_rational_and_equal Calc::Q(".218"), a.round(3, 2)
    assert_rational_and_equal Calc::Q(".219"), a.round(3, 3)
    assert_rational_and_equal 0, b.round
    assert_rational_and_equal Calc::Q("-.219"), b.round(3)
    assert_rational_and_equal Calc::Q("-.219"), b.round(3, 0)
    assert_rational_and_equal Calc::Q("-.218"), b.round(3, 1)
    assert_rational_and_equal Calc::Q("-.218"), b.round(3, 2)
    assert_rational_and_equal Calc::Q("-.219"), b.round(3, 3)
  end

  def test_cfappr
    x = Calc::Q(43, 30)
    assert_rational_and_equal x, x.cfappr(0)
    assert_rational_and_equal Calc::Q("10/7"), x.cfappr(10, 0)
    assert_rational_and_equal Calc::Q("13/9"), x.cfappr(10, 1)
    assert_rational_and_equal Calc::Q("10/7"), x.cfappr(10, 16)
    pi = Calc.pi("1e-10")
    assert_rational_and_equal Calc::Q("311/99"), pi.cfappr(100, 16)
    assert_rational_and_equal Calc::Q("22/7"), pi.cfappr(".01", 16)
    assert_rational_and_equal Calc::Q("355/113"), pi.cfappr("1e-6", 16)
    x = Calc::Q(17, 12)
    assert_rational_and_equal Calc::Q("4/3"), x.cfappr(4, 0)
    assert_rational_and_equal Calc::Q("3/2"), x.cfappr(4, 1)
    assert_rational_and_equal Calc::Q("3/2"), x.cfappr(4, 16)
  end

  def test_cfsim
    assert_rational_and_equal Calc::Q("10/7"), Calc::Q("43/30").cfsim
    assert_rational_and_equal Calc::Q("10/7"), Calc::Q("43/30").cfsim(0)
    assert_rational_and_equal Calc::Q("33/23"), Calc::Q("43/30").cfsim(1)
  end

  def test_char
    assert_equal "", Calc::Q(0).char
    assert_equal "X", Calc::Q(88).char
    assert_raises(Calc::MathError) { Calc::Q(88.5).char }
  end

  def test_cmp
    assert_rational_and_equal(-1, Calc::Q(3).cmp(4))
    assert_rational_and_equal 1, Calc::Q(4).cmp(3)
    assert_rational_and_equal 0, Calc::Q(4).cmp(4)
    assert_complex_parts [1, -1], Calc::Q(3).cmp(Calc::C(0, 4))
    assert_complex_parts [1, -1], Calc::Q(4).cmp(Calc::C(0, 4))
    assert_complex_parts [1, -1], Calc::Q(5).cmp(Calc::C(0, 4))
    assert_complex_parts [-1, -1], Calc::Q(-5).cmp(Calc::C(0, 4))
  end

  def test_comb
    assert_rational_and_equal 35, Calc::Q(7).comb(3)
    assert_rational_and_equal 35, Calc::Q(7).comb(4)
    assert_rational_and_equal 21, Calc::Q(7).comb(5)
    assert_rational_and_equal 7, Calc::Q(7).comb(1)
    assert_rational_and_equal 1, Calc::Q(3).comb(0)
    assert_rational_and_equal 1, Calc::Q(0).comb(0)
    x = Calc::Q(2).power(31)
    assert_rational_and_equal 2305843010287435776, (x + 1).comb(x - 1)
    assert_rational_and_equal Calc::Q("715/16"), Calc::Q("7.5").comb(3)
    assert_raises(Calc::MathError) { Calc::Q(7).comb(0.5) }
  end

  def test_perm
    assert_rational_and_equal 210, Calc::Q(7).perm(3)
    assert_rational_and_equal 840, Calc::Q(7).perm(4)
    assert_rational_and_equal 2520, Calc::Q(7).perm(5)
    assert_rational_and_equal 1, Calc::Q(3).perm(0)
    assert_rational_and_equal 1, Calc::Q(0).perm(0)
    assert_rational_and_equal 9903520314283042197045510144, (Calc::Q(2).power(31) + 1).perm(3)
    assert_raises(Calc::MathError) { Calc::Q(7).comb(0.5) }
  end

  def test_conj
    assert_rational_and_equal 3, Calc::Q(3).conj
  end

  def test_digit
    a = Calc::Q("123456.789")
    assert_rational_and_equal 0, a.digit(6)
    assert_rational_and_equal 1, a.digit(5)
    assert_rational_and_equal 2, a.digit(4)
    assert_rational_and_equal 3, a.digit(3)
    assert_rational_and_equal 4, a.digit(2)
    assert_rational_and_equal 5, a.digit(1)
    assert_rational_and_equal 6, a.digit(0)
    assert_rational_and_equal 7, a.digit(-1)
    assert_rational_and_equal 8, a.digit(-2)
    assert_rational_and_equal 9, a.digit(-3)
    assert_rational_and_equal 0, a.digit(-4)
    assert_rational_and_equal 0, a.digit(-5)
    assert_rational_and_equal 0, a.digit(-6)
    assert_rational_and_equal 0, a.digit(3, 100)
    assert_rational_and_equal 12, a.digit(2, 100)
    assert_rational_and_equal 34, a.digit(1, 100)
    assert_rational_and_equal 56, a.digit(0, 100)
    assert_rational_and_equal 78, a.digit(-1, 100)
    assert_rational_and_equal 90, a.digit(-2, 100)
    assert_rational_and_equal 0, a.digit(-3, 100)
    b = Calc::Q("10/7")
    assert_rational_and_equal 0, b.digit(1)
    assert_rational_and_equal 1, b.digit(0)
    assert_rational_and_equal 4, b.digit(-1)
    assert_rational_and_equal 2, b.digit(-2)
    assert_rational_and_equal 8, b.digit(-3)
    assert_rational_and_equal 5, b.digit(-4)
    assert_rational_and_equal 7, b.digit(-5)
    assert_rational_and_equal 1, b.digit(-6)
    assert_rational_and_equal 428571, b.digit("-7e1000", "1e6")
  end

  def test_digits
    assert_rational_and_equal 3, Calc::Q(100).digits
    assert_rational_and_equal 5, Calc::Q(23209).digits
    assert_rational_and_equal 22, Calc::Q(2).power(72).digits
    assert_rational_and_equal 1, Calc::Q(0).digits
    assert_rational_and_equal 1, Calc::Q(1).digits
    assert_rational_and_equal 1, Calc::Q(-1).digits
    assert_rational_and_equal 4, Calc::Q(-1234).digits
    assert_rational_and_equal 2, Calc::Q("12.3456").digits
    assert_rational_and_equal 3, Calc::Q("107.207").digits
    assert_rational_and_equal 463, (Calc::Q(17).power(463) - 1).digits(17)
    assert_rational_and_equal 3, Calc::Q(10000).digits(100)
    assert_rational_and_equal 15, Calc::Q(21791).digits(2)
  end

  def test_estr
    assert_equal "Calc::Q(1,4)", Calc::Q(1, 4).estr
    assert_equal "Calc::Q(-11,15)", Calc::Q(-11, 15).estr
    assert_equal "Calc::Q(0)", Calc::Q(0).estr
    assert_equal "Calc::Q(4)", Calc::Q(4).estr
  end

  def test_euler
    assert_rational_and_equal 1, Calc::Q(0).euler
    assert_rational_and_equal 0, Calc::Q(1).euler
    assert_rational_and_equal(-1, Calc::Q(2).euler)
    assert_rational_and_equal 0, Calc::Q(3).euler
    assert_rational_and_equal 5, Calc::Q(4).euler
    assert_rational_and_equal 0, Calc::Q(5).euler
    assert_rational_and_equal(-61, Calc::Q(6).euler)
  end

  def test_factor
    assert_rational_and_equal 1, Calc::Q(35).factor(4)
    assert_rational_and_equal 5, Calc::Q(35).factor(5)
    assert_rational_and_equal 5, Calc::Q(35).factor
    assert_rational_and_equal 5, Calc::Q(-35).factor
    assert_rational_and_equal 641, Calc::Q(2).power(32).+(1).factor
    assert_rational_and_equal 2351, Calc::Q(2).power(47).-(1).factor
    assert_rational_and_equal 179951, Calc::Q(2).power(59).-(1).factor
  end

  def test_fcnt
    assert_rational_and_equal 0, Calc::Q(7).fcnt(4)
    assert_rational_and_equal 1, Calc::Q(24).fcnt(4)
    assert_rational_and_equal 2, Calc::Q(48).fcnt(4)
    assert_raises(Calc::MathError) { Calc::Q(2).fcnt(0.5) }
    assert_raises(Calc::MathError) { Calc::Q(0.5).fcnt(2) }
  end

  def test_frem
    assert_rational_and_equal 7, Calc::Q(7).frem(4)
    assert_rational_and_equal 6, Calc::Q(24).frem(4)
    assert_rational_and_equal 3, Calc::Q(48).frem(4)
    assert_rational_and_equal 3, Calc::Q(-48).frem(4)
    assert_raises(Calc::MathError) { Calc::Q(0.5).frem(2) }
    assert_raises(Calc::MathError) { Calc::Q(2).frem(0.5) }
  end

  def test_frac
    assert_rational_and_equal 0, Calc::Q(3).frac
    assert_rational_and_equal Calc::Q(1, 7), Calc::Q(22, 7).frac
    assert_rational_and_equal Calc::Q(6, 7), Calc::Q(27, 7).frac
    assert_rational_and_equal Calc::Q(-1, 8), Calc::Q("-3.125").frac
  end

  def test_gcd
    assert_rational_and_equal 12, Calc::Q(12).gcd
    assert_rational_and_equal 4, Calc::Q(12).gcd(-8)
    assert_rational_and_equal 6, Calc::Q(12).gcd(-24, 30)
    assert_rational_and_equal Calc::Q("0.02"), Calc::Q(9, 10).gcd(Calc::Q(11, 5), Calc::Q(4, 25))
    assert_rational_and_equal 0, Calc::Q(0).gcd(0, 0, 0, 0)
  end

  def test_gcdrem
    assert_rational_and_equal 2, Calc::Q(6).gcdrem(15)
    assert_rational_and_equal 5, Calc::Q(15).gcdrem(6)
    assert_rational_and_equal 1, Calc::Q(72).gcdrem(6)
    assert_rational_and_equal 1, Calc::Q(6).gcdrem(72)
    assert_rational_and_equal 35, Calc::Q(630).gcdrem(6)
    assert_rational_and_equal 1, Calc::Q(6).gcdrem(630)
  end

  def test_highbit
    assert_rational_and_equal(-1, Calc::Q(0).highbit)
    assert_rational_and_equal 1, Calc::Q(2).highbit
    assert_rational_and_equal 1, Calc::Q(3).highbit
    assert_rational_and_equal 2, Calc::Q(4).highbit
    assert_rational_and_equal 3, Calc::Q(-15).highbit
    assert_rational_and_equal 27, Calc::Q(2).**(27).highbit
    assert_raises(Calc::MathError) { Calc::Q(0.5).highbit }
  end

  def test_ilog
    assert_rational_and_equal 0, Calc::Q(2).ilog(3)
    assert_rational_and_equal 1, Calc::Q(8).ilog(3)
    assert_rational_and_equal 1, Calc::Q("8.9").ilog(3)
    assert_rational_and_equal(-2, Calc::Q("1/8").ilog(3))
    assert_rational_and_equal 4, Calc::Q(100).ilog(3)
    assert_raises(Calc::MathError) { Calc::Q(0).ilog(3) }
    assert_raises(Calc::MathError) { Calc::Q(10).ilog(1) }
  end

  def test_ilog10
    assert_rational_and_equal 0, Calc::Q(7).ilog10
    assert_rational_and_equal 1, Calc::Q("77.7").ilog10
    assert_rational_and_equal 2, Calc::Q(777).ilog10
    assert_rational_and_equal(-3, Calc::Q(".00777").ilog10)
    assert_rational_and_equal 27, Calc::Q("-1e27").ilog10
    assert_raises(Calc::MathError) { Calc::Q(0).ilog10 }
  end

  def test_ilog2
    assert_rational_and_equal 0, Calc::Q(1).ilog2
    assert_rational_and_equal 1, Calc::Q(2).ilog2
    assert_rational_and_equal 1, Calc::Q(3).ilog2
    assert_rational_and_equal 2, Calc::Q(4).ilog2
    assert_rational_and_equal(-4, Calc::Q("1/15").ilog2)
    assert_raises(Calc::MathError) { Calc::Q(0).ilog2 }
  end

  def test_int
    assert_rational_and_equal 3, Calc::Q(3).int
    assert_rational_and_equal 3, Calc::Q("22/7").int
    assert_rational_and_equal 3, Calc::Q("27/7").int
    assert_rational_and_equal(-3, Calc::Q("-3.125").int)
  end

  def test_iroot
    assert_rational_and_equal 4, Calc::Q(100).iroot(3)
    assert_rational_and_equal 6, Calc::Q(274).iroot(3)
    assert_rational_and_equal 1, Calc::Q(1).iroot(9)
    assert_rational_and_equal 6, Calc.pi.**(8).iroot(5)
    assert_rational_and_equal(-3, Calc::Q(-44).iroot(3))
    assert_raises(Calc::MathError) { Calc::Q(2).iroot(0) }
    assert_raises(Calc::MathError) { Calc::Q(2).iroot(0.5) }
  end

  def test_mult
    check_truthy Calc::Q(6), :ismult, :mult?, 2
    check_falsey Calc::Q(2), :ismult, :mult?, 6
    check_truthy Calc::Q("7.5"), :ismult, :mult?, Calc::Q("2.5")
    check_truthy Calc::Q(4)**67, :ismult, :mult?, Calc::Q(2)**59
    check_falsey Calc::Q(13), :ismult, :mult?, Calc::Q("4/67")
    check_truthy Calc::Q(13), :ismult, :mult?, Calc::Q("7/56")
  end

  def test_prime
    check_truthy Calc::Q(-3), :isprime, :prime?
    check_falsey Calc::Q(1), :isprime, :prime?
    check_truthy Calc::Q(2), :isprime, :prime?
    check_truthy Calc::Q(21701), :isprime, :prime?
    check_truthy Calc::Q(1234577), :isprime, :prime?
    check_falsey Calc::Q(1234579), :isprime, :prime?
    check_falsey Calc::Q(2)**31 - 9, :isprime, :prime?
    check_truthy Calc::Q(2)**31 - 1, :isprime, :prime?
    check_truthy Calc::Q(2)**31 + 11, :isprime, :prime?
    assert_raises(Calc::MathError) { Calc::Q(2).**(32).+(1).prime? }
    assert_raises(Calc::MathError) { Calc::Q(3).**(99).prime? }
    check_falsey Calc::Q(4)**99, :isprime, :prime?
  end

  def test_isqrt
    assert_rational_and_equal 2, Calc::Q("8.5").isqrt
    assert_rational_and_equal 14, Calc::Q(200).isqrt
    assert_rational_and_equal 1414, Calc::Q("2e6").isqrt
    assert_rational_and_equal 14142135623730950488016887242, Calc::Q("2e56").isqrt
    assert_raises(Calc::MathError) { Calc::Q(-1).isqrt }
  end
end
