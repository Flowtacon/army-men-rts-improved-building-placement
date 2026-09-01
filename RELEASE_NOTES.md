# v1.0.0

Initial release of Army Men RTS – Improved Building Placement.

- Allows construction directly beside buildings, walls, and blocked map edges when only the extra spacing rule applies.
- Keeps actual footprint overlap blocked.
- Supports the GOG `amrts.exe` with original SHA-256 `34C9CACFCD42A816A5A9E886FBE18AE69CA2B82BDB7ED95588772F3079777B59`.
- Verifies the original executable and patch bytes before changing the file.
- Creates and verifies `amrts.exe.backup`.
- Verifies the complete patched SHA-256 after installation.
- Restores the verified clean backup with `uninstall.ps1`.

No game files are included in the release.
