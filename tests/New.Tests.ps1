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




Describe 'New-SMBSecurityOwner' {
    Context 'Create an SMBSecAccount for a SecurityDescriptor Owner using LOCAL accounts.' {
        It 'Using SYSTEM' {
            $account = "SYSTEM"
            $Owner = New-SMBSecurityOwner -Account $account

            $Owner.Account.Value | Should -Be "NT AUTHORITY\SYSTEM"
            $Owner.Username | Should -Be "SYSTEM"
            $Owner.Domain | Should -Be "NT AUTHORITY"
            $Owner.SID.Value | Should -Be "S-1-5-18"
        }

        It 'Using NT AUTHORITY\SYSTEM' {
            $account = "NT AUTHORITY\SYSTEM"
            $Owner = New-SMBSecurityOwner -Account $account

            $Owner.Account.Value | Should -Be "NT AUTHORITY\SYSTEM"
            $Owner.Username | Should -Be "SYSTEM"
            $Owner.Domain | Should -Be "NT AUTHORITY"
            $Owner.SID.Value | Should -Be "S-1-5-18"
        }

        It 'Using Administrator' {
            $account = "Administrator"
            $Owner = New-SMBSecurityOwner -Account $account

            $Owner.Account.Value | Should -Be "$ENV:COMPUTERNAME\Administrator"
            $Owner.Username | Should -Be "Administrator"
            $Owner.Domain | Should -Be "$ENV:COMPUTERNAME"
            $Owner.SID.Value | Should -Be "S-1-5-21-3682288071-2677039094-2007860391-500" # Domain SID
        }

        It 'Using `$ENV:COMPUTERNAME\Administrator' {
            $account = "$ENV:COMPUTERNAME\Administrator"
            $Owner = New-SMBSecurityOwner -Account $account

            $Owner.Account.Value | Should -Be "$ENV:COMPUTERNAME\Administrator"
            $Owner.Username | Should -Be "Administrator"
            $Owner.Domain | Should -Be "$ENV:COMPUTERNAME"
            $Owner.SID.Value | Should -Be "S-1-5-21-3682288071-2677039094-2007860391-500" # Domain SID
        }
    }

    Context 'Using LocalTest local account.' {
        It 'Using LocalTest' {
            $account = "LocalTest"
            $Owner = New-SMBSecurityOwner -Account $account

            $Owner.Account.Value | Should -Be "$ENV:COMPUTERNAME\LocalTest"
            $Owner.Username | Should -Be "LocalTest"
            $Owner.Domain | Should -Be "$ENV:COMPUTERNAME"
            $Owner.SID.Value | Should -Be "S-1-5-21-3682288071-2677039094-2007860391-1000" # Domain SID
        }

        It 'Using `$ENV:COMPUTERNAME\LocalTest' {
            $account = "$ENV:COMPUTERNAME\LocalTest"
            $Owner = New-SMBSecurityOwner -Account $account

            $Owner.Account.Value | Should -Be "$ENV:COMPUTERNAME\LocalTest"
            $Owner.Username | Should -Be "LocalTest"
            $Owner.Domain | Should -Be "$ENV:COMPUTERNAME"
            $Owner.SID.Value | Should -Be "S-1-5-21-3682288071-2677039094-2007860391-1000" # Domain SID
        }
    }

    Context 'Using DomainTest domain account.' {
        It 'Using DomainTest' {
            $account = "DomainTest"
            $Owner = New-SMBSecurityOwner -Account $account

            $Owner.Account.Value | Should -Be "TEST\DomainTest"
            $Owner.Username | Should -Be "DomainTest"
            $Owner.Domain | Should -Be "TEST"
            $Owner.SID.Value | Should -Be "S-1-5-21-2886623969-384694833-2076070812-1108" # Domain SID
        }

        It 'Using `$ENV:COMPUTERNAME\DomainTest' {
            $account = "$ENV:COMPUTERNAME\DomainTest"
            $Owner = New-SMBSecurityOwner -Account $account

            $Owner.Account.Value | Should -Be "TEST\DomainTest"
            $Owner.Username | Should -Be "DomainTest"
            $Owner.Domain | Should -Be "TEST"
            $Owner.SID.Value | Should -Be "S-1-5-21-2886623969-384694833-2076070812-1108" # Domain SID
        }
    }
}


