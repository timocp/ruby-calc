require 'minitest_helper'

class TestInteger < Minitest::Test

  BIG  =  0x4000000000000000  # first Bignum
  BIG2 =  0x8000000000000000  # first Bignum that won't fit in a long
  BIG3 = -0x8000000000000001  # first negative bignum that won't fit in a long

  def test_class_exists
    refute_nil Calc::Z
  end

  def test_initialization
    assert_instance_of Calc::Z, Calc::Z.new(42)                 # Fixnum
    assert_instance_of Calc::Z, Calc::Z.new(BIG)                # Bignum
    assert_instance_of Calc::Z, Calc::Z.new(BIG2)               # Bignum gt max long
    assert_instance_of Calc::Z, Calc::Z.new(BIG3)               # Bignum lt min long
    assert_instance_of Calc::Z, Calc::Z.new(Calc::Z.new(42))    # Calc::Z
    assert_instance_of Calc::Z, Calc::Z.new("1234")             # String

    # various string formats supported by calc
    assert_equal 42,      Calc::Z.new("0b101010")
    assert_equal 123456,  Calc::Z.new("123456")
    assert_equal 256794,  Calc::Z.new("0765432")
    assert_equal 1195503, Calc::Z.new("0x123def")
  end

  def test_concise_initialization
    assert_instance_of Calc::Z, Calc::Z(42)
    assert_equal 42, Calc::Z(42)
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
    assert_equal -1, Calc::Z(13) <=> BIG2
    assert_equal  1, Calc::Z(13) <=> BIG3
    assert_equal  0, Calc::Z(BIG2) <=> BIG2

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
    [:<, :<=, :>, :>=].each do |op|
      assert_raises(ArgumentError) { Calc::Z.new(40).send(op, "cat") }
    end

    assert Calc::Z(5).between?(1,10)
    refute Calc::Z(5).between?(6,10)
    refute Calc::Z(5).between?(1,4)
    assert Calc::Z(5).between?(Calc::Z(1), Calc::Z(10))
    assert Calc::Z(5).between?(4.5, 5.5)
    assert Calc::Z(5).between?(BIG3, BIG2)
  end

  def test_unary
    assert_instance_of Calc::Z, +Calc::Z.new(42)
    assert_instance_of Calc::Z, -Calc::Z.new(42)
    assert_equal  42, +Calc::Z.new( 42)
    assert_equal -42, +Calc::Z.new(-42)
    assert_equal -42, -Calc::Z.new( 42)
    assert_equal  42, -Calc::Z.new(-42)
    assert_equal  BIG2, +Calc::Z(BIG2)
    assert_equal -BIG2, -Calc::Z(BIG2)
    assert_equal  BIG3, +Calc::Z(BIG3)
    assert_equal -BIG3, -Calc::Z(BIG3)
  end

  def test_add
    assert_instance_of Calc::Z, Calc::Z.new(1) + Calc::Z.new(2)
    assert_instance_of Calc::Z, Calc::Z.new(3) + 4
    assert_equal 10, Calc::Z.new(4) + Calc::Z.new(6)
    assert_equal 12, Calc::Z.new(5) + 7
    assert_equal 9223372036854775850, Calc::Z(42) + BIG2
  end

  def test_subtract
    assert_instance_of Calc::Z, Calc::Z.new(1) - Calc::Z.new(2)
    assert_equal -1, Calc::Z.new(1) - Calc::Z.new(2)
    assert_equal -1, Calc::Z.new(3) - 4
    assert_equal -9223372036854775766, Calc::Z(42) - BIG2
  end

  def test_multiply
    assert_instance_of Calc::Z, Calc::Z.new(1) * Calc::Z.new(2)
    assert_equal 12, Calc::Z.new(3) * Calc::Z.new(4)
    assert_equal 30, Calc::Z.new(5) * 6
    assert_equal 0x10000000000000000, Calc::Z(2) * BIG2
  end

  def test_divide
    # returns a rational number
    assert_integral_and_equal  3, Calc::Z( 13) / Calc::Z( 4)
    assert_integral_and_equal -4, Calc::Z( 13) / Calc::Z(-4)
    assert_integral_and_equal -4, Calc::Z(-13) / Calc::Z( 4)
    assert_integral_and_equal  3, Calc::Z(-13) / Calc::Z(-4)

    # other arg types
    assert_integral_and_equal 3, Calc::Z(9) / 3
    assert_integral_and_equal 0, Calc::Z(10) / BIG2
  end

  def test_mod
    assert_instance_of Calc::Z, Calc::Z.new(13) % Calc::Z.new(4)
    assert_instance_of Calc::Z, Calc::Z.new(13) % 4
    assert_equal  1, Calc::Z.new( 13) %  4
    assert_equal -3, Calc::Z.new( 13) % -4
    assert_equal  3, Calc::Z.new(-13) %  4
    assert_equal -1, Calc::Z.new(-13) % -4

    assert_raises(ZeroDivisionError) { Calc::Z.new(13) % 0 }
    assert_raises(ZeroDivisionError) { Calc::Z.new(13) % Calc::Z.new(0) }
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
    assert_equal [ 2,  0], Calc::Z(BIG2).divmod(BIG)

    # divide by zero should raise ZeroDivisionError instead of CalcError
    assert_raises(ZeroDivisionError) { Calc::Z.new(1).divmod(0) }
    assert_raises(ZeroDivisionError) { Calc::Z.new(1).divmod(Calc::Z.new(0)) }
  end

  def test_remainder
    assert_instance_of Calc::Z, Calc::Z.new(13).remainder(Calc::Z.new(4))
    assert_instance_of Calc::Z, Calc::Z.new(13).remainder(4)

    assert_equal  1, Calc::Z.new( 13).remainder( 4)
    assert_equal  1, Calc::Z.new( 13).remainder(-4)
    assert_equal -1, Calc::Z.new(-13).remainder( 4)
    assert_equal -1, Calc::Z.new(-13).remainder(-4)
    assert_equal  0, Calc::Z.new(0).remainder(5)
    assert_equal  0, Calc::Z.new(0).remainder(-5)

    assert_raises(ZeroDivisionError) { Calc::Z.new(1).remainder(0) }
    assert_raises(ZeroDivisionError) { Calc::Z.new(1).remainder(Calc::Z.new(0)) }
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

    assert_raises(ArgumentError) { Calc::Z(2) << BIG }
    assert_raises(ArgumentError) { Calc::Z(2) << BIG2 }
  end

  def test_power
    assert_instance_of Calc::Z, Calc::Z.new(3) ** Calc::Z.new(19)
    assert_instance_of Calc::Z, Calc::Z.new(3) ** 19
    assert_equal  1162261467, Calc::Z.new(3) ** 19
    assert_equal -1162261467, Calc::Z.new(-3) ** 19
  end
  
  def test_abs
    assert_instance_of Calc::Z, Calc::Z.new(12).abs
    assert_equal 12, Calc::Z.new(12).abs
    assert_equal 12, Calc::Z.new(-12).abs
    assert_equal BIG2, Calc::Z(BIG2).abs
    assert_equal BIG2, Calc::Z(-BIG2).abs
  end

  def test_abs2
    assert_instance_of Calc::Z, Calc::Z.new(12).abs2
    assert_equal 144, Calc::Z.new(12).abs2
    assert_equal 144, Calc::Z.new(-12).abs2
    assert_equal 0x40000000000000000000000000000000, Calc::Z(BIG2).abs2
    assert_equal 0x40000000000000010000000000000001, Calc::Z(BIG3).abs2
  end

  # for integers, #ceil returns itself
  def test_ceil
    assert_instance_of Calc::Z, Calc::Z.new(42).ceil
    assert_equal 10, Calc::Z.new(10).ceil
    assert_equal -6, Calc::Z.new(-6).ceil
  end

  # same as ceil
  def test_floor
    assert_instance_of Calc::Z, Calc::Z.new(42).floor
    assert_equal 10, Calc::Z.new(10).floor
    assert_equal -6, Calc::Z.new(-6).floor
  end

  def test_truncate
    assert_instance_of Calc::Z, Calc::Z.new(42).truncate
    assert_equal 10, Calc::Z.new(10).truncate
    assert_equal -6, Calc::Z.new(-6).truncate
  end

  def test_next
    assert_instance_of Calc::Z, Calc::Z.new(42).next
    assert_equal 2, Calc::Z.new(1).next
    assert_equal 0, Calc::Z.new(-1).next
  end

  def test_fact
    assert_instance_of Calc::Z, Calc::Z(42).fact
    assert_equal 1, Calc::Z(0).fact
    assert_equal 1, Calc::Z(1).fact
    assert_equal 2, Calc::Z(2).fact
    assert_equal 120, Calc::Z(5).fact
    assert_equal 3628800, Calc::Z(10).fact
    assert_raises(Calc::MathError) { Calc::Z(-1).fact }
  end

  def test_to_f
    assert_instance_of Float, Calc::Z(42).to_f
    assert_equal 42.0, Calc::Z(42).to_f
  end

  def test_to_i
    assert_instance_of Fixnum, Calc::Z.new(42).to_i
    assert_instance_of Bignum, Calc::Z.new(BIG).to_i
    assert_equal 42, Calc::Z.new(42).to_i
    assert_equal 4611686018427387904, Calc::Z.new(BIG).to_i
    assert_equal BIG2, Calc::Z.new(BIG2.to_s).to_i
  end

  def test_to_r
    assert_instance_of Rational, Calc::Z(42).to_r
    assert_equal 42, Calc::Z(42).to_r.numerator
    assert_equal  1, Calc::Z(42).to_r.denominator
  end

  def test_to_s
    assert_equal "42",                  Calc::Z.new(42).to_s
    assert_equal "4611686018427387904", Calc::Z.new(BIG).to_s
    assert_equal "42",                  Calc::Z.new(Calc::Z.new(42)).to_s
  end

  def test_zero
    assert_instance_of TrueClass, Calc::Z.new(0).zero?
    assert_instance_of FalseClass, Calc::Z.new(1).zero?
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
