# unwin
windows unbloater ps2exe script.
# execute as administrator for it to work YAY!
# open source too. so if you wanna make any other version you can do!,hope you have a great time

# IF YOU HAVE ANY PROBLEMS WITH IT POST IN ISSUES PLEASE!
<img width="370" height="374" alt="image" src="https://github.com/user-attachments/assets/dff8804c-8f8a-4c69-a573-f05790ae4c81" />

anyways. if you use or needs the windows store. do that after pressing the remove bloat thing.
Get-AppxPackage -allusers Microsoft.WindowsStore | Foreach {Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml"}
(powershell as an admin please.)

# i will add more things soon. and prob an ui. only in beta

