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

The library provides 3 classes:

Ruby class | Represents
---------- | ----------
Calc::Z    | Integers
Calc::Q    | Rational numbers (fractions)
Calc::C    | Complex numbers

In calc, all 3 types of numbers can be arbitrarily large/precise.  It provides a large collection of builtin functions, all of which can compute results to arbitrary accuracy.

While incomplete, this library intends to implement the ruby Numeric interface on each class, and also provide wrappers for all numerical functions provided by the calc library.

In addition to providing access to the C library which implements calc (libcalc), this ruby gem aims for compatibility with the standard ruby types (`Calc::Z`, `Calc::Q` and `Calc::C` should act like `Fixnum`/`Bugnum`, `Rational` and `Complex` respectively).

### Integers (Calc::Z)

```ruby
# creating integers (following are all equivalent)
z1 = Calc::Z(42)            # fixnum or bignum argument
z2 = Calc::Z(z1)            # another Z argument
z3 = Calc::Z("42")          # strings will be converted
z4 = Calc::Z("0b101010")    # string in binary
z5 = Calc::Z("052")         # string in octal
z6 = Calc::Z("0x2a")        # string in hex

# integer arithmetic works like you'd expect:
z1 + z2  #=> Calc::Z(84)
z1 * z2  #=> Calc::Z(1764)
z1 - z2  #=> Calc::Z(0)
z1 ** z2 #=> Calc::Z(150130937545296572356771972164254457814047970568738777235893533016064)

# division in the Z class is integer division.
z1 / 4   #=> Calc::Z(10)
```

### Rational Numbers (Calc::Q)

```ruby
# creating rational numbers - parameter formats are the same as for Z, except
# there are 2 parameters, a numerator and a denominator.  if you omit the
# denominator, it is assumed to be 1.
q1 = Calc::Q(42)  # equivalent to Calc::Q(42, 1)

# you can also pass a single argument of a plain ruby Rational number:
q2 = Calc::Q(Rational(13,4))  # equivalent to Calc::Q(13, 4)

# rational arithmetic.  you can provide ruby numbers or other calc classes as
# arguments to most operators
q1 + q2   #=> Calc::Q(45.25)
q1 - q2   #=> Calc::Q(38.75)
q1 * q2   #=> Calc::Q(136.5)
q1 / q2   #=> Calc::Q(~12.92307692307692307692)

# raise to integer power (fractional powers are todo)
q2 ** q1  #=> Calc::Q(3155739610730618174599.37987276615998166797)

# factorials of non-negative whole numbers:
Calc::Q(10).fact    #=> Calc::Q(3628800)
```

### Complex numbers (Calc::C)

Not implemented yet.

### Built in functions

Where possible, calc builtin functions are exposed by this library are implemented as methods with the same name:

Method | Arguments  | Description
------ | ---------  | -----------
abs    | x          | absolute value of x
acos   | x [, b]    | arccosine of x within accuracy b
acosh  | x [, b]    | hyperbolic arccosine of x within accuracy b
acot   | x [, b]    | inverse cotangent of x within accuracy b
acoth  | x [, b]    | inverse hyperbolic cotangent of x within accuracy b
acsc   | x [, b]    | inverse cosecant of x within accuracy b
acsch  | x [, b]    | inverse hyperbolic cosecant of x within accuracy b
asec   | x [, b]    | inverse secant of x within accuracy b
asech  | x [, b]    | inverse hyperbolic secant of x within accuracy b
asin   | x [, b]    | arcsine of x within accuracy b
asinh  | x [, b]    | hyperbolic arcsine of x within accuracy b
atan   | x [, b]    | arctangent of x within accuracy b
atan2  | y, x [, b] | angle determined by the point (x,y) within accuracy b
atanh  | x [, b]    | hyperbolic arctangent of x within accuracy b
cbrt   | x [, b]    | cube root of x within accuracy b
cos    | x [, b]    | cosine of x within accuracy b
cosh   | x [, b]    | hyperbolic cosine of x within accuracy b
cot    | x [, b]    | cotangent of x within accuracy b
coth   | x [, b]    | hyperbolic cotangent of x within accuracy b
csc    | x [, b]    | cosecant of x within accuracy b
csch   | x [, b]    | hyperbolic cosecant of x within accuracy b
exp    | x [, b]    | exponential function of x within accuracy b
fact   | x          | factorial of integer x
ln     | x [, b]    | natural logarithm of x within accuracy b
log    | x [, b]    | base 10 logarithm of x within accuracy b
pi     | [b]        | value of π within accuracy b
root   | x, n [, b] | nth root of x within accuracy b
sec    | x [, b]    | secant of x within accuracy b
sech   | x [, b]    | hyperbolic secant within accuracy b
sin    | x [, b]    | sine of x within accuracy b
sinh   | x [, b]    | hyperbolic sine of x within accuracy b
sqrt   | x [, b]    | square root of x within accuracy b
tan    | x [, b]    | tangent of x within accuracy b
tanh   | x [, b]    | hyperbolic tangent of x within accuracy b

Unlike the command line verion of calc, these are implemented separated on each appropriate class and will return a value belonging to that class.  In other words, methods on `Calc::Q` will not return answers in `Calc::C`, even if the command line version of calc would have done.

