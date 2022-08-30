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
{{ Creates a cloned copy of a DACL. This is used by the modify DACL process in conjunction with  Set-SmbSecurityDescriptorDACL. }}

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ $SMBSec = Get-SMBSecurity -SecurityDescriptorName SrvsvcDefaultShareInfo }}
PS C:\> {{ $DACL = $SMBSec.DACL | Where-Object { $_.Account.Username -eq "Authenticated Users" } }}
PS C:\> {{ $NewDACL = Copy-SMBSecurityDACL $DACL }}
PS C:\> {{ Set-SMBSecurityDACL -DACL $NewDACL -Right Read }}
PS C:\> {{ Set-SmbSecurityDescriptorDACL -SecurityDescriptor $SMBSec -DACL $DACL -NewDACl $NewDACL }}
```

{{ This example creates a copy of the "Authenticated Users" DACL. The copied DACL is modified and then used to update the SMBSecurityDescriptor. }}

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

[Copy-SMBSecurityDACL](https://github.com/microsoft/SMBSecurity/wiki/Copy%E2%80%90SMBSecurityDACL)