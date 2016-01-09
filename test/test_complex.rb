require 'minitest_helper'

class TestComplex < MiniTest::Test

  BIG  =  0x4000000000000000  # first BigNum
  BIG2 =  0x8000000000000000  # first Bignum that won't fit in a long
  BIG3 = -0x8000000000000001  # first negative bignum that won't fit in a long

  def test_class_exists
    refute_nil Calc::C
  end

  def test_initialization
    assert_instance_of Calc::C, Calc::C(1,1)
    assert_instance_of Calc::C, Calc::C(BIG, BIG)
    assert_instance_of Calc::C, Calc::C(BIG2, BIG2)
    assert_instance_of Calc::C, Calc::C(BIG3, BIG3)
    assert_instance_of Calc::C, Calc::C("1", "1e3")
    assert_instance_of Calc::C, Calc::C("1/3", "1e-3")
    assert_instance_of Calc::C, Calc::C(Rational(1,3), Rational(1,3))
    assert_instance_of Calc::C, Calc::C(0.3, 0.3)
    assert_instance_of Calc::C, Calc::C(Calc::Z(1), Calc::Z(2))
    assert_instance_of Calc::C, Calc::C(Calc::Q(1), Calc::Q(2))

    assert_instance_of Calc::C, Calc::C(1)
    assert_instance_of Calc::C, Calc::C(BIG)
    assert_instance_of Calc::C, Calc::C(BIG2)
    assert_instance_of Calc::C, Calc::C(BIG3)
    assert_instance_of Calc::C, Calc::C("1")
    assert_instance_of Calc::C, Calc::C("1/3")
    assert_instance_of Calc::C, Calc::C(Rational(1,3))
    assert_instance_of Calc::C, Calc::C(0.3)
    assert_instance_of Calc::C, Calc::C(Calc::Z(1))
    assert_instance_of Calc::C, Calc::C(Calc::Q(1))
  end

  def test_re
    assert_instance_of Calc::Q, Calc::C(1,2).re
    assert_equal 1, Calc::C(1,2).re
    assert_alias Calc::C(1,2), :re, :real
  end

  def test_im
    assert_instance_of Calc::Q, Calc::C(1,2).im
    assert_equal 2, Calc::C(1,2).im
    assert_alias Calc::C(1,2), :im, :imag
  end

  def test_equal
    assert Calc::C(1,2) == Calc::C(1,2)
    assert Calc::C(BIG, BIG2) == Complex(BIG, BIG2)
    assert Calc::C(10, 0) == 10
    assert Calc::C(BIG2, 0) == BIG2
    assert Calc::C(5, 0) == Rational(5)
    assert Calc::C(5, 0) == 5.0
    assert Calc::C(5, 0) == Calc::Q(5)
    assert Calc::C(5, 0) == Calc::Z(5)

    refute Calc::C(1,2) == Calc::C(1,3)
    refute Calc::C(BIG, BIG2) == Complex(BIG2, BIG)
    refute Calc::C(10, 1) == 10
    refute Calc::C(BIG2, 1) == BIG2
    refute Calc::C(5, 1) == Rational(5)
    refute Calc::C(5, 1) == 5.0
    refute Calc::C(5, 1) == Calc::Q(5)
    refute Calc::C(5, 1) == Calc::Z(5)
  end

end