Describe 'New-SMBSecurityGroup' {
    Context 'Create an SMBSecAccount for a SecurityDescriptor Group using LOCAL USER accounts.' {
        It 'Using SYSTEM' {
            $account = "SYSTEM"
            $Owner = New-SMBSecurityGroup -Account $account

            $Owner.Account.Value | Should -Be "NT AUTHORITY\SYSTEM"
            $Owner.Username | Should -Be "SYSTEM"
            $Owner.Domain | Should -Be "NT AUTHORITY"
            $Owner.SID.Value | Should -Be "S-1-5-18"
        }

        It 'Using NT AUTHORITY\SYSTEM' {
            $account = "NT AUTHORITY\SYSTEM"
            $Owner = New-SMBSecurityGroup -Account $account

            $Owner.Account.Value | Should -Be "NT AUTHORITY\SYSTEM"
            $Owner.Username | Should -Be "SYSTEM"
            $Owner.Domain | Should -Be "NT AUTHORITY"
            $Owner.SID.Value | Should -Be "S-1-5-18"
        }

        It 'Using Administrator' {
            $account = "Administrator"
            $Owner = New-SMBSecurityGroup -Account $account

            $Owner.Account.Value | Should -Be "$ENV:COMPUTERNAME\Administrator"
            $Owner.Username | Should -Be "Administrator"
            $Owner.Domain | Should -Be "$ENV:COMPUTERNAME"
            $Owner.SID.Value | Should -Be "S-1-5-21-3682288071-2677039094-2007860391-500" # Domain SID
        }

        It 'Using `$ENV:COMPUTERNAME\Administrator' {
            $account = "$ENV:COMPUTERNAME\Administrator"
            $Owner = New-SMBSecurityGroup -Account $account

            $Owner.Account.Value | Should -Be "$ENV:COMPUTERNAME\Administrator"
            $Owner.Username | Should -Be "Administrator"
            $Owner.Domain | Should -Be "$ENV:COMPUTERNAME"
            $Owner.SID.Value | Should -Be "S-1-5-21-3682288071-2677039094-2007860391-500" # Domain SID
        }
    }

    Context 'Using LocalTest local account.' {
        It 'Using LocalTest' {
            $account = "LocalTest"
            $Owner = New-SMBSecurityGroup -Account $account

            $Owner.Account.Value | Should -Be "$ENV:COMPUTERNAME\LocalTest"
            $Owner.Username | Should -Be "LocalTest"
            $Owner.Domain | Should -Be "$ENV:COMPUTERNAME"
            $Owner.SID.Value | Should -Be "S-1-5-21-3682288071-2677039094-2007860391-1000" # Domain SID
        }

        It 'Using `$ENV:COMPUTERNAME\LocalTest' {
            $account = "$ENV:COMPUTERNAME\LocalTest"
            $Owner = New-SMBSecurityGroup -Account $account

            $Owner.Account.Value | Should -Be "$ENV:COMPUTERNAME\LocalTest"
            $Owner.Username | Should -Be "LocalTest"
            $Owner.Domain | Should -Be "$ENV:COMPUTERNAME"
            $Owner.SID.Value | Should -Be "S-1-5-21-3682288071-2677039094-2007860391-1000" # Domain SID
        }
    }

    Context 'Using DomainTest domain account.' {
        It 'Using DomainTest' {
            $account = "DomainTest"
            $Owner = New-SMBSecurityGroup -Account $account

            $Owner.Account.Value | Should -Be "TEST\DomainTest"
            $Owner.Username | Should -Be "DomainTest"
            $Owner.Domain | Should -Be "TEST"
            $Owner.SID.Value | Should -Be "S-1-5-21-2886623969-384694833-2076070812-1108" # Domain SID
        }

        It 'Using `$TEST\DomainTest' {
            $account = "TEST\DomainTest"
            $Owner = New-SMBSecurityGroup -Account $account

            $Owner.Account.Value | Should -Be "TEST\DomainTest"
            $Owner.Username | Should -Be "DomainTest"
            $Owner.Domain | Should -Be "TEST"
            $Owner.SID.Value | Should -Be "S-1-5-21-2886623969-384694833-2076070812-1108" # Domain SID
        }
    }

    Context 'Using LocalGroup.' {
        It 'Account name LocalGroup' {
            $account = "LocalGroup"
            $Owner = New-SMBSecurityGroup -Account $account

            $Owner.Account.Value | Should -Be "$ENV:COMPUTERNAME\LocalGroup"
            $Owner.Username | Should -Be "LocalGroup"
            $Owner.Domain | Should -Be "$ENV:COMPUTERNAME"
            $Owner.SID.Value | Should -Be "S-1-5-21-3682288071-2677039094-2007860391-1001"
        }

        It 'Account name `$ENV:COMPUTERNAME\LocalGroup' {
            $account = "$ENV:COMPUTERNAME\LocalGroup"
            $Owner = New-SMBSecurityGroup -Account $account

            $Owner.Account.Value | Should -Be "$ENV:COMPUTERNAME\LocalGroup"
            $Owner.Username | Should -Be "LocalGroup"
            $Owner.Domain | Should -Be "$ENV:COMPUTERNAME"
            $Owner.SID.Value | Should -Be "S-1-5-21-3682288071-2677039094-2007860391-1001"
        }
    }

    Context 'Using DomainGroup' {
        It 'Account name DomainGroup' {
            $account = "DomainGroup"
            $Owner = New-SMBSecurityGroup -Account $account

            $Owner.Account.Value | Should -Be "TEST\DomainGroup"
            $Owner.Username | Should -Be "DomainGroup"
            $Owner.Domain | Should -Be "TEST"
            $Owner.SID.Value | Should -Be "S-1-5-21-2886623969-384694833-2076070812-1109"
        }

        It 'Account name `TEST\DomainGroup' {
            $account = "TEST\DomainGroup"
            $Owner = New-SMBSecurityGroup -Account $account

            $Owner.Account.Value | Should -Be "TEST\DomainGroup"
            $Owner.Username | Should -Be "DomainGroup"
            $Owner.Domain | Should -Be "TEST"
            $Owner.SID.Value | Should -Be "S-1-5-21-2886623969-384694833-2076070812-1109"
        }
    }
}


