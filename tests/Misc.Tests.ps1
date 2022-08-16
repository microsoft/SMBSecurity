#requires -Module Pester

# Test of all exported New cmdlets.
[CmdletBinding()]
param ()

# setup
BeforeAll {
    #$VerbosePreference = "Continue"
    #$DebugPreference   = "Continue"

    # set the module path
    [string]$Script:SMBSecModulePath = "C:\Temp\SMBSecurity"

    Push-Location "$Script:SMBSecModulePath"
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

    # used in all tests
    $Script:SMBSec = Get-SMBSecurity -SecurityDescriptor SrvsvcDefaultShareInfo
    
    Pop-Location
}

Describe 'Add-SMBSecDACL' {
    Context " Add a new DACL to a SecurityDescriptor" {
        It " Authenticated Users." {
            $DACLSplat = @{
                SecurityDescriptor = 'SrvsvcDefaultShareInfo'
                Access             = 'Allow'
                Right              = 'FullControl'
                Account            = "Authenticated Users"
            }
            

            $DACL = New-SMBSecDACL @DACLSplat

            Add-SMBSecDACL -SecurityDescriptor $Script:SMBSec -DACL $DACL

            $sdDACL = $SMBSec.DACL[-1]

            $sdDACL.SecurityDescriptor    | Should -Be 'SrvsvcDefaultShareInfo'
            $sdDACL.Access                | Should -Be 'Allow'
            $sdDACL.Right                 | Should -Be 'FullControl'
            $sdDACL.Account.Account.Value | Should -Be "NT AUTHORITY\Authenticated Users"

        }

        It " Authenticated Users via pipeline." {
            $Script:SMBSec = Get-SMBSecurity -SecurityDescriptor SrvsvcDefaultShareInfo

            $DACLSplat = @{
                SecurityDescriptor = 'SrvsvcDefaultShareInfo'
                Access             = 'Allow'
                Right              = 'FullControl'
                Account            = "Authenticated Users"
            }
            

            $DACL = New-SMBSecDACL @DACLSplat

            $DACL | Add-SMBSecDACL -SecurityDescriptor $Script:SMBSec

            $sdDACL = $SMBSec.DACL[-1]

            $sdDACL.SecurityDescriptor    | Should -Be 'SrvsvcDefaultShareInfo'
            $sdDACL.Access                | Should -Be 'Allow'
            $sdDACL.Right                 | Should -Be 'FullControl'
            $sdDACL.Account.Account.Value | Should -Be "NT AUTHORITY\Authenticated Users"

        }
    }
}

Describe 'Remove-SMBSecDACL' {
    Context " Remove a DACL from a SecurityDescriptor" {
        It " Authenticated Users." {
            $Script:SMBSec = Get-SMBSecurity -SecurityDescriptor SrvsvcSharePrintInfo

            $DACL = $Script:SMBSec.DACL[4]

            Remove-SMBSecDACL -SecurityDescriptor $Script:SMBSec -DACL $DACL

            $Script:SMBSec.DACL.Account.Username | Should -Not -Contain $DACL.Account.Username

        }

        It " Authenticated Users via pipeline." {
            $Script:SMBSec = Get-SMBSecurity -SecurityDescriptor SrvsvcSharePrintInfo

            $DACL = $Script:SMBSec.DACL | Where-Object {$_.Account.Username -eq "Everyone"}

            $DACL | Remove-SMBSecDACL -SecurityDescriptor $Script:SMBSec

            $Script:SMBSec.DACL.Account.Username | Should -Not -Contain $DACL.Account.Username

        }
    }
}


