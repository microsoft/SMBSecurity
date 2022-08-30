---
external help file: SMBSecurity-help.xml
Module Name: SMBSecurity
online version:
schema: 2.0.0
---

# New-SMBSecurityDACL

## SYNOPSIS
{{ Creates a DACL for a specific SMB SecurityDescriptor (SD). }}

## SYNTAX

```
New-SMBSecurityDACL [-SecurityDescriptorName] <String> [-Access] <SMBSecAccess> [-Rights] <String[]>
 [-Account] <Object> [<CommonParameters>]
```

## DESCRIPTION
{{ Creates a DACL for a specific SMB SecurityDescriptor (SD). A DACL must be created for a specific SMB SD because each DACL has a unique set of rights. }}

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ $DACLSplat = @{
                SecurityDescriptor = 'SrvsvcDefaultShareInfo'
                Access             = 'Allow'
                Right              = 'FullControl'
                Account            = "Administrators"
            } }}
PS C:\> {{ $DACL = New-SMBSecurityDACL @DACLSplat }}
```

{{ This sample creates a DACL for the SrvsvcDefaultShareInfo SMB SecurityDescriptor. This DACL object can be added to an SMBSecurityDescriptor object to modify the permission set. }}

## PARAMETERS

### -Access
{{ Allow or Deny the the Right(s) for the Account. Please note that Deny overrules Allow. }}

```yaml
Type: SMBSecAccess
Parameter Sets: (All)
Aliases:
Accepted values: Allow, Deny

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Account
{{ The user account or group that the Right(s) will apply to. }}

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Rights
{{ What permissions the account will (Allow) or will not (Deny) have for SMB SecurityDescriptor. }}

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

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

[New-SMBSecurityDACL](https://github.com/microsoft/SMBSecurity/wiki/New%E2%80%90SMBSecurityDACL)