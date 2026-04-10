if ([Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
    Start-Process powershell.exe "-STA -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

Add-Type -Name Win32 -Namespace Native -MemberDefinition @"
[DllImport("kernel32.dll")]
public static extern IntPtr GetConsoleWindow();

[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
"@

$hWnd = [Native.Win32]::GetConsoleWindow()
[Native.Win32]::ShowWindow($hWnd, 0)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$isAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList @(
        "-NoProfile",
        "-ExecutionPolicy Bypass",
        "-File `"$PSCommandPath`""
    )
    exit
}

$form = New-Object System.Windows.Forms.Form
$form.Text = "TSS MAGIC TOOL"
$form.Size = New-Object System.Drawing.Size(520, 400)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(30,30,30)
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.Font = New-Object System.Drawing.Font("Segoe UI", 10)

$logBox = New-Object System.Windows.Forms.TextBox
$logBox.Multiline = $true
$logBox.ScrollBars = "Vertical"
$logBox.Size = New-Object System.Drawing.Size(460,150)
$logBox.Location = New-Object System.Drawing.Point(20,110)
$logBox.BackColor = "Black"
$logBox.ForeColor = "Lime"
$logBox.ReadOnly = $true

function Log($msg) {
    $logBox.AppendText("`r`n[$(Get-Date -Format HH:mm:ss)] $msg")
}

$header = New-Object System.Windows.Forms.Label
$header.Text = "TSS MAGIC TOOL!"
$header.Font = New-Object System.Drawing.Font("Segoe UI", 15, [System.Drawing.FontStyle]::Bold)
$header.ForeColor = "White"
$header.AutoSize = $true
$form.Add_Shown({
    $header.Left = ($form.ClientSize.Width - $header.Width) / 2
    $header.Top = 15
})

$subText = New-Object System.Windows.Forms.Label
$subText.Text = "Select a command below"
$subText.AutoSize = $true
$subText.ForeColor = "Gainsboro"
$subText.Location = New-Object System.Drawing.Point(160,60)

$button1 = New-Object System.Windows.Forms.Button
$button1.Text = "TMREMOVER"
$button1.Size = New-Object System.Drawing.Size(140,45)
$button1.Location = New-Object System.Drawing.Point(100,290)
$button1.BackColor = [System.Drawing.Color]::FromArgb(0,120,215)
$button1.ForeColor = "White"

$button1.Add_Click({
    try {
        Log "Starting TM removal..."

        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        $url = "https://www.dropbox.com/scl/fi/oc5960c0nebynxpomwvhf/V1ESUninstallTool.zip?rlkey=9en7bferg5t7cyw77ucalayb9&dl=1"

        $dest = "C:\Temp\TrendUninstall"
        $zip  = Join-Path $dest "tool.zip"

        if (Test-Path $dest) {
            Remove-Item $dest -Recurse -Force
        }

        New-Item -ItemType Directory -Path $dest -Force | Out-Null

        Log "Downloading tool..."
        Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing

        Log "Extracting..."
        Expand-Archive $zip -DestinationPath $dest -Force

        $exe = Get-ChildItem $dest -Recurse -Filter "*.exe" | Select-Object -First 1

        if (-not $exe) { throw "Executable not found" }

        Log "Running tool..."
        Start-Process $exe.FullName -Wait

        Log "TM removal completed."
    }
    catch {
        Log "[ERROR] $($_.Exception.Message)"
    }
})

$button2 = New-Object System.Windows.Forms.Button
$button2.Text = "BitDefender"
$button2.Size = New-Object System.Drawing.Size(140,45)
$button2.Location = New-Object System.Drawing.Point(280,290)
$button2.BackColor = [System.Drawing.Color]::FromArgb(0,153,76)
$button2.ForeColor = "White"

$button2.Add_Click({
    try {
        Log "Starting BitDefender download..."

        $url = "https://cloudap.gravityzone.bitdefender.com/Packages/BSTWIN/0/setupdownloader.exe"

        $dir = Join-Path $env:USERPROFILE "Downloads\BitDefender"
        if (-not (Test-Path $dir)) {
            New-Item $dir -ItemType Directory -Force | Out-Null
        }

        $file = Join-Path $dir "BitDefender_Setup.exe"

        Invoke-WebRequest -Uri $url -OutFile $file -UseBasicParsing

        $size = (Get-Item $file).Length
        if ($size -lt 1MB) {
            throw "Invalid download detected"
        }

        Log "Launching installer..."
        Start-Process $file

        Log "Installer opened (manual install required)."
    }
    catch {
        Log "[ERROR] $($_.Exception.Message)"
    }
})

$form.Controls.AddRange(@(
    $header,
    $subText,
    $logBox,
    $button1,
    $button2
))

[void]$form.ShowDialog()
