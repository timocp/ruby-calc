require "forwardable"

module Kernel
  extend Forwardable
  def_delegators Calc, *Calc::ALL_BUILTINS
end
