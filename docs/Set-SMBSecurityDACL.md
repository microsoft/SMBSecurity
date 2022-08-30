---
external help file: SMBSecurity-help.xml
Module Name: SMBSecurity
online version:
schema: 2.0.0
---

# Set-SMBSecurityDACL

## SYNOPSIS
{{ Alters the settings of an SMB Security Descriptor (SD) DACL. }}

## SYNTAX

```
Set-SMBSecurityDACL [-DACL] <SMBSecDaclAce> [[-Account] <Object>] [[-Access] <Object>] [[-Right] <String[]>]
 [-PassThru] [<CommonParameters>]
```

## DESCRIPTION
{{ Alters the settings of an SMB Security Descriptor (SD) DACL. }}

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ $SD = Get-SMBSecurity -SecurityDescriptorName SrvsvcSharePrintInfo }}
PS C:\> {{ $DACL = $SD.DACL | Where-Object {$_.Account.Username -eq "DomianGroup"} }}
PS C:\> {{ $NewDACL = Copy-SMBSecurityDACL $DACL }}
PS C:\> {{ Set-SMBSecurityDACL -DACL $NewDACL -Access Deny }}
```

{{ Creates the SrvsvcSharePrintInfo SMBSecurityDescriptor and then copies the DACL using the DomainGroup account. The DACL is modified to Deny this group access to SrvsvcSharePrintInfo SD. }}

## PARAMETERS

### -Access
{{ Allow or Deny the the Right(s) for the Account. Please note that Deny overrules Allow. }}

```yaml
Type: Object
Parameter Sets: (All)
Aliases:
Accepted values: Allow, Deny

Required: False
Position: 2
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

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DACL
{{ The DACL object being modified. }}

```yaml
Type: SMBSecDaclAce
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassThru
{{ Outputs the results to the success stream. }}

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Right
{{ What permissions the account will (Allow) or will not (Deny) have for SMB SecurityDescriptor. }}

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
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

[Set-SMBSecurityDACL](https://github.com/microsoft/SMBSecurity/wiki/Set%E2%80%90SMBSecurityDACL)