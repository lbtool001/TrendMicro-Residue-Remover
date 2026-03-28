$url = "https://www.dropbox.com/scl/fi/your_id/V1ESUninstallTool.zip?rlkey=your_key&dl=1"
$destDir = "C:\Temp\TrendUninstall"
$zipPath = Join-Path $destDir "V1ESUninstallTool.zip"

try {
    if (Test-Path $destDir) { Remove-Item $destDir -Recurse -Force }
    New-Item -Path $destDir -ItemType Directory -Force | Out-Null 

    Write-Host "Downloading ZIP from Dropbox..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $url -OutFile $zipPath -ErrorAction Stop

    Write-Host "Extracting files..." -ForegroundColor Magenta
    Expand-Archive -Path $zipPath -DestinationPath $destDir -Force

    $realExePath = Get-ChildItem -Path $destDir -Filter "V1ESUninstallTool.exe" -Recurse | Select-Object -First 1 -ExpandProperty FullName

    if ($realExePath) {
        Write-Host "Running Uninstall Tool: $(Split-Path $realExePath -Leaf)" -ForegroundColor Yellow
        Start-Process -FilePath $realExePath -Wait -PassThru
        
        Write-Host "`nUninstallation process complete." -ForegroundColor Green
        $choice = Read-Host "Would you like to delete the downloaded ZIP and all extracted files at '$destDir'? [Y/N]"

        if ($choice -match "y|Y") {
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

Write-Host "`nProcess finished. Press any key to close..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
