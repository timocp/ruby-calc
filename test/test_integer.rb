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

  def test_unary
    assert_instance_of Calc::Z, +Calc::Z.new(42)
    assert_instance_of Calc::Z, -Calc::Z.new(42)
    assert_equal  42, +Calc::Z.new( 42)
    assert_equal -42, +Calc::Z.new(-42)
    assert_equal -42, -Calc::Z.new( 42)
    assert_equal  42, -Calc::Z.new(-42)
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

  def test_multiply
    assert_instance_of Calc::Z, Calc::Z.new(1) * Calc::Z.new(2)
    assert_equal 12, Calc::Z.new(3) * Calc::Z.new(4)
    assert_equal 30, Calc::Z.new(5) * 6
  end

  def test_divide
    skip "division not tested until Calc::Q implemented"
  end

  def test_mod
    assert_instance_of Calc::Z, Calc::Z.new(13) % Calc::Z.new(4)
    assert_instance_of Calc::Z, Calc::Z.new(13) % 4
    assert_equal  1, Calc::Z.new( 13) %  4
    assert_equal -3, Calc::Z.new( 13) % -4
    assert_equal  3, Calc::Z.new(-13) %  4
    assert_equal -1, Calc::Z.new(-13) % -4
  end

  def test_divmod
    r = Calc::Z.new(13).divmod(Calc::Z.new(4))
    assert_instance_of Array, r
    assert_equal 2, r.size
    assert_instance_of Calc::Z, r.first
    assert_instance_of Calc::Z, r.last
    r = Calc::Z.new(13).divmod(4)
    assert_instance_of Array, r
    assert_equal 2, r.size
    assert_instance_of Calc::Z, r.first
    assert_instance_of Calc::Z, r.last

    assert_equal [ 3,  1], Calc::Z.new(13).divmod(4)
    assert_equal [-4, -3], Calc::Z.new(13).divmod(-4)
    assert_equal [-4,  3], Calc::Z.new(-13).divmod(4)
    assert_equal [ 3, -1], Calc::Z.new(-13).divmod(-4)

    # divide by zero should raise ZeroDivisionError instead of CalcError
    assert_raises(ZeroDivisionError) { Calc::Z.new(1).divmod(0) }
    assert_raises(ZeroDivisionError) { Calc::Z.new(1).divmod(Calc::Z.new(0)) }
  end

  def test_modulo
    assert_instance_of Calc::Z, Calc::Z.new(13).modulo(Calc::Z.new(4))
    assert_instance_of Calc::Z, Calc::Z.new(13).modulo(4)

    assert_equal  1, Calc::Z.new(13).modulo(4)
    assert_equal -3, Calc::Z.new(13).modulo(-4)
    assert_equal  3, Calc::Z.new(-13).modulo(4)
    assert_equal -1, Calc::Z.new(-13).modulo(-4)
  end

  # note that behaviour of &, | and ^ with negatives doesn't match ruby's
  # normal numeric types.  it is consistant with calc though.
  def test_and
    assert_instance_of Calc::Z, Calc::Z.new(4) & Calc::Z.new(7)
    assert_instance_of Calc::Z, Calc::Z.new(4) & 7
    assert_equal  4, Calc::Z.new( 4) &  7
    skip { assert_equal  0, Calc::Z.new( 4) & -7 }  # TODO: incorrectly returns 4
    assert_equal -4, Calc::Z.new(-4) &  7
    assert_equal  0, Calc::Z.new(-4) & -7
  end

  def test_or
    assert_instance_of Calc::Z, Calc::Z.new(18) | Calc::Z.new(20)
    assert_instance_of Calc::Z, Calc::Z.new(18) | 20
    assert_equal  22, Calc::Z.new( 18) |  20
    skip { assert_equal  -2, Calc::Z.new( 18) | -20 }  # TODO: incorrectly returns 22
    assert_equal -22, Calc::Z.new(-18) |  20
    assert_equal   2, Calc::Z.new(-18) | -20
  end

  def test_xor
    assert_instance_of Calc::Z, Calc::Z.new(7) | Calc::Z.new(14)
    assert_instance_of Calc::Z, Calc::Z.new(7) | 14
    assert_equal   9, Calc::Z.new( 7) ^  14
    skip { assert_equal -11, Calc::Z.new( 7) ^ -14 } # TODO: incorrectly returns 9
    assert_equal  -9, Calc::Z.new(-7) ^  14
    assert_equal  11, Calc::Z.new(-7) ^ -14
  end

  def test_shift
    assert_instance_of Calc::Z, Calc::Z.new(4) << Calc::Z.new(5)
    assert_instance_of Calc::Z, Calc::Z.new(4) << 5
    assert_instance_of Calc::Z, Calc::Z.new(100) >> Calc::Z.new(2)
    assert_instance_of Calc::Z, Calc::Z.new(100) >> 2
    assert_equal  128, Calc::Z.new(4) << 5
    assert_equal    0, Calc::Z.new(4) >> 5
    assert_equal  400, Calc::Z.new(100) << 2
    assert_equal   25, Calc::Z.new(100) >> 2
    assert_equal -320, Calc::Z.new(-20) << 4
    assert_equal   -1, Calc::Z.new(-20) >> 4
    assert_equal    1, Calc::Z.new(20) << -4
    assert_equal  320, Calc::Z.new(20) >> -4
    assert_equal  -12, Calc::Z.new(-50) << -2
    assert_equal -200, Calc::Z.new(-50) >> -2
  end

  def test_power
    assert_instance_of Calc::Z, Calc::Z.new(3) ** Calc::Z.new(19)
    assert_instance_of Calc::Z, Calc::Z.new(3) ** 19
    assert_equal  1162261467, Calc::Z.new(3) ** 19
    assert_equal -1162261467, Calc::Z.new(-3) ** 19
    skip "TODO: powers to negatives require Calc::Q"
  end
  
  def test_abs
    assert_instance_of Calc::Z, Calc::Z.new(12).abs
    assert_equal 12, Calc::Z.new(12).abs
    assert_equal 12, Calc::Z.new(-12).abs
  end

  def test_abs2
    assert_instance_of Calc::Z, Calc::Z.new(12).abs2
    assert_equal 144, Calc::Z.new(12).abs2
    assert_equal 144, Calc::Z.new(-12).abs2
  end

  # for integers, #ceil returns itself
  def test_ceil
    assert_instance_of Calc::Z, Calc::Z.new(42)
    assert_equal 10, Calc::Z.new(10).ceil
    assert_equal -6, Calc::Z.new(-6).ceil
  end

  def test_to_s
    assert_equal "42",                  Calc::Z.new(42).to_s
    assert_equal "4611686018427387904", Calc::Z.new(0x4000000000000000).to_s
    assert_equal "42",                  Calc::Z.new(Calc::Z.new(42)).to_s
  end

  def test_even_odd
    assert_instance_of TrueClass, Calc::Z.new(0).even?
    assert_instance_of FalseClass, Calc::Z.new(1).even?
    assert_instance_of TrueClass, Calc::Z.new(-1).odd?
    assert_instance_of FalseClass, Calc::Z.new(-2).odd?
  end

  def test_inspect
    assert_equal "Calc::Z(42)",  Calc::Z.new(42).inspect
    assert_equal "Calc::Z(-42)", Calc::Z.new(-42).inspect
  end
end
