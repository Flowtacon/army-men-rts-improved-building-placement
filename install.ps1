[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string] $ExecutablePath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$SupportedSha256 = '34C9CACFCD42A816A5A9E886FBE18AE69CA2B82BDB7ED95588772F3079777B59'
$PatchedSha256 = 'CB88A1F148BC9717F3B11B1310103F62E08CB3C3FA70D3DE76BB5A9C24D92F95'
$PatchOffset = 0x00184EC7
[byte[]] $OriginalBytes = 0xF7, 0xDB, 0x1B, 0xDB, 0x83, 0xC3, 0x06
[byte[]] $PatchedBytes = 0x8D, 0x1C, 0x9D, 0x01, 0x00, 0x00, 0x00

function Get-Sha256 {
    param([Parameter(Mandatory)][string] $Path)

    $stream = [System.IO.File]::Open($Path, 'Open', 'Read', 'Read')
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
        return ([System.BitConverter]::ToString($sha256.ComputeHash($stream))).Replace('-', '')
    }
    finally {
        $sha256.Dispose()
        $stream.Dispose()
    }
}

function Read-BytesAtOffset {
    param(
        [Parameter(Mandatory)][string] $Path,
        [Parameter(Mandatory)][long] $Offset,
        [Parameter(Mandatory)][int] $Count
    )

    $stream = [System.IO.File]::Open($Path, 'Open', 'Read', 'Read')
    try {
        if ($stream.Length -lt ($Offset + $Count)) {
            throw "File is too short to contain the patch location."
        }

        $null = $stream.Seek($Offset, [System.IO.SeekOrigin]::Begin)
        [byte[]] $buffer = New-Object byte[] $Count
        $read = $stream.Read($buffer, 0, $Count)
        if ($read -ne $Count) {
            throw "Could not read the complete byte sequence at the patch location."
        }

        return ,$buffer
    }
    finally {
        $stream.Dispose()
    }
}

function Test-ByteSequence {
    param(
        [Parameter(Mandatory)][byte[]] $Actual,
        [Parameter(Mandatory)][byte[]] $Expected
    )

    if ($Actual.Length -ne $Expected.Length) {
        return $false
    }

    for ($i = 0; $i -lt $Expected.Length; $i++) {
        if ($Actual[$i] -ne $Expected[$i]) {
            return $false
        }
    }

    return $true
}

function Assert-CleanBackup {
    param([Parameter(Mandatory)][string] $Path)

    if ((Get-Sha256 -Path $Path) -ne $SupportedSha256) {
        throw "Existing backup is not the supported clean GOG executable: $Path"
    }

    $bytes = Read-BytesAtOffset -Path $Path -Offset $PatchOffset -Count $OriginalBytes.Length
    if (-not (Test-ByteSequence -Actual $bytes -Expected $OriginalBytes)) {
        throw "Existing backup does not contain the expected original bytes: $Path"
    }
}

$temporaryPath = $null
$replacementBackupPath = $null

