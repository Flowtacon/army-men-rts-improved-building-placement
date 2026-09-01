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
2. Copy all extracted files into the directory containing `amrts.exe`.
3. Double-click **`Install Mod.cmd`**.
4. Read the result and press any key to close the window.

Close the game before installing or uninstalling.

The launcher starts the installer with a process-only PowerShell execution-policy bypass. It does not change the execution policy saved on the computer. The installer still verifies the complete executable hash and the original bytes before changing anything. It creates `amrts.exe.backup`, patches a temporary copy, verifies the complete patched hash, and only then replaces `amrts.exe`.

If writing to the game directory is denied, right-click `Install Mod.cmd` and select **Run as administrator**.

## Uninstallation

Double-click **`Uninstall Mod.cmd`** in the game directory. The uninstaller verifies both the backup and the current patched executable before restoring the clean file. It keeps the verified backup after restoration.

## Manual and advanced use

The PowerShell scripts remain available for inspection and automation. To install manually, open PowerShell in the game directory and run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

To uninstall manually:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\uninstall.ps1
```

To keep the scripts elsewhere, pass the executable explicitly:

```powershell
.\install.ps1 -ExecutablePath "E:\GOG Galaxy\Games\Army Men RTS\amrts.exe"
```

A broadly trusted Authenticode signature requires a certificate issued by a trusted code-signing authority. A self-signed certificate would require every user to install and trust that certificate, so it is not used here. The readable CMD launchers provide double-click installation without making a permanent security-policy change.

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

The release does not include or modify `base.x` or `winmm.dll`. It only patches the exact supported `amrts.exe`. This project is not affiliated with or endorsed by the game's publishers or distributors. Use it with a legally obtained copy of the game.

## License

The patching scripts and documentation are licensed under the [MIT License](LICENSE). The game and its files are not covered by this license.
