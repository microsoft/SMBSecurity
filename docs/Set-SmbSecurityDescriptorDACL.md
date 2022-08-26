---
external help file: SMBSecurity-help.xml
Module Name: SMBSecurity
online version:
schema: 2.0.0
---

# Set-SmbSecurityDescriptorDACL

## SYNOPSIS
{{ Replaces the existing DACL in an SecurityDescriptor with a modified version of that DACL. }}

## SYNTAX

```
Set-SmbSecurityDescriptorDACL [-SecurityDescriptor] <PSObject> [-DACL] <SMBSecDaclAce>
 [-NewDACL] <SMBSecDaclAce> [<CommonParameters>]
```

## DESCRIPTION
{{ Replaces the existing DACL in an SecurityDescriptor with a modified version of that DACL. The NewDACL should be created using Copy-SMBSecurityDACL. }}

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -DACL
{{ The existing DACL that is being replaced. }}

```yaml
Type: SMBSecDaclAce
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NewDACL
{{ The DACL replacing the existing one in the SecurityDescriptor. }}

```yaml
Type: SMBSecDaclAce
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SecurityDescriptor
{{ The SMBSecurityDescriptor object where the DACL is being replaced. The SMBSecurityDescriptor object must originate from Get-SMBSecurity. }}

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases:

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