# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/) 
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

## [0.2.0] - 2016-12-24
### Added
- Compatibility with ruby 2.4 `Fixnum`/`Bignum` unification to `Integer`
- Parameters for `ceil` and `floor` compatible with ruby 2.4 numeric classes
- Methods `finite?` and `infinite?` compatible with ruby 2.4 numeric classes
- Method `digits_r` compatible with ruby 2.4 numeric `digits`, as libcalc
  already provides a `digits` function (requires ruby 2.4)
- Method `clamp` returns ruby calc classes in ruby 2.4

## 0.1.0 - 2016-05-28
### Added
- Adds `Calc::Q` (rational numbers) and `Calc::C` (complex numbers)
- Important (mathematical) libcalc functions as methods
- Several libcalc configuration options via `Calc#config`
- Conversion to/from libcalc and ruby classes
- Compatibility methods with ruby numeric classes

[Unreleased]: https://github.com/timocp/ruby-calc/compare/0.2.0...HEAD
[0.2.0]: https://github.com/timocp/ruby-calc/compare/0.1.0...0.2.0