Describe 'New-SMBSecurityDACL' {  
    Context 'Creates a DACL that can be added to a SecurityDescriptor object.' {
        It 'Creating a DACL for SrvsvcDefaultShareInfo' {
            
            $DACLSplat = @{
                SecurityDescriptorName = 'SrvsvcDefaultShareInfo'
                Access                 = 'Allow'
                Right                  = @('Change', 'Read')
                Account                = "Administrator"
            }
            

            $DACL = New-SMBSecurityDACL @DACLSplat

            $DACL.SecurityDescriptor | Should -Be "SrvsvcDefaultShareInfo"
            $DACL.SecurityDescriptor.GetType().Name | Should -Be 'SMBSecurityDescriptor'

            $DACL.Access | Should -Be "Allow"
            $DACL.Access.GetType().Name | Should -Be 'SMBSecAccess'

            Write-Verbose "New-SMBSecurityDACL - Count: $($DACL.Right.Count), Value(s): $($DACL.Right -join '", ')"
            $DACL.Right.Count | Should -Be 2
            $DACL.Right | Should -Contain "Change"
            $DACL.Right | Should -Contain "Read"
            $DACL.Right.GetType().Name | Should -Be 'String[]'

            $DACL.Account.Account.Value | Should -Be "$ENV:COMPUTERNAME\Administrator"
            $DACL.Account.GetType().Name | Should -Be 'SMBSecAccount'
        }

        It 'Other writes are ignored when FullControl is used.' {
            
            $DACLSplat = @{
                SecurityDescriptorName = 'SrvsvcDefaultShareInfo'
                Access                 = 'Allow'
                Right                  = @('Change', 'Read', 'FullControl')
                Account                = "Administrator"
            }
            

            $DACL = New-SMBSecurityDACL @DACLSplat

            $DACL.SecurityDescriptor | Should -Be "SrvsvcDefaultShareInfo"
            $DACL.SecurityDescriptor.GetType().Name | Should -Be 'SMBSecurityDescriptor'

            $DACL.Access | Should -Be "Allow"
            $DACL.Access.GetType().Name | Should -Be 'SMBSecAccess'

            Write-Verbose "New-SMBSecurityDACL - Count: $($DACL.Right.Count), Value(s): $($DACL.Right -join '", ')"
            $DACL.Right.Count | Should -Be 1
            $DACL.Right | Should -Contain "FullControl"
            $DACL.Right.GetType().Name | Should -Be 'String[]'

            $DACL.Account.Account.Value | Should -Be "$ENV:COMPUTERNAME\Administrator"
            $DACL.Account.GetType().Name | Should -Be 'SMBSecAccount'
        }
    }

    
    Context 'The DACL rights are limited by a static set of rights based on the SecurityDescriptor name.' {
        It 'Creating a DACL for SrvsvcDefaultShareInfo' {
            
            $DACLSplat = @{
                SecurityDescriptorName = 'SrvsvcDefaultShareInfo'
                Access                 = 'Allow'
                Right                  = @('Change', 'Read', 'Cheese')
                Account                = "Administrator"
            }
            

            $DACL = New-SMBSecurityDACL @DACLSplat -EA SilentlyContinue

            $DACL | Should -BeNullOrEmpty
        }
    }
    
}


