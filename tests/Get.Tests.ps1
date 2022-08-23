#requires -Module Pester

# setup
BeforeAll {
    #$VerbosePreference = "Continue"
    #$DebugPreference   = "Continue"

    # set the module path
    [string]$Script:SMBSecModulePath = "C:\Temp\SMBSecurity"

    Set-Location "$Script:SMBSecModulePath"
    Import-Module "$Script:SMBSecModulePath"

    # Importing SDDL flags.
    # this seems to be the only consistent way to import the JSON file
    try 
    {
        $script:SMBSEC_ACE_TYPE = Get-Content "$Script:SMBSecModulePath\bin\sddl_flags.json" -EA Stop | ConvertFrom-Json    
    }
    catch 
    {
        return (Write-Error "Failed to import the SDDL flags file ($Script:SMBSecModulePath\bin\sddl_flags.json): $_ " -EA Stop)    
    }


    # load files in bin - doing this plus ScriptsToProcess in the module file seems to consistently load all the functions, classes, and enums.
    # remove either this or ScriptsToProcess and things start to break, so do them both.
    [array]$binFiles = Get-ChildItem "$SMBSecModulePath\bin\*.ps1" -EA SilentlyContinue
    foreach ($file in $binFiles)
    {
        try 
        {
            Write-Debug "Loading $($file.FullName)"
            . $file.FullName
        }
        catch 
        {
            return ( Write-Error "Failed to load file $($file.FullName): $_" -EA Stop )
        }
    }

    $Script:backup = Backup-SMBSecurity -Path C:\Temp -RegOnly -FilePassThru | Where-Object { $_ -match "^.*\.reg$"}
}


Describe 'Get-SMBSecurity' {
    It "Given no parameters, it will list all 14 SMB Security Descriptors." {
        $SMBSec = Get-SMBSecurity
        $SMBSec.Count | Should -Be 14
    }

    Context "Filter by SecurityDescriptor" {
        It "Given a valid -SecurityDescriptor '<SecurityDescriptor>', it returns [SecurityDescriptor]." -TestCases @(
            
            @{ Filter = 'SrvsvcConfigInfo'        ; Expected = 'SrvsvcConfigInfo'},
            @{ Filter = 'SrvsvcConnection'        ; Expected = 'SrvsvcConnection'},
            @{ Filter = 'SrvsvcFile'              ; Expected = 'SrvsvcFile'},
            @{ Filter = 'SrvsvcServerDiskEnum'    ; Expected = 'SrvsvcServerDiskEnum'},
            @{ Filter = 'SrvsvcSessionInfo'       ; Expected = 'SrvsvcSessionInfo'},
            @{ Filter = 'SrvsvcShareAdminConnect' ; Expected = 'SrvsvcShareAdminConnect'},
            @{ Filter = 'SrvsvcShareAdminInfo'    ; Expected = 'SrvsvcShareAdminInfo'},
            @{ Filter = 'SrvsvcShareChange'       ; Expected = 'SrvsvcShareChange'},
            @{ Filter = 'SrvsvcShareConnect'      ; Expected = 'SrvsvcShareConnect'},
            @{ Filter = 'SrvsvcShareFileInfo'     ; Expected = 'SrvsvcShareFileInfo'},
            @{ Filter = 'SrvsvcSharePrintInfo'    ; Expected = 'SrvsvcSharePrintInfo'},
            @{ Filter = 'SrvsvcStatisticsInfo'    ; Expected = 'SrvsvcStatisticsInfo'},
            @{ Filter = 'SrvsvcTransportEnum'     ; Expected = 'SrvsvcTransportEnum'},
            @{ Filter = 'SrvsvcDefaultShareInfo'  ; Expected = 'SrvsvcDefaultShareInfo'}
        ) {
            param ($Filter, $Expected)

            $SMBSec = Get-SMBSecurity -SecurityDescriptorName $Filter
            $SMBSec.Name | Should -Be $Expected
        }

        It "Given an invalid parameter -SecurityDescriptor 'blah', it returns an error and the variable will be NULL." {
            # use -EA SilentlyContinue to supress the error.
            $SMBSec = Get-SMBSecurity -SecurityDescriptorName 'blah' -EA SilentlyContinue
            $SMBSec | Should -BeNullOrEmpty
        }
    }
}


