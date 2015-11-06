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
  end

  def test_add
    assert_instance_of Calc::Q, Calc::Q.new(1, 3) + 4
    assert_instance_of Calc::Q, Calc::Q.new(1, 3) + Calc::Z(4)
    assert_instance_of Calc::Q, Calc::Q.new(1, 3) + Calc::Q.new(1, 4)
  end

  def test_denominator
    assert_equal  4, Calc::Q(13,  4).denominator
    assert_equal -4, Calc::Q(13, -4).denominator
  end

  def test_numerator
    assert_equal  13, Calc::Q( 13, 4).numerator
    assert_equal -13, Calc::Q(-13, 4).numerator
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
