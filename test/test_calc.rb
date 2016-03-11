require 'minitest_helper'

class TestCalc < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Calc::VERSION
  end

  def test_pi
    pi = Calc.pi
    assert_instance_of Calc::Q, pi
    assert_equal Rational(157079632679489661923,50000000000000000000), pi

    pi = Calc.pi("1e-5")
    assert_equal Rational(314159,100000), pi
  end

  def test_polar
    assert_rational_and_equal 2, Calc.polar(2, 0)
    assert_complex_parts [-0.41615, 0.9093], Calc.polar(1, 2, "1e-5")
    assert_complex_parts [1.4142135623730950488, 1.4142135623730950488], Calc.polar(2, Calc.pi/4)

    assert_raises(ArgumentError) { Calc.polar(1, Complex(0,1)) }
    assert_raises(ArgumentError) { Calc.polar(Complex(0,1), 1) }
    assert_raises(Calc::MathError) { Calc.polar(1, 1, -0.1) }
  end

  def test_avg
    a4 = [1,2,3,4]
    a5 = [1,2,3,4,5]
    assert_rational_and_equal 3, Calc.avg(*a5)
    assert_rational_and_equal Calc::Q("2.5"), Calc.avg(*a4)
    assert_complex_parts [3,3], Calc.avg(*a5.map { |x| Calc::C(x,x) })
    assert_complex_parts [Calc::Q("2.5"), Calc::Q("2.5")], Calc.avg(*a4.map { |x| Calc::C(x,x) })
    assert_complex_parts [Calc::Q("0.75"), Calc::Q("-0.25")], Calc.avg(1, Complex(0,1), 2, Complex(0,-2))
  end

  # following tests are for checking that Calc.foo(x) correctly calls x.foo

  def check_delegation_value(m, ruby_n, calc_n, extra_args_count)
    assert_respond_to Calc, m
    extra_args = [ruby_n] * extra_args_count
    begin
      expected = calc_n.__send__(*([m] + extra_args))
    rescue => e
      refute_instance_of NoMethodError, e
      expected_exception = e.class
    end
    if expected_exception
      assert_raises(expected_exception) { Calc.__send__(*([m, ruby_n] + extra_args)) }
    else
      actual = Calc.__send__(*([m, ruby_n] + extra_args))
      assert_instance_of expected.class, actual
      assert_equal expected, actual
    end
  end

  def check_real_delegation(m, arg_count = 1)
    [-2, -1, 0, 0.5, 1, 2, "10"].map do |n|
      check_delegation_value(m, n, Calc::Q(n), arg_count - 1)
    end
  end

  def check_complex_delegation(m, arg_count = 1)
    [[1,1], [1,-1], [0,1], [0,-1], [-1,1], [-1,1]].map do |r,i|
      check_delegation_value(m, Complex(r,i), Calc::C(r,i), arg_count - 1)
    end
  end

  def check_delegation(m, arg_count = 1)
    check_real_delegation(m, arg_count)
    check_complex_delegation(m, arg_count)
  end

  def test_delegations
    # for these methods, no need to check behaviour as they are tested in
    # test_rational/test_complex.  just check they return the same value as
    # their class version, including raising the same exceptions
    check_delegation :abs
    check_delegation :acos
    check_delegation :acosh
    check_delegation :acot
    check_delegation :acoth
    check_delegation :acsc
    check_delegation :acsch
    check_delegation :agd
    check_delegation :appr
    check_delegation :arg
    check_delegation :asec
    check_delegation :asech
    check_delegation :asin
    check_delegation :asinh
    check_delegation :atan
    check_real_delegation :atan2, 2
    check_delegation :atanh
    check_real_delegation :bernoulli
    check_real_delegation :bit
    check_delegation :bround
    check_real_delegation :catalan
    check_delegation :ceil
    check_real_delegation :cfappr
    check_real_delegation :cfsim
    check_real_delegation :char
    check_delegation :cos
    check_delegation :cosh
    check_delegation :cot
    check_delegation :coth
    check_delegation :csc
    check_delegation :csch
    check_real_delegation :den
    check_real_delegation :fact
    check_real_delegation :fib
    check_delegation :floor
    check_delegation :gd
    check_real_delegation :hypot, 2
    check_delegation :im
    check_delegation :inverse
    check_delegation :iseven
    check_delegation :isimag
    check_delegation :isint
    check_delegation :isreal
    check_delegation :isodd
    check_real_delegation :num
    check_delegation :power, 2
    check_real_delegation :quomod, 2
    check_delegation :re
    check_delegation :round
    check_delegation :sec
    check_delegation :sech
    check_delegation :sin
    check_delegation :sinh
    check_delegation :sqrt
    check_delegation :tan
    check_delegation :tanh
  end

end
