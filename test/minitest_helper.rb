$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'calc'

require 'minitest/autorun'

module Minitest::Assertions

  def assert_alias(obj, m1, m2)
    assert obj.method(m1) == obj.method(m2), "expected ##{ m2 } to be an alias of ##{ m1 }"
  end

  def assert_integral_and_equal(expected, actual)
    assert_instance_of Calc::Z, actual
    assert_equal expected, actual
  end

  def refute_integral_and_equal(expected, actual)
    refute_instance_of Calc::Z, actual
    refute_equal expected, actual
  end

  def assert_rational_and_equal(expected, actual)
    assert_instance_of Calc::Q, actual
    assert_equal expected, actual
  end

  def refute_rational_and_equal(expected, actual)
    refute_instance_of Calc::Q, actual
    refute_equal expected, actual
  end

  def assert_rational_in_epsilon(expected, actual)
    assert_instance_of Calc::Q, actual
    assert_in_epsilon expected, actual
  end

  def assert_complex_parts(c, rp, ip)
    assert_instance_of Calc::C, c
    assert_in_epsilon rp, c.re
    assert_in_epsilon ip, c.im
  end

  def with_epsilon(eps)
    old_eps = Calc::Q.get_default_epsilon
    Calc::Q.set_default_epsilon(eps)
    yield
  ensure
    Calc::Q.set_default_epsilon(old_eps)
  end

end
