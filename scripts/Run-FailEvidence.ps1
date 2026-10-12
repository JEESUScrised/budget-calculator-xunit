$ErrorActionPreference = "Continue"
$env:DOTNET_CLI_UI_LANGUAGE = "en"
$env:DOTNET_NOLOGO = "1"
$root = "C:\Users\user\Desktop\budget-calculator-xunit-red-817d011"
$outRoot = "C:\Users\user\Desktop\budget-calculator-xunit\screenshots"
$transcript = Join-Path $outRoot "02_insurance_test_failed.txt"
$ready = Join-Path $outRoot "_fail_ready.flag"

Set-Location $root
try {
    $host.UI.RawUI.BufferSize = New-Object Management.Automation.Host.Size(160, 80)
    $host.UI.RawUI.WindowSize = New-Object Management.Automation.Host.Size(120, 36)
} catch {}

Clear-Host
Write-Host "PS $root>"
Write-Host "dotnet test --nologo"
Write-Host ""

& dotnet restore --nologo | Out-Host
& dotnet build --nologo | Out-Host
Write-Host ""

$raw = & dotnet test --nologo 2>&1 | ForEach-Object { $_.ToString() }
$raw | ForEach-Object { Write-Host $_ }
# Unmodified console transcript
($raw -join "`r`n") + "`r`n" | Set-Content -Path $transcript -Encoding utf8
Write-Host ""
Write-Host "ExitCode=$LASTEXITCODE  (Expected fail: 525 vs 2500)"
# Signal outer capturer that content is on screen
Set-Content -Path $ready -Value $PID -Encoding utf8
Start-Sleep -Seconds 8
