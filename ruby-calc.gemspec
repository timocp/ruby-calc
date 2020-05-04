# coding: utf-8

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "calc/version"

Gem::Specification.new do |spec|
  spec.name          = "ruby-calc"
  spec.version       = Calc::VERSION
  spec.authors       = ["Tim Peters"]
  spec.email         = ["tim@catminion.net"]

  spec.summary       = "Ruby bindings for calc"
  spec.description   = "Ruby bindings for calc, an arbitrary precision maths library.  Provides " \
                       "access to a the large number of mathematical functions that come with calc."
  spec.homepage      = "https://github.com/timocp/ruby-calc"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f[/^(test|spec|features)/] }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.extensions    = ["ext/calc/extconf.rb"]
  spec.required_ruby_version = "~> 2.0"

  spec.add_development_dependency "bundler", "~> 1.8"
  spec.add_development_dependency "rake", "~> 12.3.3"
  spec.add_development_dependency "rake-compiler", "~> 0"
  spec.add_development_dependency "minitest", "~> 5.8", ">= 5.8.2"
  spec.add_development_dependency "yard", "~> 0.9.11"
  spec.add_development_dependency "pry", "~> 0"
end
