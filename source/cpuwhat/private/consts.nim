const
  X86*     = defined(i386) or defined(amd64)
  ARM*     = defined(arm)  or defined(arm64)
  GCCLike* = defined(gcc) or defined(clang)
  Unix*    = defined(unix)
