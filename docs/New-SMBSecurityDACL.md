---
external help file: SMBSecurity-help.xml
Module Name: SMBSecurity
online version:
schema: 2.0.0
---

# New-SMBSecurityDACL

## SYNOPSIS
{{ Fill in the Synopsis }}

## SYNTAX

```
New-SMBSecurityDACL [-SecurityDescriptorName] <String> [-Access] <SMBSecAccess> [-Rights] <String[]>
 [-Account] <Object> [<CommonParameters>]
```

## DESCRIPTION
{{ Fill in the Description }}

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -Access
{{ Fill Access Description }}

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
{{ Fill Account Description }}

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
{{ Fill Rights Description }}

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
{{ Fill SecurityDescriptorName Description }}

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
