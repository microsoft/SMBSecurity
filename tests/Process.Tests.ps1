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

<#

This test covers the process of replacing Everyone as the DefaultShareInfo with Authenticated Users.

#>

Describe 'Add a DACL' {
    Context ' Add Authenticated Users to SrvsvcDefaultShareInfo' {
        It ' using FullControl' {
            
            <#
            smbsec
            $SMBSec = Get-SMBSecurity SrvsvcDefaultShareInfo
            Remove-SMBSecurityDACL $SMBSec $SMBSec.DACL[1]
            Save-SMBSecurity $SMBSec
            $SMBSec

            Invoke-Pester
            
            #>


            # create the DACL
            $DACLSplat = @{
                SecurityDescriptorName = 'SrvsvcDefaultShareInfo'
                Access                 = 'Allow'
                Right                  = 'FullControl'
                Account                = "Authenticated Users"
            }
            
            $newDACL = New-SMBSecurityDACL @DACLSplat

            # validating newDACL
            $newDACL.SecurityDescriptor | Should -Be "SrvsvcDefaultShareInfo"
            $newDACL.SecurityDescriptor.GetType().Name | Should -Be 'SMBSecurityDescriptor'

            $newDACL.Access | Should -Be "Allow"
            $newDACL.Access.GetType().Name | Should -Be 'SMBSecAccess'

            $newDACL.Right.Count | Should -Be 1
            $newDACL.Right | Should -Contain "FullControl"
            $newDACL.Right.GetType().Name | Should -Be 'String[]'

            $newDACL.Account.Account.Value | Should -Be "NT AUTHORITY\Authenticated Users"
            $newDACL.Account.GetType().Name | Should -Be 'SMBSecAccount'
            

            # get the SrvsvcDefaultShareInfo SD
            $SMBSec = Get-SMBSecurity SrvsvcDefaultShareInfo

            $SMBSec.Name | Should -Be 'SrvsvcDefaultShareInfo'

            # add the DACL to the SD
            Add-SMBSecurityDACL -SecurityDescriptor $SMBSec -DACL $newDACL

            # validate SD after add
            $fndDACL = $SMBSec.DACL | Where-Object { $_.Account.Account.Value -eq 'NT AUTHORITY\Authenticated Users' }

            $fndDACL.SecurityDescriptor | Should -Contain "SrvsvcDefaultShareInfo"
            $fndDACL.SecurityDescriptor.GetType().Name | Should -Be 'SMBSecurityDescriptor'

            $fndDACL.Access | Should -Be "Allow"
            $fndDACL.Access.GetType().Name | Should -Be 'SMBSecAccess'

            $fndDACL.Right.Count | Should -Be 1
            $fndDACL.Right | Should -Contain "FullControl"
            $fndDACL.Right.GetType().Name | Should -Be 'String[]'

            $fndDACL.Account.Account.Value | Should -Be "NT AUTHORITY\Authenticated Users"
            $fndDACL.Account.GetType().Name | Should -Be 'SMBSecAccount'

            # save the SD
            Save-SMBSecurity $SMBSec

            # validate that a backup was created
            # short pause for file system ops to complete
            Start-Sleep -m 250 
            $pathRoot = "$ENV:LOCALAPPDATA\SMBSecurity"
            (Get-ChildItem "$pathRoot" -Filter "Backup-$($SMBSec.Name)`-SMBSec-*").FullName | Should -Exist


            # pull the new SrvsvcDefaultShareInfo SMBSec from the registry
            Remove-Variable SMBSec -EA SilentlyContinue
            $SMBSec = Get-SMBSecurity SrvsvcDefaultShareInfo

            # validate that the added DACL was in the registry
            $fndDACL = $SMBSec.DACL | Where-Object { $_.Account.Account.Value -eq 'NT AUTHORITY\Authenticated Users' }

            $fndDACL.SecurityDescriptor | Should -Be "SrvsvcDefaultShareInfo"
            $fndDACL.SecurityDescriptor.GetType().Name | Should -Be 'SMBSecurityDescriptor'

            $fndDACL.Access | Should -Be "Allow"
            $fndDACL.Access.GetType().Name | Should -Be 'SMBSecAccess'

            $fndDACL.Right.Count | Should -Be 1
            $fndDACL.Right | Should -Contain "FullControl"
            $fndDACL.Right.GetType().Name | Should -Be 'String[]'

            $fndDACL.Account.Account.Value | Should -Be "NT AUTHORITY\Authenticated Users"
            $fndDACL.Account.GetType().Name | Should -Be 'SMBSecAccount'

        }
    }
}

