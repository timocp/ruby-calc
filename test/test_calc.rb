require 'minitest_helper'

class TestCalc < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Calc::VERSION
  end

  def check_delegation_value(m, ruby_n, calc_n)
    assert_respond_to Calc, m
    begin
      expected = calc_n.__send__(m)
    rescue => e
      expected_exception = e.class
    end
    if expected_exception
      assert_raises(expected_exception) { Calc.__send__(m, ruby_n) }
    else
      actual = Calc.__send__(m, ruby_n)
      assert_instance_of expected.class, actual
      assert_equal expected, actual
    end
  end

  def check_delegation(m)
    [-2, -1, 0, 0.5, 1, 2, "10"].map do |n|
      check_delegation_value(m, n, Calc::Q(n))
    end
    [1+1i, 1-1i, 1i, -1i, -1+1i, -1-1i].map do |n|
      check_delegation_value(m, n, Calc::C(n))
    end
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
    check_delegation :arg
    check_delegation :asec
    check_delegation :asech
    check_delegation :asin
    check_delegation :asinh
    check_delegation :atan
    #check_delegation :atan2
    check_delegation :atanh
    check_delegation :cos
    check_delegation :cosh
    check_delegation :cot
    check_delegation :coth
    check_delegation :csc
    check_delegation :csch
    check_delegation :fact
    check_delegation :gd
    check_delegation :im
    check_delegation :isreal
    check_delegation :pi
    #check_delegation :quomod
    check_delegation :re
    check_delegation :sec
    check_delegation :sech
    check_delegation :sin
    check_delegation :sinh
    check_delegation :tan
    check_delegation :tanh
  end

end
