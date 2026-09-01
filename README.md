# Army Men RTS – Improved Building Placement

A small binary patch for the GOG release of *Army Men RTS*. It allows buildings to be placed directly beside other buildings, walls, and blocked map edges when only the game's extra spacing rule is triggered. Actual footprint overlap remains blocked.

No game executable or other game files are included.

## Supported version

- Release: GOG
- File: `amrts.exe`
- Original SHA-256: `34C9CACFCD42A816A5A9E886FBE18AE69CA2B82BDB7ED95588772F3079777B59`
- Patched SHA-256: `CB88A1F148BC9717F3B11B1310103F62E08CB3C3FA70D3DE76BB5A9C24D92F95`

Other executable versions are rejected without modification.

## Installation

1. Download and extract the latest release ZIP.
2. Copy `install.ps1` and `uninstall.ps1` into the directory containing `amrts.exe`.
3. Open PowerShell in that directory.
4. Run:

   ```powershell
   .\install.ps1
   ```

The installer verifies the complete executable hash and the original bytes before changing anything. It creates `amrts.exe.backup`, patches a temporary copy, verifies the complete patched hash, and only then replaces `amrts.exe`.

If PowerShell blocks local scripts, run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

To keep the scripts elsewhere, pass the executable explicitly:

```powershell
.\install.ps1 -ExecutablePath "E:\GOG Galaxy\Games\Army Men RTS\amrts.exe"
```

Close the game before installing or uninstalling.

## Uninstallation

Run from the game directory:

```powershell
.\uninstall.ps1
```

The uninstaller verifies both the backup and the current patched executable before restoring the clean file. It keeps the verified backup after restoration.

## Technical details

The supported executable uses image base `0x00400000`. At VA `0x00584EC7` (file offset `0x00184EC7`), the patch replaces:

```text
F7 DB 1B DB 83 C3 06
```

with:

```text
8D 1C 9D 01 00 00 00
```

The original result logic maps `onFoot = 0` to the spacing-only rejection and `onFoot = 1` to actual footprint overlap. The replacement maps the spacing-only case to `PR_OK` while preserving the overlap result.

## Scope

The scripts do not include or modify `base.x` or `winmm.dll`. They only patch the exact supported `amrts.exe`. This project is not affiliated with or endorsed by the game's publishers or distributors. Use it with a legally obtained copy of the game.

## License

The patching scripts and documentation are licensed under the [MIT License](LICENSE). The game and its files are not covered by this license.
