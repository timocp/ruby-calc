#! /usr/bin/env ruby

require "bundler/setup"
require "calc"

q = Calc::Q(1)
c = Calc::C(1, 1)
all = [Calc, q, c]
rat = [Calc, q]
com = [Calc, c]
builtins = Calc::Q(0)
builtins_done = Calc::Q(0)

# this is a list of all calc builtin functions which we want to implement.
# doesn't include functions where there is a ruby way to do it already (files,
# strings, arrays, hashes, matrices).
# each array is a symbol for the method, then a list of things which should
# respond to it.
#
# rand/random related functions are also excluded as there are other ruby
# methods / libs for good random number generation.
[
  [:abs, all],
  # access - use File::Stat
  [:acos, all],
  [:acosh, all],
  [:acot, all],
  [:acoth, all],
  [:acsc, all],
  [:acsch, all],
  [:agd, all],
  # append - use Arrays
  [:appr, all],
  [:arg, all],
  # argv - use ARGV
  [:asec, all],
  [:asech, all],
  [:asin, all],
  [:asinh, all],
  # assoc - use {}
  [:atan, all],
  [:atan2, rat],
  [:atanh, all],
  [:avg, Calc],
  # base - use Calc.config
  # base2 - unlikely to implement as config item
  [:bernoulli, rat],
  [:bit, rat],
  # blk - not sure why you'd need these in a ruby script
  # blkcpy
  # bklfree
  # blocks
  [:bround, all],
  # calc_tty
  # calcleve
  # calcpath
  [:catalan, rat],
  [:ceil, all],
  [:cfappr, rat],
  [:cfsim, rat],
  [:char, rat],
  # cmdbuf use ARGV
  [:cmp, all],
  [:comb, all],
  # config - implement on Calc module
  [:conj, all],
  # copy - block stuff
  [:cos, all],
  [:cosh, all],
  [:cot, all],
  [:coth, all],
  # count - use Array#count{} etc
  # cp - use Vector#cross_product (from matrix lib)
  [:csc, all],
  [:csch, all],
  # ctime - use Time.now / Time.now.ctime
  # custom - n/a no plans to access custom compiled functions yet
  # delete - use Array#delete
  [:den, rat],
  # det - use Matrix#det
  [:digit, rat],
  [:digits, rat],
  # display - use Calc.config
  # dp - use Vector#dot
  # epsilon - use Calc.config
  # errcount - only useful in command line calc
  # errmax - only useful in command line calc
  # errno - no libcalc interface
  # error - use raise and ruby exceptions
  [:estr, all],
  [:euler, rat],
  # eval - too hard for now :)
  [:exp, all],
  [:factor, rat],
  [:fcnt, rat],
  [:fib, rat],
  # forall - use ruby loops
  [:frem, rat],
  [:fact, rat],
  # fclose and other file related funcs: use File
  # feof
  # ferror
  # fflush
  # fgetc
  # fgetfield
  # fgetfile
  # fgetline
  # fgets
  # fgetstr
  # files
  [:floor, rat],
  # fopen
  # fpathopen
  # fprintf
  # fputc
  # fputs
  # fputstr
  # free - not necessary in ruby
  [:freebernoulli, Calc],
  [:freeeuler, Calc],
  # freeglobals - not necessary
  # freeredc - no REDC
  # freestatics - not necessary
  # freopen - more File stuff
  # fscan
  # fscanf
  # fseek
  # fsize
  # ftell
  [:frac, all],
  [:gcd, rat],
  [:gcdrem, rat],
  [:gd, all],
  # getenv - use ENV
  # hash - not necessary
  # head - use Array
  [:highbit, rat],
  [:hmean, Calc],
  [:hnrmod, Calc],
  [:hypot, rat],
  [:ilog, all],
  [:ilog10, all],
  [:ilog2, all],
  [:im, all],
  # indices - use ruby Hash/Matrix
  # inputlevel - calc / eval related
  # insert - use Array
  [:int, all],
  [:inverse, all],
  [:iroot, rat],
  # mostly the is* don't make sense in ruby, since only numbers are mapped to
  # ruby types.  the ones we do have are named as predicates (iseven-> even?)
  # isassoc
  # isatty
  # isblk
  # isconfig
  # isdefined
  # iserror   1     where a value is an error
  [:iseven, all],
  # isfile
  # ishash
  # isident
  [:isint, all],
  # islist
  # ismat
  [:ismult, rat],
  # isnull
  # isnum
  # isobj
  # isobjtype
  [:isodd, all],
  # isoctet
  [:isprime, rat],
  # isptr
  [:isqrt, rat],
  # isrand
  # israndom
  [:isreal, rat],
  [:isrel, rat],
  # isstr
  # issimple
  [:issq, rat],
  # istype
  [:jacobi, rat],
  # join - use Array#join
  [:lcm, rat],
  [:lcmfact, rat],
  [:lfactor, rat],
  # links - interesting but not necessary
  # list - use Array
  [:ln, all],
  [:log, all],
  [:lowbit, rat],
  [:ltol, rat],
  # makelist - use Array
  # matdim, etc - use ruby Matrix library
  # matfill
  # matmax
  # matmin
  # matsum
  # mattrace
  # mattrans
  [:max, Calc],
  # memsize - not exposed by libcalc
  [:meq, rat],
  [:min, Calc],
  [:minv, rat],
  [:mmin, all],
  [:mne, rat],
  [:mod, all],
  # modify - use Array/Matrix
  # name - block stuff
  [:near, rat],
  # newerror - use ruby exceptions
  [:nextcand, rat],
  [:nextprime, rat],
  [:norm, all],
  # null - use ruby nil
  [:num, rat],
  # ord - use String#ord
  # isupper etc - use String
  # islower
  # isalnum
  # isalpha
  # iscntrl
  # isdigit
  # isgraph
  # isprint
  # ispunct
  # isspace
  # isxdigit
  # param - use ruby method arguments
  [:perm, rat],
  [:prevcand, rat],
  [:prevprime, rat],
  [:pfact, rat],
  [:pi, Calc],
  [:pix, rat],
  [:places, rat],
  [:pmod, rat],
  [:polar, com],
  [:poly, all], # MAYBE - not in linklib
  # pop - use Array
  [:popcnt, rat],
  [:power, all],
  # protect - block stuff
  [:ptest, rat],
  # printf - use ruby printf
  # prompt - use gets (or highline, etc)
  # push - use array
  # putenv - use ENV
  [:quo, all],
  [:quomod, rat],
  # rand - no random stuff needed
  # randbit
  # random
  # randombit
  # randperm
  # rcin - no REDC
  # rcmul - no REDC
  # rcout - no REDC
  # rcpow - no REDC
  # rcsq - no REDC
  [:re, all],
  # remove - use Array
  # reverse - use Array/Matrix
  # rewind - use File
  # rm - use File
  [:root, all],
  [:round, all],
  # rsearch - use Matrix
  # runtime - use Process#times
  # saveval - not required
  [:scale, all],
  # scan - use ruby i/o methods
  # scanf
  # search - use Array/Matrix methods
  [:sec, all],
  [:sech, all],
  # seed - for random stuff, not needed
  # segment - list/matrix related
  # select
  # setbit - not sure whta this is for
  [:sgn, all],
  # sha1 - use ruby digest module (actually, don't use sha1)
  [:sin, all],
  [:sinh, all],
  # size - related to non-numeric types
  # sizeof - not necessary
  # sleep - use ruby sleep
  # sort - use ruby sort
  [:sqrt, all],
  # srand - no random stuff
  # srandom
  [:ssq, Calc],
  # stoponerror - not in link library
  [:str, all],
  # strtoupper - use ruby Strings instead of this stuff
  # strtolower
  # strcat
  # strcmp
  # strcasecmp
  # strcpy
  # strerror
  # strlen
  # strncmp
  # strncasecmp
  # strncpy
  # strpos
  # strprintf
  # strscan
  # strscanf
  # substr
  [:sum, Calc],
  # swap - not necessary, use: a,b=b,a
  # system - use ruby system
  # systime - use Process#times
  # tail - use Array
  [:tan, all],
  [:tanh, all],
  # test - not needed; truthiness in ruby is different. for Q/C, use !zero?
  # time - use Time.now.to_i
  [:trunc, rat],
  # ungetc - i/o stuff
  # usertime - use Process#times
  [:version, Calc],
  [:xor, rat]
].each do |func, (*things)|
  builtins += 1
  missing = [*things].reject do |thing|
    thing.respond_to?(func)
  end
  if missing.any?
    puts("Expected method #{ func } on " + missing.map do |thing|
      thing.is_a?(Module) ? "module #{ thing }" : "class #{ thing.class }"
    end.join(", "))
  else
    builtins_done += 1
  end
end

# check for compatibility with built in ruby equivalents

ruby_r = Rational(1, 2)
ruby_c = Complex(1, 2)

(ruby_r.methods - q.methods).sort.each do |m|
  puts "Calc::Q needs method #{ m } for Rational compatibility"
end

(ruby_c.methods - c.methods).sort.each do |m|
  puts "Calc::C needs method #{ m } for Complex compatibility"
end

[
  ["ruby-calc builtins", builtins_done, builtins],
  ["Rational compatibility", (ruby_r.methods & q.methods).size, ruby_r.methods.size.to_f],
  ["Complex compatibility", (ruby_c.methods & c.methods).size, ruby_c.methods.size.to_f]
].each do |goal, done, total|
  printf "%25s:  %3d/%3d (%3.1f%%)\n", goal, done, total, done / total * 100
end
