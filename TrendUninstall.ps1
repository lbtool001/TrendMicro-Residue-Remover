if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Elevating to Administrator..." -ForegroundColor Cyan
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$url = "https://www.dropbox.com/scl/fi/za2w68je3oy0yaksu4hig/V1ESUninstallTool.zip?rlkey=2paxcfiksbtauspboslwlvk4i&st=h9npam3m&dl=1"
$destDir = "C:\Temp\TrendUninstall"
$zipPath = Join-Path $destDir "V1ESUninstallTool.zip"
$exePath = Join-Path $destDir "V1ESUninstallTool.exe"

try {
    if (Test-Path $destDir) { Remove-Item $destDir -Recurse -Force }
    New-Item -Path $destDir -ItemType Directory -Force | Out-Null 

    Write-Host "Downloading Files..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $url -OutFile $zipPath -ErrorAction Stop

    Write-Host "Extracting files..." -ForegroundColor Magenta
    Expand-Archive -Path $zipPath -DestinationPath $destDir -Force

    $realExePath = Get-ChildItem -Path $destDir -Filter "V1ESUninstallTool.exe" -Recurse | Select-Object -First 1 -ExpandProperty FullName

    if ($realExePath) {
        Write-Host "Running Uninstall Tool: $(Split-Path $realExePath -Leaf)" -ForegroundColor Yellow
        Start-Process -FilePath $realExePath -Wait -PassThru

        Write-Host "`nUninstallation process complete." -ForegroundColor Green
        $choice = Read-Host "Delete files at '$destDir'? [Y/N]"

        if ($choice -eq "Y" -or $choice -eq "y") {
            Remove-Item -Path $destDir -Recurse -Force
            Write-Host "All files and folders deleted successfully." -ForegroundColor Gray
        } else {
            Write-Host "Cleanup skipped. Files remain at $destDir." -ForegroundColor White
        }
    } else {
        throw "Could not find V1ESUninstallTool.exe inside the extracted files."
    }
}
catch {
    Write-Host "`n[ERROR]: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nPress any key to close this window..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
