import cpuwhat / private / consts

when X86 or defined(nimdoc):
  include cpuwhat / private / info_x86

proc cpuName*() :string {.inline.} =
  ## The CPU's full name, for example: `"Intel(R) Core(TM) i3-8350K CPU @
  ## 4.00GHz"`.
  ##
  ## **NOTE:** If a CPU's name is somehow not retrievable, the value will just
  ## be the empty string.
  cached when X86: cpuNameX86() else: ""

proc hasCongruentISA*() :bool {.inline.} =
  ## Reports `true` if the available instruction feature set is the same across
  ## all cores. This does not necessarily mean the CPU cores are homogenous,
  ## only that code should be relatively compatible regardless of the core it's
  ## being executed on.
  ##
  ## Certain multi-core CPU packages are based on a heterogenous or "hybridized"
  ## design where multiple cores in a system are based on differing hardware
  ## designs to elicit different performance characteristics, e.g. CPUs of
  ## ARM's "big.LITTLE" design concept that splits a CPU into power-efficient
  ## and high-performance cores, the idea being that an OS will schedule threads
  ## to the appropriate core types based on what the user currently is doing.
  ##
  ## Whilst big.LITTLE nominally guaranteed that both types of cores in a system
  ## support the same instructions, newer takes on the big.LITTLE concept, for
  ## example, Samsung's Exynos 9600 and Intel's Alder Lake, do not follow this
  ## principle.
  ##
  ## If no relevant OS-level countermeasures exist, then user applications run
  ## the risk of crashing via illegal opcode exceptions; in the best case
  ## applications are forcibly repinned onto "known-good" cores that can
  ## execute the instructions in question, leading to potential performance
  ## issues as multiple threads of the same application compete with each other.
  cached features.allIt(it == 0 or it.popcount == cpuCount)
