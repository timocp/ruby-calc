# ruby-calc

ruby-calc provides ruby bindings for calc, a c-style arbitrary precision calculator.

For information about calc, see: http://www.isthe.com/chongo/tech/comp/calc/index.html

## Installation

Calc must be installed.  On fedora:

    $ sudo yum install calc calc-libs calc-devel

On mac, install brew then:

    $ brew install calc

On debian, calc is available as "apcalc" but the package doesn't include a shared library so it won't work.

Otherwise, download the calc source and install it manually.

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
z = Calc::Z.new(42)     # Z represents integers
q = Calc::Q.new(13, 4)  # Q represents rational numbers (fractions)
                        # C represents complex numbers (not started yet)
# etc
```

## Development

Make sure you have calc development headers installed (yum install calc-dev / apt-get install apcalc-devel).

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/timpeters/ruby-calc/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