Describe 'Modify a DACL' {
    Context ' Modify Authenticated Users in SrvsvcDefaultShareInfo.' {
        It ' Change FullControl to Read' {

             <#
            smbsec
            $SMBSec = Get-SMBSecurity SrvsvcDefaultShareInfo
            Remove-SMBSecurityDACL $SMBSec $SMBSec.DACL[1]
            Save-SMBSecurity $SMBSec
            $SMBSec

            Invoke-Pester
            
            #>

            # get the SrvsvcDefaultShareInfo decriptor object
            $SMBSec = Get-SMBSecurity -SecurityDescriptorName SrvsvcDefaultShareInfo

            # create a copy of the Authenticated Users DACL
            $DACL = $SMBSec.DACL | Where-Object { $_.Account.Username -eq "Authenticated Users" }
            $NewDACL = Copy-SMBSecurityDACL $DACL

            # validating newDACL
            $NewDACL.SecurityDescriptor | Should -Be "SrvsvcDefaultShareInfo"
            $NewDACL.SecurityDescriptor.GetType().Name | Should -Be 'SMBSecurityDescriptor'

            $NewDACL.Access | Should -Be "Allow"
            $NewDACL.Access.GetType().Name | Should -Be 'SMBSecAccess'

            $NewDACL.Right.Count | Should -Be 1
            $NewDACL.Right | Should -Contain "FullControl"
            $NewDACL.Right.GetType().Name | Should -Be 'String[]'

            $NewDACL.Account.Account.Value | Should -Be "NT AUTHORITY\Authenticated Users"
            $NewDACL.Account.GetType().Name | Should -Be 'SMBSecAccount'


            # Modify the DACL
            Set-SMBSecurityDACL -DACL $NewDACL -Right Read

            # validate Right changed
            $NewDACL.Right | Should -Contain "Read"

            # set the DACL on the SD
            Set-SmbSecurityDescriptorDACL -SecurityDescriptor $SMBSec -DACL $DACL -NewDACl $NewDACL

            # validate the change on the SD
            $sdDACL = $SMBSec.DACL | Where-Object { $_.Account.Username -eq "Authenticated Users" }

            $sdDACL.Right | Should -Contain "Read"


            # save the SD
            Save-SMBSecurity -SecurityDescriptor $SMBSec

            # udpate SMBSec and validate change worked
            $SMBSec = Get-SMBSecurity -SecurityDescriptorName SrvsvcDefaultShareInfo
            $DACL = $SMBSec.DACL | Where-Object { $_.Account.Username -eq "Authenticated Users" }

            # validating newDACL
            $DACL.SecurityDescriptor | Should -Be "SrvsvcDefaultShareInfo"
            $DACL.SecurityDescriptor.GetType().Name | Should -Be 'SMBSecurityDescriptor'

            $DACL.Access | Should -Be "Allow"
            $DACL.Access.GetType().Name | Should -Be 'SMBSecAccess'

            $DACL.Right.Count | Should -Be 1
            $DACL.Right | Should -Contain "Read"
            $DACL.Right.GetType().Name | Should -Be 'String[]'

            $DACL.Account.Account.Value | Should -Be "NT AUTHORITY\Authenticated Users"
            $DACL.Account.GetType().Name | Should -Be 'SMBSecAccount'
        }
    }
}

Describe 'Remove a DACL' {
    Context ' Remove from SrvsvcDefaultShareInfo' {
        It ' The Everyone group.' {
             <#
            smbsec
            $SMBSec = Get-SMBSecurity SrvsvcDefaultShareInfo
            Remove-SMBSecurityDACL $SMBSec $SMBSec.DACL[1]
            Save-SMBSecurity $SMBSec
            $SMBSec

            Invoke-Pester
            
            #>

            # get the SrvsvcDefaultShareInfo decriptor object
            $SMBSec = Get-SMBSecurity -SecurityDescriptorName SrvsvcDefaultShareInfo

            $DACL = $SMBSec.DACL | Where-Object {$_.Account.Username -eq "Everyone"}

            $DACL.SecurityDescriptor | Should -Be "SrvsvcDefaultShareInfo"
            $DACL.SecurityDescriptor.GetType().Name | Should -Be 'SMBSecurityDescriptor'

            $DACL.Access | Should -Be "Allow"
            $DACL.Access.GetType().Name | Should -Be 'SMBSecAccess'

            $DACL.Right.Count | Should -Be 1
            $DACL.Right | Should -Contain "Read"
            $DACL.Right.GetType().Name | Should -Be 'String[]'

            $DACL.Account.Username | Should -Be "Everyone"
            $DACL.Account.GetType().Name | Should -Be 'SMBSecAccount'

            # remove the DACL
            $DACL | Remove-SMBSecurityDACL -SecurityDescriptor $SMBSec

            # validate
            $SMBSec.DACL.Account.Username | Should -Not -Contain "Everyone"


            # save change
            Save-SMBSecurity -SecurityDescriptor $SMBSec

            # update the SrvsvcDefaultShareInfo decriptor object
            $SMBSec = Get-SMBSecurity -SecurityDescriptorName SrvsvcDefaultShareInfo

            $DACL = $SMBSec.DACL | Where-Object {$_.Account.Username -eq "Everyone"}

            # validate
            $DACL | Should -BeNullOrEmpty
            $SMBSec.DACL.Count | Should -Be 1

            $SMBSec.DACL[0].Account.Username | Should -Be "Authenticated Users"
            $SMBSec.DACL[0].Right | Should -Contain "Read"
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