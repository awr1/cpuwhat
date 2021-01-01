import std / strutils

proc cpuidX86(eaxi, ecxi :int32) :tuple[eax, ebx, ecx, edx :int32] =
  when defined(vcc):
    # limited inline asm support in vcc, so intrinsics, here we go:
    proc cpuidVcc(cpuInfo :ptr int32; functionID, subFunctionId: int32)
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
  leaf1 = cpuidX86(eaxi = 1, ecxi = 0)
  leaf7 = cpuidX86(eaxi = 7, ecxi = 0)
  leaf8 = cpuidX86(eaxi = 0x80000001'i32, ecxi = 0)

# The reason why we don't just evaluate these directly in the `let` variable
# list is so that we can internally organize features by their input (leaf)
# and output registers.
proc testX86Feature(feature :X86Feature) :bool =
  proc test(input, bit :int) :bool =
    ((1 shl bit) and input) != 0

  # see: https://en.wikipedia.org/wiki/CPUID#Calling_CPUID
  # see: Intel® Architecture Instruction Set Extensions and Future Features
  #      Programming Reference
  result = case feature
    # leaf 1, edx
    of X87FPU:
      leaf1.edx.test(0)
    of CLFLUSH:
      leaf1.edx.test(19)
    of MMX:
      leaf1.edx.test(23)
    of SSE:
      leaf1.edx.test(25)
    of SSE2:
      leaf1.edx.test(26)
    of Hyperthreading:
      leaf1.edx.test(28)

    # leaf 1, ecx
    of SSE3:
      leaf1.ecx.test(0)
    of PCLMULQDQ:
      leaf1.ecx.test(1)
    of IntelVTX:
      leaf1.ecx.test(5)
    of SSSE3:
      leaf1.ecx.test(9)
    of FMA3:
      leaf1.ecx.test(12)
    of CAS16B:
      leaf1.ecx.test(13)
    of SSE41:
      leaf1.ecx.test(19)
    of SSE42:
      leaf1.ecx.test(20)
    of MOVBigEndian:
      leaf1.ecx.test(22)
    of POPCNT:
      leaf1.ecx.test(23)
    of AES:
      leaf1.ecx.test(25)
    of AVX:
      leaf1.ecx.test(28)
    of Float16c:
      leaf1.ecx.test(29)
    of RDRAND:
      leaf1.ecx.test(30)
    of HypervisorPresence:
      leaf1.ecx.test(31)

    # leaf 7, ecx
    of PrefetchWT1:
      leaf7.ecx.test(0)
    of AVX512VBMI:
      leaf7.ecx.test(1)
    of AVX512VBMI2:
      leaf7.ecx.test(6)
    of GFNI:
      leaf7.ecx.test(8)
    of VAES:
      leaf7.ecx.test(9)
    of VPCLMULQDQ:
      leaf7.ecx.test(10)
    of AVX512VNNI:
      leaf7.ecx.test(11)
    of AVX512BITALG:
      leaf7.ecx.test(12)
    of AVX512VPOPCNTDQ:
      leaf7.ecx.test(14)

    # lead 7, eax
    of AVX512BFLOAT16:
      leaf7.eax.test(5)

    # leaf 7, ebx
    of SGX:
      leaf7.ebx.test(2)
    of BMI1:
      leaf7.ebx.test(3)
    of TSXHLE:
      leaf7.ebx.test(4)
    of AVX2:
      leaf7.ebx.test(5)
    of BMI2:
      leaf7.ebx.test(8)
    of TSXRTM:
      leaf7.ebx.test(11)
    of MPX:
      leaf7.ebx.test(14)
    of AVX512F:
      leaf7.ebx.test(16)
    of AVX512DQ:
      leaf7.ebx.test(17)
    of RDSEED:
      leaf7.ebx.test(18)
    of ADX:
      leaf7.ebx.test(19)
    of AVX512IFMA:
      leaf7.ebx.test(21)
    of CLFLUSHOPT:
      leaf7.ebx.test(23)
    of CLWB:
      leaf7.ebx.test(24)
    of AVX512PF:
      leaf7.ebx.test(26)
    of AVX512ER:
      leaf7.ebx.test(27)
    of AVX512CD:
      leaf7.ebx.test(28)
    of SHA:
      leaf7.ebx.test(29)
    of AVX512BW:
      leaf7.ebx.test(30)
    of AVX512VL:
      leaf7.ebx.test(31)

    # leaf 7, edx
    of AVX512VNNIW4:
      leaf7.edx.test(2)
    of AVX512FMAPS4:
      leaf7.edx.test(3)
    of AVX512VP2INTERSECT:
      leaf7.edx.test(8)

    # leaf 8, edx
    of NoSMT:
      leaf8.edx.test(1)
    of CAS8B:
      leaf8.edx.test(8)
    of NXBit:
      leaf8.edx.test(20)
    of MMXExt:
      leaf8.edx.test(22)
    of F3DNowEnhanced:
      leaf8.edx.test(30)
    of F3DNow:
      leaf8.edx.test(31)

    # leaf 8, ecx
    of AMDV:
      leaf8.ecx.test(2)
    of ABM:
      leaf8.ecx.test(5)
    of SSE4a:
      leaf8.ecx.test(6)
    of Prefetch:
      leaf8.ecx.test(8)
    of XOP:
      leaf8.ecx.test(11)
    of FMA4:
      leaf8.ecx.test(16)

let
  isHypervisorPresentImpl           = testX86Feature(HypervisorPresence)
  hasSimultaneousMultithreadingImpl = testX86Feature(Hyperthreading) or
                                      not testX86Feature(NoSMT)
  hasIntelVTXImpl                   = testX86Feature(IntelVTX)
  hasAMDVImpl                       = testX86Feature(AMDV)
  hasX87FPUImpl                     = testX86Feature(X87FPU)
  hasMMXImpl                        = testX86Feature(MMX)
  hasMMXExtImpl                     = testX86Feature(MMXExt)
  has3DNowImpl                      = testX86Feature(F3DNow)
  has3DNowEnhancedImpl              = testX86Feature(F3DNowEnhanced)
  hasPrefetchImpl                   = testX86Feature(Prefetch) or
                                      testX86Feature(F3DNow)
  hasSSEImpl                        = testX86Feature(SSE)
  hasSSE2Impl                       = testX86Feature(SSE2)
  hasSSE3Impl                       = testX86Feature(SSE3)
  hasSSSE3Impl                      = testX86Feature(SSSE3)
  hasSSE4aImpl                      = testX86Feature(SSE4a)
  hasSSE41Impl                      = testX86Feature(SSE41)
  hasSSE42Impl                      = testX86Feature(SSE42)
  hasAVXImpl                        = testX86Feature(AVX)
  hasAVX2Impl                       = testX86Feature(AVX2)
  hasAVX512FImpl                    = testX86Feature(AVX512F)
  hasAVX512DQImpl                   = testX86Feature(AVX512DQ)
  hasAVX512IFMAImpl                 = testX86Feature(AVX512IFMA)
  hasAVX512PFImpl                   = testX86Feature(AVX512PF)
  hasAVX512ERImpl                   = testX86Feature(AVX512ER)
  hasAVX512CDImpl                   = testX86Feature(AVX512DQ)
  hasAVX512BWImpl                   = testX86Feature(AVX512BW)
  hasAVX512VLImpl                   = testX86Feature(AVX512VL)
  hasAVX512VBMIImpl                 = testX86Feature(AVX512VBMI)
  hasAVX512VBMI2Impl                = testX86Feature(AVX512VBMI2)
  hasAVX512VPOPCNTDQImpl            = testX86Feature(AVX512VPOPCNTDQ)
  hasAVX512VNNIImpl                 = testX86Feature(AVX512VNNI)
  hasAVX512VNNIW4Impl               = testX86Feature(AVX512VNNIW4)
  hasAVX512FMAPS4Impl               = testX86Feature(AVX512FMAPS4)
  hasAVX512BITALGImpl               = testX86Feature(AVX512BITALG)
  hasAVX512BFLOAT16Impl             = testX86Feature(AVX512BFLOAT16)
  hasAVX512VP2INTERSECTImpl         = testX86Feature(AVX512VP2INTERSECT)
  hasRDRANDImpl                     = testX86Feature(RDRAND)
  hasRDSEEDImpl                     = testX86Feature(RDSEED)
  hasMOVBigEndianImpl               = testX86Feature(MOVBigEndian)
  hasPOPCNTImpl                     = testX86Feature(POPCNT)
  hasFMA3Impl                       = testX86Feature(FMA3)
  hasFMA4Impl                       = testX86Feature(FMA4)
  hasXOPImpl                        = testX86Feature(XOP)
  hasCAS8BImpl                      = testX86Feature(CAS8B)
  hasCAS16BImpl                     = testX86Feature(CAS16B)
  hasABMImpl                        = testX86Feature(ABM)
  hasBMI1Impl                       = testX86Feature(BMI1)
  hasBMI2Impl                       = testX86Feature(BMI2)
  hasTSXHLEImpl                     = testX86Feature(TSXHLE)
  hasTSXRTMImpl                     = testX86Feature(TSXRTM)
  hasADXImpl                        = testX86Feature(TSXHLE)
  hasSGXImpl                        = testX86Feature(SGX)
  hasGFNIImpl                       = testX86Feature(GFNI)
  hasAESImpl                        = testX86Feature(AES)
  hasVAESImpl                       = testX86Feature(VAES)
  hasVPCLMULQDQImpl                 = testX86Feature(VPCLMULQDQ)
  hasPCLMULQDQImpl                  = testX86Feature(PCLMULQDQ)
  hasNXBitImpl                      = testX86Feature(NXBit)
  hasFloat16cImpl                   = testX86Feature(Float16c)
  hasSHAImpl                        = testX86Feature(SHA)
  hasCLFLUSHImpl                    = testX86Feature(CLFLUSH)
  hasCLFLUSHOPTImpl                 = testX86Feature(CLFLUSHOPT)
  hasCLWBImpl                       = testX86Feature(CLWB)
  hasPrefetchWT1Impl                = testX86Feature(PrefetchWT1)
  hasMPXImpl                        = testX86Feature(MPX)

# NOTE: We use procedures here (layered over the variables) to keep the API
# consistent and usable against possible future heterogenous systems with ISA
# differences between cores (a possibility that has historical precedents, for
# instance, the PPU/SPU relationship found on the IBM Cell). If future systems
# do end up having disparate ISA features across multiple cores, expect there to
# be a "cpuCore" argument added to the feature procs.

proc isHypervisorPresent*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if this application is running inside of a virtual machine
  ## (this is by no means foolproof).
  isHypervisorPresentImpl

proc hasSimultaneousMultithreading*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware is utilizing simultaneous multithreading
  ## (branded as *"hyperthreads"* on Intel processors).
  hasSimultaneousMultithreadingImpl

proc hasIntelVTX*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the Intel virtualization extensions (VT-x) are available.
  hasIntelVTXImpl

proc hasAMDV*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the AMD virtualization extensions (AMD-V) are available.
  hasAMDVImpl

proc hasX87FPU*() :bool {.inline.} =
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
  ## .. _MSDN: https://docs.microsoft.com/en-us/windows/win32/dxtecharts/sixty-four-bit-programming-for-game-developers#porting-applications-to-64-bit-platforms
  hasX87FPUImpl

proc hasMMX*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use MMX SIMD instructions.
  ##
  ## By virtue of SSE2 enforced compliance on AMD64 CPUs, this should always be
  ## `true` on 64-bit x86 processors. It should be noted that support of these
  ## instructions is deprecated on 64-bit versions of Windows (see MSDN_ for
  ## more info).
  ##
  ## .. _MSDN: https://docs.microsoft.com/en-us/windows/win32/dxtecharts/sixty-four-bit-programming-for-game-developers#porting-applications-to-64-bit-platforms
  hasMMXImpl

proc hasMMXExt*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use "Extended MMX" SIMD instructions.
  ##
  ## It should be noted that support of these instructions is deprecated on
  ## 64-bit versions of Windows (see MSDN_ for more info).
  ##
  ## .. _MSDN: https://docs.microsoft.com/en-us/windows/win32/dxtecharts/sixty-four-bit-programming-for-game-developers#porting-applications-to-64-bit-platforms
  hasMMXExtImpl

proc has3DNow*() :bool {.inline.} =
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
  ## .. _MSDN: https://docs.microsoft.com/en-us/windows/win32/dxtecharts/sixty-four-bit-programming-for-game-developers#porting-applications-to-64-bit-platforms
  ## .. _`AMD Developer Central`: https://web.archive.org/web/20131109151245/http://developer.amd.com/community/blog/2010/08/18/3dnow-deprecated/
  has3DNowImpl

proc has3DNowEnhanced*() :bool {.inline.} =
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
  ## .. _MSDN: https://docs.microsoft.com/en-us/windows/win32/dxtecharts/sixty-four-bit-programming-for-game-developers#porting-applications-to-64-bit-platforms
  ## .. _`AMD Developer Central`: https://web.archive.org/web/20131109151245/http://developer.amd.com/community/blog/2010/08/18/3dnow-deprecated/
  has3DNowEnhancedImpl

proc hasPrefetch*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use the `PREFETCH` and `PREFETCHW`
  ## instructions. These instructions originally included as part of 3DNow!, but
  ## potentially indepdendent from the rest of it due to changes in contemporary
  ## AMD processors (see above).
  hasPrefetchImpl

proc hasSSE*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use the SSE (Streaming SIMD Extensions)
  ## 1.0 instructions, which introduced 128-bit SIMD on x86 machines.
  ##
  ## By virtue of SSE2 enforced compliance on AMD64 CPUs, this should always be
  ## `true` on 64-bit x86 processors.
  hasSSEImpl

proc hasSSE2*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use the SSE (Streaming SIMD Extensions)
  ## 2.0 instructions.
  ##
  ## By virtue of SSE2 enforced compliance on AMD64 CPUs, this should always be
  ## `true` on 64-bit x86 processors.
  hasSSE2Impl

proc hasSSE3*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use SSE (Streaming SIMD Extensions) 3.0
  ## instructions.
  hasSSE3Impl

proc hasSSSE3*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use Supplemental SSE (Streaming SIMD
  ## Extensions) 3.0 instructions.
  hasSSSE3Impl

proc hasSSE4a*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use Supplemental SSE (Streaming SIMD
  ## Extensions) 4a instructions.
  hasSSE4aImpl

proc hasSSE41*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use Supplemental SSE (Streaming SIMD
  ## Extensions) 4.1 instructions.
  hasSSE41Impl

proc hasSSE42*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use Supplemental SSE (Streaming SIMD
  ## Extensions) 4.2 instructions.
  hasSSE42Impl

proc hasAVX*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
  ## 1.0 instructions, which introduced 256-bit SIMD on x86 machines along with
  ## addded reencoded versions of prior 128-bit SSE instructions into the more
  ## code-dense and non-backward compatible VEX (Vector Extensions) format.
  hasAVXImpl

proc hasAVX2*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions) 2.0
  ## instructions.
  hasAVX2Impl

proc hasAVX512F*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
  ## 512-bit F (Foundation) instructions.
  hasAVX512FImpl

proc hasAVX512DQ*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
  ## 512-bit DQ (Doubleword + Quadword) instructions.
  hasAVX512DQImpl

proc hasAVX512IFMA*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
  ## 512-bit IFMA (Integer Fused Multiply Accumulation) instructions.
  hasAVX512IFMAImpl

proc hasAVX512PF*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
  ## 512-bit PF (Prefetch) instructions.
  hasAVX512PFImpl

proc hasAVX512ER*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
  ## 512-bit ER (Exponential and Reciprocal) instructions.
  hasAVX512ERImpl

proc hasAVX512CD*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
  ## 512-bit CD (Conflict Detection) instructions.
  hasAVX512CDImpl

proc hasAVX512BW*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
  ## 512-bit BW (Byte and Word) instructions.
  hasAVX512BWImpl

proc hasAVX512VL*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
  ## 512-bit VL (Vector Length) instructions.
  hasAVX512VLImpl

proc hasAVX512VBMI*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
  ## 512-bit VBMI (Vector Byte Manipulation) 1.0 instructions.
  hasAVX512VBMIImpl

proc hasAVX512VBMI2*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
  ## 512-bit VBMI (Vector Byte Manipulation) 2.0 instructions.
  hasAVX512VBMI2Impl

proc hasAVX512VPOPCNTDQ*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use the AVX (Advanced Vector Extensions)
  ## 512-bit `VPOPCNTDQ` (population count, i.e. determine number of flipped
  ## bits) instruction.
  hasAVX512VPOPCNTDQImpl

proc hasAVX512VNNI*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
  ## 512-bit VNNI (Vector Neural Network) instructions.
  hasAVX512VNNIImpl

proc hasAVX512VNNIW4*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
  ## 512-bit 4VNNIW (Vector Neural Network Word Variable Percision)
  ## instructions.
  hasAVX512VNNIW4Impl

proc hasAVX512FMAPS4*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
  ## 512-bit 4FMAPS (Fused-Multiply-Accumulation Single-percision) instructions.
  hasAVX512FMAPS4Impl

proc hasAVX512BITALG*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
  ## 512-bit BITALG (Bit Algorithms) instructions.
  hasAVX512BITALGImpl

proc hasAVX512BFLOAT16*() :bool {.inline.} =
  ## **(x86 Only)**
  ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
  ## 512-bit BFLOAT16 (8-bit exponent, 7-bit mantissa) instructions used by
  ## Intel DL (Deep Learning) Boost.
  hasAVX512BFLOAT16Impl

proc hasAVX512VP2INTERSECT*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
  ## 512-bit VP2INTERSECT (Compute Intersections between Dualwords + Quadwords)
  ## instructions.
  hasAVX512VP2INTERSECTImpl

proc hasRDRAND*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for the `RDRAND` instruction,
  ## i.e. Intel on-CPU hardware random number generation.
  hasRDRANDImpl

proc hasRDSEED*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for the `RDSEED` instruction,
  ## i.e. Intel on-CPU hardware random number generation (used for seeding other
  ## PRNGs).
  hasRDSEEDImpl

proc hasMOVBigEndian*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for the `MOVBE` instruction for
  ## endianness/byte-order switching.
  hasMOVBigEndianImpl

proc hasPOPCNT*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for the `POPCNT` (population
  ## count, i.e. determine number of flipped bits) instruction.
  hasPOPCNTImpl

proc hasFMA3*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for the FMA3 (Fused Multiply
  ## Accumulation 3-operand) SIMD instructions.
  hasFMA3Impl

proc hasFMA4*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for the FMA4 (Fused Multiply
  ## Accumulation 4-operand) SIMD instructions.
  hasFMA4Impl

proc hasXOP*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for the XOP (eXtended
  ## Operations) SIMD instructions. These instructions are exclusive to the
  ## Bulldozer AMD microarchitecture family (i.e. Bulldozer, Piledriver,
  ## Steamroller, and Excavator) and were phased out with the release of the Zen
  ## design.
  hasXOPImpl

proc hasCAS8B*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for the (`LOCK`-able)
  ## `CMPXCHG8B` 64-bit compare-and-swap instruction.
  hasCAS8BImpl

proc hasCAS16B*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for the (`LOCK`-able)
  ## `CMPXCHG16B` 128-bit compare-and-swap instruction.
  hasCAS16BImpl

proc hasABM*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for ABM (Advanced Bit
  ## Manipulation) insturctions (i.e. `POPCNT` and `LZCNT` for counting leading
  ## zeroes).
  hasABMImpl

proc hasBMI1*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for BMI (Bit Manipulation) 1.0
  ## instructions.
  hasBMI1Impl

proc hasBMI2*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for BMI (Bit Manipulation) 2.0
  ## instructions.
  hasBMI2Impl

proc hasTSXHLE*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for HLE (Hardware Lock Elision)
  ## as part of Intel's TSX (Transactional Synchronization Extensions).
  hasTSXHLEImpl

proc hasTSXRTM*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for RTM (Restricted
  ## Transactional Memory) as part of Intel's TSX (Transactional Synchronization
  ## Extensions).
  hasTSXRTMImpl

proc hasADX*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for ADX (Multi-percision
  ## Add-Carry Extensions) insructions.
  hasADXImpl

proc hasSGX*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for SGX (Software Guard
  ## eXtensions) memory encryption technology.
  hasSGXImpl

proc hasGFNI*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for GFNI (Galois Field Affine
  ## Transformation) instructions.
  hasGFNIImpl

proc hasAES*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for AESNI (Advanced Encryption
  ## Standard) instructions.
  hasAESImpl

proc hasVAES*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for VAES (Vectorized Advanced
  ## Encryption Standard) instructions.
  hasVAESImpl

proc hasVPCLMULQDQ*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for `VCLMULQDQ` (512 and 256-bit
  ## Carryless Multiplication) instructions.
  hasVPCLMULQDQImpl

proc hasPCLMULQDQ*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for `PCLMULQDQ` (128-bit
  ## Carryless Multiplication) instructions.
  hasPCLMULQDQImpl

proc hasNXBit*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for NX-bit (No-eXecute)
  ## technology for marking pages of memory as non-executable.
  hasNXBitImpl

proc hasFloat16c*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for F16C instructions, used for
  ## converting 16-bit "half-percision" floating-point values to and from
  ## single-percision floating-point values.
  hasFloat16cImpl

proc hasSHA*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for SHA (Secure Hash Algorithm)
  ## instructions.
  hasSHAImpl

proc hasCLFLUSH*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for the `CLFLUSH` (Cache-line
  ## Flush) instruction.
  hasCLFLUSHImpl

proc hasCLFLUSHOPT*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for the `CLFLUSHOPT` (Cache-line
  ## Flush Optimized) instruction.
  hasCLFLUSHOPTImpl

proc hasCLWB*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for the `CLWB` (Cache-line Write
  ## Back) instruction.
  hasCLWBImpl

proc hasPrefetchWT1*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for the `PREFECTHWT1`
  ## instruction.
  hasPrefetchWT1Impl

proc hasMPX*() :bool {.inline.} =
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for MPX (Memory Protection
  ## eXtensions).
  hasMPXImpl
