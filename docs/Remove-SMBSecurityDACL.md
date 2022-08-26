---
external help file: SMBSecurity-help.xml
Module Name: SMBSecurity
online version:
schema: 2.0.0
---

# Remove-SMBSecurityDACL

## SYNOPSIS
{{ Removes a DACL from an SMBSecurityDescriptor. }}

## SYNTAX

```
Remove-SMBSecurityDACL [-SecurityDescriptor] <PSObject> [-DACL] <SMBSecDaclAce> [-PassThru]
 [<CommonParameters>]
```

## DESCRIPTION
{{ Removes a DACL from an SMBSecurityDescriptor. This does not commit the change to the system, it only modifies the SMBSecurityDescriptor. The Save-SMBSecurity cmdlet is used to commit changes to a SMBSecurityDescriptor to the system. }}

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -DACL
{{ The DACL being removed to the SMBSecurityDescriptor. The DACL must be an exact match to a DACL in the SMBSecurityDescriptor object. }}

```yaml
Type: SMBSecDaclAce
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -PassThru
{{ Outputs the modified SMBSecurityDescriptor to the success stream. }}

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

### -SecurityDescriptor
{{ The SMBSecurityDescriptor object where the DACL should be removed. The SMBSecurityDescriptor object must originate from Get-SMBSecurity. }}

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

### SMBSecDaclAce

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
https://github.com/microsoft/SMBSecurity/wiki