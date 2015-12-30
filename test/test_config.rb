require 'minitest_helper'

class TestConfig < Minitest::Test

  def test_module_exists
    refute_nil Calc::Config
  end

  def test_epsilon
    # default value
    assert_equal Calc::Q("1e-20"), Calc::Config.epsilon

    # changing it
    Calc::Config.epsilon = "1e-40"
    assert_equal Calc::Q("1e-40"), Calc::Config.epsilon

    # can't be zero or negative
    assert_raises(Calc::MathError) { Calc::Config.epsilon = 0 }
    assert_raises(Calc::MathError) { Calc::Config.epsilon = -0.1 }

    # change it back to the default
    Calc::Config.epsilon = "1e-20"
  end
end
