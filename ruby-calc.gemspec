# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "calc/version"

Gem::Specification.new do |spec|
  spec.name          = "ruby-calc"
  spec.version       = Calc::VERSION
  spec.authors       = ["Tim Peters"]
  spec.email         = ["zomg.tim@gmail.com"]

  spec.summary       = "ruby bindings for calc"
  spec.description   = "ruby bindings for calc, an arbitrary precision maths library"
  spec.homepage      = "https://github.com/timpeters/ruby-calc"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f[/^(test|spec|features)/] }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.extensions    = ["ext/calc/extconf.rb"]

  spec.add_development_dependency "bundler", "~> 1.8"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rake-compiler", "~> 0"
  spec.add_development_dependency "minitest", "~> 5.8", ">= 5.8.2"
  spec.add_development_dependency "yard", "~> 0"
  spec.add_development_dependency "pry", "~> 0"
end
