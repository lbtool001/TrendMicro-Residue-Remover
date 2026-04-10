$ErrorActionPreference = "Stop"

try {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
}
catch {
    Write-Host "WinForms failed to load: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit
}

$isAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "Requesting admin..." -ForegroundColor Yellow

    Start-Process powershell.exe -Verb RunAs -ArgumentList @(
        "-NoProfile",
        "-ExecutionPolicy Bypass",
        "-File `"$PSCommandPath`""
    )

    exit
}

$form = New-Object System.Windows.Forms.Form
$form.Text = "TSS TOOL"
$form.Size = New-Object System.Drawing.Size(500,350)
$form.StartPosition = "CenterScreen"

$log = New-Object System.Windows.Forms.TextBox
$log.Multiline = $true
$log.Size = New-Object System.Drawing.Size(450,150)
$log.Location = New-Object System.Drawing.Point(20,80)
$log.ReadOnly = $true

function Write-Log($msg) {
    $log.AppendText("`r`n$msg")
}

$btn = New-Object System.Windows.Forms.Button
$btn.Text = "BitDefender"
$btn.Size = New-Object System.Drawing.Size(120,40)
$btn.Location = New-Object System.Drawing.Point(180,260)

$btn.Add_Click({
    try {
        Write-Log "Downloading..."

        $url = "https://cloudap.gravityzone.bitdefender.com/Packages/BSTWIN/0/setupdownloader.exe"
        $path = "$env:USERPROFILE\Downloads\BitDefender_Setup.exe"

        Invoke-WebRequest $url -OutFile $path -UseBasicParsing

        Write-Log "Launching installer..."
        Start-Process $path

        Write-Log "Done."
    }
    catch {
        Write-Log "ERROR: $($_.Exception.Message)"
    }
})

$form.Controls.Add($log)
$form.Controls.Add($btn)

try {
    [void]$form.ShowDialog()
}
catch {
    Write-Host "FATAL ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host "Press Enter to exit"
}
