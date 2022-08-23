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

    # used in all tests
    $Script:SMBSec = Get-SMBSecurity -SecurityDescriptorName SrvsvcDefaultShareInfo

    $Script:backup = Backup-SMBSecurity -Path C:\Temp -RegOnly -FilePassThru | Where-Object { $_ -match "^.*\.reg$"}
}

Describe 'Set-SMBSecurityOwner' {
    Context " Set the owner of a SecurityDescriptor using a local account" {
        It " Local Administrator." {
            Set-SMBSecurityOwner -SecurityDescriptor $SMBSec -Account "Administrator"

            $SMBSec.Owner.GetType().Name | Should -Be "SMBSecOwner"

            $SMBSec.Owner.Account.Value | Should -Be "$ENV:COMPUTERNAME\Administrator"
            $SMBSec.Owner.SID.Value | Should -Be "S-1-5-21-3682288071-2677039094-2007860391-500"
            $SMBSec.Owner.Username | Should -Be "Administrator"
            $SMBSec.Owner.Domain | Should -Be "$ENV:COMPUTERNAME"
        }
        
        It " Local account." {
            Set-SMBSecurityOwner -SecurityDescriptor $SMBSec -Account "LocalTest"

            $SMBSec.Owner.GetType().Name | Should -Be "SMBSecOwner"

            $SMBSec.Owner.Account.Value | Should -Be "$ENV:COMPUTERNAME\LocalTest"
            $SMBSec.Owner.SID.Value | Should -Be "S-1-5-21-3682288071-2677039094-2007860391-1000"
            $SMBSec.Owner.Username | Should -Be "LocalTest"
            $SMBSec.Owner.Domain | Should -Be "$ENV:COMPUTERNAME"
        }

    }

    Context "Set the owner of a SecurityDescriptor using a domain account." {
        It " Domain TEST\DomainTest." {
            Set-SMBSecurityOwner -SecurityDescriptor $SMBSec -Account "TEST\DomainTest"

            $SMBSec.Owner.GetType().Name | Should -Be "SMBSecOwner"

            $SMBSec.Owner.Account.Value | Should -Be "TEST\DomainTest"
            $SMBSec.Owner.SID.Value | Should -Be "S-1-5-21-2886623969-384694833-2076070812-1108"
            $SMBSec.Owner.Username | Should -Be "DomainTest"
            $SMBSec.Owner.Domain | Should -Be "TEST"
        }
    }
}

Describe 'Set-SMBSecurityGroup' {
    Context " Set the owner of a SecurityDescriptor using a local account" {
        It " Local Administrators." {
            Set-SMBSecurityGroup -SecurityDescriptor $SMBSec -Account "Administrators"

            $SMBSec.Group.GetType().Name | Should -Be "SMBSecGroup"

            $SMBSec.Group.Account.Value | Should -Be 'BUILTIN\Administrators'
            $SMBSec.Group.SID.Value | Should -Be "S-1-5-32-544"
            $SMBSec.Group.Username | Should -Be "Administrators"
            $SMBSec.Group.Domain | Should -Be "BUILTIN"
        }
        
        It " Local group." {
            Set-SMBSecurityGroup -SecurityDescriptor $SMBSec -Account "LocalGroup"

            $SMBSec.Group.GetType().Name | Should -Be "SMBSecGroup"

            $SMBSec.Group.Account.Value | Should -Be "$ENV:COMPUTERNAME\LocalGroup"
            $SMBSec.Group.SID.Value | Should -Be "S-1-5-21-3682288071-2677039094-2007860391-1001"
            $SMBSec.Group.Username | Should -Be "LocalGroup"
            $SMBSec.Group.Domain | Should -Be "$ENV:COMPUTERNAME"
        }

    }

    Context "Set the owner of a SecurityDescriptor using a domain account" {
        It " Domain TEST\DomainGroup." {
            Set-SMBSecurityGroup -SecurityDescriptor $SMBSec -Account "TEST\DomainGroup"

            $SMBSec.Group.GetType().Name | Should -Be "SMBSecGroup"

            $SMBSec.Group.Account.Value | Should -Be "TEST\DomainGroup"
            $SMBSec.Group.SID.Value | Should -Be "S-1-5-21-2886623969-384694833-2076070812-1109"
            $SMBSec.Group.Username | Should -Be "DomainGroup"
            $SMBSec.Group.Domain | Should -Be "TEST"
        }
    }
}

Describe 'Set-SMBSecurityDACL and Set-SmbSecurityDescriptorDACL' {
    Context " Modify the DACL (rights) of a SecurityDescriptor" {
        It " Change Access." {
            $Script:SMBSec = Get-SMBSecurity -SecurityDescriptorName SrvsvcSharePrintInfo

            $DACL = $Script:SMBSec.DACL[4]
            $NewDACL = Copy-SMBSecurityDACL $DACL

            Set-SMBSecurityDACL -DACL $NewDACL -Access Deny

            Set-SmbSecurityDescriptorDACL -SecurityDescriptor $Script:SMBSec -DACL $DACL -NewDACl $NewDACL

            $NewDACL.Access | Should -Be "Deny"
            $SMBSec.DACL[4].Account.Username | Should -Be "Everyone"
            $SMBSec.DACL[4].Access | Should -Be "Deny"

        }

        It " Change Rights." {
            $Script:SMBSec = Get-SMBSecurity -SecurityDescriptorName SrvsvcSharePrintInfo

            $DACL = $Script:SMBSec.DACL[4]
            $NewDACL = Copy-SMBSecurityDACL $DACL

            Set-SMBSecurityDACL -DACL $NewDACL -Right FullControl

            Set-SmbSecurityDescriptorDACL -SecurityDescriptor $Script:SMBSec -DACL $DACL -NewDACl $NewDACL

            $NewDACL.Right | Should -contain "FullControl"
            $SMBSec.DACL[4].Account.Username | Should -Be "Everyone"
            $SMBSec.DACL[4].Right | Should -Be "FullControl"
        }

        It " Change Account." {
            $Script:SMBSec = Get-SMBSecurity -SecurityDescriptorName SrvsvcSharePrintInfo

            $DACL = $Script:SMBSec.DACL[4]
            $NewDACL = Copy-SMBSecurityDACL $DACL

            Set-SMBSecurityDACL -DACL $NewDACL -Account "Authenticated Users"

            Set-SmbSecurityDescriptorDACL -SecurityDescriptor $Script:SMBSec -DACL $DACL -NewDACl $NewDACL

            $SMBSec.DACL[4].Account.Account.Value | Should -Be "NT AUTHORITY\Authenticated Users"
        }
    }
}

AfterAll {
    Restore-SMBSecurity -File $Script:backup
    Remove-Item $Script:backup -Force
}