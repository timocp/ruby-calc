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

The library provides 3 classes

Ruby class | Represents
---------- | ----------
Calc::Z    | Integers
Calc::Q    | Rational numbers (fractions)
Calc::C    | Complex numbers

In calc, all 3 types of numbers can be arbitrarily large/precise.  But ruby Bignum/Rational already do this.  Calc is useful for its rich collection of numeric functions, as well as being able to calculate transcendental functions to arbitrary accuracy.

While incomplete, this library intends to implement the ruby Numeric interface on each class, and also provide wrappers for all numerical functions provided by the calc library.

### Integers

```ruby
# creating integers (following are all equivalent)
z1 = Calc::Z(42)            # fixnum or bignum argument
z2 = Calc::Z(z1)            # another Z argument
z3 = Calc::Z("42")          # strings will be converted
z4 = Calc::Z("0b101010")    # string in binary
z5 = Calc::Z("052")         # string in octal
z6 = Calc::Z("0x2a")        # string in hex

# integer arithmetic works like you'd expect:
z1 + z2  # => Calc::Z(84)
z1 * z2  # => Calc::Z(1764)
z1 - z2  # => Calc::Z(0)
z1 ** z2 # => Calc::Z(150130937545296572356771972164254457814047970568738777235893533016064)

# division in the Z class is integer division.
z1 / 4   # => Calc::Z(10)

# if you actually wanted a rational number, say:
Calc::Q(z1, 4) # => Calc::Q(21/2)

# factorials of non-negative numbers:
Calc::Z(10).fact    # => Calc::Z(3628800)
```

### Rational Numbers

```ruby
# creating rational numbers - parameter formats are the same as for Z, except
# there are 2 parameters, a numerator and a denominator.  if you omit the
# denominator, it is assumed to be 1.
q1 = Calc::Q(42)  # equivalent to Calc::Q(42, 1)

# you can also pass a single argument of a plain ruby Rational number:
q2 = Calc::Q(Rational(13,4))  # equivalent to Calc::Q(13, 4)

# rational arithmetic.  you can provide ruby numbers or other calc classes as
# arguments to most operators
q1 + q2   # => Calc::Q(181/4)
q1 - q2   # => Calc::Q(155/4)
q1 * q2   # => Calc::Q(273/2)
q1 / q2   # => Calc::Q(168/13)

# raise to integer power (fractional powers are todo)
q2 ** q1  # => Calc::Q(61040881526285814362156628321386486455989674569/19342813113834066795298816)

# factorials of non-negative whole numbers:
Calc::Q(10).fact    # => Calc::Q(3628800)
```

### Trancendental functions

Transcendental functions such as sin, cos and pi, cannot be evaluated exactly as fractions.  The result will be a rational number within a specific accuracy of the correct value (usually an absolute difference).

The transcendental functions provided by Calc::Q are:

Method | Arguments | Description
------ | --------- | -----------
acos   | x         | arccosine of x
acosh  | x         | hyperbolic arccosine of x
acot   | x         | inverse cotangent of x
acoth  | x         | inverse hyperbolic cotangent of x
acsc   | x         | inverse cosecant of x
acsch  | x         | inverse hyperbolic cosecant of x
asec   | x         | inverse secant of x
asech  | x         | inverse hyperbolic secant of x
asin   | x         | arcsine of x
asinh  | x         | hyperbolic arcsine of x
atan   | x         | arctangent of x
atan2  | y, x      | angle determined by the point (x,y)
atanh  | x         | hyperbolic arctangent of x
cbrt   | x         | cube root of x
cos    | x         | cosine of x
cosh   | x         | hyperbolic cosine of x
cot    | x         | cotangent of x
coth   | x         | hyperbolic cotangent of x
csc    | x         | cosecant of x
csch   | x         | hyperbolic cosecant of x
exp    | x         | exponential function of x
ln     | x         | natural logarithm of x (like Math.log)
log    | x         | base 10 logarithm of x (like Math.log10)
pi     | none      | value of π
root   | x, n      | nth root of x
sec    | x         | secant of x
sech   | x         | hyperbolic secant
sin    | x         | sine of x
sinh   | x         | hyperbolic sine of x
sqrt   | x         | square root of x
tan    | x         | tangent of x
tanh   | x         | hyperbolic tangent of x

These methods have equivalent module versions for convenience.  In the module version, the first parameter is equivalent to the receiver in the instance version.  Example:

```ruby
# single parameter functions
Calc::Q(1).sin  # => Calc::Q(16829419696157930133/20000000000000000000)
Calc::Q.sin(1)  # => Calc::Q(16829419696157930133/20000000000000000000)

# two parameter functions
Calc::Q(9).root(2)  # => Calc::Q(3)
Calc::Q.root(9,2)   # => Calc::Q(3)

# functions with no parameters are only available as a module method
Cakc::Q.pi  # => Calc::Q(157079632679489661923/50000000000000000000)
```

The accuracy of transcendental functions will be within a specified `epsilon`.  Each method has an optional extra parameter which provides this for a single call.  If omitted a global epsilon is used (defaults to 1/1e20).  Epsilon must be greater than 0.

```ruby
# pi to default 20 decimal places:
Calc::Q.pi  # => Calc::Q(157079632679489661923/50000000000000000000)

# pi to 400 decimal places:
Calc::Q.pi(Calc::Q(1) / Calc::Q("1e400")) # => (omitted)

# pi to 2 decimal places:
Calc::Q.pi(Calc::Q("0.01")) # => Calc::Q(157/50)
```

The default epsilon can be changed and will affect all subsequent method calls:

```ruby
Calc::Q.get_default_epsilon           # => Calc::Q(1/100000000000000000000)
Calc::Q.set_default_epsilon("0.0001") # => nil
Calc::Q.pi.to_f                       # => 3.1416
```

### Complex numbers

Not added yet.

### Converting to core ruby classes

Method | Result
------ | ------
to_f   | Converts to a ruby Float (precision can be lost!)
to_i   | Converts to a ruby Fixnum or Bignum (for Q, discards remainder)
to_r   | Converts to a ruby Rational
to_s   | Converts to a ruby String

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
