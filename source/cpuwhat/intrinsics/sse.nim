import
  cpuwhat / private / consts,
  nimterop / build,
  nimterop / cimport,
  std / os

when GCCLike:
  {.passC: "-msse".}

static:
  cAddStdDir()
  when defined(unix):
    cDefine("__attribute__\\(x\\)", " ")
  else:
    cDefine("__attribute__(x)", " ")
  cDefine("__inline", " ")

cOverride:
  type
    m64*   {.importc: "__$1", header: "mmintrin.h".} = object
    v2si*  {.importc: "__$1", header: "mmintrin.h".} = object
    v4hi*  {.importc: "__$1", header: "mmintrin.h".} = object
    v8qi*  {.importc: "__$1", header: "mmintrin.h".} = object
    v1di*  {.importc: "__$1", header: "mmintrin.h".} = object
    v2sf*  {.importc: "__$1", header: "mmintrin.h".} = object

    m128*  {.importc: "__$1", header: "xmmintrin.h".} = object
    m128i* {.importc: "__$1", header: "xmmintrin.h".} = object
    m128d* {.importc: "__$1", header: "xmmintrin.h".} = object
    v4sf*  {.importc: "__$1", header: "xmmintrin.h".} = object
    v4sf*  {.importc: "__$1", header: "xmmintrin.h".} = object
    v2df*  {.importc: "__$1", header: "xmmintrin.h".} = object
    v2di*  {.importc: "__$1", header: "xmmintrin.h".} = object
    v2du*  {.importc: "__$1", header: "xmmintrin.h".} = object
    v4si*  {.importc: "__$1", header: "xmmintrin.h".} = object
    v4su*  {.importc: "__$1", header: "xmmintrin.h".} = object
    v8hi*  {.importc: "__$1", header: "xmmintrin.h".} = object
    v8hu*  {.importc: "__$1", header: "xmmintrin.h".} = object
    v16qi* {.importc: "__$1", header: "xmmintrin.h".} = object
    v16qu* {.importc: "__$1", header: "xmmintrin.h".} = object

cPlugin:
  import std / strutils

  proc onSymbol*(sym :var Symbol) {.exportc, dynlib.} =
    sym.name = sym.name.strip(chars = {'_'})

const Flags = "-f:ast2 -H"
cImport(cSearchPath("mmintrin.h"),  flags = Flags)
cImport(cSearchPath("xmmintrin.h"), flags = Flags)
