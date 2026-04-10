$ErrorActionPreference = "Continue"

function Pause-Fallback {
    if ($Host.Name -match "ConsoleHost") {
        Write-Host "`nPress Enter to continue..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

try {
    if ([Threading.Thread]::CurrentThread.ApartmentState -ne "STA") {
        Start-Process powershell.exe "-STA -ExecutionPolicy Bypass -Command `"irm '$MyInvocation.MyCommand.Definition' | iex`""
        exit
    }
} catch {}

$isAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    try {
        if ($PSCommandPath) {
            Start-Process powershell.exe -Verb RunAs -ArgumentList @(
                "-NoProfile",
                "-ExecutionPolicy Bypass",
                "-File `"$PSCommandPath`""
            )
        } else {
            Start-Process powershell.exe -Verb RunAs -ArgumentList @(
                "-NoProfile",
                "-ExecutionPolicy Bypass",
                "-Command `"irm '$MyInvocation.MyCommand.Definition' | iex`""
            )
        }
    } catch {
        Write-Host "Admin elevation failed." -ForegroundColor Red
        Pause-Fallback
    }
    exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "TSS TOOL"
$form.Size = New-Object System.Drawing.Size(520,400)
$form.StartPosition = "CenterScreen"

$logBox = New-Object System.Windows.Forms.TextBox
$logBox.Multiline = $true
$logBox.ScrollBars = "Vertical"
$logBox.Size = New-Object System.Drawing.Size(460,150)
$logBox.Location = New-Object System.Drawing.Point(20,110)
$logBox.ReadOnly = $true

function Log($msg) {
    $logBox.AppendText("`r`n[$(Get-Date -Format HH:mm:ss)] $msg")
}

$btn = New-Object System.Windows.Forms.Button
$btn.Text = "BitDefender"
$btn.Size = New-Object System.Drawing.Size(150,40)
$btn.Location = New-Object System.Drawing.Point(180,300)

$btn.Add_Click({
    try {
        Log "Downloading installer..."

        $url = "https://cloudap.gravityzone.bitdefender.com/Packages/BSTWIN/0/setupdownloader.exe"
        $dir = "$env:USERPROFILE\Downloads\BitDefender"
        $file = Join-Path $dir "BitDefender_Setup.exe"

        if (-not (Test-Path $dir)) {
            New-Item $dir -ItemType Directory -Force | Out-Null
        }

        Invoke-WebRequest -Uri $url -OutFile $file -UseBasicParsing

        Log "Launching installer..."
        Start-Process $file

        Log "Done (manual install required)."
    }
    catch {
        Log "[ERROR] $($_.Exception.Message)"
    }
})

$form.Controls.Add($logBox)
$form.Controls.Add($btn)

try {
    [void]$form.ShowDialog()
} catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    Pause-Fallback
}
