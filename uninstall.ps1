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

    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
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

$temporaryPath = $null
$replacementBackupPath = $null

try {
    if ([string]::IsNullOrWhiteSpace($ExecutablePath)) {
        $ExecutablePath = Join-Path -Path $PSScriptRoot -ChildPath 'amrts.exe'
    }

    $ExecutablePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ExecutablePath)
    $backupPath = "$ExecutablePath.backup"

    if (-not (Test-Path -LiteralPath $backupPath -PathType Leaf)) {
        throw "Backup not found: $backupPath. No files were modified."
    }

    $backupHash = Get-Sha256 -Path $backupPath
    $backupBytes = Read-BytesAtOffset -Path $backupPath -Offset $PatchOffset -Count $OriginalBytes.Length
    if ($backupHash -ne $SupportedSha256 -or -not (Test-ByteSequence -Actual $backupBytes -Expected $OriginalBytes)) {
        throw "Backup is not the supported clean GOG executable. No files were modified."
    }

    if (Test-Path -LiteralPath $ExecutablePath) {
        if (-not (Test-Path -LiteralPath $ExecutablePath -PathType Leaf)) {
            throw "The executable path exists but is not a file: $ExecutablePath"
        }

        $currentHash = Get-Sha256 -Path $ExecutablePath
        $currentBytes = Read-BytesAtOffset -Path $ExecutablePath -Offset $PatchOffset -Count $PatchedBytes.Length

        if ($currentHash -eq $SupportedSha256 -and (Test-ByteSequence -Actual $currentBytes -Expected $OriginalBytes)) {
            Write-Host 'Army Men RTS - Improved Building Placement is already uninstalled.'
            Write-Host "Clean executable: $ExecutablePath"
            exit 0
        }

        if ($currentHash -ne $PatchedSha256 -or -not (Test-ByteSequence -Actual $currentBytes -Expected $PatchedBytes)) {
            throw "Current amrts.exe is neither the supported clean file nor this mod's exact patched file. No files were modified."
        }
    }

    $gameDirectory = [System.IO.Path]::GetDirectoryName($ExecutablePath)
    $temporaryPath = Join-Path $gameDirectory ('.amrts.improved-building-placement.restore.' + [guid]::NewGuid().ToString('N') + '.tmp')
    [System.IO.File]::Copy($backupPath, $temporaryPath, $false)

    if ((Get-Sha256 -Path $temporaryPath) -ne $SupportedSha256) {
        throw 'Temporary restore copy failed verification. No files were modified.'
    }

    if (Test-Path -LiteralPath $ExecutablePath -PathType Leaf) {
        $replacementBackupPath = Join-Path $gameDirectory ('.amrts.improved-building-placement.rollback.' + [guid]::NewGuid().ToString('N') + '.tmp')
        [System.IO.File]::Replace($temporaryPath, $ExecutablePath, $replacementBackupPath, $true)
    }
    else {
        [System.IO.File]::Move($temporaryPath, $ExecutablePath)
    }
    $temporaryPath = $null

    $restoredHash = Get-Sha256 -Path $ExecutablePath
    $restoredBytes = Read-BytesAtOffset -Path $ExecutablePath -Offset $PatchOffset -Count $OriginalBytes.Length
    if ($restoredHash -ne $SupportedSha256 -or -not (Test-ByteSequence -Actual $restoredBytes -Expected $OriginalBytes)) {
        throw 'Final restore verification failed.'
    }

    if ($null -ne $replacementBackupPath) {
        Remove-Item -LiteralPath $replacementBackupPath -Force
        $replacementBackupPath = $null
    }

    Write-Host 'Army Men RTS - Improved Building Placement uninstalled successfully.'
    Write-Host "Restored executable: $ExecutablePath"
    Write-Host "SHA-256: $restoredHash"
    Write-Host "Backup retained: $backupPath"
    exit 0
}
catch {
    Write-Error $_.Exception.Message
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