Describe 'Get-SMBSecurityDescriptorName' {
    It "Given no parameters, it will list all 14 SMB Security Descriptor names as a string list without descriptions." {
        $SMBSec = Get-SMBSecurityDescriptorName
        $SMBSec.Count | Should -Be 14
    }
}


Describe 'Get-SMBSecurityDescription' {
    It "Given no parameters, it will list all 14 SMB Security Descriptors with descriptions." {
        $SMBSec = Get-SMBSecurityDescription
        $SMBSec.Count | Should -Be 14
    }

    Context "Filter by SecurityDescriptor" {
        It "Given a valid -SecurityDescriptor '<SecurityDescriptor>', it returns a description." -TestCases @(
            @{ Filter = 'SrvsvcDefaultShareInfo'  ; Expected = 'Default Share Permissions'},
            @{ Filter = 'SrvsvcShareAdminConnect' ; Expected = 'Connect to Administrative Shares'},
            @{ Filter = 'SrvsvcStatisticsInfo'    ; Expected = 'Read File/Print Server Statistics'}, 
            @{ Filter = 'SrvsvcFile'              ; Expected = 'Manage File Server Open Files'},
            @{ Filter = 'SrvsvcSessionInfo'       ; Expected = 'Manage File/Print Server Sessions'},
            @{ Filter = 'SrvsvcConfigInfo'        ; Expected = 'Manage File and Print Sharing'},
            @{ Filter = 'SrvsvcTransportEnum'     ; Expected = 'Enumerate Server Transport Protocols'},
            @{ Filter = 'SrvsvcShareFileInfo'     ; Expected = 'Manage File Shares'},
            @{ Filter = 'SrvsvcSharePrintInfo'    ; Expected = 'Manage Printer Shares'},
            @{ Filter = 'SrvsvcShareChange'       ; Expected = 'Manage share permissions'},
            @{ Filter = 'SrvsvcShareConnect'      ; Expected = 'Connect to File and Printer Shares'},
            @{ Filter = 'SrvsvcShareAdminInfo'    ; Expected = 'Manage Administrative Shares'},
            @{ Filter = 'SrvsvcConnection'        ; Expected = 'Manage File/Print Server Connections'},
            @{ Filter = 'SrvsvcServerDiskEnum'    ; Expected = 'Enumerate File Server Disks'}
        ) {
            param ($Filter, $Expected)

            $SMBSec = Get-SMBSecurityDescription -SecurityDescriptor $Filter
            $SMBSec | Should -Be $Expected
        }
    }
}


Describe 'Get-SMBSecurityDescriptorRight' {
    Context "Filter by SecurityDescriptor" {
        It "Given a valid -SecurityDescriptor '<SecurityDescriptor>', it returns a hashtable of available rights." -TestCases @(
            @{ Filter = 'SrvsvcDefaultShareInfo'  ; Expected = 3},
            @{ Filter = 'SrvsvcShareAdminConnect' ; Expected = 7},
            @{ Filter = 'SrvsvcStatisticsInfo'    ; Expected = 6},
            @{ Filter = 'SrvsvcFile'              ; Expected = 7},
            @{ Filter = 'SrvsvcSessionInfo'       ; Expected = 8},
            @{ Filter = 'SrvsvcConfigInfo'        ; Expected = 9},
            @{ Filter = 'SrvsvcTransportEnum'     ; Expected = 8},
            @{ Filter = 'SrvsvcShareFileInfo'     ; Expected = 8},
            @{ Filter = 'SrvsvcSharePrintInfo'    ; Expected = 8},
            @{ Filter = 'SrvsvcShareChange'       ; Expected = 8},
            @{ Filter = 'SrvsvcShareConnect'      ; Expected = 7},
            @{ Filter = 'SrvsvcShareAdminInfo'    ; Expected = 8},
            @{ Filter = 'SrvsvcConnection'        ; Expected = 6},
            @{ Filter = 'SrvsvcServerDiskEnum'    ; Expected = 6}
        ) {
            param ($Filter, $Expected)

            $SMBSec = Get-SMBSecurityDescriptorRight -SecurityDescriptor $Filter
            $SMBSec.Count | Should -Be $Expected
        }
    }
}

AfterAll {
    Restore-SMBSecurity -File $Script:backup
    Remove-Item $Script:backup -Force
}