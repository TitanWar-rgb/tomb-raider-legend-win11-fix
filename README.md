# Tomb Raider: Legend — Windows 11 Startup Crash Fix and Technical Analysis

A technical root-cause analysis and non-invasive fix for the startup crash (Access Violation `0xC0000005` at address `0x300144eb`) affecting Tomb Raider: Legend on Windows 11 and modern graphics architectures (NVIDIA RTX series).

---

## Quick Fix

### Method A: Automatic Script
1. Download `fix.bat` from this repository.
2. Place `fix.bat` into your Tomb Raider: Legend game directory (where `trl.exe` is located).
3. Run `fix.bat`. It will create a backup of the offending file and disable it safely.

### Method B: Manual Steps
1. Open your game directory: `Steam\steamapps\common\Tomb Raider Legend\`.
2. Locate the file `nvidia.bik`.
3. Rename it to `nvidia.bik.disabled`.
4. Launch the game normally through Steam or `trl.exe`.

---

## Technical Post-Mortem

### Exception Details
- Exception code: `0xC0000005` (Access Violation)
- Faulting operation: `Read of address 0x00000000`
- Faulting address: `0x300144eb`
- Faulting module: `binkw32.dll` (RAD Video Tools, ImageBase `0x30000000`, size `0x0006E000`)
- Exact offset: RVA `0x000144EB` in the `BINK` section (file offset `0x000132EB`)

CPU register state at crash:
```text
EAX = 0x00000000
EBX = 0x007ca2e8
ECX = 0x001ae730
EDX = 0x00000000
ESI = 0x28f92000
EDI = 0x28f9207c
EIP = 0x300144eb
ESP = 0x001ae6ec
EBP = 0x00000000
```

### Disassembly Analysis
Disassembly of `binkw32.dll` at RVA `0x144EB`:

```assembly
0x300144D9: mov eax, [0x300605FC]  ; Load global IDirectSound interface pointer
0x300144DE: lea ecx, [esp+40h]     ; Pointer to DSBUFFERDESC
0x300144E2: push ecx               ; Parameter: pcDSBufferDesc
0x300144E3: mov [esp+48h], 180E0h  ; DSBCAPS flags
0x300144EB: mov edx, [eax]         ; Crash: dereferencing NULL vtable pointer (EAX = 0)
0x300144ED: push eax               ; 'this' pointer
0x300144EE: call dword ptr [edx+0Ch]; Call IDirectSound::CreateSoundBuffer
```

### Root Cause Mechanism
1. Upon execution, `trl.exe` creates the Direct3D 9 device and enters the intro movie state machine (`VA 0x0045D0C0`).
2. It attempts to play the first startup logo by calling `PlayMovie("nvidia")` at `VA 0x00416480`.
3. Inside `PlayMovie`, the game calls `BinkSetSoundSystem(_BinkOpenDirectSound@4, 0)`.
4. On Windows 11, the legacy DirectSound cooperative level acquisition fails or remains unbound to the application window, leaving global variable `[0x300605FC]` set to `0x00000000`.
5. `trl.exe` does not check the return value of `BinkSetSoundSystem` and immediately calls `BinkOpen("nvidia.bik")`.
6. When `binkw32.dll` parses the movie's audio track, it executes the secondary sound buffer creation routine at `0x300144EB`. Because `EAX` is NULL, dereferencing `[eax]` triggers a fatal Access Violation.

### Why the Common "DEP Fix" is Ineffective
Many older forum guides recommend adding `trl.exe` to Windows Data Execution Prevention (DEP) exceptions or disabling DEP.
- A DEP violation produces an **Execute** access violation when attempting to run code from a non-executable memory page (`PAGE_READWRITE` / `PAGE_NOACCESS`).
- The crash data proves a **Read** operation on address `0x00000000` from valid executable code pages. Disabling DEP cannot resolve a NULL pointer dereference in user space.

---

## Modern Hardware Recommendations (GeForce RTX Series)

1. **Disable "Next Generation Content"**:
   In the graphics options, keep "Next Generation Content" turned off. This setting corresponds to the early 2006 Xbox 360 shader pipeline, which relies on legacy FP16 precision paths that cause severe in-game crashes and memory corruption on modern RTX GPUs (particularly in water areas and the Kazakhstan level).
2. **Display Resolution (1440p / 4K)**:
   Select your native display resolution (e.g., 2560 x 1440) directly in the options menu or by launching `trl.exe -setup`. Ensure "Widescreen" is enabled.

---

## License
MIT License. See [LICENSE](LICENSE) for details.
