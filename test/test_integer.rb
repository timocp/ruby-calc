require 'minitest_helper'

class TestInteger < Minitest::Test
  def test_class_exists
    refute_nil Calc::Z
  end

  def test_initialization
    assert_instance_of Calc::Z, Calc::Z.new(42)                 # Fixnum
    assert_instance_of Calc::Z, Calc::Z.new(0x4000000000000000) # Bignum
    assert_instance_of Calc::Z, Calc::Z.new(Calc::Z.new(42))    # Calc::Z
  end

  def test_dup
    z1 = Calc::Z.new(42)
    z2 = z1.dup
    assert_equal "42", z2.to_s
    refute_equal z1.object_id, z2.object_id
  end

  def test_equal
    assert_equal Calc::Z.new(3), Calc::Z.new(3)
    assert_equal Calc::Z.new(4), 4
    assert_equal 5, Calc::Z.new(5)
    refute_equal Calc::Z.new(6), Calc::Z.new(7)
    refute_equal Calc::Z.new(8), 9
    refute_equal 10, Calc::Z.new(11)
    refute_equal Calc::Z.new(12), "dog"
  end

  def test_comparisons
    assert_equal  0, Calc::Z.new(3) <=> Calc::Z.new(3)
    assert_equal -1, Calc::Z.new(4) <=> Calc::Z.new(5)
    assert_equal  1, Calc::Z.new(7) <=> Calc::Z.new(6)
    assert_equal  0, Calc::Z.new(8) <=> 8
    assert_equal -1, Calc::Z.new(9) <=> 10
    assert_equal  1, Calc::Z.new(12) <=> 11

    # <=> is supposed to return nil if objects aren't comparable
    assert_nil Calc::Z.new(3) <=> "cat"
    assert_nil "cat" <=> Calc::Z.new(4)

    assert_operator Calc::Z.new(13), :<, Calc::Z.new(14)
    assert_operator Calc::Z.new(15), :<, 16
    refute_operator Calc::Z.new(17), :<, 17
    refute_operator Calc::Z.new(18), :<, 17

    assert_operator Calc::Z.new(19), :<=, Calc::Z.new(20)
    assert_operator Calc::Z.new(21), :<=, 22
    assert_operator Calc::Z.new(23), :<=, 23
    refute_operator Calc::Z.new(24), :<=, 23

    assert_operator Calc::Z.new(25), :>, Calc::Z.new(24)
    assert_operator Calc::Z.new(26), :>, 25
    refute_operator Calc::Z.new(27), :>, 27
    refute_operator Calc::Z.new(28), :>, 29

    assert_operator Calc::Z.new(30), :>=, Calc::Z.new(29)
    assert_operator Calc::Z.new(31), :>=, 30
    assert_operator Calc::Z.new(32), :>=, 32
    refute_operator Calc::Z.new(33), :>=, 34

    # check we can't compare to non-numbers
    %i(< <= > >=).each do |op|
      assert_raises(ArgumentError) { Calc::Z.new(40).send(op, "cat") }
    end
  end

  def test_add
    assert_instance_of Calc::Z, Calc::Z.new(1) + Calc::Z.new(2)
    assert_instance_of Calc::Z, Calc::Z.new(3) + 4
    assert_equal 10, Calc::Z.new(4) + Calc::Z.new(6)
    assert_equal 12, Calc::Z.new(5) + 7
  end

  def test_subtract
    assert_instance_of Calc::Z, Calc::Z.new(1) - Calc::Z.new(2)
    assert_equal -1, Calc::Z.new(1) - Calc::Z.new(2)
    assert_equal -1, Calc::Z.new(3) - 4
  end
  
  def test_to_s
    assert_equal "42",                  Calc::Z.new(42).to_s
    assert_equal "4611686018427387904", Calc::Z.new(0x4000000000000000).to_s
    assert_equal "42",                  Calc::Z.new(Calc::Z.new(42)).to_s
  end
end
