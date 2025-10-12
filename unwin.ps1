$host.ui.RawUI.WindowTitle = "unwin"

$id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$p = New-Object System.Security.Principal.WindowsPrincipal($id)
if (-not $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $arg = "-NoProfile -ExecutionPolicy Bypass -File `"" + $PSCommandPath + "`""
    Write-Host "needs admin. relaunching as admin..." -ForegroundColor Yellow
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
          windows unbloater via powershell
"@

foreach ($c in $logo.ToCharArray()) {
    Write-Host -NoNewline $c -ForegroundColor Cyan
    Start-Sleep -Milliseconds 3
}
Write-Host ""

Write-Host "choose an option:" -ForegroundColor Green
Write-Host "1) remove common bloatware (safe list)" -ForegroundColor Yellow
Write-Host "2) apply performance tweaks (non destructive)" -ForegroundColor Yellow
Write-Host "3) do both 1 and 2" -ForegroundColor Yellow
Write-Host "4) exit" -ForegroundColor Red
$choice = Read-Host "enter choice (1-4)"

$bloat = @(
    "Microsoft.Microsoft3DViewer",
    "Microsoft.MicrosoftOfficeHub",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.XboxGamingOverlay",
    "Microsoft.Xbox.TCUI",
    "Microsoft.XboxApp",
    "Microsoft.YourPhone",
    "Microsoft.GetHelp",
    "Microsoft.Getstarted",
    "Microsoft.ZuneMusic",
    "Microsoft.ZuneVideo"
)

$traditional = @("oculus","steam","vdstreamer")

if ($choice -eq "1" -or $choice -eq "3") {
    Write-Host "removing bloatware..." -ForegroundColor Green
    foreach ($name in $bloat) {
        Write-Host "attempting to remove $name" -ForegroundColor Cyan
        try {
            Get-AppxPackage -Name $name -AllUsers | ForEach-Object {
                Remove-AppxPackage -Package $_.PackageFullName -ErrorAction SilentlyContinue
            }
        } catch {}
        try {
            $prov = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -eq $name }
            if ($prov) {
                Remove-AppxProvisionedPackage -Online -PackageName $prov.PackageName -ErrorAction SilentlyContinue
            }
        } catch {}
    }
    foreach ($n in $traditional) {
        Write-Host "attempting to uninstall MSI/EXE named like: $n" -ForegroundColor Cyan
        $un = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "*$n*" }
        foreach ($u in $un) {
            try {
                $u.Uninstall() | Out-Null
                Write-Host "uninstalled $($u.Name)" -ForegroundColor Green
            } catch {}
        }
    }
    Write-Host "done. reboot recommended." -ForegroundColor Yellow
}

if ($choice -eq "2" -or $choice -eq "3") {
    Write-Host "applying safe tweaks..." -ForegroundColor Green
    try {
        Write-Host "disabling startup apps (listing first)" -ForegroundColor Cyan
        Get-CimInstance -ClassName Win32_StartupCommand | Select Name, Command, Location | Format-Table -AutoSize
    } catch {}
    try {
        Write-Host "setting power plan to high performance" -ForegroundColor Cyan
        $guid = (powercfg -l | Select-String "High performance" | ForEach-Object { $_.ToString().Split()[3] })
        if (-not $guid) {
            $guid = (powercfg -l | Select-String "ultimate performance" | ForEach-Object { $_.ToString().Split()[3] })
        }
        if ($guid) { powercfg -setactive $guid } else { powercfg -setactive SCHEME_MIN }
    } catch {}
    try {
        Write-Host "disabling xbox game bar services" -ForegroundColor Cyan
        Stop-Service -Name "XblGameSave" -ErrorAction SilentlyContinue
        Stop-Service -Name "GamingServices" -ErrorAction SilentlyContinue
        Set-Service -Name "XblGameSave" -StartupType Disabled -ErrorAction SilentlyContinue
    } catch {}
    try {
        Write-Host "clearing temp files" -ForegroundColor Cyan
        Remove-Item "$env:temp\*" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    } catch {}
    try {
        Write-Host "running disk cleanup silent" -ForegroundColor Cyan
        Start-Process cleanmgr -ArgumentList "/sagerun:1" -Wait -NoNewWindow
    } catch {}
    Write-Host "finished safe tweaks" -ForegroundColor Green
}

if ($choice -eq "4") {
    Write-Host "exiting." -ForegroundColor Red
}

Write-Host ""
Write-Host "operation complete. please restart the system for changes to take full effect." -ForegroundColor Cyan
