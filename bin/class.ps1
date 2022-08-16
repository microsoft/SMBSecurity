using namespace System.Collections
using namespace System.Collections.Generic
using namespace System.Security.Principal

<#

Created at asciiflow.com

SMB Security Descriptor
┌──────────────────────────────────────────────────────────────────┐
│[PSCustomObject]                                                  │
├──────────────────────────────────────────────────────────────────┤
│                                                                  |
|SecurityDescriptor: Enum [SMBSecurityDescriptor]                  |
│                                                                  |
│Description: string from [hashtable]$Script:SMBSecDescriptorDef   |
│                                                                  |
│Owner: Class [SMBSecOwner] - SetOwner()                           │
│                                                                  │
│Group: Class [SMBSecGroup] - SetGroup()                           │
│                                                                  │
│DACL: [ArrayList]                                                 │
│                                                                  │
│      Class [SMBSecDaclAce] - AllowAccess(), DenyAccess()         │
│                              AddPermission(), RemovePermission() │
│                                                                  │
│SACL: * Not used by SecurityDescriptors, will always be null. *   │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘

Classes inside of classes can cause PowerShell to blow up. This design avoids nested classes to prevent said exploding.


#>

# dot sourcing enums when using classes doesn't work, so copy the contents of enum.ps1 to class.ps1

############
### ENUM ###
############


# SMB DefaultSecurity reg value names
[Flags()]
enum SMBSecurityDescriptor
{ 
    SrvsvcConfigInfo        = 1 
    SrvsvcConnection        = 2   
    SrvsvcFile              = 4   
    SrvsvcServerDiskEnum    = 8  
    SrvsvcSessionInfo       = 16  
    SrvsvcShareAdminConnect = 32  
    SrvsvcShareAdminInfo    = 64 
    SrvsvcShareChange       = 128 
    SrvsvcShareConnect      = 256 
    SrvsvcShareFileInfo     = 512 
    SrvsvcSharePrintInfo    = 1024
    SrvsvcStatisticsInfo    = 2048
    SrvsvcTransportEnum     = 65536
    SrvsvcDefaultShareInfo  = 131072
}


[flags()]
enum SMBSecPermissions
{
    FullControl                  = 1
    ReadServerInfo               = 2
    ReadAdvancedServerInfo       = 4
    ReadAdministrativeServerInfo = 8
    ChangeServerInfo             = 16
    Delete                       = 32
    ReadControl                  = 64
    WriteDAC                     = 128
    WriteOwner                   = 256
}



## Allow or deny DACL/SACL access ##
enum SMBSecAccess
{
    Allow
    Deny
}


## SrvsvcConfigInfo permissions ##
enum SMBSecSrvsvcConfigInfo
{
    FullControl
    ReadServerInfo              
    ReadAdvancedServerInfo      
    ReadAdministrativeServerInfo
    ChangeServerInfo            
    Delete                      
    ReadControl                 
    WriteDAC                    
    WriteOwner                  
}



## SrvsvcConnection Permissions ##
enum SMBSecSrvsvcConnection 
{
    FullControl
    EnumerateConnections
    Delete              
    ReadControl         
    WriteDAC            
    WriteOwner          
}

## SrvsvcFile Permissions ##
enum SMBSecSrvsvcFile 
{
    FullControl
    EnumerateOpenFiles
    ForceFilesClosed  
    Delete            
    ReadControl       
    WriteDAC          
    WriteOwner        
}


## SrvsvcServerDiskEnum Permissions ## 
enum SMBSecSrvsvcServerDiskEnum 
{
    FullControl
    EnumerateDisks
    Delete        
    ReadControl   
    WriteDAC      
    WriteOwner    
}

## SrvsvcSessionInfo Permissions ##
enum SMBSecSrvsvcSessionInfo 
{
    FullControl
    ReadSessionInfo               
    ReadAdministrativeSessionInfo 
    ChangeServerInfo              
    Delete                        
    ReadControl                   
    WriteDAC                      
    WriteOwner                    
}

## SrvsvcShareAdminInfo Permissions ##
enum SMBSecSrvsvcShareAdminInfo 
{
    FullControl
    ReadShareInfo              
    ReadAdministrativeShareInfo
    ChangeShareInfo            
    Delete                     
    ReadControl                
    WriteDAC                   
    WriteOwner                 
}

## SrvsvcShareFileInfo Permissions ##
enum SMBSecSrvsvcShareFileInfo 
{
    FullControl
    ReadShareInfo              
    ReadAdministrativeShareInfo
    ChangeShareInfo            
    Delete                     
    ReadControl                
    WriteDAC                   
    WriteOwner                 
}

## SrvsvcSharePrintInfo Permissions ##
enum SMBSecSrvsvcSharePrintInfo 
{
    FullControl
    ReadShareInfo              
    ReadAdministrativeShareInfo
    ChangeShareInfo            
    Delete                     
    ReadControl                
    WriteDAC                   
    WriteOwner                 
}


## SrvsvcShareConnect Permissions ##
enum SMBSecSrvsvcShareConnect 
{
    FullControl
    ConnectToServer      
    ConnectToPausedServer
    Delete               
    ReadControl          
    WriteDAC             
    WriteOwner           
}


## SrvsvcShareAdminConnect Permissions ##
enum SMBSecSrvsvcShareAdminConnect 
{
    FullControl
    ConnectToServer      
    ConnectToPausedServer
    Delete               
    ReadControl          
    WriteDAC             
    WriteOwner           
}

## SrvsvcStatisticsInfo Permissions ##
enum SMBSecSrvsvcStatisticsInfo 
{
    FullControl
    ReadStatistics
    Delete        
    ReadControl   
    WriteDAC      
    WriteOwner    
}


## SrvsvcDefaultShareInfo Permissions ##
enum SMBSecSrvsvcDefaultShareInfo 
{
    FullControl
    Change     
    Read       
}


## SrvsvcTransportEnum Permissions ##
enum SMBSecSrvsvcTransportEnum 
{
    FullControl
    Enumerate  
    AdvancedEnumerate
    SetInfo
    Delete     
    ReadControl
    WriteDAC   
}


