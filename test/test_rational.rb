require 'minitest_helper'

class TestRational < MiniTest::Test
  def test_class_exists
    refute_nil Calc::Q
  end

  def test_initialization
    # num/den versions (anything accepted by Calc::Z.new is allowed)
    assert_instance_of Calc::Q, Calc::Q.new(1, 3)
    assert_instance_of Calc::Q, Calc::Q.new(0x4000000000000000, 0x4000000000000001)
    assert_instance_of Calc::Q, Calc::Q.new("1", "3")
    assert_instance_of Calc::Q, Calc::Q.new(Calc::Z(1), Calc::Z(3))

    # single param version
    assert_instance_of Calc::Q, Calc::Q.new(1)
    assert_instance_of Calc::Q, Calc::Q.new(0x4000000000000000)
    assert_instance_of Calc::Q, Calc::Q.new(Calc::Z(42))
    assert_instance_of Calc::Q, Calc::Q.new("1/3")
    assert_instance_of Calc::Q, Calc::Q.new(Rational(1,3))
  end

  def test_add
    assert_instance_of Calc::Q, Calc::Q.new(1, 3) + 4
    assert_instance_of Calc::Q, Calc::Q.new(1, 3) + Calc::Z(4)
    assert_instance_of Calc::Q, Calc::Q.new(1, 3) + Calc::Q.new(1, 4)
  end

  # currently just using default calc (prints decimal approximation).  needs
  # more options.
  def test_to_s
    assert_equal "~0.33333333333333333333", Calc::Q.new(1, 3).to_s
  end

end
