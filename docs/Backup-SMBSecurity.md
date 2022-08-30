---
external help file: SMBSecurity-help.xml
Module Name: SMBSecurity
online version:
schema: 2.0.0
---

# Backup-SMBSecurity

## SYNOPSIS
{{ Creates a file-based copy of an SMB SecurityDescriptor (SD). }}

## SYNTAX

```
Backup-SMBSecurity [[-SecurityDescriptorName] <String[]>] [[-Path] <String>] [-RegOnly] [-WithReg]
 [-FilePassThru] [<CommonParameters>]
```

## DESCRIPTION
{{ Creates a file-based copy of an SMB SecurityDescriptor (SD). Individual SMB SDs are written as XML files. A full, or registry, backup file is written as a REG file. These files can by used by Restore-SMBSecurity to quickly revert changes. When no backup path is set the automatic backup path is used: %LOCALAPPDATA%\SMBSecurity. }}

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Backup-SMBSecurity }}
```

{{ Backs up all SMB Security Descriptors (SD) individually. A total of 14 XML files will be created in the automatic backup path %LOCALAPPDATA%\SMBSecurity (PowerShell: $ENV:LOCALAPPDATA\SMBSecurity). }}

### Example 2
```powershell
PS C:\> {{ Backup-SMBSecurity -RegOnly }}
```

{{ Backs up all SMB Security Descriptors (SD) to a single REG file. The files will be saved to the automatic backup path, %LOCALAPPDATA%\SMBSecurity. }}

### Example 3
```powershell
PS C:\> {{ Backup-SMBSecurity -SecurityDescriptorName SrvsvcDefaultShareInfo -Path C:\Backups\SMBSecurity -WithReg }}
```

{{ Backs up the SrvsvcDefaultShareInfo SMB SecurityDescriptor to an XML file, and all SMB Security Descriptors (SD) to a single REG file. The files will be saved to the custom backup path, C:\Backups\SMBSecurity. }}

### Example 4
```powershell
PS C:\> {{ $files = Backup-SMBSecurity -Path C:\Backups\SMBSecurity -WithReg -FilePassThru }}
```

{{ All SMB SecurityDescriptor will be backed up individually to XML files and as a single REG file. The files will be saved to the custom backup path, C:\Backups\SMBSecurity. The full file paths will be returned and stored in the $files variable. }}

## PARAMETERS

### -FilePassThru
{{ Returns an array of full paths to each file created by Backup-SMBSecurity. }}

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

### -Path
{{ Sets the backup path. The automatic backup path (%LOCALAPPDATA%\SMBSecurity) is used when the path is not set or is invalid. }}

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

### -RegOnly
{{ Only a full registry export-based backup is created. Individual backups using XML files are not created. }}

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

### -SecurityDescriptorName
{{ The name(s) of the SMB SecurityDescriptor(s) to be backed up. The valid set of names are: SrvsvcConfigInfo, SrvsvcConnection, SrvsvcFile, SrvsvcServerDiskEnum, SrvsvcSessionInfo, SrvsvcShareAdminConnect, SrvsvcShareAdminInfo, SrvsvcShareChange, SrvsvcShareConnect, SrvsvcShareFileInfo, SrvsvcSharePrintInfo, SrvsvcStatisticsInfo, SrvsvcTransportEnum, and SrvsvcDefaultShareInfo. }}

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: SDName, Name

Required: False
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WithReg
{{ Creates a full registry export-based backup in addition to the individual XML-based backup.  }}

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

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS

[Backup-SMBSecurity](https://github.com/microsoft/SMBSecurity/wiki/Backup%E2%80%90SMBSecurity)