Describe 'New-SMBSecurityDescriptor' {
    Context 'Creates SecurityDescriptor object which can be manipulated and saved to the system' {
        It ' New SD using objects and a single DACL.' {
            # create a DACL
            $DACLSplat = @{
                SecurityDescriptor = 'SrvsvcDefaultShareInfo'
                Access             = 'Allow'
                Right              = 'FullControl'
                Account            = "Administrator"
            }
            

            $DACL = New-SMBSecurityDACL @DACLSplat

            # create an owner
            $account = "NT AUTHORITY\SYSTEM"
            $Owner = New-SMBSecurityOwner -Account $account

            # create a group
            $Group = New-SMBSecurityGroup -Account $account

            $SD = New-SMBSecurityDescriptor -SecurityDescriptor "SrvsvcDefaultShareInfo" -Owner $Owner -Group $Group -DACL $DACL

            $SD.Owner.Account | Should -Be "NT AUTHORITY\SYSTEM"
            $SD.Group.Account | Should -Be "NT AUTHORITY\SYSTEM"
            $SD.Name | Should -Be "SrvsvcDefaultShareInfo"
            $SD.DACL.Account | Should -Be "JAK-19-SMBSEC\Administrator"
            $SD.DACL.Right.Count | Should -Be 1
            $SD.DACL.Right | Should -Contain "FullControl"
        }

        It 'New SD using objects and a multiple DACLs in ArrayList.' {
            # create a DACL
            $DACLs = New-Object System.Collections.ArrayList

            $DACLSplat = @{
                SecurityDescriptor = 'SrvsvcDefaultShareInfo'
                Access             = 'Allow'
                Right              = 'FullControl'
                Account            = "Administrators"
            }
            

            $DACL = New-SMBSecurityDACL @DACLSplat

            $DACLSplat2 = @{
                SecurityDescriptor = 'SrvsvcDefaultShareInfo'
                Access             = 'Allow'
                Right              = 'Read'
                Account            = "Authenticated Users"
            }
            

            $DACL2 = New-SMBSecurityDACL @DACLSplat2

            $DACLs.Add($DACL)
            $DACLs.Add($DACL2)


            # create an owner
            $account = "SYSTEM"
            $Owner = New-SMBSecurityOwner -Account $account

            # create a group
            $Group = New-SMBSecurityGroup -Account $account

            $SD = New-SMBSecurityDescriptor -SecurityDescriptor "SrvsvcDefaultShareInfo" -Owner $Owner -Group $Group -DACL $DACLs

            $SD.DACL.Count | Should -Be 2
            $SD.DACL.SecurityDescriptor[0] | Should -Be "SrvsvcDefaultShareInfo"
            $SD.DACL.SecurityDescriptor[1] | Should -Be "SrvsvcDefaultShareInfo"

            $SD.DACL | Where-Object { $_.Account.Account.Value -match "Administrators" } | ForEach-Object { $_.Right } | Should -Contain 'FullControl'
            $SD.DACL | Where-Object { $_.Account.Account.Value -match "Authenticated Users" } | ForEach-Object { $_.Right } | Should -Contain 'Read'

        }

        It 'New SD using objects and a multiple DACLs in Array.' {
            # create a DACL
            $DACLs = @()

            $DACLSplat = @{
                SecurityDescriptor = 'SrvsvcDefaultShareInfo'
                Access             = 'Allow'
                Right              = 'FullControl'
                Account            = "Administrators"
            }
            

            $DACL = New-SMBSecurityDACL @DACLSplat

            $DACLSplat2 = @{
                SecurityDescriptor = 'SrvsvcDefaultShareInfo'
                Access             = 'Allow'
                Right              = 'Read'
                Account            = "Authenticated Users"
            }
            

            $DACL2 = New-SMBSecurityDACL @DACLSplat2

            $DACLs += $DACL
            $DACLs += $DACL2


            # create an owner
            $account = "SYSTEM"
            $Owner = New-SMBSecurityOwner -Account $account

            # create a group
            $Group = New-SMBSecurityGroup -Account $account

            $SD = New-SMBSecurityDescriptor -SecurityDescriptor "SrvsvcDefaultShareInfo" -Owner $Owner -Group $Group -DACL $DACLs

            $SD.DACL.Count | Should -Be 2
            $SD.DACL.SecurityDescriptor[0] | Should -Be "SrvsvcDefaultShareInfo"
            $SD.DACL.SecurityDescriptor[1] | Should -Be "SrvsvcDefaultShareInfo"

            $SD.DACL | Where-Object { $_.Account.Account.Value -match "Administrators" } | ForEach-Object { $_.Right } | Should -Contain 'FullControl'
            $SD.DACL | Where-Object { $_.Account.Account.Value -match "Authenticated Users" } | ForEach-Object { $_.Right } | Should -Contain 'Read'

        }

        It 'New SD using objects and a multiple DACLs in generic list.' {
            # create a DACL
            $DACLs = [System.Collections.Generic.List[PSCustomObject]]::new()

            $DACLSplat = @{
                SecurityDescriptor = 'SrvsvcDefaultShareInfo'
                Access             = 'Allow'
                Right              = 'FullControl'
                Account            = "Administrators"
            }
            

            $DACL = New-SMBSecurityDACL @DACLSplat

            $DACLSplat2 = @{
                SecurityDescriptor = 'SrvsvcDefaultShareInfo'
                Access             = 'Allow'
                Right              = 'Read'
                Account            = "Authenticated Users"
            }
            

            $DACL2 = New-SMBSecurityDACL @DACLSplat2

            $DACLs.Add($DACL)
            $DACLs.Add($DACL2)


            # create an owner
            $account = "SYSTEM"
            $Owner = New-SMBSecurityOwner -Account $account

            # create a group
            $Group = New-SMBSecurityGroup -Account $account

            $SD = New-SMBSecurityDescriptor -SecurityDescriptor "SrvsvcDefaultShareInfo" -Owner $Owner -Group $Group -DACL $DACLs

            $SD.DACL.Count | Should -Be 2
            $SD.DACL.SecurityDescriptor[0] | Should -Be "SrvsvcDefaultShareInfo"
            $SD.DACL.SecurityDescriptor[1] | Should -Be "SrvsvcDefaultShareInfo"

            $SD.DACL | Where-Object { $_.Account.Account.Value -match "Administrators" } | ForEach-Object { $_.Right } | Should -Contain 'FullControl'
            $SD.DACL | Where-Object { $_.Account.Account.Value -match "Authenticated Users" } | ForEach-Object { $_.Right } | Should -Contain 'Read'

        }

        It 'New SD for using an SDDL string,' {
            $strSDDL = 'O:SYG:SYD:(A;;FA;;;WD)'

            $SD = New-SMBSecurityDescriptor -SecurityDescriptor "SrvsvcDefaultShareInfo" -SDDLString $strSDDL

            $SD.Owner.Account | Should -Be "NT AUTHORITY\SYSTEM"
            $SD.Group.Account | Should -Be "NT AUTHORITY\SYSTEM"
            $SD.Name | Should -Be "SrvsvcDefaultShareInfo"
            $SD.DACL.Account | Should -Be "Everyone"
            $SD.DACL.Right.Count | Should -Be 1
            $SD.DACL.Right | Should -Contain "FullControl"
        }
    }
}

AfterAll {
    Restore-SMBSecurity -File $Script:backup
    
    # do file cleanup so it doesn't interfere with other tests
    $paths = "C:\Temp",  "$ENV:LOCALAPPDATA\SMBSecurity"

    foreach ($path in $paths)
    {
        $files = Get-ChildItem "$path" -Filter "SMBSec-*.reg"
        $files | ForEach-Object { Remove-Item $_.FullName -Force }

        $files = Get-ChildItem "$path" -Filter "Backup-*-SMBSec-*.xml"
        $files | ForEach-Object { Remove-Item $_.FullName -Force }
    }   
}