## SrvsvcTransportEnum Permissions ##
enum SMBSecSrvsvcShareChange 
{
    FullControl           
    ReadShareUserInfo     
    ReadAdminShareUserInfo
    SetShareInfo          
    Delete                
    ReadControl           
    WriteDAC              
    WriteOwner              
}


# list of reserved words - not an enum because there are spaces
[string[]]$Script:SMBSecReservedWords = 'ANONYMOUS',
                                        'AUTHENTICATED USER',
                                        'BATCH',
                                        'BUILTIN',
                                        'CREATOR GROUP',
                                        'CREATOR GROUP SERVER',
                                        'CREATOR OWNER',
                                        'CREATOR OWNER SERVER',
                                        'DIALUP',
                                        'DIGEST AUTH',
                                        'INTERACTIVE',
                                        'INTERNET',
                                        'LOCAL',
                                        'LOCAL SYSTEM',
                                        'NETWORK',
                                        'NETWORK SERVICE',
                                        'NT AUTHORITY',
                                        'NT DOMAIN',
                                        'NTLM AUTH',
                                        'NULL',
                                        'PROXY',
                                        'REMOTE INTERACTIVE',
                                        'RESTRICTED',
                                        'SCHANNEL AUTH',
                                        'SELF',
                                        'SERVER',
                                        'SERVICE',
                                        'SYSTEM',
                                        'TERMINAL SERVER',
                                        'THIS ORGANIZATION',
                                        'USERS',
                                        'WORLD'


# list of well known local accounts.
[hashTable]$Script:SMBSecReservedLocalAccounts = @{
    'S-1-0-0'      = "Null SID"
    'S-1-1-0'      = "World"
    'S-1-2-0'      = "Local"
    'S-1-2-1'      = "Console Logon"
    'S-1-3-0'      = "Creator Owner ID"
    'S-1-3-1'      = "Creator Group ID"
    'S-1-3-2'      = "Creator Owner Server"
    'S-1-3-3'      = "Creator Group Server"
    'S-1-3-4'      = "Owner Rights"
    'S-1-5-1'      = "Dialup"
    'S-1-5-113'    = "Local account"
    'S-1-5-114'    = "Local account and member of Administrators group"
    'S-1-5-2'      = "NT AUTHORITY\NETWORK"
    'S-1-5-3'      = "NT AUTHORITY\BATCH"
    'S-1-5-4'      = "NT AUTHORITY\INTERACTIVE"
    'S-1-5-5'      = "Logon Session"
    'S-1-5-6'      = "Service"
    'S-1-5-7'      = "Anonymous Logon"
    'S-1-5-8'      = "Proxy"
    'S-1-5-9'      = "NT AUTHORITY\ENTERPRISE DOMAIN CONTROLLERS"
    'S-1-5-10'     = "Self"
    'S-1-5-11'     = "Authenticated Users"
    'S-1-5-12'     = "Restricted Code"
    'S-1-5-13'     = "Terminal Server User"
    'S-1-5-14'     = "NT AUTHORITY\REMOTE INTERACTIVE LOGON"
    'S-1-5-15'     = "This Organization"
    'S-1-5-17'     = "IIS_USRS"
    'S-1-5-18'     = "SYSTEM"
    'S-1-5-19'     = "LocalService"
    'S-1-5-20'     = "Network Service"
    'S-1-5-32-544' = "BUILTIN\Administrators"
    'S-1-5-32-545' = "BUILTIN\Users"
    'S-1-5-32-546' = "BUILTIN\Guests"
    'S-1-5-32-547' = "BUILTIN\Power Users"
    'S-1-5-32-548' = "BUILTIN\Account Operators"
    'S-1-5-32-549' = "Server Operators"
    'S-1-5-32-550' = "Print Operators"
    'S-1-5-32-551' = "Backup Operators"
    'S-1-5-32-552' = "Replicators"
    'S-1-5-32-554' = "BUILTIN\Pre-Windows 2000 Compatible Access"
    'S-1-5-32-555' = "BUILTIN\Remote Desktop Users"
    'S-1-5-32-556' = "BUILTIN\Network Configuration Operators"
    'S-1-5-32-557' = "BUILTIN\Incoming Forest Trust Builders"
    'S-1-5-32-558' = "BUILTIN\Performance Monitor Users"
    'S-1-5-32-559' = "BUILTIN\Performance Log Users"
    'S-1-5-32-560' = "BUILTIN\Windows Authorization Access Group"
    'S-1-5-32-561' = "BUILTIN\Terminal Server License Servers"
    'S-1-5-32-562' = "BUILTIN\Distributed COM Users"
    'S-1-5-32-569' = "BUILTIN\Cryptographic Operators"
    'S-1-5-32-573' = "BUILTIN\Event Log Readers"
    'S-1-5-32-574' = "BUILTIN\Certificate Service DCOM Access"
    'S-1-5-32-575' = "BUILTIN\RDS Remote Access Servers"
    'S-1-5-32-576' = "BUILTIN\RDS Endpoint Servers"
    'S-1-5-32-577' = "BUILTIN\RDS Management Servers"
    'S-1-5-32-578' = "BUILTIN\Hyper-V Administrators"
    'S-1-5-32-579' = "BUILTIN\Access Control Assistance Operators"
    'S-1-5-32-580' = "BUILTIN\Remote Management Users"
    'S-1-5-83'     = "NT VIRTUAL MACHINE\Virtual Machines"
}

#'S-1-5-*-500' = "Administrator"


# list of well known domain accounts.
[hashTable]$Script:SMBSecReservedDomainAccounts = @{
    'S-1-5-*-500' = "Administrator"
    'S-1-5-*-501' = "Guest"
    'S-1-5-*-502' = "krbtgt"
    'S-1-5-*-512' = "Domain Admins"
    'S-1-5-*-513' = "Domain Users"
    'S-1-5-*-514' = "Domain Guests"
    'S-1-5-*-515' = "Domain Computers"
    'S-1-5-*-516' = "Domain Controllers"
    'S-1-5-*-517' = "Cert Publishers"
    'S-1-5-*-520' = "Group Policy Creator Owners"
    'S-1-5-*-553' = "RAS and IAS Servers"
}



<#

