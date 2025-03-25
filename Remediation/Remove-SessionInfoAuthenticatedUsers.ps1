# Commands to remove Authenticated Users from SrvsvcSessionInfo with the SMBSecurity PowerShell module.
# This file might need to be unblocked before it will run in PowerShell! See line 14.
#requires -RunAsAdministrator

[CmdletBinding()]
param (
    # Path to the SMBSecurity module files.
    [Parameter()]
    [string]
    $smbSecPath = $null
)

# make sure the app data directory is there
$appDataDir = "$ENV:LOCALAPPDATA\SMBSecurity"
$appDirFnd = Get-Item $appDataDir -EA SilentlyContinue

if (-NOT $appDirFnd) {
    # create the directory
    $null = New-Item -Path $appDataDir -ItemType Directory -Force -EA SilentlyContinue
    Start-Sleep 1
}

if (-NOT $smbSecPath) {
    # is the script in a Remediation dir?
    $isRemDir = Split-Path $PSScriptRoot -Leaf
    if ($isRemDir -eq 'Remediation') {
        # Assume the dir structure is as-in from GitHub and the module is in the parent directory
        $smbSecPath = Split-Path $PSScriptRoot -Parent
    } elseif ($isRemDir -eq 'SMBSecurity') {
        $smbSecPath = $PSScriptRoot
    }
}

# look for the module file in the smbSecPath
$modFnd = Get-Item "$smbSecPath\SMBSecurity.psm1" -EA SilentlyContinue
if (-NOT $modFnd) {
    throw "Failed to find the SMBSecurity.psm1 module."
}

# make sure the SMBSecurity script files are unblocked.
Get-ChildItem "$smbSecPath" -Include "*.ps*1" -Recurse | Unblock-File

# import the module
try {
    Import-Module "$smbSecPath\SMBSecurity.psm1" -Force -EA Stop
} catch {
    throw "Failed to import the SMBSecurity module. Is the path to SMBSecurity.psm1 correct? The path used is $smbSecPath`."
}

# get the current state of the SrvsvcSessionInfo security descriptor (SD)
$SD = Get-SMBSecurity -SecurityDescriptorName SrvsvcSessionInfo
$DACL = $SD.Dacl | Where-Object {$_.Account.Username -eq "Authenticated Users"}

if ($DACL) {
    try {
        # remove Authenticated Users
        $DACL | Remove-SMBSecurityDACL -SecurityDescriptor $SD -EA Stop

        # save the change
        $bkupPathFnd = Get-Item "$ENV:LOCALAPPDATA\SMBSecurity" -EA SilentlyContinue
        if (-NOT $bkupPathFnd) {
            $null = mkdir $bkupPathFnd -Force
        }
        $beforeName = "$($PWD.Path)\SMBSecurityDescriptors_before_$([datetime]::Now.ToFileTime()).reg"
        reg.exe export HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\DefaultSecurity $beforeName /y
        Save-SMBSecurity -SecurityDescriptor $SD -EA Stop

        # refresh
        $SD = Get-SMBSecurity -SecurityDescriptorName SrvsvcSessionInfo
        Write-Host "Authenticated Users was removed from the SrvsvcSessionInfo security descriptor. The currect rights are:`n$($Sd.Dacl | Format-Table | Out-String)"
    } catch {
        Write-Error "Failed to remove Authenticated Users. Error: $_"
    }
} else {
    Write-Host "Authenticated Users not found in the SrvsvcSessionInfo security descriptor. No changes were made."
}

# export the modified SrvsvcSessionInfo registry value
$afterName = "$($PWD.Path)\SMBSecurityDescriptors_after_$([datetime]::Now.ToFileTime()).reg"
reg.exe export HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\DefaultSecurity $afterName /y
$binRaw = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\DefaultSecurity" -Name SrvsvcSessionInfo | ForEach-Object SrvsvcSessionInfo
[string]$binString = "" 
$binRaw | Foreach-Object {$binString += "$("{0:X2}" -f $_)"}

$backupFile = Get-ChildItem "$ENV:LOCALAPPDATA\SMBSecurity" -Filter "Backup-SrvsvcSessionInfo-SMBSec*.xml" | Sort-Object -Descending | Select-Object -First 1

Write-Host -ForegroundColor Green @"


The SMBSecurity backup file is located at: $($backupFile.FullName)

The updated DefaultSecurity key has been exported to: $afterName

The reg key backup file, before the change, has been exported to: $beforeName

The binary string for the updated SrvsvcSessionInfo registry value is:

$binString


"@
