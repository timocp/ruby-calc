# ruby-calc

[![Build Status](https://travis-ci.org/timpeters/ruby-calc.svg?branch=master)](https://travis-ci.org/timpeters/ruby-calc)

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

This library is currently very incomplete.

```ruby
require 'calc'

# there are 3 classes, Z (integers), Q (rational numbers) and C (complex
# numbers).  For each class,
Calc::Z(x)
# is equivalent to
Calc::Z.new(x)
```

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
Calc::Q(z1, 4) # => Calc::Q(10.5)
```

### Rational Numbers

```ruby
# creating rational numbers - parameter formats are the same as for Z, except
# there are 2 parameters, a numerator and a denominator.  if you omit the
# denominator, it is assumed to be 1.
q1 = Calc::Q(42)  # equivalent to Calc::Q(42, 1)

# you can also pass a single argument of a plain ruby Rational number:
q1 = Calc::Q(Rational(13,4))  # equivalent to Calc::Q(13, 4)
```

### Complex numbers

Not added yet.

## Development

ruby-calc currently requires ruby 2.1 or newer.

Make sure you have calc development headers installed (yum install calc-dev / apt-get install apcalc-devel, or have manually installed calc).

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/timpeters/ruby-calc/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