If you want complex results, make sure you use complex parameters (even if the complex part is zero).  This matches the standard ruby Numeric/Rational/Complex behaviours.

```ruby
Calc::Q.sqrt(-1)    #=> Calc::MathError; command line calc would return 1i.
Calc::C.sqrt(-1)    #=> Calc::C(1i)
```

These methods (unlike in the command line version of calc) use the first argument as the method receiver, eg:

```ruby
Calc::Q(1).sin          # in calc: sin(1)
Calc::Q(2).power(3)     # in calc: power(2,3)
```

If you prefer it, most of these are also available as equivalent class methods:

```ruby
Calc::Q.sin(1)
Calc::Q.power(2,3)
```

Functions with no arguments (other than precision/rounding modes) are only available as class methods:

```ruby
Calc::Q.pi              # in calc: pi()
```


### Trancendental functions

Transcendental functions such as sin, cos and pi, cannot be evaluated exactly as fractions.  The result will be a rational number within a specific accuracy of the correct value (usually an absolute difference).

These methods have equivalent module versions for convenience.  In the module version, the first parameter is equivalent to the receiver in the instance version.  Example:

```ruby
# single parameter functions
Calc::Q(1).sin  #=> Calc::Q(0.84147098480789650665)
Calc::Q.sin(1)  #=> Calc::Q(0.84147098480789650665)

# two parameter functions
Calc::Q(9).root(2)  #=> Calc::Q(3)
Calc::Q.root(9,2)   #=> Calc::Q(3)

# functions with no parameters are only available as a module method
Calc::Q.pi  #=> Calc::Q(3.14159265358979323846)
```

The accuracy of transcendental functions will be within a specified `epsilon`.  Each method has an optional extra parameter which provides this for a single call.  If omitted a global epsilon is used (defaults to 1e-20).  Epsilon must be greater than 0.

```ruby
# pi to default 20 decimal places:
Calc::Q.pi  #=> Calc::Q(3.14159265358979323846)

# pi to 2 decimal places:
Calc::Q.pi("0.01") #=> Calc::Q(3.14)

# Usually using a ruby float as a precision won't work as floating point
# numbers are converted into rational number that may not be exactly the same
Calc::Q(0.01).to_s(:frac) #=> "5764607523034235/576460752303423488"
# For this reason it is recommended to use a Calc::Q or a string as the
# epsilon.  Eg, pi to 400 decimal places:
Calc::Q.pi("1e-400") #=> (omitted)

```

The default epsilon can be changed via the Calc.config method and will affect all subsequent method calls:

```ruby
Calc.config(:epsilon)                 #=> Calc::Q(0.00000000000000000001)
Calc::Q.pi                            #=> Calc::Q(3.14159265358979323846)
Calc.config(:epsilon, "0.0001")
Calc::Q.pi                            #=> Calc::Q(3.1416)
```

### Converting to other classes

Each class implements the following methods:

Method | Result
------ | ------
to_f   | Converts to a ruby Float (precision can be lost!)
to_i   | Converts to a ruby Fixnum or Bignum (for Q, discards remainder)
to_r   | Converts to a ruby Rational
to_s   | Converts to a ruby String (see below)

The following methods will convert to other `Calc` methods:

Method | Result
------ | ------
to_z   | Convert to `Calc::Z` (non-integer parts will be lost)
to_q   | Convert to `Calc::Q`
to_c   | Convert to `Calc::C`

However, you can't convert from Calc::C

#### Converting to strings

Internally, `Calc::Q` are always stored as a rational number (fraction).  Libcalc supports various output modes.  The default is "real" which will output as floating points.

```ruby
Calc::Q.exp(1).to_s #=> "2.71828182845904523536"
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

### Configuration

Default output modes, precision, rounding modes, etc can be set with the `Calc.config` method.  It acts the same as the `config()` function in calc:
* The first parameter is the name of a configuration item (string or symbol)
* If a second parameter is present, it is the new value (the old value is returned)
* If there is no second parameter, it only returns the current value.

Not all of calc's configuration is implemented (and only onese related to maths functions will be).  The defaults are the same as using calc with no command line options.  The current set are:

Parameter | Default | Meaning
--------- | ------- | -------
display   | 20      | number of digits when converting to string (does NOT affect internal value)
epsilon   | 1e-20   | default precision for transcendental functions
mode      | :real   | default output mode when converting to string

For more details of these, type "help config" in calc.

## Differences from Calc

For people familiar with the command line interface to calc, here are some important differences to make this library more ruby-ish:

Calc methods which act on values now use the first value as the method receiver, eg:

Ruby doesn't have output parameters; for functions which in calc modify their parameters, ruby-calc instead returns values, eg:

```ruby
q, r = Calc::Q.divmod(a, b)   # in calc: divmod(a, b, q, r)
                              # the actual calc return value is not available
```

In calc, the normal number type is rational, but return values will automatically become complex if necessary.  This is not the case for ruby-calc; `Calc::Q` methods will only return `Calc::Q` values.  If you want complex results, you have to start with `Calc::C` objects.

Other differences:
* Non-maths builtin functions are not implemented - use the normal ruby way of doing that
* Not all configuration items are implemented (and only ones related to maths will be)
* You can't define/call calc functions (ie, eval() is not implemented)

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
