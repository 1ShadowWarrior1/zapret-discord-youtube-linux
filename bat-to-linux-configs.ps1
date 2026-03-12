# Конвертация .bat конфигов zapret в .conf для Linux (run_zapret.sh)
# Запуск: из каталога zapret-discord-youtube-xxx: .\bat-to-linux-configs.ps1
# Либо: .\bat-to-linux-configs.ps1 -BatDir "C:\path\to\zapret-discord-youtube-xxx"

param(
    [string]$BatDir = $PSScriptRoot,
    [string]$OutDir = ""
)

$ErrorActionPreference = "Stop"
if (-not $OutDir) { $OutDir = Join-Path $BatDir "linux-configs" }

$linuxConfigs = Join-Path $BatDir "linux-configs"
if (-not (Test-Path $linuxConfigs)) {
    New-Item -ItemType Directory -Path $linuxConfigs -Force | Out-Null
}

$batFiles = Get-ChildItem -Path $BatDir -Filter "*.bat" -File |
    Where-Object { $_.Name -like "general*" -and $_.Name -ne "service.bat" }

function Get-SafeConfName($batName) {
    $base = [System.IO.Path]::GetFileNameWithoutExtension($batName)
    if ($base -eq "general") { return "general" }
    $base = $base -replace "general\s*\(?", "_"
    $base = $base -replace "\)", ""
    $base = $base -replace "\s+", "_" -replace "_+", "_" -replace "^_", ""
    if ([string]::IsNullOrWhiteSpace($base)) { return "general" }
    "general_$base"
}

function Convert-BatLineToLinux($line) {
    $line = $line.Trim()
    if ($line -match "\^$") { $line = $line.TrimEnd("^").Trim() }
    $line = $line -replace "\^!", "!"
    $line = $line -replace "%BIN%", "@FAKE@/"
    $line = $line -replace "%LISTS%", "@LISTS_DIR@/"
    if ($line -match "--filter-tcp=") {
        $line = $line -replace "%GameFilter%", "@GAME_TCP_NFQ@"
    }
    if ($line -match "--filter-udp=") {
        $line = $line -replace "%GameFilter%", "@GAME_UDP_NFQ@"
    }
    $line = $line -replace "\\", "/"
    return $line
}

$converted = 0
foreach ($bat in $batFiles) {
    $lines = Get-Content -Path $bat.FullName -Encoding UTF8
    $filterLines = New-Object System.Collections.ArrayList

    foreach ($line in $lines) {
        $trimmed = $line.Trim()
        if ($trimmed -match "^\s*--filter-") {
            $linuxLine = Convert-BatLineToLinux $trimmed
            if ($linuxLine.Length -gt 0) {
                [void]$filterLines.Add($linuxLine)
            }
        }
    }

    if ($filterLines.Count -eq 0) {
        Write-Host "Skip $($bat.Name): no --filter- lines"
        continue
    }

    $confName = Get-SafeConfName $bat.Name
    $confPath = Join-Path $OutDir "$confName.conf"
    $header = "# Generated from $($bat.Name) - run bat-to-linux-configs.ps1 to update"
    $content = $header + "`n" + ($filterLines -join "`n")
    [System.IO.File]::WriteAllText($confPath, $content, [System.Text.UTF8Encoding]::new($false))
    Write-Host "OK $($bat.Name) -> $confName.conf ($($filterLines.Count) filters)"
    $converted++

    if ($bat.Name -eq "general.bat") {
        $defaultPath = Join-Path $OutDir "default.conf"
        [System.IO.File]::WriteAllText($defaultPath, $content.Replace("`r`n", "`n"), [System.Text.UTF8Encoding]::new($false))
        Write-Host "    + default.conf (copy for run_zapret.sh default)"
    }
}

Write-Host ""
Write-Host "Done: $converted configs written to $OutDir"
Write-Host "On Linux: ./run_zapret.sh list   then   ./run_zapret.sh <config_name>"
