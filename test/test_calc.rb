require 'minitest_helper'

class TestCalc < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Calc::VERSION
  end

  def test_abs
    assert_rational_and_equal 5, Calc.abs(5)
    assert_rational_and_equal 5, Calc.abs(-5)
    assert_rational_and_equal 5, Calc.abs(Calc::C(-5,0))
    assert_rational_and_equal Calc::C(4,5).abs, Calc.abs(Calc::C(4,5))
  end

  def test_acos
    assert_rational_in_epsilon 1.04719755119659774615, Calc.acos(0.5)
    assert_complex_parts Calc.acos(2), 0, 1.31695789692481670863
  end
end
