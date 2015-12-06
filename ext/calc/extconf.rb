require "mkmf"

if !find_header("calc/cmath.h")
  abort "calc/cmath.h is missing, please install calc development headers"
end

if RUBY_PLATFORM =~ /darwin/
  # on macosx, detection of libcustcalc doesn't work.  just assume it is
  # required.
  $libs = append_library($libs, "custcalc")
  if !have_library("calc", "libcalc_call_me_first")
    abort "can't find libcalc, please install calc"
  end
  # on macosx, i can't get the linker to use our version of math_error().
  # this macro uses an alternative error hander based on setjmp/longjmp.
  $defs << "-DJUMP_ON_MATH_ERROR"
else
  # try libcalc by itself first - this will work if libcustcalc wasn't made,
  # but will fail if it was
  if !have_library("calc", "libcalc_call_me_first")
    puts "trying again with -lcustcalc"
    $libs = append_library($libs, "custcalc")
    if !have_library("calc", "libcalc_call_me_first")
      abort "can't find libcalc, please install calc"
    end
  end
end

create_makefile("calc/calc")
