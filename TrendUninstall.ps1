if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "powershell.exe"
    $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    $psi.Verb = "runas"
    try {
        [System.Diagnostics.Process]::Start($psi) | Out-Null
    } catch {
        Write-Host "Elevation canceled. Exiting..." -ForegroundColor Red
    }
    exit
}

$url = "https://www.dropbox.com/scl/fi/za2w68je3oy0yaksu4hig/V1ESUninstallTool.zip?rlkey=2paxcfiksbtauspboslwlvk4i&st=h9npam3m&dl=1"
$destDir = "C:\Temp\TrendUninstall"
$zipPath = Join-Path $destDir "V1ESUninstallTool.zip"

try {
    if (Test-Path $destDir) { 
        Write-Host "Cleaning existing temp folder..." -ForegroundColor Gray
        Remove-Item $destDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    New-Item -Path $destDir -ItemType Directory -Force | Out-Null

    Write-Host "Downloading ZIP from Dropbox..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $url -OutFile $zipPath -UserAgent "Mozilla/5.0" -MaximumRedirection 5 -ErrorAction Stop

    $fileSize = (Get-Item $zipPath).Length
    if ($fileSize -lt 1024) { throw "Downloaded file is too small. Check the Dropbox link or network." }

    $firstTwoBytes = Get-Content $zipPath -Encoding Byte -TotalCount 2
    if (-not ($firstTwoBytes[0] -eq 80 -and $firstTwoBytes[1] -eq 75)) {
        throw "The downloaded file is not a valid ZIP archive."
    }

    Write-Host "Extracting files..." -ForegroundColor Magenta
    Expand-Archive -Path $zipPath -DestinationPath $destDir -Force

    $realExePath = Get-ChildItem -Path $destDir -Filter "V1ESUninstallTool.exe" -Recurse | Select-Object -First 1 -ExpandProperty FullName
    if (-not $realExePath) { throw "Could not find V1ESUninstallTool.exe inside the ZIP." }

    Write-Host "Running Uninstall Tool..." -ForegroundColor Yellow
    & $realExePath

    # Move out of C:\Temp before deleting
    Set-Location C:\

    $choice = Read-Host "Uninstallation complete. Delete entire C:\Temp folder? [Y/N]"
    if ($choice.Trim().ToUpper() -eq "Y") {
        $deleted = $false
        for ($i=0; $i -lt 5; $i++) {
            try {
                if (Test-Path "C:\Temp") { Remove-Item -Path "C:\Temp" -Recurse -Force }
                $deleted = $true
                break
            } catch {
                Start-Sleep -Milliseconds 500
            }
        }
        if ($deleted) {
            Write-Host "C:\Temp folder and all files deleted successfully." -ForegroundColor Gray
        } else {
            Write-Host "Failed to delete C:\Temp. Some files may still be in use." -ForegroundColor Red
        }
    }

} catch {
    Write-Host "`n[ERROR]: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nProcess finished. Press any key to close..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
