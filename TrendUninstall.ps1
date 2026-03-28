if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -Command `"& {$(Get-Content $PSCommandPath | Out-String)}`"" -Verb RunAs
    exit
}

$url = "https://drive.google.com/file/d/18lfyIfuhiXKLlx0_iTm-F7p7KvmgYoAT/view?usp=sharing"
$destDir = "C:\Temp\TrendUninstall"
$exePath = Join-Path $destDir "V1ESUninstallTool.exe"

if (-not (Test-Path $destDir)) { New-Item -Path $destDir -ItemType Directory }
Write-Host "Downloading tool..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $url -OutFile $exePath

Write-Host "Running Uninstall Tool. Please wait for it to finish..." -ForegroundColor Yellow
$process = Start-Process -FilePath $exePath -Wait -PassThru

Write-Host "`nUninstallation process complete." -ForegroundColor Green
$choice = Read-Host "Would you like to delete the files and folders at '$destDir'? [Y/N]"

if ($choice -eq "Y") {
    Remove-Item -Path $destDir -Recurse -Force
    Write-Host "Directory deleted successfully." -ForegroundColor Gray
}
else {
    Write-Host "Cleanup skipped. Files remain at $destDir." -ForegroundColor White
}