---
external help file: SMBSecurity-help.xml
Module Name: SMBSecurity
online version:
schema: 2.0.0
---

# New-SMBSecurityDescriptor

## SYNOPSIS
{{ Creates an SMBSecurityDescriptor object. }}

## SYNTAX

```
New-SMBSecurityDescriptor [-SecurityDescriptorName] <SMBSecurityDescriptor> [[-SDDLString] <String>]
 [[-Owner] <Object>] [[-Group] <Object>] [[-DACL] <Object>] [<CommonParameters>]
```

## DESCRIPTION
{{ Creates an SMBSecurityDescriptor object. This cmdlet can be used in advanced scripting scenarios. The recommendation is to use Get-SMBSecurity and modify the esisting SMB SecurityDescriptor rather than building the SMBSecurityDescriptor manually. }}

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -DACL
{{ An array of one or more DACLs to add to the SMBSecurityDescriptor. The DACL must originate from Copy-SMBSecurityDACL or New-SMBSecurityDACL and the DACL's SecurityDescriptor property must match the SecurityDescriptor's Name, because each SMB SecurityDescriptor has a unique set of rights. Attempting to add a DACL with a mismatched SMBSecurityDescriptor will result in an error. }}

```yaml
Type:  System.Collections.ArrayList
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Group
{{ The primary group for the Security Descriptor. This should be 'NT AUTHORITY\SYSTEM'. }}

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Owner
{{ The owner of the Security Descriptor. This should be 'NT AUTHORITY\SYSTEM'. }}

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SDDLString
{{ Creates the SMBSecurityDescriptor based on a compatible SDDL string. }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SecurityDescriptorName
{{ The name of the SMB SecurityDescriptor. The valid set of names are: SrvsvcConfigInfo, SrvsvcConnection, SrvsvcFile, SrvsvcServerDiskEnum, SrvsvcSessionInfo, SrvsvcShareAdminConnect, SrvsvcShareAdminInfo, SrvsvcShareChange, SrvsvcShareConnect, SrvsvcShareFileInfo, SrvsvcSharePrintInfo, SrvsvcStatisticsInfo, SrvsvcTransportEnum, and SrvsvcDefaultShareInfo. }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: SrvsvcConfigInfo, SrvsvcConnection, SrvsvcFile, SrvsvcServerDiskEnum, SrvsvcSessionInfo, SrvsvcShareAdminConnect, SrvsvcShareAdminInfo, SrvsvcShareChange, SrvsvcShareConnect, SrvsvcShareFileInfo, SrvsvcSharePrintInfo, SrvsvcStatisticsInfo, SrvsvcTransportEnum, SrvsvcDefaultShareInfo

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
https://github.com/microsoft/SMBSecurity/wiki