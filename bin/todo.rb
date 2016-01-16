#! /usr/bin/env ruby

require "bundler/setup"
require "calc"

q = Calc::Q(1)
c = Calc::C(1,1)
ALL = [Calc::Q, Calc::C, q, c]
Q = [Calc::Q, q]
C = [Calc::C, c]
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
  [:abs, ALL],
  # access - use File::Stat
  [:acos, ALL],
  [:acosh, ALL],
  [:acot, ALL],
  [:acoth, ALL],
  [:acsc, ALL],
  [:acsch, ALL],
  [:agd, ALL],
  # append - use Arrays
  [:appr, ALL],
  [:arg, ALL],
  # argv - use ARGV
  [:asec, ALL],
  [:asech, ALL],
  [:asin, ALL],
  [:asinh, ALL],
  # assoc - use {}
  [:atan, ALL],
  [:atan2, Q],
  [:atanh, ALL],
  [:avg, Calc],
  # base - use Calc.config
  # base2 - unlikely to implement as config item
  [:bernoulli, Q],
  [:bit, Q],
  # blk - not sure why you'd need these in a ruby script
  # blkcpy
  # bklfree
  # blocks
  [:bround, ALL],
  # calc_tty
  # calcleve
  # calcpath
  [:catalan, Q],
  [:ceil, ALL],
  [:cfappr, Q],
  [:cfsim, Q],
  [:char, Q],
  # cmdbuf use ARGV
  [:cmp, ALL],
  [:comb, ALL],
  # config - implement on Calc module
  [:conj, ALL],
  # copy - block stuff
  [:cos, ALL],
  [:cosh, ALL],
  [:cot, ALL],
  [:coth, ALL],
  # count - use Array#count{} etc
  # cp - use Vector#cross_product (from matrix lib)
  [:csc, ALL],
  [:csch, ALL],
  # ctime - use Time.now / Time.now.ctime
  # custom - n/a no plans to access custom compiled functions yet
  # delete - use Array#delete
  [:den, Q],
  # det - use Matrix#det
  [:digit, Q],
  [:digits, Q],
  # display - use Calc.config
  # dp - use Vector#dot
  # epsilon - use Calc.config
  # errcount - only useful in command line calc
  # errmax - only useful in command line calc
  # errno - no libcalc interface
  # error - use raise and ruby exceptions
  [:estr, ALL],
  [:euler, Q],
  # eval - too hard for now :)
  [:exp, ALL],
  [:factor, Q],
  [:fcnt, Q],
  [:fib, Q],
  # forall - use ruby loops
  [:frem, Q],
  [:fact, Q],
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
  [:floor, Q],
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
  [:freeredc, Calc],
  # freestatics - not necessary
  # freopen - more File stuff
  # fscan
  # fscanf
  # fseek
  # fsize
  # ftell
  [:frac, ALL],
  [:gcd, Q],
  [:gcdrem, Q],
  [:gd, ALL],
  # getenv - use ENV
  # hash - not necessary
  # head - use Array
  [:highbit, Q],
  [:hmean, Calc],
  [:hnrmod, Q],
  [:hypot, Q],
  [:ilog, ALL],
  [:ilog10, Q],
  [:ilog2, Q],
  [:im, ALL],
  # indices - use ruby Hash/Matrix
  # inputlevel - calc / eval related
  # insert - use Array
  [:int, ALL],
  [:inverse, ALL],
  [:iroot, Q],
  # mostly the is* don't make sense in ruby, since only numbers are mapped to
  # ruby types.  the ones we do have are named as predicates (iseven-> even?)
  # isassoc
  # isatty
  # isblk
  # isconfig
  # isdefined
  # iserror   1     where a value is an error
  [:iseven, ALL],
  # isfile
  # ishash
  # isident
  [:isint, ALL],
  # islist
  # ismat
  [:ismult, Q],
  # isnull
  # isnum
  # isobj
  # isobjtype
  [:isodd, ALL],
  # isoctet
  [:isprime, Q],
  # isptr
  [:isqrt, Q],
  # isrand
  # israndom
  [:isreal, Q],
  [:isrel, Q],
  # isstr
  # issimple
  [:issq, Q],
  # istype
  [:jacobi, Q],
  # join - use Array#join
  [:lcm, Q],
  [:lcmfact, Q],
  [:lfactor, Q],
  # links - interesting but not necessary
  # list - use Array
  [:ln, ALL],
  [:log, ALL],
  [:lowbit, Q],
  [:ltol, Q],
  # makelist - use Array
  # matdim, etc - use ruby Matrix library
  # matfill
  # matmax
  # matmin
  # matsum
  # mattrace
  # mattrans
  [:max, Calc::Q],
  # memsize - not exposed by libcalc
  [:meq, Q],
  [:min, Calc::Q],
  [:minv, Q],
  [:mmin, ALL],
  [:mne, Q],
  [:mod, ALL],
  # modify - use Array/Matrix
  # name - block stuff
  [:near, Q],
  # newerror - use ruby exceptions
  [:nextcand, Q],
  [:nextprime, Q],
  [:norm, ALL],
  # null - use ruby nil
  [:num, Q],
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
  [:perm, Q],
  [:prevcand, Q],
  [:prevprime, Q],
  [:pfact, Q],
  [:pi, Calc::Q],
  [:pix, Q],
  [:places, Q],
  [:pmod, Q],
  [:polar, Calc::C],
  [:poly, ALL], # MAYBE - not in linklib
  # pop - use Array
  [:popcnt, Q],
  [:power, ALL],
  # protect - block stuff
  [:ptest, Q],
  # printf - use ruby printf
  # prompt - use gets (or highline, etc)
  # push - use array
  # putenv - use ENV
  [:quo, ALL],
  [:quomod, Q],
  # rand - no random stuff needed
  # randbit
  # random
  # randombit
  # randperm
  [:rcin, Q],
  [:rcmul, Q],
  [:rcout, Q],
  [:rcpow, Q],
  [:rcsq, Q],
  [:re, ALL],
  # remove - use Array
  # reverse - use Array/Matrix
  # rewind - use File
  # rm - use File
  [:root, ALL],
  [:round, ALL],
  # rsearch - use Matrix
  # runtime - use Process#times
  # saveval - not required
  [:scale, ALL],
  # scan - use ruby i/o methods
  # scanf
  # search - use Array/Matrix methods
  [:sec, ALL],
  [:sech, ALL],
  # seed - for random stuff, not needed
  # segment - list/matrix related
  # select
  # setbit - not sure whta this is for
  [:sgn, ALL],
  # sha1 - use ruby digest module (actually, don't use sha1)
  [:sin, ALL],
  [:sinh, ALL],
  # size - related to non-numeric types
  # sizeof - not necessary
  # sleep - use ruby sleep
  # sort - use ruby sort
  [:sqrt, ALL],
  # srand - no random stuff
  # srandom
  [:ssq, Calc],
  # stoponerror - not in link library
  [:str, ALL],
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
  [:tan, ALL],
  [:tanh, ALL],
  # test - not needed; truthiness in ruby is different. for Q/C, use !zero?
  # time - use Time.now.to_i
  [:trunc, Q],
  # ungetc - i/o stuff
  # usertime - use Process#times
  [:version, Calc],
  [:xor, Q],
].each do |func, (*things)|
  builtins += 1
  missing = [*things].reject do |thing|
    thing.respond_to?(func)
  end
  if missing.size > 0
    puts("Expected method #{ func } on " + missing.map do |thing|
      thing.is_a?(Module) ? "module #{ thing }" : "class #{ thing.class }"
    end.join(", "))
  else
    builtins_done += 1
  end
end

# check for compatibility with built in ruby equivalents

ruby_r = Rational(1,2)
ruby_c = Complex(1,2)

(ruby_r.methods - q.methods).sort.each do |m|
  puts "Calc::Q needs method #{ m } for Rational compatibility"
end

(ruby_c.methods - c.methods).sort.each do |m|
  puts "Calc::C needs method #{ m } for Complex compatibility"
end

[
  ["ruby-calc builtins", builtins_done, builtins],
  ["Rational compatibility", (ruby_r.methods & q.methods).size, ruby_r.methods.size.to_f],
  ["Complex compatibility", (ruby_c.methods & c.methods).size, ruby_c.methods.size.to_f],
].each do |goal, done, total|
  printf "%25s:  %3d/%3d (%3.1f%%)\n", goal, done, total, done/total*100
end
