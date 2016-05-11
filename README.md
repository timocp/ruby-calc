# ruby-calc [![Build Status](https://travis-ci.org/timpeters/ruby-calc.svg?branch=master)](https://travis-ci.org/timpeters/ruby-calc)

ruby-calc provides ruby bindings for calc, a c-style arbitrary precision calculator.

For information about calc, see: http://www.isthe.com/chongo/tech/comp/calc/index.html

## Installation

Calc must be installed.

OS  | Instructions
--- | ------------
Fedora | `sudo yum install calc calc-libs calc-devel`
OS X | Install [Homebrew](http://brew.sh), then `brew install calc`
Debian/Ubuntu | Calc is packaged as "apcalc", but because it doesn't include a shared library it won't work, so see instructions under "Manual"
Manual | Download and install calc yourself by referring to the calc website, or using `bin/install_calc` from this repository

Add this line to your application's Gemfile:

```ruby
gem 'ruby-calc', git: 'git://github.com/timpeters/ruby-calc.git'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ruby-calc

## Usage

The library provides 2 types of number classes:

### Rational Numbers (Calc::Q)

Rational numbers are a pair of integers (numerator and denominator).  Each value can be arbitraily large;  the number is always stored in lowest common terms with the sign in the numerator.

```ruby
# any numeric type can be passed as a parameter
Calc::Q(42)             #=> Calc::Q(42)
Calc::Q(Rational(3,10)) #=> Calc::Q(0.3)
Calc::Q(Calc::Q(42))    #=> Calc::Q(42)
Calc::Q(0.3)            #=> Calc::Q(~0.29999999999999998890)

# strings are parsed by the calc library, which allows real, rational
# exponential, scientific, hex, octal and binary:
Calc::Q("0.3")      #=> Calc::Q("0.3")  (compare to Float example above)
Calc::Q("3/10")     #=> Calc::Q("0.3")
Calc::Q("1e10")     #=> Calc::Q(10000000000)
Calc::Q("1e-10")    #=> Calc::Q(0.0000000001)
Calc::Q("0x2a")     #=> Calc::Q(42)
Calc::Q("052")      #=> Calc::Q(42)
Calc::Q("0b101010") #=> Calc::Q(42)

# If you pass a second parameter, the first will be divided by it (if you
# are passing integers, you are effectively passing a numerator/denominator).
Calc::Q(1,4) #=> Calc::Q(0.25)

# rational arithmetic.  you can provide ruby numbers or other calc classes as
# arguments to most operators
q1 = Calc::Q(42)
q2 = Calc::Q(13,4)
q1 + q2   #=> Calc::Q(45.25)
q1 - q2   #=> Calc::Q(38.75)
q1 * q2   #=> Calc::Q(136.5)
q1 / q2   #=> Calc::Q(~12.92307692307692307692)

# raise to power
q1 ** q2  #=> Calc::Q(188608.03646237737943757212)
```

### Complex numbers (Calc::C)

```ruby
# Complex numbers can be created by passing a real and imaginary pair of
# rational numbers.  In this form, the arguments can be anything accepted by
# Calc::Q#new:
c1 = Calc::C(2, 3) #=> Calc::C(2+3i)

# You can pass a single Complex or Calc::C parameter:
c2 = Calc::C(Complex(-1,-1)) #=> Calc::C(-1-1i)
# note that ruby 2.1 and later allow complex literals which turn into Complex
# objects, so:
Calc::C(4+5i) #=> Calc::C(4+5i)

# You can also use the polar method to initialize a complex number by giving
# a modulus (radius) and argument (angle, in radians)
Calc.polar(1,2) #=> Calc::C(-0.416146836547142387+0.9092974268256816954i)
Calc.polar(c2.abs, c2.arg) #=> Calc::C(-1-1i)
# Polar will return a rational number if the result is not complex
Calc.polar(1, Calc.pi) #=> Calc::Q(-1)

# If any other single numeric type is passed, it is used as the real part and
# the imaginary part is set to zero:
c3 = Calc::C(1) #=> Calc::C(1)

# Complex arithmetic is available:
c1 + c2  #=> Calc::C(1+2i)
c1 - c2  #=> Calc::C(3+4i)
c1 * c2  #=> Calc::C(1-5i)
c1 / c2  #=> Calc::C(-2.5+0.5i)
c1 ** c2 #=> Calc::C(-0.47426003871893157744-0.56942019125139104294i)

# The real and imaginary parts can be retrieved with #re/#im
# (aliases #real/#imag).  Calc::Q rational numbers are returned
(c1 / c2).re #=> Calc::Q(-2.5)
(c1 / c2).im #=> Calc::Q(-0.5)
```

### Built in functions

Where possible, calc builtin functions are exposed by this library are implemented as methods with the same name:

Method | Arguments  | Description
------ | ---------  | -----------
abs    | x [, b]    | absolute value of x (for complex x, within accuracy b)
acos   | x [, b]    | arccosine of x within accuracy b
acosh  | x [, b]    | hyperbolic arccosine of x within accuracy b
acot   | x [, b]    | inverse cotangent of x within accuracy b
acoth  | x [, b]    | inverse hyperbolic cotangent of x within accuracy b
acsc   | x [, b]    | inverse cosecant of x within accuracy b
acsch  | x [, b]    | inverse hyperbolic cosecant of x within accuracy b
agd    | z [, b]    | inverse gudermannian function of z within accuracy b
appr   | x [, e, r] | approximate x as a multiple of e with rounding r
arg    | x [, b]    | argument (angle) of complex number x within acccuracy b
asec   | x [, b]    | inverse secant of x within accuracy b
asech  | x [, b]    | inverse hyperbolic secant of x within accuracy b
asin   | x [, b]    | arcsine of x within accuracy b
asinh  | x [, b]    | hyperbolic arcsine of x within accuracy b
atan   | x [, b]    | arctangent of x within accuracy b
atan2  | y, x [, b] | angle determined by the point (x,y) within accuracy b
atanh  | x [, b]    | hyperbolic arctangent of x within accuracy b
avg    | x, y, ...  | arithmetic mean of values
bernoulli | x       | xth bernoulli number
bit    | x, y       | whether bit y in value x is set (also: #bit?)
bround | x [, p, r] | round x to p binary places with rounding r
catalan| x          | Catalan number for index x
cbrt   | x [, b]    | cube root of x within accuracy b
ceil   | x          | smallest integer greater than or equal to x
cfappr | x [, e|n, r] | approximate x within accuracy e using continued fractions
cfsim  | x [, r]    | simplify x using continued fractions
char   | x          | character corresponding to integer x
cmp    | x, y       | compare values returning -1, 0 or 1 real or complex
comb   | x, y       | combinatorial number a!/b!(a-b)!
conj   | x          | complex conjugate of x
cos    | x [, b]    | cosine of x within accuracy b
cosh   | x [, b]    | hyperbolic cosine of x within accuracy b
cot    | x [, b]    | cotangent of x within accuracy b
coth   | x [, b]    | hyperbolic cotangent of x within accuracy b
csc    | x [, b]    | cosecant of x within accuracy b
csch   | x [, b]    | hyperbolic cosecant of x within accuracy b
den    | x          | denominator of x
digit  | x, n [, b] | nth digit of x in base b
digits | x [, b]    | number of intgral digits of x in base b
estr   | x          | text representation of a value
euler  | n          | nth euler number
exp    | x [, b]    | exponential function of x within accuracy b
fact   | x          | factorial of integer x
factor | x [, limit]| smallest prime factor of x not exceeding limit
fcnt   | x, y       | count number of times y divides x
frem   | x, y       | remove occurances of factor y from x
fib    | z          | zth Fibonacci number
freebernoulli |     | free memory storing calculated bernoulli numbers
freeeuler |         | free memory storing calculated euler numbers
floor  | x          | greatest integer less than or equal to x
gd     | z [, b]    | gudermannian function of z within accuracy b
inverse| x          | inverse of x
iseven | x          | whether a value is even (also: #even?)
isimag | x          | whether a value is imaginary (also: #imag?)
isint  | x          | whether a value is an integer (also: #int?)
isodd  | x          | whether a value is odd (also: #odd?)
isreal | x          | whether a value is real (also: #real?)
ln     | x [, b]    | natural logarithm of x within accuracy b
log    | x [, b]    | base 10 logarithm of x within accuracy b
num    | x          | numerator of x
perm   | x, y       | permutation number x!/(x-y)!
pi     | [b]        | value of π within accuracy b
power  | x, y [, b] | x raised to the power of y within accuracy b
root   | x, n [, b] | nth root of x within accuracy b
round  | x [, p, r] | round x to p decimal places with rounding r
sec    | x [, b]    | secant of x within accuracy b
sech   | x [, b]    | hyperbolic secant within accuracy b
sin    | x [, b]    | sine of x within accuracy b
sinh   | x [, b]    | hyperbolic sine of x within accuracy b
sqrt   | x [, b, z] | square root of x within accuracy b with rounding/sign controlled by z
tan    | x [, b]    | tangent of x within accuracy b
tanh   | x [, b]    | hyperbolic tangent of x within accuracy b

Builtins with at least one required parameter are implemented as class methods of Calc::Q, Calc::C (or both) to allow object orientated style.  Their behaviour matches the calc builtins as closely as possible.  The receiver of these methods is what would have been the first parameter in calc.

```ruby
Calc::Q(1).sin      #=> Calc::Q(0.84147098480789650665)
Calc::Q(2).power(3) #=> Calc::Q(8)
```

If you prefer the C-like style of calc, these are also available as class methods on Calc.  This allows you to include Calc and use the builtins directly.  These will call the rational/complex version of the method based on the type of the first parameter.

```ruby
Calc.sin(1)     #=> Calc::Q(0.84147098480789650665)
Calc.power(2,3) #=> Calc::Q(8)
```

Functions with no arguments (other than precision/rounding modes) are only available as class methods:

```ruby
Calc.pi #=> Calc::Q(3.14159265358979323846)
```

### Trancendental functions

Transcendental functions such as sin, cos and pi, cannot be evaluated exactly as fractions.  The result will be a rational number within a specific accuracy of the correct value (usually an absolute difference).

These methods have equivalent module versions for convenience.  In the module version, the first parameter is equivalent to the receiver in the instance version.  Example:

```ruby
# single parameter functions
Calc::Q(1).sin  #=> Calc::Q(0.84147098480789650665)
Calc.sin(1)     #=> Calc::Q(0.84147098480789650665)

# two parameter functions
Calc::Q(9).root(2)  #=> Calc::Q(3)
Calc.root(9,2)      #=> Calc::Q(3)

# functions with no parameters are only available as a module method
Calc.pi  #=> Calc::Q(3.14159265358979323846)
```

The accuracy of transcendental functions will be within a specified `epsilon`.  Each method has an optional extra parameter which provides this for a single call.  If omitted a global epsilon is used (defaults to 1e-20).  Epsilon must be greater than 0.

```ruby
# pi to default 20 decimal places:
Calc.pi  #=> Calc::Q(3.14159265358979323846)

# pi to 2 decimal places:
Calc.pi("0.01") #=> Calc::Q(3.14)

# Avoid using a ruby float as a precision, since it won't exactly represent
# what you expect (see below in "Differences from Calc").
# For this reason it is recommended to use a Calc::Q or a string as the
# epsilon.  Eg, pi to 400 decimal places:
Calc.pi("1e-400") #=> (long fraction omitted)
```

The default epsilon can be changed via the Calc.config method and will affect all subsequent method calls:

```ruby
Calc.config(:epsilon)                 #=> Calc::Q(0.00000000000000000001)
Calc.pi                               #=> Calc::Q(3.14159265358979323846)
Calc.config(:epsilon, "0.0001")
Calc.pi                               #=> Calc::Q(3.1416)
```

### Converting between numeric types

The following methods can be used to convert a ruby-calc class to ruby numeric types.

Method             | Result
------             | ------
Calc::Q#to_f       | Converts to ruby Float (precision can be lost!)
Calc::Q#to_i       | Converts to ruby Fixnum/Bignum (discards remainder)
Calc::Q#to_r       | Converts to ruby Rational
Calc::Q#to_c       | Converts to ruby Complex
Calc::Q#to_complex | Converts to a Calc::C with zero imaginary part
Calc::C#to_c       | Converts to ruby Complex

#### Converting to strings

Internally, `Calc::Q` are always stored as a rational number (fraction).  Libcalc supports various output modes.  The default is "real" which will output in decimal format.

```ruby
Calc.exp(1).to_s #=> "2.71828182845904523536"
```

Numbers are rounded after `Calc::Config.display` digits; if any rounding has to occur, a leading tilde is included in the output.  If you don't want rounding, you can output as a fraction:

```ruby
Calc::Q(1,11).to_s         #=> "~0.09090909090909090909"
Calc::Q(1,11).to_s(:frac)  #=> "1/11"
```

`to_s` takes an optional parameter which is the output mode to use.  It must be a symbol or a string with one of the following values:

```ruby
Calc::Q(1,20).to_s(:frac)     #=> "1/20"        base 10 fractions
Calc::Q(1,20).to_s(:int)      #=> "~0"          base 10 integers
Calc::Q(1,20).to_s(:real)     #=> "0.05"        base 10 floating point (default)
Calc::Q(1,20).to_s(:sci)      #=> "5e-2"        base 10 scientific notation
Calc::Q(1,20).to_s(:hex)      #=> "1/0x14"      base 16 fractions
Calc::Q(1,20).to_s(:oct)      #=> "1/024"       base 8 fractions
Calc::Q(1,20).to_s(:bin)      #=> "1/0b10100    base 2 fractions
```

The default output mode can be set with [Calc::Config].  The output of `inspect` will match whatever the current default is.

Note that you can also provide `Calc::Q` objects to the ruby printf method.  The format string parameter will coerce the number to the right internal type first (eg %d will display as an integer, %f as a floating point number).  The display may have lost precision in this conversion.

### Configuration

Default output modes, precision, rounding modes, etc can be set with the `Calc.config` method.  It acts the same as the `config()` function in calc:
* The first parameter is the name of a configuration item (string or symbol)
* If a second parameter is present, it is the new value (the old value is returned)
* If there is no second parameter, it only returns the current value.

Not all of calc's configuration is implemented (and only onese related to maths functions will be).  The defaults are the same as using calc with no command line options.  The current set are:

Parameter | Default | Meaning
--------- | ------- | -------
appr      | 24      | rounding mode for `appr`
cfappr    | 0       | rounding mode for `cfappr`
display   | 20      | number of digits when converting to string (does NOT affect internal value)
epsilon   | 1e-20   | default precision for transcendental functions
mode      | :real   | default output mode when converting to string
round     | 24      | rounding mode for `bround` and `round`
sqrt      | 24      | rounding mode and sign for `sqrt`

For more details of these, type "help config" in calc.

## Differences from Calc

For people familiar with the command line interface to calc, here are some important differences to make this library more ruby-ish:

### Literals

In calc, a decimal literal is interpreted as a rational number, whereas in ruby it will be a floating point number.  In fact, libcalc does not use or allow C types float or double anywhere in its API.

Although you can initialize Calc::Q objects from ruby floats, their internal representation will actually be a rational number as close as possible to the ruby float, which is not necessarily the same as what you typed.  This is also true for scientific notation.

```ruby
Calc::Q(1.2)              #=> Calc::Q(~1.19999999999999995559)
Calc::Q(1.2).to_s(:frac)  #=> "5404319552844595/4503599627370496"
Calc::Q(1e-5)             #=> Calc::Q(~0.00001000000000000000)
Calc::Q(1e-5).to_s(:frac) #=> "5902958103587057/590295810358705651712"
```

In most cases where you can provide a numeric argument to a method, ruby-calc allows a string.  The string will be parsed using libcalc, so the exact intended value is stored.

```ruby
Calc::Q("1.2")  #=> Calc::Q(1.2)
Calc::Q("1e-5") #=> Calc::Q(0.00001)
```

### Output Parameters

Ruby doesn't have output parameters; for functions which in calc modify their parameters, ruby-calc instead returns values, eg:

```ruby
q, r = Calc::Q(a).quomod(b)   # in calc: quomod(a, b, q, r)
                              # the actual calc return value is not available
```

### Predicate Functions and Truthiness

Predicate functions (usually starting with "is") return 0 or 1 indicating false or true, matching the original calc version.  In ruby, 0 is true so you shouldn't use these in a boolean context.  Each function has a more rubyish version named with a question mark which returns true or false.

If in calc you would do this:

```
if (iseven(q)) {
  something();
}
```

Three options in ruby-calc:

```ruby
# preferred
if q.even?
  something
end

# or
if q.iseven == 1
  something
end

# or
if Calc.iseven(q) == 1
  something
end
```

These builtins work this way:
* bit / bit?
* iseven / even?
* isimag / imag?
* isint / int?
* isodd / odd?
* isreal / real?

`isimag` isn't a real calc builtin but it is included anyway.

### Other Differences

* `estr` return format is different, intended to be eval'd by ruby rather than calc
* the "error" argument of `factor` is not implemented, mainly because I don't understand the purpose of it.  errors in `factor` will always raise exceptions
* Non-maths builtin functions are not implemented - use the normal ruby way of doing that
* Not all configuration items are implemented (and only ones related to maths will be)
* You can't define/call calc functions (ie, eval() is not implemented)
* Libcalc provides an integer type (ZVALUE) which ruby-calc doesn't provide access to (because ruby already has arbitrary size integers and libcalc's interesting functions are all for Rational or Complex numbers)

## Development

ruby-calc requires ruby 2.0.0 or newer.

Make sure you have calc development headers installed (yum install calc-dev / apt-get install apcalc-devel, or have manually installed calc).

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/timpeters/ruby-calc/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
