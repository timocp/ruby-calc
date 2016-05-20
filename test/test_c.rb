require "minitest_helper"

class TestC < MiniTest::Test
  BIG  =  0x4000000000000000  # first BigNum
  BIG2 =  0x8000000000000000  # first Bignum that won't fit in a long
  BIG3 = -0x8000000000000001  # first negative bignum that won't fit in a long

  def test_class_exists
    refute_nil Calc::C
  end

  def test_initialization
    assert_instance_of Calc::C, Calc::C(1, 1)
    assert_instance_of Calc::C, Calc::C(BIG, BIG)
    assert_instance_of Calc::C, Calc::C(BIG2, BIG2)
    assert_instance_of Calc::C, Calc::C(BIG3, BIG3)
    assert_instance_of Calc::C, Calc::C("1", "1e3")
    assert_instance_of Calc::C, Calc::C("1/3", "1e-3")
    assert_instance_of Calc::C, Calc::C(Rational(1, 3), Rational(1, 3))
    assert_instance_of Calc::C, Calc::C(0.3, 0.3)
    assert_instance_of Calc::C, Calc::C(Calc::Q(1), Calc::Q(2))

    assert_instance_of Calc::C, Calc::C(1)
    assert_instance_of Calc::C, Calc::C(BIG)
    assert_instance_of Calc::C, Calc::C(BIG2)
    assert_instance_of Calc::C, Calc::C(BIG3)
    assert_instance_of Calc::C, Calc::C("1")
    assert_instance_of Calc::C, Calc::C("1/3")
    assert_instance_of Calc::C, Calc::C(Rational(1, 3))
    assert_instance_of Calc::C, Calc::C(0.3)
    assert_instance_of Calc::C, Calc::C(Calc::Q(1))
    assert_instance_of Calc::C, Calc::C(Complex(1, 1))
    assert_instance_of Calc::C, Calc::C(Calc::C(1, 1))
  end

  def test_re
    assert_instance_of Calc::Q, Calc::C(1, 2).re
    assert_equal 1, Calc::C(1, 2).re
    assert_alias Calc::C(1, 2), :re, :real
  end

  def test_im
    assert_instance_of Calc::Q, Calc::C(1, 2).im
    assert_equal 2, Calc::C(1, 2).im
    assert_alias Calc::C(1, 2), :im, :imag
  end

  def test_equal
    assert Calc::C(1, 2) == Calc::C(1, 2) # rubocop:disable Lint/UselessComparison
    assert Calc::C(BIG, BIG2) == Complex(BIG, BIG2)
    assert Calc::C(10, 0) == 10
    assert Calc::C(BIG2, 0) == BIG2
    assert Calc::C(5, 0) == Rational(5)
    assert Calc::C(5, 0) == 5.0
    assert Calc::C(5, 0) == Calc::Q(5)

    refute Calc::C(1, 2) == Calc::C(1, 3)
    refute Calc::C(BIG, BIG2) == Complex(BIG2, BIG)
    refute Calc::C(10, 1) == 10
    refute Calc::C(BIG2, 1) == BIG2
    refute Calc::C(5, 1) == Rational(5)
    refute Calc::C(5, 1) == 5.0
    refute Calc::C(5, 1) == Calc::Q(5)
  end

  def test_to_s
    assert_equal "1+1i", Calc::C(1, 1).to_s
    assert_equal "1", Calc::C(1, 0).to_s
    assert_equal "1i", Calc::C(0, 1).to_s
    assert_equal "0", Calc::C(0, 0).to_s
    assert_equal "-1i", Calc::C(0, -1).to_s
    assert_equal "-1", Calc::C(-1, 0).to_s
    assert_equal "-1-1i", Calc::C(-1, -1).to_s
    assert_equal "0.2+0.4i", Calc::C(Calc::Q(1, 5), Calc::Q(2, 5)).to_s
    assert_equal "1/5+2i/5", Calc::C(Calc::Q(1, 5), Calc::Q(2, 5)).to_s(:frac)
    assert_equal "-0.2-0.4i", Calc::C(Calc::Q(-1, 5), Calc::Q(-2, 5)).to_s
    assert_equal "-1/5-2i/5", Calc::C(Calc::Q(-1, 5), Calc::Q(-2, 5)).to_s(:frac)
  end

  def test_inspect
    assert_equal "Calc::C(1+1i)", Calc::C(1, 1).inspect
  end

  def test_unary
    assert_instance_of Calc::C, +Calc::C(1, 1)
    assert_instance_of Calc::C, -Calc::C(1, 1)
    assert_equal Complex(1, 1), +Calc::C(1, 1)
    assert_equal Complex(-1, -1), +Calc::C(-1, -1)
    assert_equal Complex(-1, -1), -Calc::C(1, 1)
    assert_equal Complex(1, 1), -Calc::C(-1, -1)
  end

  def test_add
    assert_instance_of Calc::C, Calc::C(1, 1) + Calc::C(2, -2)
    assert_equal Calc::C(3, -1), Calc::C(1, 1) + Calc::C(2, -2)
    assert_equal Calc::C(3, 1), Calc::C(1, 1) + Calc::Q(2)
    assert_equal Calc::C(3, 3), Calc::C(1, 1) + Complex(2, 2)
    assert_equal Calc::C(Calc::Q(5, 3), 1), Calc::C(1, 1) + Rational(2, 3)
    assert_equal Calc::C(3, 1), Calc::C(1, 1) + 2
    assert_equal Calc::C(1 + BIG2, 1), Calc::C(1, 1) + BIG2
    assert_equal Calc::C(Calc::Q(3, 2), 1), Calc::C(1, 1) + 0.5
  end

  def test_subtract
    assert_rational_and_equal 0, Calc::C(1, 1) - Calc::C(1, 1)
    assert_equal Calc::C(Calc::Q(1, 3), 1), Calc::C(1, 1) - Calc::Q(2, 3)
  end

  def test_multiply
    assert_instance_of Calc::C, Calc::C(1, 1) * Calc::C(1, 1)
    assert_equal Calc::C(0, 2), Calc::C(1, 1) * Calc::C(1, 1)
    assert_equal Calc::C(0, 1), Calc::C(1, 0) * Calc::C(0, 1)
    assert_equal Calc::C(0, -2), Calc::C(1, 1) * Calc::C(-1, -1)
  end

  def test_divide
    assert_rational_and_equal 1, Calc::C(1, 1) / Calc::C(1, 1)
    assert_equal Calc::C(1, -1), Calc::C(1, 1) / Calc::C(0, 1)
    assert_equal Calc::C(1, 1), Calc::C(1, 1) / Calc::C(1, 0)
    assert_equal Calc::C(2, -2), Calc::C(4, -4) / 2
    assert_equal Calc::C(-2, -2), Calc::C(4, -4) / Calc::C(0, 2)
    assert_equal Calc::C(0, -2), Calc::C(4, -4) / Calc::C(2, 2)

    assert_raises(Calc::MathError) { Calc::C(1, 1) / 0 }
  end

  def test_power
    assert_instance_of Calc::C, Calc::C(1, 1)**2
    assert_instance_of Calc::C, Calc::C(1, 1).power(2)

    assert_equal(-4, Calc::C(1, 1)**4)
    assert_equal 8.22074, Calc::C("1.2345").power(10, "1e-5").re.to_f
    assert_equal 0, Calc::C("1.2345").power(10, "1e-5").im
    assert_equal(-26, Calc::C(1, 3).power(3).re)
    assert_equal(-18, Calc::C(1, 3).power(3).im)
    assert_equal Calc::C("-2.50593", "-1.39445"), Calc::C(1, 3).power(Calc::C(2, 1), "1e-5")
    assert_equal Calc::C(".20787957635076190855"), Calc::C(0, 1)**Calc::C(0, 1)
  end

  def test_coerce
    assert_instance_of Calc::C, Complex(1, 1) + Calc::C(2, 2)
    assert_equal Calc::C(3, 3), Complex(1, 1) + Calc::C(2, 2)
    assert_equal Calc::C(3, 2), 1 + Calc::C(2, 2)
    assert_equal Calc::C(4, 4), 2 * Calc::C(2, 2)
    assert_equal Calc::C("0.5", "-0.5"), 2 / Calc::C(2, 2)
    assert_equal Calc::C(1, 1), 0.5 * Calc::C(2, 2)
  end

  def test_abs
    assert_instance_of Calc::Q, Calc::C(1, 0).abs
    assert_instance_of Calc::Q, Calc::C(1, 1).abs
    assert_instance_of Calc::Q, Calc::C(0, 1).abs
    assert_equal 1, Calc::C(1, 0).abs
    assert_in_epsilon 1.4142135623730950488, Calc::C(1, 1).abs
    assert_equal 1, Calc::C(0, 1).abs
    assert_equal 0, Calc::C(0, 0).abs
    assert_equal 1, Calc::C(-1).abs
    assert_equal 5, Calc::C(3, -4).abs
  end

  def test_real
    check_truthy Calc::C(1, 0), :isreal, :real?
    check_falsey Calc::C(1, 1), :isreal, :real?
    check_falsey Calc::C(0, 1), :isreal, :real?
  end

  def test_imag
    check_truthy Calc::C(0, 1), :isimag, :imag?
    check_falsey Calc::C(1, 1), :isimag, :imag?
    check_falsey Calc::C(1, 0), :isimag, :imag?
  end

  def test_arg
    assert_instance_of Calc::Q, Calc::C(1, 1).arg
    assert_equal 0, Calc::C(2).arg
    assert_in_epsilon Calc.pi, Calc::C(-2).arg
    assert_in_epsilon 0.98279372324732906799, Calc::C(2, 3).arg
    assert_in_epsilon 0.98279, Calc::C(2, 3).arg("1e-5")
  end

  def test_cos
    assert_complex_parts [-4.18962569096880723013, -9.10922789375533659798], Calc::C(2, 3).cos
  end

  def test_sin
    assert_complex_parts [9.15449914691142957347, -4.16890695996656435076], Calc::C(2, 3).sin
  end

  def test_cosh
    assert_complex_parts [-3.72454550491532256548, 0.51182256998738460884], Calc::C(2, 3).cosh
  end

  def test_sinh
    assert_complex_parts [-3.59056458998577995202, 0.53092108624851980526], Calc::C(2, 3).sinh
  end

  def test_asin
    assert_complex_parts [0.57065278432109940071, 1.98338702991653543235], Calc::C(2, 3).asin
  end

  def test_acos
    assert_complex_parts [1.00014354247379721852, -1.98338702991653543235], Calc::C(2, 3).acos
  end

  def test_atan
    assert_complex_parts [1.40992104959657552253, 0.22907268296853876630], Calc::C(2, 3).atan
  end

  def test_acot
    assert_complex_parts [0.1608752771983210967, -0.22907268296853876630], Calc::C(2, 3).acot
  end

  def test_asec
    assert_complex_parts [1.42041072246703465598, 0.2313346985739733145], Calc::C(2, 3).asec
  end

  def test_acsc
    assert_complex_parts [0.15038560432786196325, -0.23133469857397331455], Calc::C(2, 3).acsc
  end

  def test_asinh
    assert_complex_parts [1.96863792579309629179, 0.96465850440760279204], Calc::C(2, 3).asinh
  end

  def test_acosh
    assert_complex_parts [1.98338702991653543235, 1.00014354247379721852], Calc::C(2, 3).acosh
  end

  def test_atanh
    assert_complex_parts [0.14694666622552975204, 1.33897252229449356112], Calc::C(2, 3).atanh
  end

  def test_acoth
    assert_complex_parts [0.14694666622552975204, -0.23182380450040305810], Calc::C(2, 3).acoth
  end

  def test_asech
    assert_complex_parts [0.23133469857397331455, -1.42041072246703465598], Calc::C(2, 3).asech
  end

  def test_acsch
    assert_complex_parts [0.15735549884498542878, -0.22996290237720785451], Calc::C(2, 3).acsch
  end

  def test_cot
    assert_complex_parts [-0.00373971037633695666, -0.99675779656935831046], Calc::C(2, 3).cot
  end

  def test_coth
    assert_complex_parts [1.03574663776499539611, 0.01060478347033710175], Calc::C(2, 3).coth
  end

  def test_csc
    assert_complex_parts [0.09047320975320743981, 0.04120098628857412646], Calc::C(2, 3).csc
  end

  def test_csch
    assert_complex_parts [-0.27254866146294019951, -0.04030057885689152187], Calc::C(2, 3).csch
  end

  def test_sec
    assert_complex_parts [-0.04167496441114427005, 0.09061113719623759653], Calc::C(2, 3).sec
  end

  def test_sech
    assert_complex_parts [-0.26351297515838930964, -0.03621163655876852087], Calc::C(2, 3).sech
  end

  def test_tan
    assert_complex_parts [-0.00376402564150424829, 1.00323862735360980145], Calc::C(2, 3).tan
  end

  def test_tanh
    assert_complex_parts [0.96538587902213312428, -0.00988437503832249372], Calc::C(2, 3).tanh
  end

  def test_agd
    assert_complex_parts [0.22751065843194319695, 1.422911462459226797], Calc::C(1, 2).agd
    assert_equal 0, Calc::C(0, 0).agd
  end

  def test_gd
    assert_rational_in_epsilon 0.86576948323965862429, Calc::C(1).gd
    assert_complex_parts [1.422911462459226797, 0.22751065843194319695], Calc::C(2, 1).gd
    assert_equal 0, Calc::C(0, 0).gd

    assert_raises(Calc::MathError) { Calc::C(0, Calc.pi / 2).gd }
  end

  def test_inverse
    assert_complex_parts [0.12, -0.16], Calc::C(3, 4).inverse
    assert_raises(Calc::MathError) { Calc::C(0, 0).inverse }
  end

  def test_even
    check_truthy Calc::C(0, 0), :iseven, :even?
    check_falsey Calc::C(0, 1), :iseven, :even?
    check_falsey Calc::C(0, 2), :iseven, :even?
    check_falsey Calc::C(1, 0), :iseven, :even?
    check_falsey Calc::C(1, 1), :iseven, :even?
    check_falsey Calc::C(1, 2), :iseven, :even?
    check_truthy Calc::C(2, 0), :iseven, :even?
    check_falsey Calc::C(2, 1), :iseven, :even?
    check_falsey Calc::C(2, 2), :iseven, :even?
  end

  def test_odd
    check_falsey Calc::C(0, 0), :isodd, :odd?
    check_falsey Calc::C(0, 1), :isodd, :odd?
    check_falsey Calc::C(0, 2), :isodd, :odd?
    check_truthy Calc::C(1, 0), :isodd, :odd?
    check_falsey Calc::C(1, 1), :isodd, :odd?
    check_falsey Calc::C(1, 2), :isodd, :odd?
    check_falsey Calc::C(2, 0), :isodd, :odd?
    check_falsey Calc::C(2, 1), :isodd, :odd?
    check_falsey Calc::C(2, 2), :isodd, :odd?
  end

  def test_sqrt
    eps = Calc::Q("1e-4")
    assert_complex_parts [2, 2], Calc::C(0, 8).sqrt(eps, 0)
    assert_complex_parts [-2, -2], Calc::C(0, 8).sqrt(eps, 64)
  end

  def test_appr
    x = Calc::C(7, -3).sqrt
    assert_complex_parts [2.70331, -0.55488], x.appr("1e-5", 0)
    assert_complex_parts [2.70332, -0.55487], x.appr("1e-5", 1)
    assert_complex_parts [2.70331, -0.55487], x.appr("1e-5", 2)
    assert_complex_parts [2.70332, -0.55488], x.appr("1e-5", 3)
  end

  def test_ceil
    assert_complex_parts [8, -9], Calc::C(7.8, -9.1).ceil
  end

  def test_floor
    assert_complex_parts [7, -10], Calc::C(7.8, -9.1).floor
  end

  def test_isint
    check_truthy Calc::C(1, 0), :isint, :int?
    check_falsey Calc::C(1, 1), :isint, :int?
    check_falsey Calc::C(0, -1), :isint, :int?
    assert_alias Calc::C(1, 1), :int?, :integer?
  end

  def test_round
    a = Calc::Q(7, 32)
    c = Calc::C(a, -a)
    assert_rational_and_equal 0, c.round
    assert_complex_parts [Calc::Q(".219"), Calc::Q("-.219")], c.round(3)
    assert_complex_parts [Calc::Q(".218"), Calc::Q("-.219")], c.round(3, 0)
  end

  def test_bround
    a = Calc::Q(7, 32)
    c = Calc::C(a, -a)
    assert_rational_and_equal 0, c.bround
    assert_complex_parts [Calc::Q(".25"), Calc::Q("-.25")], c.bround(3)
    assert_complex_parts [Calc::Q(".125"), Calc::Q("-.25")], c.bround(3, 0)
  end

  def test_cmp
    assert_complex_parts [-1, -1], Calc::C(0, -4).cmp(5)
    assert_complex_parts [1, -1], Calc::C(0, -4).cmp(-5)
    assert_complex_parts [0, -1], Calc::C(0, 3).cmp(Calc::C(0, 4))
    assert_rational_and_equal 0, Calc::C(0, 4).cmp(Calc::C(0, 4))
    assert_complex_parts [0, 1], Calc::C(0, 5).cmp(Calc::C(0, 4))
    assert_complex_parts [-1, 1], Calc::C(3, 4).cmp(5)
    assert_complex_parts [1, 1], Calc::C(3, 4).cmp(-5)
    assert_rational_and_equal 0, Calc::C(3, 4).cmp(Calc::C(3, 4))
    assert_complex_parts [0, 1], Calc::C(3, 4).cmp(Calc::C(3, -4))
    assert_complex_parts [1, 1], Calc::C(3, 4).cmp(Calc::C(2, 3))
    assert_complex_parts [1, 1], Calc::C(3, 4).cmp(Calc::C(-4, -5))
  end

  def test_comb
    assert_complex_parts [Calc::Q("49/2"), Calc::Q("-329/6")], Calc::C(0, 7).comb(3)
  end

  def test_conj
    assert_complex_parts [3, -4], Calc::C(3, 4).conj
  end

  def test_estr
    assert_equal "Calc::C(0)", Calc::C(0).estr
    assert_equal "Calc::C(4)", Calc::C(4).estr
    assert_equal "Calc::C(-4)", Calc::C(-4).estr
    assert_equal "Calc::C(0,-4)", Calc::C(0, -4).estr
    assert_equal "Calc::C(Calc::Q(-1,2),2)", Calc::C(-Calc::Q(1, 2), 2).estr
    assert_equal "Calc::C(-4,Calc::Q(1,3))", Calc::C(-4, Calc::Q(1, 3)).estr
  end

  def test_exp
    assert_complex_parts [-1.13120438375681363843, 2.47172667200481892762], Calc::C(1, 2).exp
  end

  def test_frac
    assert_complex_parts [Calc::Q("0.15"), Calc::Q("-0.25")], Calc::C("2.15", "-3.25").frac
    assert_rational_and_equal 0.5, Calc::C(1.5, 0).frac
  end

  def test_ln
    assert_complex_parts [0, -Calc.pi / 2], Calc::C(0, -1).ln
    assert_complex_parts [0, Calc.pi / 2], Calc::C(0, 1).ln
    assert_complex_parts [1.03972077083991796413, 0.78539816339744830962], Calc::C(2, 2).ln
  end

  def test_log
    assert_complex_parts [0, -0.68218817692092067374], Calc::C(0, -1).log
    assert_complex_parts [0, 0.68218817692092067374], Calc::C(0, 1).log
    assert_complex_parts [0.45154499349597179282, 0.34109408846046033687], Calc::C(2, 2).log
  end

  def test_ilog
    assert_rational_and_equal 2, Calc::C(10, 10).ilog(3)
    assert_rational_and_equal 4, Calc::C(10, 100).ilog(3)
    assert_rational_and_equal 4, Calc::C(100, 10).ilog(3)
    assert_rational_and_equal 4, Calc::C(100, 100).ilog(3)
    assert_raises(Calc::MathError) { Calc::C(0, 10).ilog(1) }
  end

  def test_ilog10
    assert_rational_and_equal 0, Calc::C(0, 7).ilog10
    assert_rational_and_equal 1, Calc::C(0, 99).ilog10
    assert_rational_and_equal 2, Calc::C(0, 100).ilog10
  end

  def test_ilog2
    assert_rational_and_equal 0, Calc::C(0, 1).ilog2
    assert_rational_and_equal 1, Calc::C(0, 2).ilog2
    assert_rational_and_equal 1, Calc::C(0, 3).ilog2
    assert_rational_and_equal 2, Calc::C(0, 4).ilog2
    assert_rational_and_equal(-4, Calc::C(0, "1/15").ilog2)
  end

  def test_int
    assert_complex_parts [2, -3], Calc::C("2.15", "-3.25").int
  end

  def test_mod
    assert_complex_parts [0, 1], Calc::C(0, 11).mod(5)
    assert_complex_parts [0, 1], Calc::C(0, 11).mod(5, 0)
    assert_complex_parts [0, -4], Calc::C(0, 11).mod(5, 1)
    assert_complex_parts [0, 1], Calc::C(0, 11).mod(5, 2)
    assert_complex_parts [0, -4], Calc::C(0, 11).mod(5, 3)

    assert_complex_parts [0, 1], Calc::C(0, 11) % 5
    assert_complex_parts [0, -4], Calc::C(0, 11) % -5
    assert_complex_parts [0, 4], Calc::C(0, -11) % 5
    assert_complex_parts [0, -1], Calc::C(0, -11) % -5
  end

  def test_mmin
    assert_complex_parts [0, 3], Calc::C(0, 3).mmin(6)
    assert_complex_parts [0, -2], Calc::C(0, 4).mmin(6)
    assert_complex_parts [0, -1], Calc::C(0, 5).mmin(6)
    assert_rational_and_equal 0, Calc::C(0, 6).mmin(6)
    assert_complex_parts [0, 1], Calc::C(0, 7).mmin(6)
  end

  def test_norm
    assert_rational_and_equal 25, Calc::C(3, 4).norm
    assert_rational_and_equal 41, Calc::C(4, -5).norm
  end

  def test_quo
    assert_rational_and_equal 0, Calc::C(4, 4).quo(5)
    assert_rational_and_equal 0, Calc::C(4, 4).quo(5, 0)
    assert_complex_parts [2, 2], Calc::C(11, 11).quo(5, 0)
    assert_complex_parts [3, 3], Calc::C(11, 11).quo(5, 1)
  end

  def test_root
    assert_complex_parts [1.34240774523313957268, 0.59361278251901041813], Calc::C(1, 3).root(3)
    assert_complex_parts [1.34241, 0.59361], Calc::C(1, 3).root(3, "1e-5")
    assert_complex_parts [0.99987663248166059864, 0.01570731731182067575], Calc::C(0, 1).root(100)
  end
end
