$url = "https://www.dropbox.com/scl/fi/your_id/V1ESUninstallTool.zip?rlkey=your_key&dl=1"
$destDir = "C:\Temp\TrendUninstall"
$zipPath = Join-Path $destDir "V1ESUninstallTool.zip"

try {
    if (Test-Path $destDir) { Remove-Item $destDir -Recurse -Force }
    New-Item -Path $destDir -ItemType Directory -Force | Out-Null 

    Write-Host "Downloading ZIP from Dropbox..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $url -OutFile $zipPath -UserAgent "Mozilla/5.0" -ErrorAction Stop

    $fileContent = Get-Content $zipPath -TotalCount 1
    if ($fileContent -notmatch "PK") {
        throw "Downloaded file is not a valid ZIP. Check your Dropbox link (ensure it ends in dl=1)."
    }

    Write-Host "Extracting files..." -ForegroundColor Magenta
    Expand-Archive -Path $zipPath -DestinationPath $destDir -Force

    $realExePath = Get-ChildItem -Path $destDir -Filter "V1ESUninstallTool.exe" -Recurse | Select-Object -First 1 -ExpandProperty FullName

    if ($realExePath) {
        Write-Host "Running Uninstall Tool..." -ForegroundColor Yellow
        Start-Process -FilePath $realExePath -Wait -PassThru

        Write-Host "`nUninstallation process complete." -ForegroundColor Green
        $choice = Read-Host "Delete temp files at '$destDir'? [Y/N]"

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

Write-Host "`nProcess finished. Press any key to close..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
