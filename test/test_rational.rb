require 'minitest_helper'

class TestRational < MiniTest::Test

  BIG = 0x4000000000000000  # first BigNum

  def test_class_exists
    refute_nil Calc::Q
  end

  def test_initialization
    # num/den versions (anything accepted by Calc::Z.new is allowed)
    assert_instance_of Calc::Q, Calc::Q.new(1, 3)
    assert_instance_of Calc::Q, Calc::Q.new(BIG, BIG+1)
    assert_instance_of Calc::Q, Calc::Q.new("1", "3")
    assert_instance_of Calc::Q, Calc::Q.new(Calc::Z(1), Calc::Z(3))

    # single param version
    assert_instance_of Calc::Q, Calc::Q.new(1)
    assert_instance_of Calc::Q, Calc::Q.new(BIG)
    assert_instance_of Calc::Q, Calc::Q.new(Calc::Z(42))
    assert_instance_of Calc::Q, Calc::Q.new("1/3")
    assert_instance_of Calc::Q, Calc::Q.new(Rational(1,3))
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
    assert_equal "3.25", q2.to_s
    refute_equal q1.object_id, q2.object_id
  end

  def test_equal
    assert Calc::Q.new(3) == Calc::Q.new(3)     # Q == Q
    assert Calc::Q.new(3) == Calc::Z.new(3)     # Q == Z
    assert Calc::Q.new(3) == Calc::Q.new(6, 2)  # Q == Q (reduced)
    assert Calc::Q.new(3) == 3                  # Q == Fixnum
    assert Calc::Q.new(BIG) == BIG              # Q == Bignum
    assert Calc::Q.new(2,3) == Rational(2,3)    # Q == Rational

    assert Calc::Q.new(3) != Calc::Q.new(4)
    assert Calc::Q.new(3) != Calc::Z.new(4)
    assert Calc::Q.new(3) != Calc::Q.new(4, 2)
    assert Calc::Q.new(3) != 4
    assert Calc::Q.new(BIG) != BIG + 1
    assert Calc::Q.new(2,3) != Rational(3,4)
    assert Calc::Q.new(2,3) != "dog"
  end

  def test_reduction
    assert_equal 2, Calc::Q(4, 6).numerator
    assert_equal 3, Calc::Q(4, 6).denominator
    assert_equal 2, Calc::Q("4/6").numerator
    assert_equal 3, Calc::Q("4/6").denominator
    assert_equal 2, Calc::Q(Rational(4,6)).numerator
    assert_equal 3, Calc::Q(Rational(4,6)).denominator

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

  def test_power
    # TODO: skips because qpowi requires and integer power (i guess because the
    # result wouldn't necessarily be a rational number). calc has qpower which
    # calculates a rational result to an arbitray precision, but having a
    # second argument to ** would be weird. need to think about this.
    skip { assert_rational_and_equal Calc::Q(3),    Calc::Q(81) ** Calc::Q(1,4) }
    assert_rational_and_equal Calc::Q(1,9),  Calc::Q(1,3) ** 2
    assert_rational_and_equal Calc::Q(1,27), Calc::Q(1,3) ** Calc::Z(3)
    skip { assert_rational_and_equal Calc::Q(2),    Calc::Q(8) ** Rational(2,3) }
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
    skip { assert_raises("SomethingError") { Calc::Q.new(1,3) << 1 } }
  end

  def test_denominator
    assert_equal 4, Calc::Q( 13,  4).denominator
    assert_equal 4, Calc::Q( 13, -4).denominator
    assert_equal 4, Calc::Q(-13, -4).denominator
    assert_equal 4, Calc::Q(-13, -4).denominator
  end

  def test_numerator
    assert_equal  13, Calc::Q( 13,  4).numerator
    assert_equal -13, Calc::Q(-13,  4).numerator
    assert_equal -13, Calc::Q( 13, -4).numerator
    assert_equal  13, Calc::Q(-13, -4).numerator
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
    assert_equal "0.25", Calc::Q.new(Rational(1, 4)).to_s
    assert_equal "0.25", Calc::Q.new(1, 4).to_s
    assert_equal "2305843009213693952", Calc::Q.new(BIG, 2).to_s
    assert_equal "0.25", Calc::Q.new(Calc::Z.new(1), Calc::Z.new(4)).to_s
    assert_equal "0.25", Calc::Q.new("1", "4").to_s
  end

end