SMBSecAccount

Username
Domain (COMPUTERNAME goes here for local accounts)
SID

#>


class SMBSecAccount
{
    [string]$Username
    [string]$Domain
    [System.Security.Principal.NTAccount]$Account
    [System.Security.Principal.SecurityIdentifier]$SID

    # I'm going to disallow a blank SMBSecAccount for now
    <#
    SMBSecAccount()
    {
        $this.Username = $null
        $this.Domain   = $null
        $this.Account  = $null
        $this.SID      = $null
    }
    #>

    SMBSecAccount([System.Security.Principal.NTAccount]$Obj)
    {
        $this.CreateAccountByNTAccount($obj)
    }

    SMBSecAccount([System.Security.Principal.SecurityIdentifier]$Obj)
    {
        $this.CreateAccountByNTAccount($obj)
    }

    SMBSecAccount([string]$Obj)
    {
        # check for SIDs
        if ($Obj -match "S-1-\d{1,3}-\d{1,3}")
        {
            Write-Verbose "[SMBSecAccount] - Converting string SID to [System.Security.Principal.SecurityIdentifier]."
            [System.Security.Principal.SecurityIdentifier]$Obj = $Obj
            Write-Debug "[SMBSecAccount] - Account type is now $($Obj.GetType().Name)."

            $this.CreateAccountBySID($obj)
        }
        else
        {
            Write-Verbose "[SMBSecAccount] - Converting string Account to [System.Security.Principal.NTAccount]."
            [System.Security.Principal.NTAccount]$Obj = $Obj
            Write-Debug "[SMBSecAccount] - Account type is now $($Obj.GetType().Name)."
            $this.CreateAccountByNTAccount($obj)
        }       
    }


    AddUserName([string]$user)
    {
        $this.Username = $user
    }

    AddDomain([string]$domain)
    {
        $this.Domain = $domain
    }

    AddAccount([System.Security.Principal.NTAccount]$acc)
    {
        $this.Account = $acc
    }

    AddSID([System.Security.Principal.SecurityIdentifier]$SID)
    {
        $this.SID = $SID
    }

    [string]
    ToString()
    {
        return "$($this.Account.Value)"
    }

    [System.Security.Principal.SecurityIdentifier]
    ConvertNTAccount2SID([System.Security.Principal.NTAccount]$Obj)
    {
        Write-Verbose "[SMBSecAccount]::ConvertNTAccount2SID() - Begin"
        try 
        {
            <# translate the account to a SID
            switch ($Obj.Value)
            {
                "Server Operators" 
                { 
                    Write-Verbose "[SMBSecAccount]::ConvertNTAccount2SID() - Using well-known account 'S-1-5-32-549'."
                    [System.Security.Principal.SecurityIdentifier]$objSID = 'S-1-5-32-549'
                    break 
                }

                "Print Operators"  
                { 
                    Write-Verbose "[SMBSecAccount]::ConvertNTAccount2SID() - Using well-known account 'S-1-5-32-550'."
                    [System.Security.Principal.SecurityIdentifier]$objSID = 'S-1-5-32-550'
                    break 
                }

                default 
                {
                    Write-Verbose "[SMBSecAccount]::ConvertNTAccount2SID() - Attempting translation of $($Obj.Value)."
                    $objSID = $Obj.Translate([System.Security.Principal.SecurityIdentifier])    
                    Write-Verbose "[SMBSecAccount]::ConvertNTAccount2SID() - Result: $($objSID.Value)"
                    break
                }
            }
            #>

            Write-Verbose "[SMBSecAccount]::ConvertNTAccount2SID() - Attempting translation of $($Obj.Value)."
            $objSID = $Obj.Translate([System.Security.Principal.SecurityIdentifier])
            Write-Verbose "[SMBSecAccount]::ConvertNTAccount2SID() - Result: $($objSID.Value)"

        }
        catch 
        {
            Write-Verbose "[SMBSecAccount]::ConvertNTAccount2SID() - Auto conversion failed. Trying manual conversion: $_"

            $tmpAccnt = $Obj.Value

            # check against well known local accounts
            [array]$tmpResults = $Script:SMBSecReservedLocalAccounts.GetEnumerator() | ForEach-Object { if ($_.Value -eq $tmpAccnt -or $_.Value -match $tmpAccnt) {$_}}

            if ($tmpResults.Count -eq 1)
            {
                # found a match
                [System.Security.Principal.SecurityIdentifier]$objSID = $tmpResults.Key
                Write-Verbose "[SMBSecAccount]::ConvertNTAccount2SID() - Result: $($objSID.Value)"
                Write-Verbose "[SMBSecAccount]::ConvertNTAccount2SID() - End"
                return $objSID
                break
            }
            elseif ($tmpResults.Count -gt 1)
            {
                Write-Error "[SMBSecOwner]::ConvertNTAccount2SID() - Multiple matches were found. Please be more exact: $($tmpResults.Value -join ', ')"
                return $null
                break
            }
            else 
            {
                Write-Error "[SMBSecOwner]::ConvertNTAccount2SID() - Unable to find a matching SID: $_" -EA Stop
                return $null
                break
            }
        }

        Write-Verbose "[SMBSecAccount]::ConvertNTAccount2SID() - End"
        return $objSID
    }

