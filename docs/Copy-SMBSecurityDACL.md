---
external help file: SMBSecurity-help.xml
Module Name: SMBSecurity
online version:
schema: 2.0.0
---

# Copy-SMBSecurityDACL

## SYNOPSIS
{{ Creates a cloned copy of a DACL. }}

## SYNTAX

```
Copy-SMBSecurityDACL [[-DACL] <SMBSecDaclAce>] [<CommonParameters>]
```

## DESCRIPTION
{{ Creates a cloned copy of a DACL. This is used by the modify DACL process when using Set-SmbSecurityDescriptorDACL. }}

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -DACL
{{ The DACL object to be copied. In general, this should be a DACL in an SMBSecurityDescriptor object. }}

```yaml
Type: SMBSecDaclAce
Parameter Sets: (All)
Aliases:

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