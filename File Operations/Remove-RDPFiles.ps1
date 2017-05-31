## This script will remove all .RDP files from a directory, recursively. Should be run as a logon script.

Remove-Item -Path $env:USERPROFILE\Downloads\*.rdp -Force -Recurse