    [System.Security.Principal.NTAccount]
    ConvertSID2NTAccount([System.Security.Principal.SecurityIdentifier]$Obj)
    {
        Write-Verbose "[SMBSecAccount]::ConvertSID2NTAccount() - Begin"
        try
        {
            Write-Verbose "[SMBSecAccount]::ConvertSID2NTAccount() - Translating SID to NTAccount."
            <# translate the account to a SID
            switch ($Obj.Value)
            {
                'S-1-5-32-549' 
                { 
                    Write-Verbose "[SMBSecAccount]::ConvertSID2NTAccount() - Using well-known account 'Server Operators'."
                    [System.Security.Principal.NTAccount]$objUser = "Server Operators"
                    break 
                }
                
                'S-1-5-32-550' 
                { 
                    Write-Verbose "[SMBSecAccount]::ConvertSID2NTAccount() - Using well-known account 'Print Operators'."
                    [System.Security.Principal.NTAccount]$objUser = "Print Operators"                    
                    break 
                }

                'S-1-5-3'
                {
                    Write-Verbose "[SMBSecAccount]::ConvertSID2NTAccount() - Using well-known account 'NT AUTHORITY\BATCH'."
                    [System.Security.Principal.NTAccount]$objUser = "NT AUTHORITY\BATCH"                    
                    break 
                }
                
                default        
                {
                    
                    break
                }
            }
            #>

            Write-Verbose "[SMBSecAccount]::ConvertSID2NTAccount() - Attempting translation of $($Obj.Value)."
            $objUser = $Obj.Translate([System.Security.Principal.NTAccount]) 
            Write-Verbose "[SMBSecAccount]::ConvertSID2NTAccount() - Result: $($objUser.Value)"
        }
        catch
        {
            Write-Verbose "[SMBSecAccount]::ConvertSID2NTAccount() - Auto conversion failed. Trying manual conversion: $_"

            $tmpSID = $Obj.Value

            # check against well known local accounts
            try
            {
                Write-Verbose "[SMBSecAccount]::ConvertSID2NTAccount() - Looking for $tmpSID in known accounts."
                $tmpResults = $Script:SMBSecReservedLocalAccounts["$tmpSID"]
                Write-Verbose "[SMBSecAccount]::ConvertSID2NTAccount() - Known good result: $($tmpResults)"

                if ($tmpResults)
                {
                    [System.Security.Principal.NTAccount]$objUser = $tmpResults
                    Write-Verbose "[SMBSecAccount]::ConvertSID2NTAccount() - Result: $($objUser.Value)"
                    Write-Verbose "[SMBSecAccount]::ConvertSID2NTAccount() - End"
                    return $objUser
                    break
                }
            }
            catch
            {
                Write-Error "[SMBSecOwner]::ConvertSID2NTAccount() - Unable to find a matching SID: $_" -EA Stop
                return $null
            }            
        }

        Write-Verbose "[SMBSecAccount]::ConvertSID2NTAccount() - End"
        return $objUser
    }

