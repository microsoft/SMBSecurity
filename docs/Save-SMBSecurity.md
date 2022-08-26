---
external help file: SMBSecurity-help.xml
Module Name: SMBSecurity
online version:
schema: 2.0.0
---

# Save-SMBSecurity

## SYNOPSIS
{{ Commits changes made to SMBSecurityDescriptor(s) to the system. }}

## SYNTAX

```
Save-SMBSecurity [-SecurityDescriptor] <PSObject[]> [[-BackupPath] <String>] [-BackupWithRegFile] [-Force]
 [<CommonParameters>]
```

## DESCRIPTION
{{ Commits changes made to SMBSecurityDescriptor(s) to the system. Running this command will automatically generate a backup prior to the committing the change. }}

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -BackupPath
{{ Path to the directory (folder) where backups will be written to. The automatic backup path (%LOCALAPPDATA%\\SMBSecurity) is used when this parameter is not set. }}

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

### -BackupWithRegFile
{{ Creates a full registry-based backup in addition to individual XML-based backup(s). The BackupPath is honored, when set; otherwise, the automatic backup path (%LOCALAPPDATA%\\SMBSecurity) is used.  }}

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

### -Force
{{ By default, changes are not committed to the system when the backup fails. The Force parameter will commit changes even if the backup fails. }}

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
{{ The SMBSecurityDescriptor object to be committed to the registry. The SMBSecurityDescriptor object must originate from Get-SMBSecurity. }}

```yaml
Type: PSObject[]
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