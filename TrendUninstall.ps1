$ErrorActionPreference = "Continue"

function Write-Log($msg) {
    try { $logBox.AppendText("`r`n$msg") } catch {}
}

try {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
} catch {
    Write-Host "WinForms load failed: $($_.Exception.Message)"
    return
}

$isAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    try {
        Start-Process powershell.exe -Verb RunAs -ArgumentList @(
            "-NoProfile",
            "-ExecutionPolicy Bypass",
            "-Command",
            "irm '$MyInvocation.MyCommand.Definition' | iex"
        )
    } catch {
        Write-Host "Admin request failed."
    }
    return
}

$form = New-Object System.Windows.Forms.Form
$form.Text = "TSS TOOL"
$form.Size = New-Object System.Drawing.Size(520, 380)
$form.StartPosition = "CenterScreen"

$logBox = New-Object System.Windows.Forms.TextBox
$logBox.Multiline = $true
$logBox.Size = New-Object System.Drawing.Size(460, 160)
$logBox.Location = New-Object System.Drawing.Point(20, 80)
$logBox.ScrollBars = "Vertical"

$btn = New-Object System.Windows.Forms.Button
$btn.Text = "BitDefender"
$btn.Size = New-Object System.Drawing.Size(150, 40)
$btn.Location = New-Object System.Drawing.Point(180, 270)

$btn.Add_Click({
    try {
        Write-Log "Downloading installer..."

        $url = "https://cloudap.gravityzone.bitdefender.com/Packages/BSTWIN/0/setupdownloader.exe"
        $file = "$env:USERPROFILE\Downloads\BitDefender_Setup.exe"

        Invoke-WebRequest -Uri $url -OutFile $file -UseBasicParsing

        Write-Log "Launching installer..."
        Start-Process $file

        Write-Log "Done (manual install)."
    }
    catch {
        Write-Log "ERROR: $($_.Exception.Message)"
    }
})

$form.Controls.Add($logBox)
$form.Controls.Add($btn)

try {
    [void]$form.ShowDialog()
}
catch {
    Write-Host "GUI error: $($_.Exception.Message)"
}
