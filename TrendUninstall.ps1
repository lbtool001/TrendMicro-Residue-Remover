Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("kernel32.dll")]
public static extern IntPtr GetConsoleWindow();

[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
'

$consolePtr = [Console.Window]::GetConsoleWindow()
[Console.Window]::ShowWindow($consolePtr, 0)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$isAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "powershell.exe"
    $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    $psi.Verb = "runas"
    $psi.UseShellExecute = $true
    [System.Diagnostics.Process]::Start($psi) | Out-Null
    exit
}

$form = New-Object System.Windows.Forms.Form
$form.Text = "TMREMOVER | BITDEFENDER"
$form.Size = New-Object System.Drawing.Size(520, 400)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.Font = New-Object System.Drawing.Font("Segoe UI", 10)

$header = New-Object System.Windows.Forms.Label
$header.Text = "TSS MAGIC TOOL!"
$header.Font = New-Object System.Drawing.Font("Segoe UI", 15, [System.Drawing.FontStyle]::Bold)
$header.ForeColor = [System.Drawing.Color]::White
$header.AutoSize = $true

$form.Add_Shown({
    $header.Left = [int](($form.ClientSize.Width - $header.Width) / 2)
    $header.Top = 15
})

$subText = New-Object System.Windows.Forms.Label
$subText.Text = "Welcome Fellow Technical Service!`nPlease select your command!"
$subText.AutoSize = $true
$subText.ForeColor = [System.Drawing.Color]::Gainsboro
$subText.Location = New-Object System.Drawing.Point(120, 60)

$logBox = New-Object System.Windows.Forms.TextBox
$logBox.Multiline = $true
$logBox.ScrollBars = "Vertical"
$logBox.Size = New-Object System.Drawing.Size(460, 150)
$logBox.Location = New-Object System.Drawing.Point(20, 110)
$logBox.BackColor = [System.Drawing.Color]::Black
$logBox.ForeColor = [System.Drawing.Color]::Lime
$logBox.ReadOnly = $true

function Log($msg) {
    $logBox.AppendText("`r`n$msg")
}

$button1 = New-Object System.Windows.Forms.Button
$button1.Text = "TMREMOVE"
$button1.Size = New-Object System.Drawing.Size(140, 45)
$button1.Location = New-Object System.Drawing.Point(100, 290)
$button1.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$button1.ForeColor = [System.Drawing.Color]::White
$button1.FlatStyle = "Flat"

$button1.Add_Click({

    Log "Starting TMREMOVE process..."

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        $url = "https://www.dropbox.com/scl/fi/oc5960c0nebynxpomwvhf/V1ESUninstallTool.zip?rlkey=9en7bferg5t7cyw77ucalayb9&st=izcn1n4o&dl=1"
        $destDir = "C:\Temp\TrendUninstall"
        $zipPath = Join-Path $destDir "V1ESUninstallTool.zip"

        if (Test-Path $destDir) {
            Remove-Item $destDir -Recurse -Force -ErrorAction SilentlyContinue
            Log "Old temp removed."
        }

        New-Item -Path $destDir -ItemType Directory -Force | Out-Null
        Log "Downloading TM removal tool! Please wait....."

        Invoke-WebRequest -Uri $url -OutFile $zipPath -UserAgent "Mozilla/5.0" -ErrorAction Stop

        Log "Extracting archive..."
        Expand-Archive -Path $zipPath -DestinationPath $destDir -Force

        $exe = Get-ChildItem $destDir -Recurse -Filter "V1ESUninstallTool.exe" |
            Select-Object -First 1 -ExpandProperty FullName

        if (-not $exe) {
            throw "V1ESUninstallTool.exe not found."
        }

        Log "Running V1ESUninstallTool.exe..."

        $outLog = Join-Path $destDir "stdout.log"
        $errLog = Join-Path $destDir "stderr.log"

        $proc = Start-Process -FilePath $exe `
            -WindowStyle Hidden `
            -PassThru `
            -RedirectStandardOutput $outLog `
            -RedirectStandardError $errLog `
            -Wait

        if (Test-Path $outLog) {
            Get-Content $outLog -ErrorAction SilentlyContinue | ForEach-Object {
                Log "[OUT] $_"
            }
        }

        if (Test-Path $errLog) {
            Get-Content $errLog -ErrorAction SilentlyContinue | ForEach-Object {
                Log "[ERR] $_"
            }
        }

        Log "TMREMOVE completed successfully."

    } catch {
        Log "[ERROR] $($_.Exception.Message)"
    }
})

$button2 = New-Object System.Windows.Forms.Button
$button2.Text = "BitDefender"
$button2.Size = New-Object System.Drawing.Size(140, 45)
$button2.Location = New-Object System.Drawing.Point(280, 290)
$button2.BackColor = [System.Drawing.Color]::FromArgb(0, 153, 76)
$button2.ForeColor = [System.Drawing.Color]::White
$button2.FlatStyle = "Flat"

$button2.Add_Click({

    Log "Starting BitDefender installation..."

    try {
        $url = "https://cloudap.gravityzone.bitdefender.com/Packages/BSTWIN/0/setupdownloader_[aHR0cHM6Ly9jbG91ZGFwLWVjcy5ncmF2aXR5em9uZS5iaXRkZWZlbmRlci5jb20vUGFja2FnZXMvQlNUV0lOLzAvUlp3Y2t4L2luc3RhbGxlci54bWw-bGFuZz1lbi1VUw==].exe"

        $downloads = Join-Path ([Environment]::GetFolderPath("UserProfile")) "Downloads\BitDefender"

        if (-not (Test-Path $downloads)) {
            New-Item -Path $downloads -ItemType Directory -Force | Out-Null
        }

        $tempPath = Join-Path $downloads "download.tmp"
        $finalPath = Join-Path $downloads "setupdownloader_[aHR0cHM6Ly9jbG91ZGFwLWVjcy5ncmF2aXR5em9uZS5iaXRkZWZlbmRlci5jb20vUGFja2FnZXMvQlNUV0lOLzAvUlp3Y2t4L2luc3RhbGxlci54bWw-bGFuZz1lbi1VUw==].exe"

        Log "Downloading installer..."

        if (Test-Path $tempPath) {
            Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
        }

        Invoke-WebRequest -Uri $url -OutFile $tempPath -UserAgent "Mozilla/5.0" -MaximumRedirection 10 -ErrorAction Stop

        $size = (Get-Item $tempPath).Length
        Log "Downloaded size: $size bytes"

        if ($size -lt 1MB) {
            Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
            throw "Download failed or invalid file."
        }

        if (Test-Path $finalPath) {
            Remove-Item $finalPath -Force -ErrorAction SilentlyContinue
        }

        Move-Item $tempPath $finalPath -Force

        Log "Launching installer UI..."

        Start-Process -FilePath $finalPath -WindowStyle Normal

        Log "Installer opened. Manual installation required."

    } catch {
        Log "[ERROR] $($_.Exception.Message)"
    }
})

$form.Controls.Add($header)
$form.Controls.Add($subText)
$form.Controls.Add($logBox)
$form.Controls.Add($button1)
$form.Controls.Add($button2)

[void]$form.ShowDialog()
