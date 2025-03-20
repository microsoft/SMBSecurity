# commands to remove Authenticated Users from SrvsvcSessionInfo with the SMBSecurity PowerShell module.

[CmdletBinding()]
param (
    # Path to the SMBSecurity module files.
    [Parameter()]
    [string]
    $smbSecPath = "C:\Scripts\SMBSecurity"
)

# make sure the SMBSecurity script files are unblocked.
Get-ChildItem "$smbSecPath" -Include "*.ps*1" -Recurse | Unblock-File

# import the module
Import-Module "$smbSecPath\SMBSecurity.psm1" -Force

# get the current state of the SrvsvcSessionInfo security descriptor (SD)
$SD = Get-SMBSecurity -SecurityDescriptorName SrvsvcSessionInfo
$DACL = $SD.Dacl | Where-Object {$_.Account.Username -eq "Authenticated Users"}

if ($DACL) {
    try {
        $DACL | Remove-SMBSecurityDACL -SecurityDescriptor $SD -EA Stop
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
reg.exe export HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\DefaultSecurity "$($PWD.Path)\SMBSecurityDescriptors.reg" /y
$binRaw = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\DefaultSecurity" -Name SrvsvcSessionInfo | ForEach-Object SrvsvcSessionInfo
$binString = $binRaw -join "$("{0:X2}" -f $_)"

$backupFile = Get-ChildItem "$ENV:LOCALAPPDATA\SMBSecurity" -Filter "Backup-SrvsvcSessionInfo-SMBSec*.xml" | Sort-Object -Descending | Select-Object -First 1

Write-Host -ForegroundColor Green @"


The backup file is located at: $($backupFile.FullName)

The updated DefaultSecurity key has been exported to: $($PWD.Path)\SMBSecurityDescriptors.reg

The binary string for the updated SrvsvcSessionInfo registry value is:

$binString


"@
