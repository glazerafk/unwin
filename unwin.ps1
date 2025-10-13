$host.ui.RawUI.WindowTitle = "unwin"

$id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$p = New-Object System.Security.Principal.WindowsPrincipal($id)
if (-not $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $arg = "-NoProfile -ExecutionPolicy Bypass -File `"" + $PSCommandPath + "`""
    Write-Host "needs admin. relaunching as admin..." -ForegroundColor Red
    Start-Process powershell -ArgumentList $arg -Verb RunAs
    exit
}

$logo = @"
 █    ██  ███▄    █  █     █░ ██▓ ███▄    █ 
 ██  ▓██▒ ██ ▀█   █ ▓█░ █ ░█░▓██▒ ██ ▀█   █ 
▓██  ▒██░▓██  ▀█ ██▒▒█░ █ ░█ ▒██▒▓██  ▀█ ██▒
▓▓█  ░██░▓██▒  ▐▌██▒░█░ █ ░█ ░██░▓██▒  ▐▌██▒
▒▒█████▓ ▒██░   ▓██░░░██▒██▓ ░██░▒██░   ▓██░
░▒▓▒ ▒ ▒ ░ ▒░   ▒ ▒ ░ ▓░▒ ▒  ░▓  ░ ▒░   ▒ ▒ 
░░▒░ ░ ░ ░ ░░   ░ ▒░  ▒ ░ ░   ▒ ░░ ░░   ░ ▒░
 ░░░ ░ ░    ░   ░ ░   ░   ░   ▒ ░   ░   ░ ░ 
   ░              ░     ░     ░           ░ 
"@

function Show-AnimatedText($text, $color="DarkRed", $delay=20) {
    foreach ($c in $text.ToCharArray()) {
        Write-Host -NoNewline $c -ForegroundColor $color
        Start-Sleep -Milliseconds $delay
    }
    Write-Host ""
}

foreach ($line in $logo.Split("`n")) { Show-AnimatedText $line "DarkRed" (Get-Random -Minimum 1 -Maximum 6) }

$tips = @(
    "💡 Tip: Have you tried turning it off and on again?",
    "💡 Tip: Edge is like glitter. Once it’s there, it never leaves.",
    "💡 Tip: Windows Update is the real boss fight.",
    "💡 Tip: Task Manager knows your secrets.",
    "💡 Tip: Cortana retired, but she’s still watching.",
    "💡 Tip: The Recycle Bin is where dreams go to die."
)

function Show-RandomTips($count=3) {
    $tips | Get-Random -Count $count | ForEach-Object {
        Show-AnimatedText "`n$_" "DarkRed" 30
        Start-Sleep -Milliseconds 500
    }
}

Show-RandomTips

Show-AnimatedText "`nchoose an option:" "Red" 20
Show-AnimatedText "1) remove all bloatware" "DarkRed" 20
Show-AnimatedText "2) apply performance tweaks" "DarkRed" 20
Show-AnimatedText "3) do both" "DarkRed" 20
Show-AnimatedText "4) exit" "Gray" 20
$choice = Read-Host "enter choice (1-4)"

$bloat = (Get-AppxPackage -AllUsers).Name

if ($choice -eq "1" -or $choice -eq "3") {
    Show-AnimatedText "`nremoving bloatware..." "DarkRed" 15
    foreach ($name in $bloat) {
        Show-AnimatedText "slaughtering $name" "Red" 5
        try {
            Get-AppxPackage -Name $name -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue
            Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -eq $name } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
        } catch {}
    }
    Show-AnimatedText "done. system bleeding less now." "DarkRed" 15
}

if ($choice -eq "2" -or $choice -eq "3") {
    Show-AnimatedText "`ncleaning and tweaking..." "DarkRed" 15
    try {
        powercfg -setactive SCHEME_MIN
        Stop-Service -Name "DiagTrack","SysMain","XblGameSave","GamingServices" -ErrorAction SilentlyContinue
        Set-Service -Name "DiagTrack","SysMain","XblGameSave","GamingServices" -StartupType Disabled -ErrorAction SilentlyContinue
        Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item "C:\Windows\Prefetch\*" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item "C:\Users\*\AppData\Local\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
        del /f /s /q "C:\Windows\LiveKernelReports\*"
        del /f /s /q "C:\Windows\MEMORY.DMP"
        Show-AnimatedText "system cleansed. performance unleashed." "DarkRed" 15
    } catch {}
}

if ($choice -eq "4") {
    Show-AnimatedText "leaving the ritual..." "Gray" 20
    exit
}

Show-RandomTips
Show-AnimatedText "`n operation complete. restart to seal the ritual." "Red" 20
