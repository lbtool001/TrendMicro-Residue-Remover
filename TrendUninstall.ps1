if(-not([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command irm tinyurl.com/tmremover | iex";exit}

$url="https://www.dropbox.com/scl/fi/za2w68je3oy0yaksu4hig/V1ESUninstallTool.zip?rlkey=2paxcfiksbtauspboslwlvk4i&st=h9npam3m&dl=1"
$destDir="C:\Temp\TrendUninstall"
$zipPath=Join-Path $destDir "V1ESUninstallTool.zip"

try{
if(Test-Path $destDir){Remove-Item $destDir -Recurse -Force}
New-Item -Path $destDir -ItemType Directory -Force|Out-Null

Write-Host "Downloading files..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $url -OutFile $zipPath -UserAgent "Mozilla/5.0" -ErrorAction Stop

$firstTwoBytes=Get-Content $zipPath -Encoding Byte -TotalCount 2
if(-not($firstTwoBytes[0]-eq 80 -and $firstTwoBytes[1]-eq 75)){throw "Download file is corrupted or not a ZIP file."}

Write-Host "Extracting files..." -ForegroundColor Magenta
Expand-Archive -Path $zipPath -DestinationPath $destDir -Force

$realExePath=Get-ChildItem -Path $destDir -Filter "V1ESUninstallTool.exe" -Recurse|Select-Object -First 1 -ExpandProperty FullName
if(-not $realExePath){throw "Could not find V1ESUninstallTool.exe inside the ZIP."}

Write-Host "Running Uninstall Tool..." -ForegroundColor Yellow
Start-Process -FilePath $realExePath -Wait

Write-Host "`nUninstallation process complete." -ForegroundColor Green

$choice=Read-Host "Would you like to delete the temp files at '$destDir'? [Y/N]"
if($choice -match "^[Yy]$"){Remove-Item -Path $destDir -Recurse -Force;Write-Host "Cleanup successful." -ForegroundColor Gray}
}
catch{
Write-Host "`n[ERROR]: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nProcess finished. Press any key to close..." -ForegroundColor Gray
$null=$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
