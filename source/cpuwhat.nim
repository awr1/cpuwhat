import cpuwhat / private / consts

when X86 or defined(nimdoc):
  include cpuwhat / private / info_x86

proc cpuName*() :string =
  ## The CPU's full name, for example: `"Intel(R) Core(TM) i3-8350K CPU @
  ## 4.00GHz"`.
  ##
  ## **NOTE:** If a CPU's name is somehow not retrievable, the value will just
  ## be the empty string.
  var cachedResult {.global.} = when X86: cpuNameX86()
                                else:     ""
  cachedResult
