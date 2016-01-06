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

end
