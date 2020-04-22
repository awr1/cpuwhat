<p align="center">
  <img src=https://user-images.githubusercontent.com/41453959/65995578-6e962000-e45b-11e9-9fc5-f793d6523953.png 
       width="300px">
</p>

- - -

**cpuwhat** is a [Nim](https://github.com/nim-lang/Nim) library for providing
utilities for advanced CPU operations. Features (and planned features)
include:

- [X] x86 Support
- [ ] ARM Support
- [X] Querying CPU Name
- [ ] Querying CPU Vendor + Microarchitecture
- [ ] Querying CPU Cache Topology
- [X] Testing Presence of CPU Instruction Set Extensions
- [X] (WIP) Compiler Intrinsics (currently supporting MMX, SSE 1-3)

### Query Example

```nim
import cpuwhat

echo(cpuName())
echo("has SSE2:     ", hasSSE2())
echo("has AVX512BW: ", hasAVX512BW())
```

### Intrinsics Example

```nim
import cpuwhat / intrinsics / sse

let zero = mm_setzero_ps()
```

### License

Uses the Internet Systems Consortium (ISC) open-source license.
