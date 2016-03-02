require 'minitest_helper'

class TestConfig < Minitest::Test

  # test Calc.config() method and that they actually do something

  def with_config(name, default_value, new_value, &block)
    # check expected default
    assert_equal default_value, Calc.config(name)

    # check setting new value returns old value
    assert_equal default_value, Calc.config(name, new_value)

    # do whatever other tests are needed
    yield
  ensure
    # change it back to default
    Calc.config(name, default_value)
  end

  def test_appr
    assert_equal 6, Calc::Q("5.5").appr(1)
    with_config(:appr, 24, 0) do
      assert_equal 5, Calc::Q("5.5").appr(1)
    end
    assert_raises(Calc::MathError) { Calc.config(:appr, -1) }
  end

  def test_display
    assert_equal "~0.33333333333333333333", Calc::Q(1,3).to_s
    with_config(:display, 20, 5) do
      assert_equal "~0.33333", Calc::Q(1,3).to_s
    end
    assert_raises(Calc::MathError) { Calc.config(:display, -1) }
  end

  def test_epsilon
    assert_equal Calc::Q("3.14159265358979323846"), Calc.pi
    with_config(:epsilon, Calc::Q("1e-20"), Calc::Q("1e-3")) do
      assert_equal Calc::Q("3.142"), Calc.pi
    end
    assert_raises(Calc::MathError) { Calc.config(:epsilon, 0) }
    assert_raises(Calc::MathError) { Calc.config(:epsilon, -0.1) }
  end

  def test_mode
    q = Calc::Q(1,20)
    assert_equal "0.05", q.to_s
    with_config(:mode, "real", "fraction") do
      assert_equal "1/20", q.to_s
    end
    assert_raises(ArgumentError) { Calc.config(:mode, "cat") }
  end

  def test_round
    assert_rational_and_equal Calc::Q("3.14159"), Calc.pi.round(5)
    with_config(:round, 24, 1) do
      assert_rational_and_equal Calc::Q("3.1416"), Calc.pi.round(5)
    end
    assert_raises(Calc::MathError) { Calc.config(:round, 0.5) }
    assert_raises(Calc::MathError) { Calc.config(:round, -1) }
  end

  def test_sqrt
    assert_equal 2, Calc::Q(4).sqrt
    with_config(:sqrt, 24, 24+64) do
      assert_equal -2, Calc::Q(4).sqrt
    end
    assert_raises(Calc::MathError) { Calc.config(:sqrt, 0.5) }
    assert_raises(Calc::MathError) { Calc.config(:sqrt, -1) }
  end

end
