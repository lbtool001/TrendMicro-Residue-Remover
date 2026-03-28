if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Elevating privileges..." -ForegroundColor Cyan
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -Command `"& {$(Get-Content $PSCommandPath | Out-String)}`"" -Verb RunAs
    exit
}

$url = "https://drive.google.com/uc?export=download&id=18lfyIfuhiXKLlx0_iTm-F7p7KvmgYoAT"
$destDir = "C:\Temp\TrendUninstall"
$exePath = Join-Path $destDir "V1ESUninstallTool.exe"

if (-not (Test-Path $destDir)) { 
    New-Item -Path $destDir -ItemType Directory | Out-Null 
}

Write-Host "Downloading tool..." -ForegroundColor Cyan
try {
    Invoke-WebRequest -Uri $url -OutFile $exePath -ErrorAction Stop
} catch {
    Write-Host "Download failed! Check your internet or URL." -ForegroundColor Red
    Pause
    exit
}

if (Test-Path $exePath) {
    Write-Host "Running Uninstall Tool. Please wait for it to finish..." -ForegroundColor Yellow
    $process = Start-Process -FilePath $exePath -Wait -PassThru
} else {
    Write-Host "File not found at $exePath" -ForegroundColor Red
    Pause
    exit
}

Write-Host "`nUninstallation process complete. Update your sheet now!" -ForegroundColor Green
$choice = Read-Host "Would you like to delete the files and folders at '$destDir'? [Y/N]"

if ($choice -eq "Y") {
    Remove-Item -Path $destDir -Recurse -Force
    Write-Host "Directory deleted successfully." -ForegroundColor Gray
}
else {
    Write-Host "Cleanup skipped. Files remain at $destDir." -ForegroundColor White
}

Write-Host "`nScript finished. Press any key to close..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
