import
  cpuwhat / private / consts,
  nimterop / build,
  nimterop / cimport,
  std / os

when GCCLike:
  const GCCFlags = "-msse2"
  {.passC: GCCFlags.}
  {.passL: GCCFlags.}

static:
  cAddStdDir()

cOverride:
  type
    m64*     {.importc: "__$1", header: "<emmintrin.h>".} = object
    m64_u*   {.importc: "__$1", header: "<emmintrin.h>".} = object
    m128*    {.importc: "__$1", header: "<emmintrin.h>".} = object
    m128_u*  {.importc: "__$1", header: "<emmintrin.h>".} = object
    m128i*   {.importc: "__$1", header: "<emmintrin.h>".} = object
    m128i_u* {.importc: "__$1", header: "<emmintrin.h>".} = object
    m128d*   {.importc: "__$1", header: "<emmintrin.h>".} = object
    m128d_u* {.importc: "__$1", header: "<emmintrin.h>".} = object
    v2si     {.importc: "__$1", header: "<emmintrin.h>".} = object
    v4hi     {.importc: "__$1", header: "<emmintrin.h>".} = object
    v8qi     {.importc: "__$1", header: "<emmintrin.h>".} = object
    v1di     {.importc: "__$1", header: "<emmintrin.h>".} = object
    v2sf     {.importc: "__$1", header: "<emmintrin.h>".} = object
    v4sf     {.importc: "__$1", header: "<emmintrin.h>".} = object
    v4sf     {.importc: "__$1", header: "<emmintrin.h>".} = object
    v2df     {.importc: "__$1", header: "<emmintrin.h>".} = object
    v2di     {.importc: "__$1", header: "<emmintrin.h>".} = object
    v2du     {.importc: "__$1", header: "<emmintrin.h>".} = object
    v4si     {.importc: "__$1", header: "<emmintrin.h>".} = object
    v4su     {.importc: "__$1", header: "<emmintrin.h>".} = object
    v8hi     {.importc: "__$1", header: "<emmintrin.h>".} = object
    v8hu     {.importc: "__$1", header: "<emmintrin.h>".} = object
    v16qi    {.importc: "__$1", header: "<emmintrin.h>".} = object
    v16qu    {.importc: "__$1", header: "<emmintrin.h>".} = object
    v16qs    {.importc: "__$1", header: "<emmintrin.h>".} = object

cPlugin:
  import std / strutils

  proc onSymbol*(sym :var Symbol) {.exportc, dynlib.} =
    sym.name = sym.name.strip(chars = {'_'})

cImport(cSearchPath("mmintrin.h"),  flags = ToastFlags)
cImport(cSearchPath("mm_malloc.h"), flags = ToastFlags)
cImport(cSearchPath("xmmintrin.h"), flags = ToastFlags)
cImport(cSearchPath("emmintrin.h"), flags = ToastFlags)
