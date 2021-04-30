import
  std / strutils,
  std / threads,
  std / cpuinfo,
  std / sequtils,
  std / bitops

proc cpuidX86(eaxi, ecxi :int32) :tuple[eax, ebx, ecx, edx :int32] =
  when defined(vcc):
    # limited inline asm support in vcc, so intrinsics, here we go:
    proc cpuidVcc(cpuInfo :ptr int32; functionID, subFunctionId :int32)
      {.cdecl, importc: "__cpuidex", header: "intrin.h".}
    cpuidVcc(addr result.eax, eaxi, ecxi)
  else:
    var (eaxr, ebxr, ecxr, edxr) = (0'i32, 0'i32, 0'i32, 0'i32)
    asm """
      cpuid
      :"=a"(`eaxr`), "=b"(`ebxr`), "=c"(`ecxr`), "=d"(`edxr`)
      :"a"(`eaxi`), "c"(`ecxi`)"""
    (eaxr, ebxr, ecxr, edxr)

proc cpuNameX86() :string =
  var leaves = cast[array[48, char]]([
    cpuidX86(eaxi = 0x80000002'i32, ecxi = 0),
    cpuidX86(eaxi = 0x80000003'i32, ecxi = 0),
    cpuidX86(eaxi = 0x80000004'i32, ecxi = 0)])
  result = $cast[cstring](addr leaves[0])
  result.removeSuffix({'\x01', ' '})

type
  X86Feature {.pure.} = enum
    HypervisorPresence, Hyperthreading, NoSMT, IntelVTX, AMDV, X87FPU, MMX,
    MMXExt, F3DNow, F3DNowEnhanced, Prefetch, SSE, SSE2, SSE3, SSSE3, SSE4a,
    SSE41, SSE42, AVX, AVX2, AVX512F, AVX512DQ, AVX512IFMA, AVX512PF,
    AVX512ER, AVX512CD, AVX512BW, AVX512VL, AVX512VBMI, AVX512VBMI2,
    AVX512VPOPCNTDQ, AVX512VNNI, AVX512VNNIW4, AVX512FMAPS4, AVX512BITALG,
    AVX512BFLOAT16, AVX512VP2INTERSECT, RDRAND, RDSEED, MOVBigEndian, POPCNT,
    FMA3, FMA4, XOP, CAS8B, CAS16B, ABM, BMI1, BMI2, TSXHLE, TSXRTM, ADX, SGX,
    GFNI, AES, VAES, VPCLMULQDQ, PCLMULQDQ, NXBit, Float16c, SHA, CLFLUSH,
    CLFLUSHOPT, CLWB, PrefetchWT1, MPX

let
  cpuCount {.global.} = countProcessors()
  features {.global.} = block:
    func gatherFeatures(supported :var set[X86Feature]) =
      let
        leaf1 = cpuidX86(eaxi = 1, ecxi = 0)
        leaf7 = cpuidX86(eaxi = 7, ecxi = 0)
        leaf8 = cpuidX86(eaxi = 0x80000001'i32, ecxi = 0)

      # see: https://en.wikipedia.org/wiki/CPUID#Calling_CPUID
      # see: Intel® Architecture Instruction Set Extensions and Future Features
      #      Programming Reference
      for feature in X86Feature:
        func test(input, bit :int) :bool = ((1 shl bit) and input) != 0
        let validity = case feature
          # Leaf 1, EDX
          of X87FPU:             leaf1.edx.test(0)
          of CLFLUSH:            leaf1.edx.test(19)
          of MMX:                leaf1.edx.test(23)
          of SSE:                leaf1.edx.test(25)
          of SSE2:               leaf1.edx.test(26)
          of Hyperthreading:     leaf1.edx.test(28)

          # Leaf 1, ECX
          of SSE3:               leaf1.ecx.test(0)
          of PCLMULQDQ:          leaf1.ecx.test(1)
          of IntelVTX:           leaf1.ecx.test(5)
          of SSSE3:              leaf1.ecx.test(9)
          of FMA3:               leaf1.ecx.test(12)
          of CAS16B:             leaf1.ecx.test(13)
          of SSE41:              leaf1.ecx.test(19)
          of SSE42:              leaf1.ecx.test(20)
          of MOVBigEndian:       leaf1.ecx.test(22)
          of POPCNT:             leaf1.ecx.test(23)
          of AES:                leaf1.ecx.test(25)
          of AVX:                leaf1.ecx.test(28)
          of Float16c:           leaf1.ecx.test(29)
          of RDRAND:             leaf1.ecx.test(30)
          of HypervisorPresence: leaf1.ecx.test(31)

          # Leaf 7, ECX
          of PrefetchWT1:        leaf7.ecx.test(0)
          of AVX512VBMI:         leaf7.ecx.test(1)
          of AVX512VBMI2:        leaf7.ecx.test(6)
          of GFNI:               leaf7.ecx.test(8)
          of VAES:               leaf7.ecx.test(9)
          of VPCLMULQDQ:         leaf7.ecx.test(10)
          of AVX512VNNI:         leaf7.ecx.test(11)
          of AVX512BITALG:       leaf7.ecx.test(12)
          of AVX512VPOPCNTDQ:    leaf7.ecx.test(14)

          # Leaf 7, EAX
          of AVX512BFLOAT16:     leaf7.eax.test(5)

          # Leaf 7, EBX
          of SGX:                leaf7.ebx.test(2)
          of BMI1:               leaf7.ebx.test(3)
          of TSXHLE:             leaf7.ebx.test(4)
          of AVX2:               leaf7.ebx.test(5)
          of BMI2:               leaf7.ebx.test(8)
          of TSXRTM:             leaf7.ebx.test(11)
          of MPX:                leaf7.ebx.test(14)
          of AVX512F:            leaf7.ebx.test(16)
          of AVX512DQ:           leaf7.ebx.test(17)
          of RDSEED:             leaf7.ebx.test(18)
          of ADX:                leaf7.ebx.test(19)
          of AVX512IFMA:         leaf7.ebx.test(21)
          of CLFLUSHOPT:         leaf7.ebx.test(23)
          of CLWB:               leaf7.ebx.test(24)
          of AVX512PF:           leaf7.ebx.test(26)
          of AVX512ER:           leaf7.ebx.test(27)
          of AVX512CD:           leaf7.ebx.test(28)
          of SHA:                leaf7.ebx.test(29)
          of AVX512BW:           leaf7.ebx.test(30)
          of AVX512VL:           leaf7.ebx.test(31)

          # Leaf 7, EDX
          of AVX512VNNIW4:       leaf7.edx.test(2)
          of AVX512FMAPS4:       leaf7.edx.test(3)
          of AVX512VP2INTERSECT: leaf7.edx.test(8)

          # Leaf 8, EDX
          of NoSMT:              leaf8.edx.test(1)
          of CAS8B:              leaf8.edx.test(8)
          of NXBit:              leaf8.edx.test(20)
          of MMXExt:             leaf8.edx.test(22)
          of F3DNowEnhanced:     leaf8.edx.test(30)
          of F3DNow:             leaf8.edx.test(31)

          # Leaf 8, ECX
          of AMDV:               leaf8.ecx.test(2)
          of ABM:                leaf8.ecx.test(5)
          of SSE4a:              leaf8.ecx.test(6)
          of Prefetch:           leaf8.ecx.test(8)
          of XOP:                leaf8.ecx.test(11)
          of FMA4:               leaf8.ecx.test(16)
        if validity: supported.incl(feature)

    var
      featureSets = newSeq[set[X86Feature]](cpuCount)
      threads     = newSeq[Thread[var set[X86Feature]]](cpuCount)
    for affinity, thread in threads.mpairs:
      thread.pinToCPU(affinity)
      thread.createThread(gatherFeatures, featureSets[affinity])
    threads.joinThreads

    var featuresByAffinity :array[X86Feature, uint64]
    for affinity, featureSet in featureSets:
      for feature in featureSet:
        featuresByAffinity[feature].setBit(affinity)
    featuresByAffinity

template cached(expression :untyped) :bool =
  let cache {.global.} = expression
  expression

proc currentAffinity() :uint {.inline.} =
  when defined(windows):
    proc GetCurrentProcessorNumber() :uint32
      {.importc, stdcall, dynlib: "Kernel32".}
    GetCurrentProcessorNumber.uint
  else:
    # TODO(awr1): Implement this on Linux/MacOS, etc.
    discard

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

proc isHypervisorPresent*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if this application is running inside of a virtual machine
  ## (this is by no means foolproof).
  cached features[HypervisorPresence].testBit(0)

proc hasSimultaneousMultithreading*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware is utilizing simultaneous multithreading
  ## (branded as *"hyperthreads"* on Intel processors).
  cached (features[Hyperthreading] or not features[NoSMT]).testBit(0)

template onThread(feature :X86Feature; affinity :uint) :bool =
  when compileOption("rangeChecks"):
    if affinity notin 0 ..< cpuCount:
      IndexError.newException(
        "Requested affinity greater than number of logical processors")
  features[feature].testBit(affinity)

proc hasIntelVTX*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the Intel virtualization extensions (VT-x) are available.
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  IntelVTX.onThread(affinity)

proc hasAMDV*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the AMD virtualization extensions (AMD-V) are available.
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  AMDV.onThread(affinity)

proc hasX87FPU*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use x87 floating-point instructions
  ## (includes support for single, double, and 80-bit percision floats as per
  ## IEEE 754-1985).
  ##
  ## By virtue of SSE2 enforced compliance on AMD64 CPUs, this should always be
  ## `true` on 64-bit x86 processors. It should be noted that support of these
  ## instructions is deprecated on 64-bit versions of Windows - see MSDN_.
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  ##
  ## .. _MSDN: https://docs.microsoft.com/en-us/windows/win32/dxtecharts/sixty-four-bit-programming-for-game-developers#porting-applications-to-64-bit-platforms
  X87FPU.onThread(affinity)

proc hasMMX*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use MMX SIMD instructions.
  ##
  ## By virtue of SSE2 enforced compliance on AMD64 CPUs, this should always be
  ## `true` on 64-bit x86 processors. It should be noted that support of these
  ## instructions is deprecated on 64-bit versions of Windows (see MSDN_ for
  ## more info).
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  ##
  ## .. _MSDN: https://docs.microsoft.com/en-us/windows/win32/dxtecharts/sixty-four-bit-programming-for-game-developers#porting-applications-to-64-bit-platforms
  MMX.onThread(affinity)

proc hasMMXExt*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use "Extended MMX" SIMD instructions.
  ##
  ## It should be noted that support of these instructions is deprecated on
  ## 64-bit versions of Windows (see MSDN_ for more info).
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  ##
  ## .. _MSDN: https://docs.microsoft.com/en-us/windows/win32/dxtecharts/sixty-four-bit-programming-for-game-developers#porting-applications-to-64-bit-platforms
  MMXExt.onThread(affinity)

proc has3DNow*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use 3DNow! SIMD instructions.
  ##
  ## It should be noted that support of these instructions is deprecated on
  ## 64-bit versions of Windows (see MSDN_ for more info), and that the 3DNow!
  ## instructions (with an exception made for the prefetch instructions, see the
  ## `hasPrefetch` procedure) have been phased out of AMD processors since 2010
  ## (see `AMD Developer Central`_ for more info).
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  ##
  ## .. _MSDN: https://docs.microsoft.com/en-us/windows/win32/dxtecharts/sixty-four-bit-programming-for-game-developers#porting-applications-to-64-bit-platforms
  ## .. _`AMD Developer Central`: https://web.archive.org/web/20131109151245/http://developer.amd.com/community/blog/2010/08/18/3dnow-deprecated/
  3DNow.onThread(affinity)

proc has3DNowEnhanced*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use "Enhanced 3DNow!" SIMD instructions.
  ##
  ## It should be noted that support of these instructions is deprecated on
  ## 64-bit versions of Windows (see MSDN_ for more info), and that the 3DNow!
  ## instructions (with an exception made for the prefetch instructions, see the
  ## `hasPrefetch` procedure) have been phased out of AMD processors since 2010
  ## (see `AMD Developer Central`_ for more info).
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  ##
  ## .. _MSDN: https://docs.microsoft.com/en-us/windows/win32/dxtecharts/sixty-four-bit-programming-for-game-developers#porting-applications-to-64-bit-platforms
  ## .. _`AMD Developer Central`: https://web.archive.org/web/20131109151245/http://developer.amd.com/community/blog/2010/08/18/3dnow-deprecated/
  3DNowEnhanced.onThread(affinity)

proc hasPrefetch*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use the `PREFETCH` and `PREFETCHW`
  ## instructions. These instructions originally included as part of 3DNow!, but
  ## potentially indepdendent from the rest of it due to changes in contemporary
  ## AMD processors (see above).
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  Prefetch.onThread(affinity)

proc hasSSE*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use the SSE (Streaming SIMD Extensions)
  ## 1.0 instructions, which introduced 128-bit SIMD on x86 machines.
  ##
  ## By virtue of SSE2 enforced compliance on AMD64 CPUs, this should always be
  ## `true` on 64-bit x86 processors.
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  SSE.onThread(affinity)

proc hasSSE2*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use the SSE (Streaming SIMD Extensions)
  ## 2.0 instructions.
  ##
  ## By virtue of SSE2 enforced compliance on AMD64 CPUs, this should always be
  ## `true` on 64-bit x86 processors.
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  SSE2.onThread(affinity)

proc hasSSE3*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use SSE (Streaming SIMD Extensions) 3.0
  ## instructions.
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  SSE3.onThread(affinity)

proc hasSSSE3*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use Supplemental SSE (Streaming SIMD
  ## Extensions) 3.0 instructions.
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  SSSE3.onThread(affinity)

proc hasSSE4a*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use Supplemental SSE (Streaming SIMD
  ## Extensions) 4a instructions.
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  SSE4a.onThread(affinity)

proc hasSSE41*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use Supplemental SSE (Streaming SIMD
  ## Extensions) 4.1 instructions.
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  SSE41.onThread(affinity)

proc hasSSE42*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use Supplemental SSE (Streaming SIMD
  ## Extensions) 4.2 instructions.
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  SSE42.onThread(affinity)

proc hasAVX*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
  ## 1.0 instructions, which introduced 256-bit SIMD on x86 machines along with
  ## addded reencoded versions of prior 128-bit SSE instructions into the more
  ## code-dense and non-backward compatible VEX (Vector Extensions) format.
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  AVX.onThread(affinity)

proc hasAVX2*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions) 2.0
  ## instructions.
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  AVX2.onThread(affinity)

proc hasAVX512F*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
  ## 512-bit F (Foundation) instructions.
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  AVX512F.onThread(affinity)

proc hasAVX512DQ*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
  ## 512-bit DQ (Doubleword + Quadword) instructions.
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  AVX512DQ.onThread(affinity)

proc hasAVX512IFMA*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
  ## 512-bit IFMA (Integer Fused Multiply Accumulation) instructions.
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  AVX512IFMA.onThread(affinity)

proc hasAVX512PF*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
  ## 512-bit PF (Prefetch) instructions.
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  AVX512PF.onThread(affinity)

proc hasAVX512ER*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
  ## 512-bit ER (Exponential and Reciprocal) instructions.
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  AVX512ER.onThread(affinity)

proc hasAVX512CD*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
  ## 512-bit CD (Conflict Detection) instructions.
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  AVX512CD.onThread(affinity)

proc hasAVX512BW*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
  ## 512-bit BW (Byte and Word) instructions.
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  AVX512BW.onThread(affinity)

proc hasAVX512VL*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
  ## 512-bit VL (Vector Length) instructions.
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  AVX512VL.onThread(affinity)

proc hasAVX512VBMI*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
  ## 512-bit VBMI (Vector Byte Manipulation) 1.0 instructions.
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  AVX512VBMI.onThread(affinity)

proc hasAVX512VBMI2*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
  ## 512-bit VBMI (Vector Byte Manipulation) 2.0 instructions.
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  AVX512VBMI2.onThread(affinity)

proc hasAVX512VPOPCNTDQ*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use the AVX (Advanced Vector Extensions)
  ## 512-bit `VPOPCNTDQ` (population count, i.e. determine number of flipped
  ## bits) instruction.
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  AVX512VPOPCNTDQ.onThread(affinity)

proc hasAVX512VNNI*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
  ## 512-bit VNNI (Vector Neural Network) instructions.
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  AVX512VNNI.onThread(affinity)

proc hasAVX512VNNIW4*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
  ## 512-bit 4VNNIW (Vector Neural Network Word Variable Percision)
  ## instructions.
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  AVX512VNNIW4.onThread(affinity)

proc hasAVX512FMAPS4*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
  ## 512-bit 4FMAPS (Fused-Multiply-Accumulation Single-percision) instructions.
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  AVX512FMAPS4.onThread(affinity)

proc hasAVX512BITALG*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
  ## 512-bit BITALG (Bit Algorithms) instructions.
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  AVX512BITALG.onThread(affinity)

proc hasAVX512BFLOAT16*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
  ## 512-bit BFLOAT16 (8-bit exponent, 7-bit mantissa) instructions used by
  ## Intel DL (Deep Learning) Boost.
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  AVX512BFLOAT16.onThread(affinity)

proc hasAVX512VP2INTERSECT*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
  ## 512-bit VP2INTERSECT (Compute Intersections between Dualwords + Quadwords)
  ## instructions.
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  AVX512VP2INTERSECT.onThread(affinity)

proc hasRDRAND*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for the `RDRAND` instruction,
  ## i.e. Intel on-CPU hardware random number generation.
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  RDRAND.onThread(affinity)

proc hasRDSEED*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for the `RDSEED` instruction,
  ## i.e. Intel on-CPU hardware random number generation (used for seeding other
  ## PRNGs).
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  RDSEED.onThread(affinity)

proc hasMOVBigEndian*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for the `MOVBE` instruction for
  ## endianness/byte-order switching.
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  MOVBigEndian.onThread(affinity)

proc hasPOPCNT*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for the `POPCNT` (population
  ## count, i.e. determine number of flipped bits) instruction.
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  POPCNT.onThread(affinity)

proc hasFMA3*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for the FMA3 (Fused Multiply
  ## Accumulation 3-operand) SIMD instructions.
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  FMA3.onThread(affinity)

proc hasFMA4*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for the FMA4 (Fused Multiply
  ## Accumulation 4-operand) SIMD instructions.
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  FMA4.onThread(affinity)

proc hasXOP*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for the XOP (eXtended
  ## Operations) SIMD instructions. These instructions are exclusive to the
  ## Bulldozer AMD microarchitecture family (i.e. Bulldozer, Piledriver,
  ## Steamroller, and Excavator) and were phased out with the release of the Zen
  ## design.
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  XOP.onThread(affinity)

proc hasCAS8B*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for the (`LOCK`-able)
  ## `CMPXCHG8B` 64-bit compare-and-swap instruction.
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  CAS8B.onThread(affinity)

proc hasCAS16B*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for the (`LOCK`-able)
  ## `CMPXCHG16B` 128-bit compare-and-swap instruction.
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  CAS16B.onThread(affinity)

proc hasABM*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for ABM (Advanced Bit
  ## Manipulation) insturctions (i.e. `POPCNT` and `LZCNT` for counting leading
  ## zeroes).
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  ABM.onThread(affinity)

proc hasBMI1*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for BMI (Bit Manipulation) 1.0
  ## instructions.
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  BMI1.onThread(affinity)

proc hasBMI2*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for BMI (Bit Manipulation) 2.0
  ## instructions.
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  BMI2.onThread(affinity)

proc hasTSXHLE*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for HLE (Hardware Lock Elision)
  ## as part of Intel's TSX (Transactional Synchronization Extensions).
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  TSXHLE.onThread(affinity)

proc hasTSXRTM*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for RTM (Restricted
  ## Transactional Memory) as part of Intel's TSX (Transactional Synchronization
  ## Extensions).
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  TSXRTM.onThread(affinity)

proc hasADX*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for ADX (Multi-percision
  ## Add-Carry Extensions) insructions.
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  ADX.onThread(affinity)

proc hasSGX*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for SGX (Software Guard
  ## eXtensions) memory encryption technology.
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  SGX.onThread(affinity)

proc hasGFNI*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for GFNI (Galois Field Affine
  ## Transformation) instructions.
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  GFNI.onThread(affinity)

proc hasAES*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for AESNI (Advanced Encryption
  ## Standard) instructions.
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  AES.onThread(affinity)

proc hasVAES*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for VAES (Vectorized Advanced
  ## Encryption Standard) instructions.
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  VAES.onThread(affinity)

proc hasVPCLMULQDQ*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for `VCLMULQDQ` (512 and 256-bit
  ## Carryless Multiplication) instructions.
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  VPCLMULQDQ.onThread(affinity)

proc hasPCLMULQDQ*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for `PCLMULQDQ` (128-bit
  ## Carryless Multiplication) instructions.
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  PCLMULQDQ.onThread(affinity)

proc hasNXBit*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for NX-bit (No-eXecute)
  ## technology for marking pages of memory as non-executable.
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  NXBit.onThread(affinity)

proc hasFloat16c*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for F16C instructions, used for
  ## converting 16-bit "half-percision" floating-point values to and from
  ## single-percision floating-point values.
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  Float16c.onThread(affinity)

proc hasSHA*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for SHA (Secure Hash Algorithm)
  ## instructions.
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  SHA.onThread(affinity)

proc hasCLFLUSH*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for the `CLFLUSH` (Cache-line
  ## Flush) instruction.
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  CLFLUSH.onThread(affinity)

proc hasCLFLUSHOPT*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for the `CLFLUSHOPT` (Cache-line
  ## Flush Optimized) instruction.
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  CLFLUSHOPT.onThread(affinity)

proc hasCLWB*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for the `CLWB` (Cache-line Write
  ## Back) instruction.
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  CLWB.onThread(affinity)

proc hasPrefetchWT1*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for the `PREFECTHWT1`
  ## instruction.
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  PrefetchWT1.onThread(affinity)

proc hasMPX*(affinity = 0'u) :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for MPX (Memory Protection
  ## eXtensions).
  ##
  ## `affinity` specifies thread affinity as exposed by the OS, including SMT
  ## threads. (Begining with Intel's Alder Lake, some x86 processors may exhibit
  ## ISA feature set incongurence across heterogenous cores; see the
  ## `hasCongruentISA` procedure for more.)
  MPX.onThread(affinity)
