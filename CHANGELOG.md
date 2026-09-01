# Changelog

All notable changes to this project are documented here.

## [1.1.0] - 2026-09-01

- Added `Install Mod.cmd` and `Uninstall Mod.cmd` for double-click installation and removal.
- Kept the PowerShell execution-policy bypass limited to each launcher process.
- Added clear success, concise failure, missing-file, and access-denied guidance.
- Removed reliance on PowerShell module autoloading for SHA-256 verification.
- Updated the installation documentation for the recommended launcher workflow.
- Kept the binary patch and supported executable hashes unchanged.

## [1.0.0] - 2026-09-01

- Added the improved building placement patch for the supported GOG executable.
- Preserved rejection of actual building footprint overlap.
- Added full-file hash and original-byte verification before installation.
- Added automatic clean executable backup and verified restoration.
- Added complete patched-file verification after installation.