try {
    if ([string]::IsNullOrWhiteSpace($ExecutablePath)) {
        $ExecutablePath = Join-Path -Path $PSScriptRoot -ChildPath 'amrts.exe'
    }

    if (-not (Test-Path -LiteralPath $ExecutablePath -PathType Leaf)) {
        throw "amrts.exe was not found. Place this script in the game directory or pass -ExecutablePath."
    }

    $ExecutablePath = (Get-Item -LiteralPath $ExecutablePath).FullName
    $backupPath = "$ExecutablePath.backup"
    $currentHash = Get-Sha256 -Path $ExecutablePath
    $currentBytes = Read-BytesAtOffset -Path $ExecutablePath -Offset $PatchOffset -Count $OriginalBytes.Length

    if ($currentHash -eq $PatchedSha256 -and (Test-ByteSequence -Actual $currentBytes -Expected $PatchedBytes)) {
        if (-not (Test-Path -LiteralPath $backupPath -PathType Leaf)) {
            throw "The supported patch is already present, but the clean backup is missing. No files were modified."
        }

        Assert-CleanBackup -Path $backupPath
        Write-Host 'Army Men RTS - Improved Building Placement is already installed.'
        Write-Host "Backup: $backupPath"
        exit 0
    }

    if ($currentHash -ne $SupportedSha256) {
        throw "Unsupported Army Men RTS executable (SHA-256: $currentHash). No files were modified."
    }

    if (-not (Test-ByteSequence -Actual $currentBytes -Expected $OriginalBytes)) {
        throw "The executable hash is supported, but the original bytes do not match. No files were modified."
    }

    if (Test-Path -LiteralPath $backupPath) {
        if (-not (Test-Path -LiteralPath $backupPath -PathType Leaf)) {
            throw "The backup path exists but is not a file: $backupPath"
        }
        Assert-CleanBackup -Path $backupPath
    }
    else {
        [System.IO.File]::Copy($ExecutablePath, $backupPath, $false)
        Assert-CleanBackup -Path $backupPath
    }

    $gameDirectory = [System.IO.Path]::GetDirectoryName($ExecutablePath)
    $temporaryPath = Join-Path $gameDirectory ('.amrts.improved-building-placement.' + [guid]::NewGuid().ToString('N') + '.tmp')
    [System.IO.File]::Copy($ExecutablePath, $temporaryPath, $false)

    $stream = [System.IO.File]::Open($temporaryPath, 'Open', 'ReadWrite', 'None')
    try {
        $null = $stream.Seek($PatchOffset, [System.IO.SeekOrigin]::Begin)
        $stream.Write($PatchedBytes, 0, $PatchedBytes.Length)
        $stream.Flush($true)
    }
    finally {
        $stream.Dispose()
    }

    $temporaryBytes = Read-BytesAtOffset -Path $temporaryPath -Offset $PatchOffset -Count $PatchedBytes.Length
    if (-not (Test-ByteSequence -Actual $temporaryBytes -Expected $PatchedBytes)) {
        throw 'Patched byte verification failed. The game executable was not replaced.'
    }

    $temporaryHash = Get-Sha256 -Path $temporaryPath
    if ($temporaryHash -ne $PatchedSha256) {
        throw "Patched file hash verification failed (SHA-256: $temporaryHash). The game executable was not replaced."
    }

    $replacementBackupPath = Join-Path $gameDirectory ('.amrts.improved-building-placement.rollback.' + [guid]::NewGuid().ToString('N') + '.tmp')
    [System.IO.File]::Replace($temporaryPath, $ExecutablePath, $replacementBackupPath, $true)
    $temporaryPath = $null

    $installedHash = Get-Sha256 -Path $ExecutablePath
    $installedBytes = Read-BytesAtOffset -Path $ExecutablePath -Offset $PatchOffset -Count $PatchedBytes.Length
    if ($installedHash -ne $PatchedSha256 -or -not (Test-ByteSequence -Actual $installedBytes -Expected $PatchedBytes)) {
        throw 'Final verification failed. Restore amrts.exe from amrts.exe.backup before starting the game.'
    }

    Remove-Item -LiteralPath $replacementBackupPath -Force
    $replacementBackupPath = $null

    Write-Host 'Army Men RTS - Improved Building Placement installed successfully.'
    Write-Host "Patched executable: $ExecutablePath"
    Write-Host "Backup: $backupPath"
    Write-Host "SHA-256: $installedHash"
    exit 0
}
catch {
    Write-Host ''
    Write-Host ('ERROR: ' + $_.Exception.Message) -ForegroundColor Red
    exit 1
}
finally {
    if ($null -ne $temporaryPath -and (Test-Path -LiteralPath $temporaryPath -PathType Leaf)) {
        Remove-Item -LiteralPath $temporaryPath -Force -ErrorAction SilentlyContinue
    }
    if ($null -ne $replacementBackupPath -and (Test-Path -LiteralPath $replacementBackupPath -PathType Leaf)) {
        Remove-Item -LiteralPath $replacementBackupPath -Force -ErrorAction SilentlyContinue
    }
}
