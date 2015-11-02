require 'minitest_helper'

class TestInteger < Minitest::Test
  def test_initialization
    refute_nil ::Calc::Z
  end
end
