$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "calc"

require "minitest/autorun"

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

  def assert_rational_array(expected, actual)
    assert_instance_of Array, actual
    assert_equal expected.size, actual.size
    expected.zip(actual) do |e, a|
      assert_rational_value e, a
    end
  end

  def assert_rational_in_epsilon(expected, actual)
    assert_instance_of Calc::Q, actual
    assert_in_epsilon expected, actual
  end

  def assert_rational_value(expected, actual)
    if expected.integer?
      assert_rational_and_equal expected, actual
    else
      assert_rational_in_epsilon expected, actual
    end
  end

  # expected is an array of [real_part, imag_part]
  def assert_complex_parts(expected, actual)
    assert_instance_of Calc::C, actual
    assert_rational_value expected.first, actual.re
    assert_rational_value expected.last, actual.im
  end

  # check a pair of methods return 1/true
  def check_truthy(v, qmethod, bmethod, *args)
    assert_rational_and_equal 1, v.__send__(*([qmethod] + args))
    assert_instance_of TrueClass, v.__send__(*([bmethod] + args))
  end

  # check a pair of methods return 0/false
  def check_falsey(v, qmethod, bmethod, *args)
    assert_rational_and_equal 0, v.__send__(*([qmethod] + args))
    assert_instance_of FalseClass, v.__send__(*([bmethod] + args))
  end

  def with_config(name, value)
    orig = Calc.config(name, value)
    yield
  ensure
    Calc.config(name, orig)
  end
end
