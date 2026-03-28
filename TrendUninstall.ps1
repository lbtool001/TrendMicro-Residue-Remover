$ErrorActionPreference = "Stop"

$scriptUrl = "https://raw.githubusercontent.com/lbtool001/TrendMicro-Residue-Remover/refs/heads/main/TrendUninstall.ps1"

if (-not ([Security.Principal.WindowsPrincipal]([Security.Principal.WindowsIdentity]::GetCurrent())
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {

    Write-Host "Requesting administrator permission..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList "-NoExit -ExecutionPolicy Bypass -Command `"irm $scriptUrl | iex`"" -Verb RunAs
    return
}

$url = "https://www.dropbox.com/scl/fi/za2w68je3oy0yaksu4hig/V1ESUninstallTool.zip?rlkey=2paxcfiksbtauspboslwlvk4i&st=h9npam3m&dl=1"
$destDir = "C:\Temp\TrendUninstall"
$zipPath = Join-Path $destDir "V1ESUninstallTool.zip"

try {

    if (Test-Path $destDir) {
        Remove-Item $destDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    New-Item -ItemType Directory -Path $destDir -Force | Out-Null

    Write-Host "Downloading uninstall tool..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $url -OutFile $zipPath -UserAgent "Mozilla/5.0"

    $fs = [System.IO.File]::OpenRead($zipPath)
    $bytes = New-Object byte[] 2
    $fs.Read($bytes, 0, 2) | Out-Null
    $fs.Close()

    if (-not ($bytes[0] -eq 80 -and $bytes[1] -eq 75)) {
        throw "Download failed or file is not a valid ZIP."
    }

    Write-Host "Extracting files...." -ForegroundColor Magenta
    Expand-Archive -Path $zipPath -DestinationPath $destDir -Force

    $exe = Get-ChildItem -Path $destDir -Filter "V1ESUninstallTool.exe" -Recurse -ErrorAction SilentlyContinue |
           Select-Object -First 1 -ExpandProperty FullName

    if (-not $exe) {
        throw "V1ESUninstallTool.exe not found."
    }

    Write-Host "Launching uninstall tool..." -ForegroundColor Green
    Start-Process -FilePath $exe -Wait

    Write-Host "`nUninstallation process finished." -ForegroundColor Green

    $choice = Read-Host "Delete temporary files in $destDir ? (Y/N)"

    if ($choice -match "^[Yy]$") {
        Remove-Item $destDir -Recurse -Force
        Write-Host "Temporary files deleted." -ForegroundColor Gray
    }
    else {
        Write-Host "Temporary files kept at: $destDir" -ForegroundColor Gray
    }

}
catch {
    Write-Host "`n[ERROR] $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nPress any key to close..." -ForegroundColor DarkGray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
