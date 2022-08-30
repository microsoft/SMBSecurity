---
external help file: SMBSecurity-help.xml
Module Name: SMBSecurity
online version:
schema: 2.0.0
---

# Get-SMBSecurityDescription

## SYNOPSIS
{{ Returns a brief SMB SecurityDescriptor (SD) description for a given SD name. }}

## SYNTAX

```
Get-SMBSecurityDescription [[-SecurityDescriptorName] <String>] [<CommonParameters>]
```

## DESCRIPTION
{{ Returns a brief SMB SecurityDescriptor (SD) description for a given SD name. All SMB SD name and descriptions are returned when no name is passed. }}

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Get-SMBSecurityDescription }}
```

{{ Returns the name and description of all SMB SecurityDescriptors. }}

### Example 2
```powershell
PS C:\> {{ Get-SMBSecurityDescription -SecurityDescriptorName SrvsvcDefaultShareInfo }}
```

{{ Returns the description of the SrvsvcDefaultShareInfo SMB SecurityDescriptors. }}

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

[Get-SMBSecurityDescription]([https://github.com/microsoft/SMBSecurity/wiki/Get%E2%80%90SMBSecurityDescription)