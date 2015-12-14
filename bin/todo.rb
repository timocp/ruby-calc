#! /usr/bin/env ruby

require "bundler/setup"
require "calc"

# check for compatibility with built in ruby equivalents

(1.methods - Calc::Z(1).methods).sort.each do |m|
  puts "Calc::Z needs method #{ m }"
end

(Rational(1,2).methods - Calc::Q(1,2).methods).sort.each do |m|
  puts "Calc::Q needs method #{ m }"
end

(Complex(1,2).methods - Calc::C(1,2).methods).sort.each do |m|
  puts "Calc::C needs method #{ m }"
end
