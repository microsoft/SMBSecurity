---
external help file: SMBSecurity-help.xml
Module Name: SMBSecurity
online version:
schema: 2.0.0
---

# Set-SMBSecurityGroup

## SYNOPSIS
{{ Replaces the Group in a SecurityDescriptor. }}

## SYNTAX

```
Set-SMBSecurityGroup [-SecurityDescriptor] <PSObject> [[-Account] <String>] [-PassThru] [<CommonParameters>]
```

## DESCRIPTION
{{ Replaces the Group in a SecurityDescriptor. }}

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ $SD = Get-SMBSecurity -SecurityDescriptorName SrvsvcDefaultShareInfo }}
PS C:\> {{ Set-SMBSecurityGroup -SecurityDescriptor $SMBSec -Account "Administrators" }}
```

{{ Changes the primary group of the SrvsvcDefaultShareInfo SMB SecurityDescriptor to the Administrators group.

WARNING! Extreme caution should be used when chaning SMB SecurityDescriptor group! }}

## PARAMETERS

### -Account
{{ The group name. String SID or account/group name, [System.Security.Principal.NTAccount], [System.Security.Principal.SecurityIdentifier] (SID), [SMBSecAccount], and ,[SMBSecGroup] objects are accepted. Strings accept input in '[username|group]', 'domain\\[username|group]', and '[username|group]@domain' format. }}

```yaml
Type: String
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

[Set-SMBSecurityGroup](https://github.com/microsoft/SMBSecurity/wiki/Set%E2%80%90SMBSecurityGroup)