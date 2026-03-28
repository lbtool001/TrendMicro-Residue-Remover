if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Elevating to Administrator..." -ForegroundColor Cyan
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -Command `"& {$(Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/lbtool001/TrendMicro-Residue-Remover/refs/heads/main/TrendUninstall.ps1')}`"" -Verb RunAs
    exit
}

$url = "https://www.dropbox.com/scl/fi/za2w68je3oy0yaksu4hig/V1ESUninstallTool.zip?rlkey=2paxcfiksbtauspboslwlvk4i&st=h9npam3m&dl=1"
$destDir = "C:\Temp\TrendUninstall"
$zipPath = Join-Path $destDir "V1ESUninstallTool.zip"

try {
    if (Test-Path $destDir) { Remove-Item $destDir -Recurse -Force }
    New-Item -Path $destDir -ItemType Directory -Force | Out-Null 

    Write-Host "Downloading files..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $url -OutFile $zipPath -UserAgent "Mozilla/5.0" -ErrorAction Stop

    $firstTwoBytes = Get-Content $zipPath -Encoding Byte -TotalCount 2
    if (-not ($firstTwoBytes[0] -eq 80 -and $firstTwoBytes[1] -eq 75)) {
        throw "Download file error!."
    }

    Write-Host "Extracting files..." -ForegroundColor Magenta
    Expand-Archive -Path $zipPath -DestinationPath $destDir -Force

    $realExePath = Get-ChildItem -Path $destDir -Filter "V1ESUninstallTool.exe" -Recurse | Select-Object -First 1 -ExpandProperty FullName

    if ($realExePath) {
        Write-Host "Running Uninstall Tool..." -ForegroundColor Yellow
        Start-Process -FilePath $realExePath -Wait -PassThru

        Write-Host "`nUninstallation process complete." -ForegroundColor Green
        $choice = Read-Host "Would you like to delete the temp files at '$destDir'? [Y/N]"

        if ($choice -match "y|Y") {
            Remove-Item -Path $destDir -Recurse -Force
            Write-Host "Cleanup successful." -ForegroundColor Gray
        }
    } else {
        throw "Could not find V1ESUninstallTool.exe inside the ZIP."
    }
}
catch {
    Write-Host "`n[ERROR]: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nProcess finished. Press any key to close..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
