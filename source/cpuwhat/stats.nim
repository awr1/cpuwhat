
const
  OnX86 = defined(i386) or defined(amd64)
  OnARM = defined(arm) or defined(arm64)

when OnX86 or defined(nimdoc):
  include cpuinfo / private / stats_x86

proc cpuName*() :string =
  ## The CPU's full name, for example: `"Intel(R) Core(TM) i3-8350K CPU @
  ## 4.00GHz"`.
  ##
  ## **NOTE:** If a CPU's name is somehow not retrievable, the value will just
  ## be the empty string.
  when OnX86: cpuNameX86()
  else:       ""
