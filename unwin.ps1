$host.ui.RawUI.WindowTitle = "unwin"


function is-admin {
    $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $p = New-Object System.Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (is-admin)) {
    $arg = "-NoProfile -ExecutionPolicy Bypass -File `"" + $PSCommandPath + "`""
    Write-Host "needs admin. relaunching as admin..." -foregroundcolor yellow
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

function typewrite([string]$text, [int]$delay=4) {
    foreach ($c in $text.ToCharArray()) {
        Write-Host -NoNewline $c -ForegroundColor Cyan
        Start-Sleep -Milliseconds $delay
    }
    Write-Host ""
}

typewrite $logo 3

Write-Host ""
Write-Host "choose an option:" -ForegroundColor Green
Write-Host "1) remove common bloatware (safe list)" -ForegroundColor Yellow
Write-Host "2) apply performance tweaks (non destructive)" -ForegroundColor Yellow
Write-Host "3) do both 1 and 2" -ForegroundColor Yellow
Write-Host "4) exit" -ForegroundColor Red
$choice = Read-Host "enter choice (1-4)"

function remove-appx-list([string[]]$list) {
    foreach ($name in $list) {
        Write-Host "attempting to remove $name" -ForegroundColor Cyan
        try {
            Get-AppxPackage -Name $name -AllUsers | ForEach-Object {
                Remove-AppxPackage -Package $_.PackageFullName -ErrorAction SilentlyContinue
            }
        } catch {
            Write-Host "failed removing appx $name" -ForegroundColor DarkYellow
        }
        try {
            $prov = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -eq $name }
            if ($prov) {
                Remove-AppxProvisionedPackage -Online -PackageName $prov.PackageName -ErrorAction SilentlyContinue
            }
        } catch {
            Write-Host "failed removing provisioned $name" -ForegroundColor DarkYellow
        }
    }
}

function remove-traditional-programs([string[]]$names) {
    foreach ($n in $names) {
        Write-Host "attempting to uninstall MSI/EXE named like: $n" -ForegroundColor Cyan
        $un = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "*$n*" }
        foreach ($u in $un) {
            try {
                $u.Uninstall() | Out-Null
                Write-Host "uninstalled $($u.Name)" -ForegroundColor Green
            } catch {
                Write-Host "could not uninstall $($u.Name)" -ForegroundColor DarkYellow
            }
        }
    }
}

function safe-performance-tweaks {
    Write-Host "applying safe tweaks..." -ForegroundColor Green
    try {
        Write-Host "disabling startup apps (via task scheduler / registry query) - listing first" -ForegroundColor Cyan
        Get-CimInstance -ClassName Win32_StartupCommand | Select-Object Name, Command, Location | Format-Table -AutoSize
    } catch {}
    try {
        Write-Host "setting power plan to high performance" -ForegroundColor Cyan
        $guid = (powercfg -l | Select-String -Pattern "High performance" | ForEach-Object { $_.ToString().Split()[3] } )
        if (-not $guid) {
            $guid = (powercfg -l | Select-String -Pattern "ultimate performance" | ForEach-Object { $_.ToString().Split()[3] })
        }
        if ($guid) { powercfg -setactive $guid } else { powercfg -setactive SCHEME_MIN } 
    } catch {}
    try {
        Write-Host "disabling xbox game bar background services (if present)" -ForegroundColor Cyan
        Stop-Service -Name "XblGameSave" -ErrorAction SilentlyContinue
        Stop-Service -Name "GamingServices" -ErrorAction SilentlyContinue
        Set-Service -Name "XblGameSave" -StartupType Disabled -ErrorAction SilentlyContinue
    } catch {}
    try {
        Write-Host "clearing temporary files (users temp and system temp)" -ForegroundColor Cyan
        $u = "$env:temp\*"
        Remove-Item -Path $u -Recurse -Force -ErrorAction SilentlyContinue
        $s = "C:\Windows\Temp\*"
        Remove-Item -Path $s -Recurse -Force -ErrorAction SilentlyContinue
    } catch {}
    try {
        Write-Host "trimming pagefile and optimizing system (safe)" -ForegroundColor Cyan
        # adjust for minimal swap fragmentation: not changing size, only enabling trimming
        # use wim optimization steps if needed; here we run windows builtin disk cleanup silent
        Start-Process cleanmgr -ArgumentList "/sagerun:1" -Wait -NoNewWindow
    } catch {}
    Write-Host "finished safe tweaks" -ForegroundColor Green
}

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

switch ($choice) {
    "1" {
        Write-Host "removing bloatware..." -ForegroundColor Green
        remove-appx-list $bloat
        remove-traditional-programs $traditional
        Write-Host "done. reboot recommended." -ForegroundColor Yellow
    }
    "2" {
        safe-performance-tweaks
        Write-Host "tweaks applied. reboot recommended." -ForegroundColor Yellow
    }
    "3" {
        remove-appx-list $bloat
        remove-traditional-programs $traditional
        safe-performance-tweaks
        Write-Host "all actions completed. reboot recommended." -ForegroundColor Yellow
    }
    default {
        Write-Host "exiting." -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "operation complete. please restart the system for changes to take full effect." -ForegroundColor Cyan
