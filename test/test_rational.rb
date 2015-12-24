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
    # num/den versions (anything accepted by Calc::Z.new is allowed)
    assert_instance_of Calc::Q, Calc::Q.new(1, 3)
    assert_instance_of Calc::Q, Calc::Q.new(BIG, BIG+1)
    assert_instance_of Calc::Q, Calc::Q.new(BIG2, BIG2+1)
    assert_instance_of Calc::Q, Calc::Q.new(BIG3, BIG3-1)
    assert_instance_of Calc::Q, Calc::Q.new("1", "3")
    assert_instance_of Calc::Q, Calc::Q.new(Calc::Z(1), Calc::Z(3))

    # single param version
    assert_instance_of Calc::Q, Calc::Q.new(1)
    assert_instance_of Calc::Q, Calc::Q.new(BIG)
    assert_instance_of Calc::Q, Calc::Q.new(BIG2)
    assert_instance_of Calc::Q, Calc::Q.new(BIG3)
    assert_instance_of Calc::Q, Calc::Q.new(Calc::Z(42))
    assert_instance_of Calc::Q, Calc::Q.new("1/3")
    assert_instance_of Calc::Q, Calc::Q.new(Rational(1,3))
    assert_instance_of Calc::Q, Calc::Q.new(0.3)
  end

  def test_intialization_div_zero
    assert_raises(ZeroDivisionError) { Calc::Q.new(5, 0) }
    assert_raises(ZeroDivisionError) { Calc::Q.new(5, "0") }
    assert_raises(ZeroDivisionError) { Calc::Q.new(5, Calc::Z(0)) }
    assert_raises(ZeroDivisionError) { Calc::Q.new("5/0") }
  end

  def test_concise_initialization
    assert_instance_of Calc::Q, Calc::Q(1, 3)
    assert_instance_of Calc::Q, Calc::Q(42)
  end
  
  def test_dup
    q1 = Calc::Q(13, 4)
    q2 = q1.dup
    assert_equal "13/4", q2.to_s
    refute_equal q1.object_id, q2.object_id
  end

  def test_equal
    assert Calc::Q.new(3) == Calc::Q.new(3)     # Q == Q
    assert Calc::Q.new(3) == Calc::Z.new(3)     # Q == Z
    assert Calc::Q.new(3) == Calc::Q.new(6, 2)  # Q == Q (reduced)
    assert Calc::Q.new(3) == 3                  # Q == Fixnum
    assert Calc::Q.new(BIG) == BIG              # Q == Bignum
    assert Calc::Q.new(2,3) == Rational(2,3)    # Q == Rational
    assert Calc::Q.new(0.5) == 0.5              # Q == Float

    assert Calc::Q.new(3) != Calc::Q.new(4)
    assert Calc::Q.new(3) != Calc::Z.new(4)
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
      [ Calc::Q(2),   Calc::Z(1),    Calc::Z(2),    Calc::Z(3)    ],
      [ Calc::Q(3),   2,             3,             4             ],
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
    assert_rational_and_equal Calc::Q(13, 3), Calc::Q.new(1, 3) + Calc::Z(4)
    assert_rational_and_equal Calc::Q(7, 12), Calc::Q.new(1, 3) + Calc::Q.new(1, 4)
    assert_rational_and_equal Calc::Q(7, 12), Calc::Q.new(1, 3) + Rational(1, 4)
  end

  def test_subtract
    assert_rational_and_equal Calc::Q(-1,6), Calc::Q(1,3) - Calc::Q(1,2)
    assert_rational_and_equal Calc::Q(-2,3), Calc::Q(1,3) - 1
    assert_rational_and_equal Calc::Q(-5,3), Calc::Q(1,3) - Calc::Z(2)
    assert_rational_and_equal Calc::Q(1,12), Calc::Q(1,3) - Rational(1,4)
  end

  def test_multiply
    assert_rational_and_equal Calc::Q(1,12), Calc::Q(1,3) * Calc::Q(1,4)
    assert_rational_and_equal Calc::Q(4,3),  Calc::Q(1,3) * 4
    assert_rational_and_equal Calc::Q(5,3),  Calc::Q(1,3) * Calc::Z(5)
    assert_rational_and_equal Calc::Q(1,5),  Calc::Q(1,3) * Rational(3,5)
  end

  def test_divide
    assert_rational_and_equal Calc::Q(4,3),  Calc::Q(1,3) / Calc::Q(1,4)
    assert_rational_and_equal Calc::Q(1,6),  Calc::Q(1,3) / 2
    assert_rational_and_equal Calc::Q(1,12), Calc::Q(1,3) / Calc::Z(4)
    assert_rational_and_equal Calc::Q(5,3),  Calc::Q(1,3) / Rational(1,5)
  end

  def test_mod
    assert_rational_and_equal Calc::Q( 3,28), Calc::Q( 1,4) % Calc::Q( 1,7)
    assert_rational_and_equal Calc::Q( 1,28), Calc::Q(-1,4) % Calc::Q( 1,7)
    assert_rational_and_equal Calc::Q(-1,28), Calc::Q( 1,4) % Calc::Q(-1,7)
    assert_rational_and_equal Calc::Q(-3,28), Calc::Q(-1,4) % Calc::Q(-1,7)

    # other arg types
    assert_rational_and_equal Calc::Q(3,4),  Calc::Q(11,4) % Calc::Z(2)
    assert_rational_and_equal Calc::Q(3,4),  Calc::Q(11,4) % 2
    assert_rational_and_equal Calc::Q(1,12), Calc::Q(11,4) % Rational(1,3)

    # unlike Z and ruby, q % 0 == q
    assert_rational_and_equal Calc::Q(1,4), Calc::Q(1,4) % 0
  end

  def test_power
    assert_rational_and_equal Calc::Q(3),    Calc::Q(81) ** Calc::Q(1,4)
    assert_in_epsilon Calc::Q(1,9).to_f,  (Calc::Q(1,3) ** 2).to_f
    assert_in_epsilon Calc::Q(1,27).to_f, (Calc::Q(1,3) ** Calc::Z(3)).to_f
    assert_rational_and_equal Calc::Q(4),    Calc::Q(8) ** Rational(2,3)

    assert_instance_of Calc::Q, Calc::Q.power(1.2345, 10)
    assert_in_epsilon 8.2207405646327461795, Calc::Q.power(1.2345, 10).to_f
  end

  def test_shift
    # both arguments have to be integers
    assert_rational_and_equal  128, Calc::Q(4) << Calc::Q(5)
    assert_rational_and_equal    0, Calc::Q(4) >> 5
    assert_rational_and_equal  400, Calc::Q(100) << Calc::Z(2)
    assert_rational_and_equal   25, Calc::Q(100) >> Rational(2,1)
    assert_rational_and_equal -320, Calc::Q(-20) << 4
    assert_rational_and_equal   -1, Calc::Q(-20) >> 4
    assert_rational_and_equal    1, Calc::Q(20) << -4
    assert_rational_and_equal  320, Calc::Q(20) >> -4
    assert_rational_and_equal  -12, Calc::Q(-50) << -2
    assert_rational_and_equal -200, Calc::Q(-50) >> -2

    assert_raises(ArgumentError) { Calc::Q.new(2) << Calc::Q(1,3) }
    assert_raises(ArgumentError) { Calc::Q.new(2) << Rational(1,3) }

    # this need proper exception handling, will just exit with math_error atm
    assert_raises(Calc::MathError) { Calc::Q.new(1,3) << 1 }
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

  # currently just using default calc (prints decimal approximation).  needs
  # more options.
  def test_to_s
    assert_equal "42", Calc::Q.new(42).to_s
    assert_equal "4611686018427387904", Calc::Q.new(BIG).to_s
    assert_equal "42", Calc::Q.new(Calc::Z.new(42)).to_s
    assert_equal "42", Calc::Q.new("42").to_s
    assert_equal "42", Calc::Q.new("0b101010").to_s
    assert_equal "42", Calc::Q.new("052").to_s
    assert_equal "42", Calc::Q.new("0x2a").to_s
    assert_equal "1/4", Calc::Q.new(Rational(1, 4)).to_s
    assert_equal "1/4", Calc::Q.new(1, 4).to_s
    assert_equal "2305843009213693952", Calc::Q.new(BIG, 2).to_s
    assert_equal "1/4", Calc::Q.new(Calc::Z.new(1), Calc::Z.new(4)).to_s
    assert_equal "1/4", Calc::Q.new("1", "4").to_s
  end

  def test_epsilon
    # check the default matches expected value
    assert_equal "1/100000000000000000000", Calc::Q.get_default_epsilon.to_s

    # check we can change it and doing so affects the transcendental functions
    # when called with no epsilon argument
    with_epsilon(EPS4) do
      assert_equal "1/10000", Calc::Q.get_default_epsilon.to_s
      assert_equal "3927/1250", Calc::Q.pi.to_s
      assert_equal "0", Calc::Q.sin(0).to_s
      assert_equal "1683/2000", Calc::Q.sin(1).to_s
      assert_equal "1", Calc::Q.cos(0).to_s
      assert_equal "5403/10000", Calc::Q.cos(1).to_s
    end
  end

  def test_pi
    pi = Calc::Q.pi(EPS20)
    assert_instance_of Calc::Q, pi
    assert_equal "157079632679489661923/50000000000000000000", pi.to_s

    pi = Calc::Q.pi(EPS5)
    assert_equal "314159/100000", pi.to_s
  end

  def test_trig
    # test trig functions which are also in ruby Math by comparing our result
    # to theirs.  note that our results lose precision when converting to
    # float, so this is just testing values are roughly right.
    %i(acos asin asinh atan cos cosh sin sinh tan tanh).each do |method|
      [-1, 0, 1].each do |input|
        assert_in_epsilon(Math.send(method, input), Calc::Q.send(method, input).to_f)
        assert_in_epsilon(Math.send(method, input), Calc::Q(input).send(method).to_f)
      end
    end
  end

  def test_acosh
    assert_instance_of Calc::Q, Calc::Q.acosh(1)
    assert_instance_of Calc::Q, Calc::Q(1).acosh
    assert_equal 0, Calc::Q.acosh(1)
    assert_in_epsilon 1.31695789692481670862, Calc::Q.acosh(2).to_f
  end

  def test_acot
    assert_instance_of Calc::Q, Calc::Q.acot(1)
    assert_instance_of Calc::Q, Calc::Q(1).acot
    assert_in_epsilon 2.35619449019234492885, Calc::Q(-1).acot.to_f
    assert_in_epsilon 1.57079632679489661923, Calc::Q(0).acot.to_f
    assert_in_epsilon 0.78539816339744830962, Calc::Q(1).acot.to_f
  end

  def test_acoth
    assert_instance_of Calc::Q, Calc::Q.acoth(2)
    assert_instance_of Calc::Q, Calc::Q(2).acoth
    assert_in_epsilon 0.5493061443340548457, Calc::Q.acoth(2).to_f
    assert_raises(Calc::MathError) { Calc::Q.acoth(0) }
    assert_raises(Calc::MathError) { Calc::Q.acoth(1) }
  end

  def test_acsc
    assert_instance_of Calc::Q, Calc::Q.acsc(1)
    assert_instance_of Calc::Q, Calc::Q(1).acsc
    assert_in_epsilon 1.57079632679489661923, Calc::Q(1).acsc.to_f
    assert_raises(Calc::MathError) { Calc::Q(0).acsc }
  end

  def test_acsch
    assert_instance_of Calc::Q, Calc::Q.acsch(1)
    assert_instance_of Calc::Q, Calc::Q(1).acsch
    assert_in_epsilon 0.88137358701954302523, Calc::Q(1).acsch.to_f
    assert_raises(Calc::MathError) { Calc::Q(0).acsch }
  end

  def test_asec
    assert_instance_of Calc::Q, Calc::Q.asec(1)
    assert_instance_of Calc::Q, Calc::Q(1).asec
    assert_in_epsilon 3.14159265358979323846, Calc::Q(-1).asec.to_f
    assert_equal 0, Calc::Q(1).asec
    assert_raises(Calc::MathError) { Calc::Q(0).asec }
  end

  def test_asech
    assert_instance_of Calc::Q, Calc::Q.asech(1)
    assert_instance_of Calc::Q, Calc::Q(1).asech
    assert_equal 0, Calc::Q.asech(1)
    assert_in_epsilon 1.31695789692481670862, Calc::Q.asech(0.5).to_f
    assert_raises(Calc::MathError) { Calc::Q(0).asech }
  end

  def test_atan2
    assert_instance_of Calc::Q, Calc::Q(0).atan2(0)
    assert_instance_of Calc::Q, Calc::Q.atan2(0,0)
    [-1,0,1].each do |y|
      [-1,0,1].each do |x|
        assert_in_epsilon Math.atan2(y,x), Calc::Q.atan2(y,x).to_f
        assert_in_epsilon Math.atan2(y,x), Calc::Q(y).atan2(x).to_f
      end
    end
  end

  def test_atanh
    assert_instance_of Calc::Q, Calc::Q.atanh(0)
    assert_instance_of Calc::Q, Calc::Q(0).atanh
    assert_equal 0, Calc::Q.atanh(0)
    assert_in_epsilon 0.5493061443340548457, Calc::Q.atanh(0.5).to_f
    assert_raises(Calc::MathError) { Calc::Q.atanh(1) }
  end

  def test_cot
    assert_instance_of Calc::Q, Calc::Q.cot(1)
    assert_in_epsilon 0.64209261593433070301, Calc::Q.cot(1).to_f
    assert_in_epsilon 0.64209261593433070301, Calc::Q(1).cot.to_f
    assert_raises(Calc::MathError) { Calc::Q.cot(0) }
  end

  def test_coth
    assert_instance_of Calc::Q, Calc::Q.coth(1)
    assert_instance_of Calc::Q, Calc::Q(1).coth
    assert_in_epsilon 1.31303528549933130364, Calc::Q(1).coth.to_f
    assert_raises(Calc::MathError) { Calc::Q.coth(0) }
  end

  def test_csc
    assert_instance_of Calc::Q, Calc::Q.csc(1)
    assert_in_epsilon 1.18839510577812121626, Calc::Q.csc(1).to_f
    assert_in_epsilon 1.18839510577812121626, Calc::Q(1).csc.to_f
    assert_raises(Calc::MathError) { Calc::Q.csc(0) }
  end

  def test_csch
    assert_instance_of Calc::Q, Calc::Q.csch(1)
    assert_instance_of Calc::Q, Calc::Q(1).csch
    assert_in_epsilon 0.85091812823932154513, Calc::Q.csch(1).to_f
    assert_raises(Calc::MathError) { Calc::Q.csch(0) }
  end

  def test_exp
    assert_instance_of Calc::Q, Calc::Q.exp(1)
    assert_instance_of Calc::Q, Calc::Q(1).exp
    assert_in_epsilon Math.exp(-1), Calc::Q.exp(-1).to_f
    assert_equal 0, Calc::Q.exp(0)
    assert_in_epsilon Math::E, Calc::Q.exp(1).to_f
    assert_in_epsilon Math.exp(2), Calc::Q.exp(2).to_f
  end

  # libcalc ln is equivalent to Math.log
  def test_ln
    assert_instance_of Calc::Q, Calc::Q.ln(1)
    assert_instance_of Calc::Q, Calc::Q(1).ln
    assert_raises(Calc::MathError) { Calc::Q.ln(0) }
    assert_equal 0, Calc::Q.ln(1)
    assert_in_epsilon Math.log(2), Calc::Q.ln(2).to_f
  end

  # libcalc log is equivalent to Math.log10 or Math.log(x, 10)
  def test_log
    assert_instance_of Calc::Q, Calc::Q.log(1)
    assert_instance_of Calc::Q, Calc::Q(1).log
    assert_raises(Calc::MathError) { Calc::Q.log(0) }
    assert_equal 0, Calc::Q.log(1)
    assert_in_epsilon Math.log10(2), Calc::Q.log(2).to_f
  end

  def test_root
    assert_instance_of Calc::Q, Calc::Q.root(7, 4)
    assert_instance_of Calc::Q, Calc::Q(7).root(4)
    assert_in_epsilon 1.62658, Calc::Q.root(7, 4).to_f

    assert_raises(Calc::MathError) { Calc::Q.root(1, 0) }
    assert_raises(Calc::MathError) { Calc::Q.root(0, -1) }
    assert_raises(Calc::MathError) { Calc::Q.root(-2, 4) }

    # these are currently implemented in terms of Q#root
    # calc actually has a sqrt with many options, we're not exposing yet
    assert_instance_of Calc::Q, Calc::Q.sqrt(4)
    assert_instance_of Calc::Q, Calc::Q(4).sqrt
    assert_instance_of Calc::Q, Calc::Q.cbrt(8)
    assert_instance_of Calc::Q, Calc::Q(8).cbrt
    assert_equal 2, Calc::Q(4).sqrt
    assert_equal 2, Calc::Q(8).cbrt
  end

  def test_sec
    assert_instance_of Calc::Q, Calc::Q.sec(0)
    assert_in_epsilon 1.85081571768092561791, Calc::Q.sec(1).to_f
    assert_in_epsilon 1.85081571768092561791, Calc::Q(1).sec.to_f
    assert_equal 1, Calc::Q.sec(0)
  end

  def test_sech
    assert_instance_of Calc::Q, Calc::Q.sech(0)
    assert_instance_of Calc::Q, Calc::Q(0).sech
    assert_equal 1, Calc::Q.sech(0)
    assert_in_epsilon 0.64805427366388539958, Calc::Q.sech(1).to_f
  end

end
