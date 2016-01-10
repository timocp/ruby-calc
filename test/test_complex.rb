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
    assert_instance_of Calc::C, Calc::C(Complex(1,1))
    assert_instance_of Calc::C, Calc::C(Calc::C(1,1))
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

  def test_to_s
    assert_equal "1+1i", Calc::C(1,1).to_s
    assert_equal "1", Calc::C(1,0).to_s
    assert_equal "1i", Calc::C(0,1).to_s
    assert_equal "0", Calc::C(0,0).to_s
    assert_equal "-1i", Calc::C(0,-1).to_s
    assert_equal "-1", Calc::C(-1,0).to_s
    assert_equal "-1-1i", Calc::C(-1,-1).to_s
    assert_equal "0.2+0.4i", Calc::C(Calc::Q(1,5), Calc::Q(2,5)).to_s
    assert_equal "1/5+2i/5", Calc::C(Calc::Q(1,5), Calc::Q(2,5)).to_s(:frac)
    assert_equal "-0.2-0.4i", Calc::C(Calc::Q(-1,5), Calc::Q(-2,5)).to_s
    assert_equal "-1/5-2i/5", Calc::C(Calc::Q(-1,5), Calc::Q(-2,5)).to_s(:frac)
  end

  def test_inspect
    assert_equal "Calc::C(1+1i)", Calc::C(1,1).inspect
  end

  def test_unary
    assert_instance_of Calc::C, +Calc::C(1,1)
    assert_instance_of Calc::C, -Calc::C(1,1)
    assert_equal Complex(1,1), +Calc::C(1,1)
    assert_equal Complex(-1,-1), +Calc::C(-1,-1)
    assert_equal Complex(-1,-1), -Calc::C(1,1)
    assert_equal Complex(1,1), -Calc::C(-1,-1)
  end

  def test_add
    assert_instance_of Calc::C, Calc::C(1,1) + Calc::C(2,-2)
    assert_equal Calc::C(3,-1), Calc::C(1,1) + Calc::C(2,-2)
    assert_equal Calc::C(3,1), Calc::C(1,1) + Calc::Q(2)
    assert_equal Calc::C(3,1), Calc::C(1,1) + Calc::Z(2)
    assert_equal Calc::C(3,3), Calc::C(1,1) + Complex(2,2)
    assert_equal Calc::C(Calc::Q(5,3), 1), Calc::C(1,1) + Rational(2,3)
    assert_equal Calc::C(3,1), Calc::C(1,1) + 2
    assert_equal Calc::C(1+BIG2,1), Calc::C(1,1) + BIG2
    assert_equal Calc::C(Calc::Q(3,2), 1), Calc::C(1,1) + 0.5
  end

  def test_subtract
    assert_instance_of Calc::C, Calc::C(1,1) - Calc::C(1,1)
    assert_equal Calc::C(0), Calc::C(1,1) - Calc::C(1,1)
    assert_equal Calc::C(Calc::Q(1,3),1), Calc::C(1,1) - Calc::Q(2,3)
  end

  def test_multiply
    assert_instance_of Calc::C, Calc::C(1,1) * Calc::C(1,1)
    assert_equal Calc::C(0,2), Calc::C(1,1) * Calc::C(1,1)
    assert_equal Calc::C(0,1), Calc::C(1,0) * Calc::C(0,1)
    assert_equal Calc::C(0,-2), Calc::C(1,1) * Calc::C(-1,-1)
  end

  def test_divide
    assert_instance_of Calc::C, Calc::C(1,1) / Calc::C(1,1)
    assert_equal 1, Calc::C(1,1) / Calc::C(1,1)
    assert_equal Calc::C(1,-1), Calc::C(1,1) / Calc::C(0,1)
    assert_equal Calc::C(1,1), Calc::C(1,1) / Calc::C(1,0)
    assert_equal Calc::C(2,-2), Calc::C(4,-4) / 2
    assert_equal Calc::C(-2,-2), Calc::C(4,-4) / Calc::C(0,2)
    assert_equal Calc::C(0,-2), Calc::C(4,-4) / Calc::C(2,2)

    assert_raises(Calc::MathError) { Calc::C(1,1) / 0 }
  end

  def test_power
    assert_instance_of Calc::C, Calc::C(1,1) ** 2
    assert_instance_of Calc::C, Calc::C.power(Calc::C(1,1), 2)

    assert_equal -4, Calc::C(1,1) ** 4
    assert_equal 8.22074, Calc::C("1.2345").power(10, "1e-5").re.to_f
    assert_equal       0, Calc::C("1.2345").power(10, "1e-5").im
    assert_equal -26, Calc::C(1,3).power(3).re
    assert_equal -18, Calc::C(1,3).power(3).im
    assert_equal Calc::C("-2.50593","-1.39445"), Calc::C(1,3).power(Calc::C(2,1), "1e-5")
    assert_equal Calc::C(".20787957635076190855"), Calc::C(0,1) ** Calc::C(0,1)
  end

  def test_coerce
    assert_instance_of Calc::C, Complex(1,1) + Calc::C(2,2)
    assert_equal Calc::C(3,3), Complex(1,1) + Calc::C(2,2)
    assert_equal Calc::C(3,2), 1 + Calc::C(2,2)
    assert_equal Calc::C(4,4), 2 * Calc::C(2,2)
    assert_equal Calc::C("0.5","-0.5"), 2 / Calc::C(2,2)
    assert_equal Calc::C(1,1), 0.5 * Calc::C(2,2)
  end

  def test_abs
    assert_instance_of Calc::Q, Calc::C(1,0).abs
    assert_instance_of Calc::Q, Calc::C(1,1).abs
    assert_instance_of Calc::Q, Calc::C(0,1).abs
    assert_equal 1, Calc::C(1,0).abs
    assert_in_epsilon 1.4142135623730950488, Calc::C(1,1).abs
    assert_equal 1, Calc::C(0,1).abs
    assert_equal 0, Calc::C(0,0).abs
    assert_equal 1, Calc::C(-1).abs
    assert_equal 5, Calc::C(3,-4).abs
  end

  def test_real?
    assert_instance_of TrueClass, Calc::C(1,0).real?
    assert_instance_of FalseClass, Calc::C(1,1).real?
    assert_instance_of FalseClass, Calc::C(0,1).real?
  end

  def test_imag?
    assert_instance_of TrueClass, Calc::C(0,1).imag?
    assert_instance_of FalseClass, Calc::C(1,1).imag?
    assert_instance_of FalseClass, Calc::C(1,0).imag?
  end

end
