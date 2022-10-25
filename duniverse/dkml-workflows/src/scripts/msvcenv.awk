# MSVC environment variables:
# 1. https://docs.microsoft.com/en-us/cpp/build/reference/cl-environment-variables?view=msvc-170
# 2. https://docs.microsoft.com/en-us/cpp/build/reference/linking?view=msvc-170#link-environment-variables (except TMP)
# 3. VCToolsRedistDir: https://docs.microsoft.com/en-us/cpp/windows/redistributing-visual-cpp-files?view=msvc-170#locate-the-redistributable-files
BEGIN{FS="="}
$1=="CL"||$1=="_CL_"||$1=="INCLUDE"||$1=="LIBPATH" {print "export " $0}
$1=="LINK"||$1=="_LINK_"||$1=="LIB"||$1=="PATH"    {print "export " $0}
$1=="VCToolsRedistDir"                             {print "export " $0}
