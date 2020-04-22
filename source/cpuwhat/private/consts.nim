import
  std / sequtils,
  std / strutils

const
  X86*     = defined(i386) or defined(amd64)
  ARM*     = defined(arm)  or defined(arm64)
  GCCLike* = defined(gcc) or defined(clang)
  Unix*    = defined(unix)

  # Defines are passed to `toast` - and `toast` only! cDefine() passes an
  # undesirable `-D` flag to the C compiler...

  ToastDefines = ["__inline", "__attribute__(x)", "__extension__"]
  ToastProto   = "-f:ast2 -H " & ToastDefines.mapIt("-D " & it & "= ").join
  ToastFlags*  = when Unix: ToastProto.multiReplace(("(", "\\("), (")", "\\)"))
                 else:      ToastProto
