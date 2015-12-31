require 'minitest_helper'

class TestConfig < Minitest::Test

  def test_module_exists
    refute_nil Calc::Config
  end

  # expected defaults
  EXPECTED = {
    display: 20,
    epsilon: Calc::Q("1e-20"),
    mode: "real",
  }

  def test_display
    assert_equal EXPECTED[:display], Calc::Config.display

    Calc::Config.display = 10
    assert_equal 10, Calc::Config.display

    assert_raises(Calc::MathError) { Calc::Config.display = -1 }

    Calc::Config.display = EXPECTED[:display]
  end

  def test_epsilon
    assert_equal EXPECTED[:epsilon], Calc::Config.epsilon

    Calc::Config.epsilon = "1e-40"
    assert_equal Calc::Q("1e-40"), Calc::Config.epsilon

    assert_raises(Calc::MathError) { Calc::Config.epsilon = 0 }
    assert_raises(Calc::MathError) { Calc::Config.epsilon = -0.1 }

    Calc::Config.epsilon = EXPECTED[:epsilon]
  end

  def test_mode
    assert_equal EXPECTED[:mode], Calc::Config.mode

    Calc::Config.mode = "fraction"
    assert_equal "fraction", Calc::Config.mode
    Calc::Config.mode = "frac"
    assert_equal "fraction", Calc::Config.mode
    Calc::Config.mode = "default"
    assert_equal EXPECTED[:mode], Calc::Config.mode
    Calc::Config.mode = "scientific"
    assert_equal "scientific", Calc::Config.mode

    assert_raises(ArgumentError) { Calc::Config.mode = "cat" }

    Calc::Config.mode = EXPECTED[:mode]
  end

end
