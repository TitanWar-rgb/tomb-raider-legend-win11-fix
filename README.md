# Tomb Raider: Legend — Windows 11 Crash Fixes and Technical Analysis

A comprehensive technical root-cause analysis and verified fixes for the two major crashes affecting **Tomb Raider: Legend** (v1.2) on Windows 11 and modern graphics architectures (NVIDIA GeForce RTX series):

1. **Startup Crash**: Access Violation `0xC0000005` at address `0x300144eb` (`binkw32.dll`).
2. **Kazakhstan Parachute Drop Crash**: Access Violation `0xC0000005` at address `0x005c136b` (`trl.exe`).

---

## Quick Summary of Solutions

| Issue | Cause | Fix |
| :--- | :--- | :--- |
| **Crash 1: Startup black screen** | `binkw32.dll` NULL pointer dereference while opening `nvidia.bik` audio track | Rename `nvidia.bik` to `nvidia.bik.disabled` (or use `fix.bat`) |
| **Crash 2: Kazakhstan parachute jump** | `trl.exe` out-of-bounds bone index calculation in Next-Gen cloth physics (`ikcloth.cpp`) | Turn **OFF** "Next Generation Content" in Display Options |

---

## 1. Startup Crash Fix (`0x300144eb`)

### Method A: Automated Script
1. Download `fix.bat` from this repository.
2. Place `fix.bat` into your Tomb Raider: Legend game directory (where `trl.exe` is located).
3. Run `fix.bat`. It creates a backup in `_backup_original\` and safely disables the file.

### Method B: Manual Steps
1. Open your game directory: `Steam\steamapps\common\Tomb Raider Legend\`.
2. Locate `nvidia.bik`.
3. Rename it to `nvidia.bik.disabled`.
4. Launch the game normally.

### Technical Analysis
- **Faulting Module**: `binkw32.dll` (RAD Video Tools, ImageBase `0x30000000`, size `0x0006E000`)
- **Faulting Address**: `0x300144eb` (RVA `0x000144EB` in `BINK` section)
- **Faulting Operation**: Read of address `0x00000000` (`0xC0000005`)
- **CPU Registers**: `EAX = 0x00000000`, `EDX = 0x00000000`, `EIP = 0x300144eb`

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

**Root Cause**: When `trl.exe` enters its intro sequence at `VA 0x0045D0C0`, it calls `PlayMovie("nvidia")` at `VA 0x00416480`. Inside `PlayMovie`, `BinkSetSoundSystem(_BinkOpenDirectSound@4, 0)` fails to bind a DirectSound cooperative level on Windows 11, leaving `[0x300605FC]` set to 0. `trl.exe` ignores the return value and immediately calls `BinkOpen("nvidia.bik")`. Bink parses the audio track and attempts to create the secondary sound buffer via `CreateSoundBuffer`, crashing on `mov edx, [eax]`.

---

## 2. Kazakhstan Parachute Drop Crash (`0x005c136b`)

### Symptoms
The game launches and plays normally, but when starting the **Kazakhstan — Project Carbonek** level (`russia11`), the game crashes immediately upon Lara jumping off the cliff with her parachute.

### Solution
1. In the main menu, go to **Options** -> **Display Settings** (or Graphics Options).
2. Set **Next Generation Content** to **OFF**.
3. Load the Kazakhstan level and proceed through the parachute drop.
4. Once you land on the facility roof and trigger the first checkpoint, you may continue playing.

### Technical Analysis
- **Faulting Module**: `trl.exe`
- **Faulting Address**: `0x005c136b` (RVA `0x001C136B` in `.text`)
- **Faulting Operation**: Read of address `0x0323fa80` (`0xC0000005`)
- **CPU Registers**: `EAX = 0x0323fa80`, `EBX = 0x0b3c60a0`, `EIP = 0x005c136b`

Disassembly of `trl.exe` at `0x005C133A`:

```assembly
005C133A: mov eax, [ebx+18h]         ; Load attachment bone index for parachute cloth
...
005C135F: jl 0x005C1374              ; Only checks if index < 0 (no upper bound check!)
005C1361: shl eax, 4                 ; Multiplies index by 16 (sizeof 4D vector)
005C1364: add eax, 0x0113F880        ; Base address of bone matrix array in .data
005C136B: movaps xmm1, [eax]         ; Crash: Read of address 0x0323fa80
005C136E: addps xmm0, xmm1
```

**Root Cause**: In `ikcloth.cpp` (`G2Instance_BuildClothTransforms`), the Next-Gen parachute model has an uninitialized attachment vertex index of `2,162,720` (`0x00210020`). Because the code only checks for negative values (`jl`), it calculates an offset 34 MB beyond the end of the `.data` segment (`0x0113F880 + 0x02100200 = 0x0323fa80`). When the SSE instruction `movaps xmm1, [eax]` attempts to read from this unmapped memory address, a fatal Access Violation occurs. In Last-Gen mode (Next-Gen OFF), the standard parachute asset avoids this uninitialized vertex index.

---

## Why the Common "DEP Fix" is a Myth

Older internet forum guides frequently recommend disabling Windows Data Execution Prevention (DEP) for `trl.exe`:
- A true DEP violation is an **Execute** access violation attempting to execute code from non-executable data pages (`PAGE_READWRITE` / `PAGE_NOACCESS`).
- Both of these crashes are **Read** violations (`Read of 0x00000000` in Bink and `Read of 0x0323fa80` in `trl.exe`) occurring from legitimate executable code pages. Altering DEP settings cannot prevent either crash.

---

## Modern Hardware Configuration (GeForce RTX Series)

1. **Keep "Next Generation Content" Disabled**: Beyond the Kazakhstan parachute crash, the 2006 Xbox 360 shader pipeline uses legacy FP16 blend paths that cause random crashes in water areas and severe texture flickering on modern GeForce RTX GPUs.
2. **Aspect Ratio and Resolution**: Set your native resolution (2560 x 1440 or 4K) in options or by running `trl.exe -setup`. Ensure "Widescreen" is enabled.

---

## License
MIT License. See [LICENSE](LICENSE) for details.
