import
  cpuwhat / private / consts,
  nimterop / build,
  nimterop / cimport,
  std / os

when GCCLike:
  const GCCFlags = "-mmmx"
  {.passC: GCCFlags.}
  {.passL: GCCFlags.}

static:
  cAddStdDir()

cOverride:
  type
    m64_u* {.importc: "__$1", header: "<mmintrin.h>".} = object
    m64*   {.importc: "__$1", header: "<mmintrin.h>".} = object
    v2si   {.importc: "__$1", header: "<mmintrin.h>".} = object
    v4hi   {.importc: "__$1", header: "<mmintrin.h>".} = object
    v8qi   {.importc: "__$1", header: "<mmintrin.h>".} = object
    v1di   {.importc: "__$1", header: "<mmintrin.h>".} = object
    v2sf   {.importc: "__$1", header: "<mmintrin.h>".} = object

cPlugin:
  import std / strutils

  proc onSymbol*(sym :var Symbol) {.exportc, dynlib.} =
    sym.name = sym.name.strip(chars = {'_'})

cImport(cSearchPath("mmintrin.h"), flags = ToastFlags)
