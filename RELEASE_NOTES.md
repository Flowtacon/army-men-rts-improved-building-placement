# v1.1.0

This release adds a double-click installation and uninstallation workflow. The binary patch itself is unchanged from v1.0.0.

- Added `Install Mod.cmd`: place the release files beside `amrts.exe` and double-click it.
- Added `Uninstall Mod.cmd`: double-click it to restore the verified backup.
- The launchers keep the window open so the result or error remains visible.
- The PowerShell execution-policy bypass applies only to the launched process and does not change system settings.
- SHA-256 verification now uses the built-in .NET implementation and does not depend on PowerShell module autoloading.
- The original hash checks, byte checks, backup verification, and patched-file verification remain unchanged.
- Supports the GOG `amrts.exe` with original SHA-256 `34C9CACFCD42A816A5A9E886FBE18AE69CA2B82BDB7ED95588772F3079777B59`.

No game files are included in the release.