    CreateAccountBySID([System.Security.Principal.SecurityIdentifier]$Obj)
    {
        Write-Verbose "[SMBSecAccount]::CreateAccountBySID() - Begin"
        
        # use the SID to get the canonical account name
        try
        {
            Write-Verbose "[SMBSecAccount]::CreateAccountBySID() - Calling ConvertSID2NTAccount."
            $objAccount = $this.ConvertSID2NTAccount($Obj)
            Write-Verbose "[SMBSecAccount]::CreateAccountBySID() - Result: $($objAccount.Value)"
        }
        catch
        {
            Write-Error "[SMBSecAccount]::CreateAccountBySID() - Unable to find a matching NTAccount: $_" -EA Stop
            break
        }

        # try to find the cannonical NTAccount based on the SID
        # this seems like extra effort but formatting the account is important for consistency
        try
        {
            Write-Verbose "[SMBSecAccount]::CreateAccountBySID() - Calling ConvertNTAccount2SID."
            $objSID = $this.ConvertNTAccount2SID($objAccount)
            Write-Verbose "[SMBSecAccount]::CreateAccountBySID() - Result: $($objSID.Value)"
        }
        catch
        {
            Write-Error "[SMBSecAccount]::CreateAccountBySID() - Unable to find a matching SID: $_" -EA Stop
            break
        }
        
        # split up the account
        if ($objAccount)
        {
            Write-Verbose "[SMBSecAccount]::CreateAccountBySID() - Split domain from account."
            # check for domain\user formatting. '\\' is needed for the regex -match to work
            if ($objAccount.Value -match '\\')
            {
                $tmpDomain = $objAccount.Value.ToString().Split('\')[0]
                $tmpUsername = $objAccount.Value.ToString().Split('\')[1]
            }
            else
            {
                # use objUser for the username
                $tmpUsername = $objAccount.Value

                # set the domain to the local computer
                $tmpDomain = $env:COMPUTERNAME
            }
            Write-Verbose "[SMBSecAccount]::CreateAccountBySID() - Username: $tmpUsername, Domain: $tmpDomain"

            # last check, if $obj.Value does not exactly match $objUser, then make the account name equal to $objUser.toString() for consistency's sake with how the system sees the account.
            #if ($objAccount.Value -cne $Obj.Value)
            #{
            #    Write-Error "[SMBSecAccount]::CreateAccountBySID() - Setting "
            #    $obj = $objAccount
            #}
        }
        else
        {
            Write-Error "[SMBSecAccount] - Unable to find a matching NT account: $_" -EA Stop
            break
        }

        Write-Verbose @"
[SMBSecAccount]::CreateAccountBySID() - Updating values in this object:
Account  = $($objAccount.Value)
Domain   = $tmpDomain
Username = $tmpUsername
SID      = $($objSID.Value)

"@
        Write-Verbose "[SMBSecAccount]::CreateAccountBySID() - End"
        $this.Account  = $objAccount
        $this.Domain   = $tmpDomain
        $this.Username = $tmpUsername
        $this.SID      = $objSID
    }

    CreateAccountByNTAccount([System.Security.Principal.NTAccount]$Obj)
    {
        Write-Verbose "[SMBSecAccount]::CreateAccountByNTAccount() - Begin"
        # try to find the NTAccount based on the SID
        try
        {
            Write-Verbose "[SMBSecAccount]::CreateAccountByNTAccount() - Calling ConvertNTAccount2SID($($Obj.Value))."
            $objSID = $this.ConvertNTAccount2SID($Obj)
            Write-Verbose "[SMBSecAccount]::CreateAccountByNTAccount() - Returned $($objSID.Value)"
        }
        catch
        {
            Write-Error "[SMBSecAccount]::CreateAccountByNTAccount() - Unable to find a matching SID: $_" -EA Stop
            break
        }
        
        # use the SID to get the canonical account name
        # this seems like extra effort but formatting the account is important for consistency
        try
        {
            Write-Verbose "[SMBSecAccount]::CreateAccountByNTAccount() - Calling ConvertSID2NTAccount($($objSID.Value))."
            $objAccount = $this.ConvertSID2NTAccount($objSID)
            Write-Verbose "[SMBSecAccount]::CreateAccountByNTAccount() - Returned $($objSID.Value)"
        }
        catch
        {
            Write-Error "[SMBSecAccount]::CreateAccountByNTAccount() - Unable to find a matching NTAccount: $_" -EA Stop
            break
        }
        

        if ($objAccount)
        {
            # check for domain\user formatting. '\\' is needed for the regex -match to work
            if ($objAccount.Value -match '\\')
            {
                Write-Verbose "[SMBSecAccount]::CreateAccountByNTAccount() - Splitting account by domain/reserved and username."
                $tmpDomain = $objAccount.Value.ToString().Split('\')[0]
                $tmpUsername = $objAccount.Value.ToString().Split('\')[1]
            }
            else
            {
                Write-Verbose "[SMBSecAccount]::CreateAccountByNTAccount() - Using the $ENV:COMPUTERNAME for the domain."
                # use objUser for the username
                $tmpUsername = $objAccount.Value

                # set the domain to the local computer
                $tmpDomain = $env:COMPUTERNAME
            }
        }
        else
        {
            Write-Error "[SMBSecAccount] - Unable to find a matching NT account: $_" -EA Stop
            break
        }

        Write-Verbose "[SMBSecAccount]::CreateAccountByNTAccount() - Updating `$this with the discovered details."
        $this.Account  = $objAccount
        $this.Domain   = $tmpDomain
        $this.Username = $tmpUsername
        $this.SID      = $objSID

        Write-Debug @"
[SMBSecAccount]::CreateAccountByNTAccount() - Resulting object:
Account  = $($this.Account)
Domain   = $($this.Domain)
Username = $($this.Username)
SID      = $($this.SID)

"@

        Write-Verbose "[SMBSecAccount]::CreateAccountByNTAccount() - End"
    }
}



# Stores the owner portion of the SSDL (O:<owner>)
class SMBSecOwner
{
    #[SMBSecAccount]$Owner
    [string]$Username
    [string]$Domain
    [System.Security.Principal.NTAccount]$Account
    [System.Security.Principal.SecurityIdentifier]$SID

    ## constructors ##
    #region
    SMBSecOwner()
    {
        $this.Username = $null
        $this.Domain   = $null
        $this.Account  = $null
        $this.SID      = $null
    }

    SMBSecOwner([SMBSecAccount]$Obj)
    {
        $this.Username = $Obj.Username
        $this.Domain   = $Obj.Domain
        $this.Account  = $Obj.Account
        $this.SID      = $Obj.SID
    }

    SMBSecOwner($Obj)
    {
        Write-Verbose "[SMBSecOwner] - Begin"
        try 
        {
            $Owner = [SMBSecAccount]::new($Obj)

            $this.Username = $Owner.Username
            $this.Domain   = $Owner.Domain
            $this.Account  = $Owner.Account
            $this.SID      = $Owner.SID
        }
        catch 
        {
            Write-Error "Failed to create the [SMBSecAccount] object: $_" -EA Stop
        }
        
        Write-Verbose "[SMBSecOwner] - End"
    }

    SetOwner($Obj)
    {
        Write-Verbose "[SMBSecOwner]::SetOwner() - Begin"
        try 
        {
            $Owner = [SMBSecAccount]::new($Obj)

            $this.Username = $Owner.Username
            $this.Domain   = $Owner.Domain
            $this.Account  = $Owner.Account
            $this.SID      = $Owner.SID
        }
        catch 
        {
            Write-Error "Failed to create the [SMBSecAccount] object: $_" -EA Stop
        }
        
        Write-Verbose "[SMBSecOwner]::SetOwner() - End"
    }

    SetOwner([SMBSecAccount]$Owner)
    {
        $this.Username = $Owner.Username
        $this.Domain   = $Owner.Domain
        $this.Account  = $Owner.Account
        $this.SID      = $Owner.SID
    }

    SetOwner([SMBSecOwner]$Owner)
    {
        $this.Username = $Owner.Username
        $this.Domain   = $Owner.Domain
        $this.Account  = $Owner.Account
        $this.SID      = $Owner.SID
    }

    [string]
    ToString()
    {
        return "$($this.Owner.Account.Value)"
    }
}


# Stores the owner portion of the SSDL (G:<group>)
class SMBSecGroup
{
    #[SMBSecAccount]$Group
    [string]$Username
    [string]$Domain
    [System.Security.Principal.NTAccount]$Account
    [System.Security.Principal.SecurityIdentifier]$SID

    ## constructors ##
    #region
    SMBSecGroup()
    {
        $this.Username = $null
        $this.Domain   = $null
        $this.Account  = $null
        $this.SID      = $null
    }

    SMBSecGroup([SMBSecAccount]$Obj)
    {
        $this.Username = $Obj.Username
        $this.Domain   = $Obj.Domain
        $this.Account  = $Obj.Account
        $this.SID      = $Obj.SID
    }

    SMBSecGroup($Obj)
    {
        Write-Verbose "[SMBSecGroup] - Begin"
        try 
        {
            $Group = [SMBSecAccount]::new($Obj)

            $this.Username = $Group.Username
            $this.Domain   = $Group.Domain
            $this.Account  = $Group.Account
            $this.SID      = $Group.SID
        }
        catch 
        {
            Write-Error "Failed to create the [SMBSecGroup] object: $_" -EA Stop
        }
        
        Write-Verbose "[SMBSecGroup] - End"
    }

    SetGroup($Obj)
    {
        Write-Verbose "[SMBSecGroup]::SetGroup() - Begin full process"
        try 
        {
            $Group = [SMBSecAccount]::new($Obj)

            $this.Username = $Group.Username
            $this.Domain   = $Group.Domain
            $this.Account  = $Group.Account
            $this.SID      = $Group.SID
        }
        catch 
        {
            Write-Error "Failed to create the [SMBSecAccount] object: $_" -EA Stop
        }
        
        Write-Verbose "[SMBSecGroup]::SetGroup() - End"
    }

    SetGroup([SMBSecAccount]$Group)
    {
        Write-Verbose "[SMBSecGroup]::SetGroup() - Add by SMBSecAccount"

        $this.Username = $Group.Username
        $this.Domain   = $Group.Domain
        $this.Account  = $Group.Account
        $this.SID      = $Group.SID
    }

    SetGroup([SMBSecGroup]$Group)
    {
        Write-Verbose "[SMBSecGroup]::SetGroup() - Add by SMBSecGroup"

        $this.Username = $Group.Username
        $this.Domain   = $Group.Domain
        $this.Account  = $Group.Account
        $this.SID      = $Group.SID
    }

    [string]
    ToString()
    {
        return "$($this.Group.Account.Value)"
    }
}




<# Stores the group portion of the SSDL (G:<group>)
# the guts of this class are identical to SMBSecOwner
# Stores the owner portion of the SSDL (O:<owner>)
class SMBSecGroup
{
    [SMBSecAccount]$Group

    ## constructors ##
    #region
    SMBSecGroup()
    {
        $this.Owner = $null
    }

    # Account Only
    SMBSecGroup([System.Security.Principal.NTAccount]$Obj)
    {
        # create the [SMBSecAccount] object
        $objAcnt = $this.CreateOwnerByNTAccount($Obj)

        if (-NOT $objAcnt)
        {
            Write-Error "[SetGroup]::([NTAccount]) - Failed to create the [SMBSecAccount]." -EA Stop
        }

        $this.Owner = $objAcnt

    }

    # Account Only - As a string
    SMBSecGroup([string]$Obj)
    {
        # start by converting the string to an NTAccount
        try 
        {
            $accnt = New-Object System.Security.Principal.NTAccount($obj)
        
            # create the [SMBSecAccount] object
            $objAcnt = $this.CreateOwnerByNTAccount($accnt)

            if (-NOT $objAcnt)
            {
                Write-Error "[SetGroup]::([string]'NTAccount') - Failed to create the [SMBSecAccount]." -EA Stop
            }

            # finally, add the object to this
            $this.Owner = $objAcnt
        }
        catch 
        {
            Write-Error "Failed to find an account named $obj`: $_" -EA Stop
        }

        
    }

    # SID Only
    SMBSecGroup([System.Security.Principal.SecurityIdentifier]$Obj)
    {
        # create the [SMBSecAccount] object
        $objAcnt = $this.CreateOwnerBySID($Obj)

        if (-NOT $objAcnt)
        {
            Write-Error "[SetGroup]::([SID]) - Failed to create the [SMBSecAccount]." -EA Stop
        }

        $this.Owner = $objAcnt
    }

    SMBSecGroup([SMBSecAccount]$Obj)
    {
        # assume the account is valid if an SMBSecAccount is passed
        $this.Group = $Obj
    }
    #endregion

    ## methods ##
    # set owner by SID
    [System.Management.Automation.ErrorRecord]
    SetGroup($Obj)
    {
        try 
        {
            $this.SMBSecGroup($obj)    
        }
        catch 
        {
            return ( Write-Error "[SetGroup] - Failed to create the [SMBSecAccount]: $_" -EA Stop )
        }

        return $null
    }

    <# 
    
    # NTAccount as string
    [System.Management.Automation.ErrorRecord]
    SetGroup([string]$Obj)
    {
        # start by converting the string to an NTAccount
        try 
        {
            $accnt = New-Object System.Security.Principal.NTAccount($obj)    
        }
        catch 
        {
            return (Write-Error "Failed to find an account named $obj`: $_" -EA Stop)
        }

        # create the [SMBSecAccount] object
        $objAcnt = $this.CreateOwnerByNTAccount($accnt)

        if (-NOT $objAcnt)
        {
            return ( Write-Error "[SetGroup]::([string]'NTAccount') - Failed to create the [SMBSecAccount]." -EA Stop )
        }

        $this.Owner = $objAcnt
        return $null
    }


    # set owner by account name
    [System.Management.Automation.ErrorRecord]
    SetGroup([System.Security.Principal.NTAccount]$Obj)
    {
        # create the [SMBSecAccount] object
        $objAcnt = $this.CreateOwnerByNTAccount($Obj)

        if (-NOT $objAcnt)
        {
            return ( Write-Error "[SetGroup]::([NTAccount]) - Failed to create the [SMBSecAccount]." -EA Stop )
        }

        $this.Owner = $objAcnt
        return $null
    }
    

    [string]
    ToString()
    {
        return return "$($this.Owner.Account.Value)"
    }

    [System.Security.Principal.SecurityIdentifier]
    ConvertNTAccount2SID([System.Security.Principal.NTAccount]$Obj)
    {
        try 
        {
            # translate the account to a SID
            switch ($Obj.Value)
            {
                "Server Operators" { [System.Security.Principal.SecurityIdentifier]$objSID = 'S-1-5-32-549'; break }
                "Print Operators"  { [System.Security.Principal.SecurityIdentifier]$objSID = 'S-1-5-32-550'; break }
                default            {
                    try 
                    {
                        $objSID = $Obj.Translate([System.Security.Principal.SecurityIdentifier])    
                    }
                    catch 
                    {
                        # currently not a terminting error, but may be in the future if this causes problems
                        Write-Warning "Failed to find the SID for $($Obj.Value)`: $_"
                        exit
                    }
                    break
                }
            }
        }
        catch 
        {
            Write-Error "[SMBSecGroup] - Unable to find a matching SID: $_" -EA Stop
            return $null
        }

        return $objSID
    }

    [System.Security.Principal.NTAccount]
    ConvertSID2NTAccount([System.Security.Principal.SecurityIdentifier]$Obj)
    {
        try
        {
            # translate the account to a SID
            switch ($Obj.Value)
            {
                'S-1-5-32-549' { [System.Security.Principal.NTAccount]$objUser = "Server Operators"; break }
                'S-1-5-32-550'  { [System.Security.Principal.NTAccount]$objUser = "Print Operators"; break }
                default            {
                    try 
                    {
                        $objUser = $Obj.SID.Translate([System.Security.Principal.NTAccount]) 
                    }
                    catch 
                    {
                        # currently not a terminting error, but may be in the future if this causes problems
                        Write-Warning "Failed to find the NTAccount for $($Obj.Value)`: $_"
                        exit
                    }
                    break
                }
            }
        }
        catch
        {
            Write-Error "[SMBSecGroup] - Unable to find a matching NTAccount: $_" -EA Stop
            return $null
        }

        return $objUser
    }

    [SMBSecAccount]
    CreateOwnerBySID([System.Security.Principal.SecurityIdentifier]$Obj)
    {
        # create the [SMBSecAccount] object
        $objAcnt = [SMBSecAccount]::New()

        # try to find the SID
        $objSID = $this.ConvertNTAccount2SID($obj)
        if ($objSID)
        {
            $objAcnt.AddSID($objSID)
        }
        else 
        {
            Write-Error "[SMBSecGroup] - Unable to find a matching SID: $_" -EA Stop
            return $null
        }
        

        # use the SID to get the canonical account name
        $objUser = $this.ConvertSID2NTAccount($objSID)

        if ($objUser)
        {
            # check for domain\user formatting. '\\' is needed for the regex -match to work
            if ($objUser.Value -match '\\')
            {
                $domain = $objUser.Value.ToString().Split('\')[1]
                $username = $objUser.Value.ToString().Split('\')[0]
            }
            else
            {
                # use objUser for the username
                $username = $objUser.Value

                # set the domain to the local computer
                $domain = $env:COMPUTERNAME
            }

            $objAcnt.AddUserName($username)
            $objAcnt.AddDomain($domain)

            # last check, if $obj.Value does not exactly match $objUser, then make the account name equal to $objUser.toString() for consistency's sake with how the system sees the account.
            if ($objUser.Value -cne $obj.Value)
            {
                $obj = $objUser
            }
        }
        else
        {
            Write-Error "[SMBSecGroup] - Unable to find a matching NT account: $_" -EA Stop
            return $null
        }

        # add the account
        $objAcnt.AddAccount($Obj)

        # finally, add the object to this
        return $objAcnt

    }

    [SMBSecAccount]
    CreateOwnerByNTAccount([System.Security.Principal.NTAccount]$Obj)
    {
        # create the [SMBSecAccount] object
        $objAcnt = [SMBSecAccount]::New()

        # try to find the SID
        $objSID = $this.ConvertNTAccount2SID($obj)
        if ($objSID)
        {
            $objAcnt.AddSID($objSID)
        }
        else 
        {
            Write-Error "[SMBSecGroup] - Unable to find a matching SID: $_" -EA Stop
            return $null
        }
        

        # use the SID to get the canonical account name
        $objUser = $this.ConvertSID2NTAccount($objSID)

        if ($objUser)
        {
            # check for domain\user formatting. '\\' is needed for the regex -match to work
            if ($objUser.Value -match '\\')
            {
                $domain = $objUser.Value.ToString().Split('\')[1]
                $username = $objUser.Value.ToString().Split('\')[0]
            }
            else
            {
                # use objUser for the username
                $username = $objUser.Value

                # set the domain to the local computer
                $domain = $env:COMPUTERNAME
            }

            $objAcnt.AddUserName($username)
            $objAcnt.AddDomain($domain)

            # last check, if $obj.Value does not exactly match $objUser, then make the account name equal to $objUser.toString() for consistency's sake with how the system sees the account.
            if ($objUser.Value -cne $obj.Value)
            {
                $obj = $objUser
            }
        }
        else
        {
            Write-Error "[SMBSecGroup] - Unable to find a matching NT account: $_" -EA Stop
            return $null
        }

        # add the account
        $objAcnt.AddAccount($Obj)

        # return the [SMBSecAccount] object
        return $objAcnt
    }
}
#>


# Stores DACL configuration
# D:dacl_flags(string_ace1)(string_ace2)... (string_acen)
# DACL Flags are not supported with SMB Security Descriptors, only account and permissions, so they are not implemented here.
# Write-Verbose "[SMBSecDaclAce] - "
class SMBSecDaclAce
{
    [SMBSecurityDescriptor]$SecurityDescriptor
    [SMBSecAccount]$Account
    [SMBSecAccess]$Access
    [string[]]$Right # permission control will be handled by the functions and methods

    ## constructors ##
    #region 

    SMBSecDaclAce([SMBSecurityDescriptor]$SecDesc)
    {
        Write-Verbose "[SMBSecDaclAce] - Begin"
        Write-Verbose "[SMBSecDaclAce] - Creating class with SecDesc"
        $this.SecurityDescriptor = $SecDesc
        $this.Account            = $null
        $this.Access             = "Deny"
        $this.Right              = $null
        Write-Verbose "[SMBSecDaclAce] - End"
    }

    SMBSecDaclAce([SMBSecurityDescriptor]$SecDesc, 
                  [SMBSecAccess]$Access)
    {
        Write-Verbose "[SMBSecDaclAce] - Begin"
        Write-Verbose "[SMBSecDaclAce] - Creating class with SecDesc and Access"
        $this.SecurityDescriptor = $SecDesc
        $this.Account            = $null
        $this.Access             = $Access
        $this.Right              = $null
        Write-Verbose "[SMBSecDaclAce] - End"
    }

    SMBSecDaclAce([SMBSecurityDescriptor]$SecDesc, 
                  [SMBSecAccount]$Account,
                  [SMBSecAccess]$Access)
    {
        Write-Verbose "[SMBSecDaclAce] - Begin"
        Write-Verbose "[SMBSecDaclAce] - Creating class with SecDesc, Access, and Account"
        # the account must be resolvable by the system 
        Write-Verbose "[SMBSecDaclAce] - Validating account: $($Account.Value)"
        switch($Account.Value)
        {
            # some accounts are known not to resolve (Server Operators and Print Operators) but are valid, we skip checking these
            "Server Operators" {break}
            "Print Operators" {break}
            default 
            {
                try 
                {
                    Write-Verbose "[SMBSecDaclAce] - Starting simple account validation."
                    $SID = $Account.Translate([System.Security.Principal.SecurityIdentifier])
                    Write-Verbose "[SMBSecDaclAce] - Translated $Account to SID $($SID.Value)."
                }
                catch 
                {
                    Write-Error "Failed to find an account named $Account`: $_" -EA Stop
                    Write-Verbose "[SMBSecDaclAce] - End without saving values."
                    exit
                }
            }
        }
        

        Write-Verbose "[SMBSecDaclAce] - Saving results."
        $this.SecurityDescriptor = $SecDesc
        $this.Access             = $Access
        $this.Right              = $null
        $this.Account            = $Account
        Write-Verbose "[SMBSecDaclAce] - End"
    }

    SMBSecDaclAce([SMBSecurityDescriptor]$SecDesc, 
                  [SMBSecAccount]$Account,
                  [SMBSecAccess]$Access,
                  [string[]]$Perms)
    {
        Write-Verbose "[SMBSecDaclAce] - Begin"
        Write-Verbose "[SMBSecDaclAce] - Creating class with SecDesc, Access, Permissions, and Account"

        # no need to validate SecDesc, Account, or Access because the classes handle that

        # validate the rights match the SecDesc
        Write-Verbose "[SMBSecDaclAce] - Testing permissions for $SecDesc."
        $permListName =  $Script:SMBSecPermMap.($SecDesc.ToString())
        Write-Verbose "[SMBSecDaclAce] - PermListName: $permListName"
        $permListHash = (Get-Variable $permListName -Scope script).Value
        $permList = $permListHash.Keys
        Write-Verbose "[SMBSecDaclAce] - Valid permissions are: $($permList -join ',')"
        $failed = $false
        foreach ($perm in $Perms)
        {
            if ($perm -notin $permList)
            {
                Write-Error "Failed to find the permission $perm in SecurityDescriptor $SecDesc"
                $failed = $true
            }
        }

        if ($failed) 
        { 
            Write-Verbose "[SMBSecDaclAce] - End without saving values."
            break
        }

        # if FullControl is part of the permissions, delete the other perms
        if ($Perms -contains "FullControl" -and $Perms.Count -gt 1)
        {
            $Perms = "FullControl"
        }

        Write-Verbose "[SMBSecDaclAce] - Saving results."
        $this.SecurityDescriptor = $SecDesc
        $this.Access             = $Access
        $this.Right              = $Perms
        $this.Account            = $Account
        Write-Verbose "[SMBSecDaclAce] - End"
    }

    #endregion

    # Set the access of the DACL
    SetAccess([SMBSecAccess]$Access)
    {
        Write-Verbose "[SMBSecDaclAce] - SetAccount: Setting DACL access to $Access."
        $this.Access = $Access
    }

    SetAccess($Access)
    {
        Write-Verbose "[SMBSecDaclAce] - SetAccount: Setting DACL access to $Access."

        try
        {
            $tmpAcc = [SMBSecAccess]$Access
            $this.Access = $tmpAcc
        }
        catch
        {
            Write-Error "Failed to convert $Access to a [SMBSecAccess] object. The valid values are Allow and Deny: $_" -EA Stop
        }

        $this.Access = $Access
    }


    # Change the DACL account. Assumes account validation is done prior to calling SetAccount.
    SetAccount([SMBSecAccount]$Account)
    {
        Write-Verbose "[SMBSecDaclAce] - SetAccount: Setting DACL account to $($Account.ToString())"
        $this.Account = $Account
    }

    # Change the DACL account. Does not assume account validation is done prior to calling SetAccount.
    SetAccount($Account)
    {
        Write-Verbose "[SMBSecDaclAce] - SetAccount: Setting DACL account to $($Account.ToString())"

        try
        {
            $tmpAcc = [SMBSecAccount]::new($Account)
            $this.Account = $tmpAcc
        }
        catch
        {
            Write-Error "Failed to convert $Account to a [SMBSecAccount] object: $_" -EA Stop
        }
    }

    # change the DACL right(s). This is validated within the class.
    SetRights([string[]]$Right)
    {
        # if FullControl is part of the permissions, set that and break because the rest don't matter
        if ($Right -contains "FullControl")
        {
            $this.Right = "FullControl"
            Write-Verbose "[SMBSecDaclAce] - SetRight: Set to FullControl. Ignoring other rights."
            break
        }

        # validate the rights match the SecDesc
        Write-Verbose "[SMBSecDaclAce] - SetRight: Begin."
        Write-Verbose "[SMBSecDaclAce] - SetRight: Testing permissions for $($this.SecurityDescriptor))."
        $permListName =  $Script:SMBSecPermMap.($this.SecurityDescriptor.ToString())
        Write-Verbose "[SMBSecDaclAce] - SetRight: PermListName: $permListName"
        $permListHash = (Get-Variable $permListName -Scope script).Value
        $permList = $permListHash.Keys
        Write-Verbose "[SMBSecDaclAce] - SetRight: Valid permissions are: $($permList -join ', ')"
        $failed = $false
        foreach ($perm in $Right)
        {
            if ($perm -notin $permList)
            {
                Write-Error "SetRight: Failed to find the permission $perm in SecurityDescriptor $($this.SecurityDescriptor)" -EA Stop
                $failed = $true
            }
        }

        if ($failed) 
        { 
            Write-Verbose "[SMBSecDaclAce] - SetRight: End without saving values."
            break
        }

        Write-Verbose "[SMBSecDaclAce] - SetRight: Setting the rights to: $($Right -join ', ')"
        Write-Verbose "[SMBSecDaclAce] - SetRight: End"
        $this.Right = $Right
    }

    [SMBSecDaclAce]
    Clone()
    {
        # create a new [SMBSecDaclAce] object based on the existing one
        $newDACL = [SMBSecDaclAce]::new($this.SecurityDescriptor, $this.Account, $this.Access, $this.Right)

        return $newDACL
    }

    [string]
    ToStringList()
    {
        return @"
SecurityDescriptor : $($this.SecurityDescriptor)
account            : $($this.Account.ToString())
access             : $($this.Access)
arrRights          : $($this.Right.ToString())
"@
    }

    [string]
    ToBoxString()
    {
        return @"
`t`tAccount  : $($this.Account.ToString())
`t`tAccess   : $($this.Access)
`t`tArrRights: $($this.Right -join ',')
"@
    }

    [string]
    ToString()
    {
        return "$($this.Account.ToString()) ($($this.Access)) {$($this.Right -join ", ")}"
    }

}
