$ErrorActionPreference = "Continue"
$env:DOTNET_CLI_UI_LANGUAGE = "en"
$env:DOTNET_NOLOGO = "1"
$root = "C:\Users\user\Desktop\budget-calculator-xunit"
$outRoot = Join-Path $root "screenshots"
$reports = Join-Path $root "reports"
$transcript = Join-Path $outRoot "03_all_tests_passed.txt"
$covTxt = Join-Path $outRoot "04_coverage_summary.txt"
$readyPass = Join-Path $outRoot "_pass_ready.flag"
$readyCov = Join-Path $outRoot "_cov_ready.flag"

Set-Location $root
try {
    $host.UI.RawUI.BufferSize = New-Object Management.Automation.Host.Size(160, 90)
    $host.UI.RawUI.WindowSize = New-Object Management.Automation.Host.Size(120, 40)
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
($raw -join "`r`n") + "`r`n" | Set-Content -Path $transcript -Encoding utf8
Write-Host ""
Write-Host "ExitCode=$LASTEXITCODE"
Set-Content -Path $readyPass -Value $PID -Encoding utf8
Start-Sleep -Seconds 6

Clear-Host
Write-Host "PS $root>"
Write-Host 'dotnet test --collect:"XPlat Code Coverage" --results-directory TestResults --nologo'
Write-Host ""

if (Test-Path (Join-Path $root "TestResults")) {
    Remove-Item -Recurse -Force (Join-Path $root "TestResults")
}

$covRaw = & dotnet test --collect:"XPlat Code Coverage" --results-directory TestResults --nologo 2>&1 | ForEach-Object { $_.ToString() }
$covRaw | ForEach-Object { Write-Host $_ }

$cobertura = Get-ChildItem -Recurse (Join-Path $root "TestResults") -Filter "coverage.cobertura.xml" | Select-Object -First 1
if (-not $cobertura) { throw "Cobertura XML not found" }
Copy-Item -Force $cobertura.FullName (Join-Path $reports "coverage.cobertura.xml")

[xml]$xml = Get-Content -Raw $cobertura.FullName
$controller = Select-Xml -Xml $xml -XPath "//class[contains(@name,'BudgetController')]" | Select-Object -First 1
$lineRate = [double]$controller.Node.GetAttribute("line-rate")
$branchRate = [double]$controller.Node.GetAttribute("branch-rate")

$summary = @()
$summary += "PS $root>"
$summary += 'dotnet test --collect:"XPlat Code Coverage" --results-directory TestResults --nologo'
$summary += ""
$summary += $covRaw
$summary += ""
$summary += "Cobertura file: $($cobertura.FullName)"
$summary += ("BudgetController line-rate={0:P2} branch-rate={1:P2}" -f $lineRate, $branchRate)
($summary -join "`r`n") + "`r`n" | Set-Content -Path $covTxt -Encoding utf8

Write-Host ""
Write-Host ("BudgetController line-rate={0:P2} branch-rate={1:P2}" -f $lineRate, $branchRate)
Set-Content -Path $readyCov -Value $PID -Encoding utf8
Start-Sleep -Seconds 8
