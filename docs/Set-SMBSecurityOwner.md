---
external help file: SMBSecurity-help.xml
Module Name: SMBSecurity
online version:
schema: 2.0.0
---

# Set-SMBSecurityOwner

## SYNOPSIS
{{ Replaces the Owner in a SecurityDescriptor. }}

## SYNTAX

```
Set-SMBSecurityOwner [-SecurityDescriptor] <PSObject> [[-Account] <Object>] [-PassThru] [<CommonParameters>]
```

## DESCRIPTION
{{ Replaces the Owner in a SecurityDescriptor. }}

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ $SD = Get-SMBSecurity -SecurityDescriptorName SrvsvcDefaultShareInfo }}
PS C:\> {{ Set-SMBSecurityOwner -SecurityDescriptor $SMBSec -Account "Administrator" }}
```

{{ Changes the owner of the SrvsvcDefaultShareInfo SMB SecurityDescriptor to the Administrator account.

WARNING! Extreme caution should be used when chaning SMB SecurityDescriptor owner! }}

## PARAMETERS

### -Account
{{ The owner name. String SID or account name, [System.Security.Principal.NTAccount], [System.Security.Principal.SecurityIdentifier] (SID), [SMBSecAccount], and ,[SMBSecGroup] objects are accepted. Strings accept input in 'username', 'domain\username', and 'user@domain' format. }}

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

### -PassThru
{{ Returns the result to the success stream. }}

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
{{ The SMBSecurityDescriptor object where the Owner will be changed. The SMBSecurityDescriptor object must originate from Get-SMBSecurity. }}

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Management.Automation.PSObject

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS

[Set-SMBSecurityOwner](https://github.com/microsoft/SMBSecurity/wiki/Set%E2%80%90SMBSecurityOwner)