Describe 'Backup-SMBSecurity' {
    Context ' Backup a single SD' {
        It ' Test all SDs.'  -TestCases @(
            @{ SD = 'SrvsvcDefaultShareInfo' },
            @{ SD = 'SrvsvcShareAdminConnect'},
            @{ SD = 'SrvsvcStatisticsInfo'   }, 
            @{ SD = 'SrvsvcFile'             },
            @{ SD = 'SrvsvcSessionInfo'      },
            @{ SD = 'SrvsvcConfigInfo'       },
            @{ SD = 'SrvsvcTransportEnum'    },
            @{ SD = 'SrvsvcShareFileInfo'    },
            @{ SD = 'SrvsvcSharePrintInfo'   },
            @{ SD = 'SrvsvcShareChange'      },
            @{ SD = 'SrvsvcShareConnect'     },
            @{ SD = 'SrvsvcShareAdminInfo'   },
            @{ SD = 'SrvsvcConnection'       },
            @{ SD = 'SrvsvcServerDiskEnum'   }
        ) {
            param ($SD)

            $pathRoot = "$ENV:LOCALAPPDATA\SMBSecurity"

            $result = Backup-SMBSecurity -SecurityDescriptor $SD

            $result | Should -Be $true
            (Get-ChildItem "$pathRoot" -Filter "Backup-$SD`-SMBSec-*").FullName | Should -Exist

            # archive the backups for future tests
            $null = mkdir "$pathRoot\Archive" -Force
            Get-ChildItem "$pathRoot" -Filter "*.xml" | Move-Item -Destination "$pathRoot\Archive" -Force
        }
    }
}


Describe 'Save-SMBSecurity' {
    Context ' Save a single SD' {
        It ' Test all SDs.'  -TestCases @(
            @{ SD = 'SrvsvcDefaultShareInfo' },
            @{ SD = 'SrvsvcShareAdminConnect'},
            @{ SD = 'SrvsvcStatisticsInfo'   }, 
            @{ SD = 'SrvsvcFile'             },
            @{ SD = 'SrvsvcSessionInfo'      },
            @{ SD = 'SrvsvcConfigInfo'       },
            @{ SD = 'SrvsvcTransportEnum'    },
            @{ SD = 'SrvsvcShareFileInfo'    },
            @{ SD = 'SrvsvcSharePrintInfo'   },
            @{ SD = 'SrvsvcShareChange'      },
            @{ SD = 'SrvsvcShareConnect'     },
            @{ SD = 'SrvsvcShareAdminInfo'   },
            @{ SD = 'SrvsvcConnection'       },
            @{ SD = 'SrvsvcServerDiskEnum'   }
        ) {
            param ($SD)

            # constant locations
            $pathRoot = "$ENV:LOCALAPPDATA\SMBSecurity"
            $Script:SMBSecRegPath = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\DefaultSecurity"

            # dot source Add-RegKeyMember to get LastWriteTime
            #. .\Add-RegKeyMember.ps1

            # start state
            $SMBSecBefore = Get-SMBSecurity -SecurityDescriptor $SD
            #$sdPropBefore = Get-Item $Script:SMBSecRegPath | Add-RegKeyMember

            # perform sace
            $null = Save-SMBSecurity -SecurityDescriptor $SMBSecBefore

            # start state
            $SMBSecAfter = Get-SMBSecurity -SecurityDescriptor $SD
            #$sdPropAfter = Get-Item $Script:SMBSecRegPath | Add-RegKeyMember

            # the actuacl Pester tests
            #$result | Should -Be $true
            (Get-ChildItem "$pathRoot" -Filter "Backup-$SD`-SMBSec-*").FullName | Should -Exist
            $SMBSecBefore.SecurityDescriptor | Should -Be $SMBSecAfter.SecurityDescriptor
            $SMBSecBefore.Account | Should -Be $SMBSecAfter.Account
            $SMBSecBefore.Access | Should -Be $SMBSecAfter.Access
            $SMBSecBefore.DACL.Count | Should -Be $SMBSecAfter.DACL.Count
            $SMBSecBefore.DACL[0].Account.Username | Should -Be $SMBSecAfter.DACL[0].Account.Username

            # archive the backups for future tests
            $null = mkdir "$pathRoot\Archive" -Force
            Get-ChildItem "$pathRoot" -Filter "*.xml" | Move-Item -Destination "$pathRoot\Archive" -Force
        }
    }

    Context ' Save multiple SDs' {
        It ' Modify and save SrvsvcDefaultShareInfo and SrvsvcShareFileInfo' {

        }
    }
}

