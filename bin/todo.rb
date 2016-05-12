#! /usr/bin/env ruby

require "bundler/setup"
require "calc"

q = Calc::Q(1)
c = Calc::C(1,1)
ALL = [Calc, q, c]
RAT = [Calc, q]
COM = [Calc, c]
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
  [:atan2, RAT],
  [:atanh, ALL],
  [:avg, Calc],
  # base - use Calc.config
  # base2 - unlikely to implement as config item
  [:bernoulli, RAT],
  [:bit, RAT],
  # blk - not sure why you'd need these in a ruby script
  # blkcpy
  # bklfree
  # blocks
  [:bround, ALL],
  # calc_tty
  # calcleve
  # calcpath
  [:catalan, RAT],
  [:ceil, ALL],
  [:cfappr, RAT],
  [:cfsim, RAT],
  [:char, RAT],
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
  [:den, RAT],
  # det - use Matrix#det
  [:digit, RAT],
  [:digits, RAT],
  # display - use Calc.config
  # dp - use Vector#dot
  # epsilon - use Calc.config
  # errcount - only useful in command line calc
  # errmax - only useful in command line calc
  # errno - no libcalc interface
  # error - use raise and ruby exceptions
  [:estr, ALL],
  [:euler, RAT],
  # eval - too hard for now :)
  [:exp, ALL],
  [:factor, RAT],
  [:fcnt, RAT],
  [:fib, RAT],
  # forall - use ruby loops
  [:frem, RAT],
  [:fact, RAT],
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
  [:floor, RAT],
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
  [:frac, ALL],
  [:gcd, RAT],
  [:gcdrem, RAT],
  [:gd, ALL],
  # getenv - use ENV
  # hash - not necessary
  # head - use Array
  [:highbit, RAT],
  [:hmean, Calc],
  [:hnrmod, RAT],
  [:hypot, RAT],
  [:ilog, RAT],
  [:ilog10, RAT],
  [:ilog2, RAT],
  [:im, ALL],
  # indices - use ruby Hash/Matrix
  # inputlevel - calc / eval related
  # insert - use Array
  [:int, ALL],
  [:inverse, ALL],
  [:iroot, RAT],
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
  [:ismult, RAT],
  # isnull
  # isnum
  # isobj
  # isobjtype
  [:isodd, ALL],
  # isoctet
  [:isprime, RAT],
  # isptr
  [:isqrt, RAT],
  # isrand
  # israndom
  [:isreal, RAT],
  [:isrel, RAT],
  # isstr
  # issimple
  [:issq, RAT],
  # istype
  [:jacobi, RAT],
  # join - use Array#join
  [:lcm, RAT],
  [:lcmfact, RAT],
  [:lfactor, RAT],
  # links - interesting but not necessary
  # list - use Array
  [:ln, ALL],
  [:log, ALL],
  [:lowbit, RAT],
  [:ltol, RAT],
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
  [:meq, RAT],
  [:min, Calc],
  [:minv, RAT],
  [:mmin, ALL],
  [:mne, RAT],
  [:mod, ALL],
  # modify - use Array/Matrix
  # name - block stuff
  [:near, RAT],
  # newerror - use ruby exceptions
  [:nextcand, RAT],
  [:nextprime, RAT],
  [:norm, ALL],
  # null - use ruby nil
  [:num, RAT],
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
  [:perm, RAT],
  [:prevcand, RAT],
  [:prevprime, RAT],
  [:pfact, RAT],
  [:pi, Calc],
  [:pix, RAT],
  [:places, RAT],
  [:pmod, RAT],
  [:polar, COM],
  [:poly, ALL], # MAYBE - not in linklib
  # pop - use Array
  [:popcnt, RAT],
  [:power, ALL],
  # protect - block stuff
  [:ptest, RAT],
  # printf - use ruby printf
  # prompt - use gets (or highline, etc)
  # push - use array
  # putenv - use ENV
  [:quo, ALL],
  [:quomod, RAT],
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
  [:trunc, RAT],
  # ungetc - i/o stuff
  # usertime - use Process#times
  [:version, Calc],
  [:xor, RAT],
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
