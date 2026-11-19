# AutoPush_Calculator.ps1
# Urmareste fisierul de pe Desktop si, la fiecare modificare salvata,
# il copiaza in repo si face commit + push pe GitHub (Vercel se actualizeaza singur).

$Sursa   = "C:\Users\necul\Desktop\calculator_fiscal_client_friendly_2025.html"
$Repo    = "C:\Users\necul\Documents\CalculatorFiscal"
$Git     = "C:\Program Files\Git\cmd\git.exe"
$Log     = Join-Path $Repo "autopush.log"
$Interval = 5   # secunde intre verificari

function Write-Log($msg) {
    $line = "{0}  {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $msg
    Add-Content -Path $Log -Value $line -Encoding UTF8
}

function Get-Hash($path) {
    try { (Get-FileHash -Path $path -Algorithm SHA256 -ErrorAction Stop).Hash } catch { $null }
}

$dest = Join-Path $Repo (Split-Path $Sursa -Leaf)
$ultimul = Get-Hash $dest
Write-Log "Pornit. Urmaresc $Sursa"

while ($true) {
    Start-Sleep -Seconds $Interval
    if (-not (Test-Path $Sursa)) { continue }

    $h = Get-Hash $Sursa
    if (-not $h -or $h -eq $ultimul) { continue }

    # asteapta sa termine salvarea (fisierul sa nu se mai schimbe 2 secunde)
    Start-Sleep -Seconds 2
    if ((Get-Hash $Sursa) -ne $h) { continue }

    try {
        Copy-Item -Path $Sursa -Destination $dest -Force -ErrorAction Stop
        & $Git -C $Repo add -- (Split-Path $Sursa -Leaf) | Out-Null
        & $Git -C $Repo diff --cached --quiet
        if ($LASTEXITCODE -ne 0) {
            $msg = "Actualizare calculator " + (Get-Date -Format "yyyy-MM-dd HH:mm")
            & $Git -C $Repo commit -m $msg | Out-Null
        }
        & $Git -C $Repo push origin main 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            $ultimul = $h
            Write-Log "Push reusit."
        } else {
            Write-Log "Push esuat (cod $LASTEXITCODE) - reincerc la urmatoarea verificare."
        }
    } catch {
        Write-Log "Eroare: $($_.Exception.Message)"
    }
}
