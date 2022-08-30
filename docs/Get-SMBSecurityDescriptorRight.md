---
external help file: SMBSecurity-help.xml
Module Name: SMBSecurity
online version:
schema: 2.0.0
---

# Get-SMBSecurityDescriptorRight

## SYNOPSIS
{{ Returns a hashtable of valid rights for the given SMB SecurityDescriptor (SD). }}

## SYNTAX

```
Get-SMBSecurityDescriptorRight [-SecurityDescriptorName] <String> [<CommonParameters>]
```

## DESCRIPTION
{{ Returns a hashtable of valid rights for the given SMB SecurityDescriptor (SD). The hashtable invludes the right name, which is used other SMBSecurity cmdlets like Set-SMBSecurityDACL, with its corresponding DACL value. }}

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Get-SMBSecurityDescriptorRight -SecurityDescriptorName SrvsvcDefaultShareInfo }}
```

{{ Outputs a hashtable of valid rights for the SrvsvcDefaultShareInfo SMB SD. }}

## PARAMETERS

### -SecurityDescriptorName
{{ The name of the SMB SecurityDescriptor. The valid set of names are: SrvsvcConfigInfo, SrvsvcConnection, SrvsvcFile, SrvsvcServerDiskEnum, SrvsvcSessionInfo, SrvsvcShareAdminConnect, SrvsvcShareAdminInfo, SrvsvcShareChange, SrvsvcShareConnect, SrvsvcShareFileInfo, SrvsvcSharePrintInfo, SrvsvcStatisticsInfo, SrvsvcTransportEnum, and SrvsvcDefaultShareInfo. }}

```yaml
Type: String
Parameter Sets: (All)
Aliases: SDName, Name

Required: True
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

[Get-SMBSecurityDescriptorRight](https://github.com/microsoft/SMBSecurity/wiki/Get%E2%80%90SMBSecurityDescriptorRight)