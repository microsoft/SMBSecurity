---
external help file: SMBSecurity-help.xml
Module Name: SMBSecurity
online version:
schema: 2.0.0
---

# Add-SMBSecurityDACL

## SYNOPSIS
{{ Adds a DACL to an SMBSecurityDescriptor. }}

## SYNTAX

```
Add-SMBSecurityDACL [-SecurityDescriptor] <PSObject> [-DACL] <SMBSecDaclAce> [-PassThru] [<CommonParameters>]
```

## DESCRIPTION
{{ Adds a DACL to an SMBSecurityDescriptor.  }}

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -DACL
{{ The DACL being added to the SMBSecurityDescriptor. The DACL must originate from Copy-SMBSecurityDACL or New-SMBSecurityDACL and the DACL's SecurityDescriptor property must match the SecurityDescriptor's Name, because each SMB SecurityDescriptor has a unique set of rights. Attempting to add a DACL with a mismatched SMBSecurityDescriptor will result in an error. }}

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
{{ The SMBSecurityDescriptor object where the DACL should be added. The SMBSecurityDescriptor object must originate from Get-SMBSecurity. }}

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