require "mkmf"

if !find_header("calc/cmath.h")
  abort "calc/cmath.h is missing, please install calc development headers"
end

# if custcalc is compiled into calc, then you need both.  need to find a way
# for #have_library or similar to try both first, then libcalc by itself if
# both fail.
# meantime, just always use it.
$libs = append_library($libs, "custcalc")
if !have_library("calc", "libcalc_call_me_first")
  abort "can't find libcalc, please install calc"
end

create_makefile("calc/calc")
