type CPUVendor* = enum
  UnknownCPUVendor
  # X86-associated
  AMD, Intel, VIA, NSC, IDT, Cyrix, Transmeta, NexGen, Rise, SiS, DMP, Zhaoxin,
  Hygon, MCST, UMC
  # ARM-associated
  Apple, Qualcomm, MediaTek, Samsung, HiSilicon, LG, Actions, Allwinner,
  Amlogic, Marvell, MStar, Nvidia, Rockchip, Spreadtrum, Telechips,
  TexasInstruments, Wondermedia, Broadcom
  # Hypervisors
  Bhyve, KVM, QEMU, MicrosoftHyperV, Parallels, VMWare, Xen, ACRN, QNX

const
  HypervisorVendors* = {Bhyve .. QNX}
  X86Vendors*        = {AMD .. UMC} + HypervisorVendors
  ARMVendors*        = {Apple .. Broadcom} + {AMD, Intel}

