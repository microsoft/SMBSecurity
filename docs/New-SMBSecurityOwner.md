---
external help file: SMBSecurity-help.xml
Module Name: SMBSecurity
online version:
schema: 2.0.0
---

# New-SMBSecurityOwner

## SYNOPSIS
{{ Creates an SMBSecOwner object. }}

## SYNTAX

```
New-SMBSecurityOwner [-Account] <Object> [-ForceDomain] [<CommonParameters>]
```

## DESCRIPTION
{{ Creates an SMBSecOwner object. The owner can be added to the SMBSecurityDescriptor via Set-SMBSecurityOwner. The command will fail if the account's SID cannot be resolved by the system. }}

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -Account
{{ The owner name. String SID or account name, [System.Security.Principal.NTAccount], [System.Security.Principal.SecurityIdentifier] (SID), [SMBSecAccount], and ,[SMBSecGroup] objects are accepted. Strings accept input in 'username', 'domain\username', and 'user@domain' format. }}

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -ForceDomain
{{ [Experimental] Certain domain configurations, namely Azure AD joined, may cause the Account lookup to fail. This parameter adds extra domain lookup logic that should be AAD compatible. Hybrid joined and traditional AD joined systems should not need this parameter. }}

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Object

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
https://github.com/microsoft/SMBSecurity/wiki