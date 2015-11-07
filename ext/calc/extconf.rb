require "mkmf"

if !find_header("calc/cmath.h")
  abort "calc/cmath.h is missing, please install calc development headers"
end

# try libcalc by itself first - this will work if libcustcalc wasn't made,
# but will fail if it was
if !have_library("calc", "libcalc_call_me_first")
  puts "trying again with -lcustcalc"
  $libs = append_library($libs, "custcalc")
  if !have_library("calc", "libcalc_call_me_first")
    abort "can't find libcalc, please install calc"
  end
end

create_makefile("calc/calc")
