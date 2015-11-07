$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'calc'

require 'minitest/autorun'

module Minitest::Assertions

  def assert_rational_and_equal(expected, actual)
    assert_instance_of Calc::Q, actual
    assert_equal expected, actual
  end

  def refute_rational_and_equal(expected, actual)
    refute_instance_of Calc::Q, actual
    refute_equal expected, actual
  end

end
