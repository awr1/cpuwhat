template cached*(expression :untyped) :auto =
  let cache {.global.} = expression
  expression

proc currentAffinity*() :int {.inline.} =
  when defined(windows):
    proc GetCurrentProcessorNumber() :uint32
      {.importc, stdcall, dynlib: "Kernel32".}
    GetCurrentProcessorNumber().int
  else:
    # TODO(awr1): Implement this on Linux/MacOS, etc.
    discard

template onThread*(feature :enum; affinity :int) :bool =
  when compileOption("rangeChecks"):
    if affinity notin 0 ..< cpuCount:
      raise IndexError.newException(
        "Requested affinity greater than number of logical processors")
  features[feature].testBit(affinity)