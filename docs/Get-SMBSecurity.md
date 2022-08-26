---
external help file: SMBSecurity-help.xml
Module Name: SMBSecurity
online version:
schema: 2.0.0
---

# Get-SMBSecurity

## SYNOPSIS
{{ Retrieves one or more SMB SecurityDescriptor. }}

## SYNTAX

```
Get-SMBSecurity [[-SecurityDescriptorName] <String>] [<CommonParameters>]
```

## DESCRIPTION
{{ Retrieves one or more SMB SecurityDescriptor (SD) from the local registry. The SDs are converted into an SMBSecurityDescriptor object that can be used to modify the SMB server security capabilities of the Windows computer. }}

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Get-SMBSecurity }}
```

{{ Returns an array of SMBSecurityDescriptors for all SMB SDs on the system. }}


### Example 2
```powershell
PS C:\> {{ $sdDefaultShareInfo = Get-SMBSecurity -SecurityDescriptorName SrvsvcDefaultShareInfo }}
```

{{ Returns a single SMBSecurityDescriptor object for SrvsvcDefaultShareInfo. }}


## PARAMETERS

### -SecurityDescriptorName
{{ The name of the SMB SecurityDescriptor. The valid set of names are: SrvsvcConfigInfo, SrvsvcConnection, SrvsvcFile, SrvsvcServerDiskEnum, SrvsvcSessionInfo, SrvsvcShareAdminConnect, SrvsvcShareAdminInfo, SrvsvcShareChange, SrvsvcShareConnect, SrvsvcShareFileInfo, SrvsvcSharePrintInfo, SrvsvcStatisticsInfo, SrvsvcTransportEnum, and SrvsvcDefaultShareInfo. }}

```yaml
Type: String
Parameter Sets: (All)
Aliases: SDName, Name

Required: False
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
https://github.com/microsoft/SMBSecurity/wiki