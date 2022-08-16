# https://docs.microsoft.com/en-us/windows/win32/secauthz/sid-strings
<#
# only works in Windows PowerShell (5.1)
$u = Invoke-WebRequest 'https://docs.microsoft.com/en-us/windows/win32/secauthz/sid-strings'

[regex]$findStr = '\"(?<str>[A-Z]{2})\"'
[regex]$findDesc = "(?<sddl>SDDL(?:_[A-Z]{1,10}){1,5})"

foreach ($el in ( $u.AllElements | where { $_.TagName -eq "TR" } ))
{
    $td = $el.innerHTML.Split("`n")
    
    if ($td[0] -match $findStr)
    {
        [string]$SDDL_SID = $matches.str

        if ($td[1] -match $findDesc)
        {
            $SDDLDesc = $matches.sddl
        }
    }
    
    "`"$SDDL_SID`" = `"$SDDLDesc`","
}

#>
# maps SID to SDL constant
[hashtable]$Script:SMBSecSIDMap = @{
    WR = "SDDL_WRITE_RESTRICTED_CODE"
    AA = "SDDL_ACCESS_CONTROL_ASSISTANCE_OPS"
    AC = "SDDL_ALL_APP_PACKAGES"
    AN = "SDDL_ANONYMOUS"
    AO = "SDDL_ACCOUNT_OPERATORS"
    AP = "SDDL_PROTECTED_USERS"
    AU = "SDDL_AUTHENTICA"
    BA = "SDDL_BUILTIN_ADMINISTRA"
    BG = "SDDL_BUILTIN_GUESTS"
    BO = "SDDL_BACKUP_OPERATORS"
    BU = "SDDL_BUILTIN_USERS"
    CA = "SDDL_CERT_SERV_ADMINISTRA"
    CD = "SDDL_CERTSVC_DCOM_ACCESS"
    CG = "SDDL_CREATOR_GROUP"
    CN = "SDDL_CLONEABLE_CONTROLLER"
    CO = "SDDL_CREATOR_OWNER"
    CY = "SDDL_CRYPTO_OPERATORS"
    DA = "SDDL_DOMAIN_ADMINISTRA"
    DC = "SDDL_DOMAIN_COMPUTERS"
    DD = "SDDL_DOMAIN_DOMAIN_CONTROLLER"
    DG = "SDDL_DOMAIN_GUESTS"
    DU = "SDDL_DOMAIN_USERS"
    EA = "SDDL_ENTERPRISE_ADMINS"
    ED = "SDDL_ENTERPRISE_DOMAIN_CONTROLLER"
    EK = "SDDL_ENTERPRISE_KEY_ADMINS"
    ER = "SDDL_EVENT_LOG_READERS"
    ES = "SDDL_RDS_ENDPOINT_SERVERS"
    HA = "SDDL_HYPER_V_ADMINS"
    HI = "SDDL_ML_HIGH"
    IS = "SDDL_IIS_USERS"
    IU = "SDDL_INTERACTIV"
    KA = "SDDL_KEY_ADMINS"
    LA = "SDDL_LOCAL_ADMIN"
    LG = "SDDL_LOCAL_GUEST"
    LS = "SDDL_LOCAL_SERVICE"
    LU = "SDDL_PERFLOG_USERS"
    LW = "SDDL_ML_LOW"
    ME = "SDDL_ML_MEDIUM"
    MP = "SDDL_ML_MEDIUM_PLUS"
    MU = "SDDL_PERFMON_USERS"
    NO = "SDDL_NETWORK_CONFIGURAT"
    NS = "SDDL_NETWORK_SERVICE"
    NU = "SDDL_NETWORK"
    OW = "SDDL_OWNER_RIGHTS"
    PA = "SDDL_GROUP_POLICY_ADMINS"
    PO = "SDDL_PRINTER_OPERATORS"
    PS = "SDDL_PERSONAL_SELF"
    PU = "SDDL_POWER_USERS"
    RA = "SDDL_RDS_REMOTE_ACCESS_SERVERS"
    RC = "SDDL_RESTRICTED_CODE"
    RD = "SDDL_REMOTE_DESKTOP"
    RE = "SDDL_REPLICATOR"
    RM = "SDDL_RMS"
    RO = "SDDL_ENTERPRISE_RO_DC"
    RS = "SDDL_RAS_SERVERS"
    RU = "SDDL_ALIAS_PREW"
    SA = "SDDL_SCHEMA_ADMINISTRA"
    SI = "SDDL_ML_SYSTEM"
    SO = "SDDL_SERVER_OPERATORS"
    SS = "SDDL_SERVICE_ASSERTED"
    SU = "SDDL_SERVICE"
    SY = "SDDL_LOCAL_SYSTEM"
    UD = "SDDL_USER_MODE_DRIVERS"
    WD = "SDDL_EVERYONE"
}


<#

# get a mostly accurate SID to account list
$u = Invoke-WebRequest 'https://docs.microsoft.com/en-us/windows/security/identity-protection/access-control/security-identifiers'


[regex]$findSID = '(?<str>S-1-5-32-[0-9]{1,3})|(?<str>S-1-[0-9]-[0-9]{1,3})|(?<str>S-1-5-\<EM\>domain\<\/EM\>-[0-9]{1,3})'
#[regex]$findSID = '(?<str>S-1-5-\<EM\>domain\<\/EM\>-[0-9]{1,3})'
[regex]$findAccnt = "\>(?<sddl>(?:\w{1,15}[-|\s]){1,7}\w{1,15})\<|\>(?<sddl>(?:\w{1,15}))\<|\>(?<sddl>((\w{1,30})[(\s\w{1,30}){1,3}]\\(?:\w{1,15}[-|\s]){1,7}\w{1,15}))\<"

foreach ($el in ( $u.AllElements | where { $_.TagName -eq "TR" } ))
{
    $td = $el.innerHTML.Split("`n")
    
    if ($td[0] -match $findSID)
    {
        [string]$SDDL_SID = $matches.str

        if ($td[1] -match $findAccnt)
        {
            $SDDLAccnt = $matches.sddl
        }

        "'$SDDL_SID' = `"$SDDLAccnt`""
        #"'$SDDLAccnt',"

    }
    
    Remove-Variable td, SDDL_SID, SDDLAccnt -EA SilentlyContinue
}



# build a list of key to account name hashtable entries
$converter = New-Object System.Management.ManagementClass Win32_SecurityDescriptorHelper
foreach ($key in $SMBSecSIDMap.Keys)
{
    $owner = ($converter.SDDLToWin32SD("O:$key")).Descriptor.Owner
    $accnt = $owner.Name

    if ([string]::IsNullOrEmpty($accnt))
    {
        switch ($owner.SIDString)
        {
            'S-1-5-80' { $accnt = "All Services" }
            'S-1-5-11' { $accnt = "Local account" }
            'S-1-5-11' { $accnt = "Local account and member of Administrators group" }
            'S-1-5-10' { $accnt = "Self" }
            'S-1-5-11' { $accnt = "Authenticated Users" }
            'S-1-5-12' { $accnt = "Restricted Code" }
            'S-1-5-13' { $accnt = "Terminal Server User" }
            'S-1-5-14' { $accnt = "Remote Interactive Logon" }
            'S-1-5-15' { $accnt = "This Organization" }
            'S-1-5-17' { $accnt = "IIS_USRS" }
            'S-1-5-18' { $accnt = "System" }
            'S-1-5-19' { $accnt = "LocalService" }
            'S-1-5-20' { $accnt = "Network Service" }
            'S-1-5-32-544' { $accnt = "Administrators" }
            'S-1-5-32-545' { $accnt = "Users" }
            'S-1-5-32-546' { $accnt = "Guests" }
            'S-1-5-32-547' { $accnt = "Power Users" }
            'S-1-5-32-548' { $accnt = "Account Operators" }
            'S-1-5-32-549' { $accnt = "Server Operators" }
            'S-1-5-32-550' { $accnt = "Print Operators" }
            'S-1-5-32-551' { $accnt = "Backup Operators" }
            'S-1-5-32-552' { $accnt = "Replicators" }
            'S-1-5-32-554' { $accnt = "Pre-Windows 2000 Compatible Access" }
            'S-1-5-32-555' { $accnt = "Remote Desktop Users" }
            'S-1-5-32-556' { $accnt = "Network Configuration Operators" }
            'S-1-5-32-557' { $accnt = "Incoming Forest Trust Builders" }
            'S-1-5-32-558' { $accnt = "Performance Monitor Users" }
            'S-1-5-32-559' { $accnt = "Performance Log Users" }
            'S-1-5-32-560' { $accnt = "Windows Authorization Access Group" }
            'S-1-5-32-561' { $accnt = "Terminal Server License Servers" }
            'S-1-5-32-562' { $accnt = "Distributed COM Users" }
            'S-1-5-32-569' { $accnt = "Cryptographic Operators" }
            'S-1-5-32-573' { $accnt = "Event Log Readers" }
            'S-1-5-32-574' { $accnt = "Certificate Service DCOM Access" }
            'S-1-5-32-575' { $accnt = "RDS Remote Access Servers" }
            'S-1-5-32-576' { $accnt = "RDS Endpoint Servers" }
            'S-1-5-32-577' { $accnt = "RDS Management Servers" }
            'S-1-5-32-578' { $accnt = "Hyper-V Administrators" }
            'S-1-5-32-579' { $accnt = "Access Control Assistance Operators" }
            'S-1-5-32-580' { $accnt = "Remote Management Users" }
            'S-1-5-64-10' { $accnt = "NTLM Authentication" }
            'S-1-5-64-14' { $accnt = "SChannel Authentication" }
            'S-1-5-64-21' { $accnt = "Digest Authentication" }
            'S-1-5-80' { $accnt = "NT Service" }
            'S-1-5-80-0' { $accnt = "All Services" }
            'S-1-5-83-0' { $accnt = "NT VIRTUAL MACHINE\Virtual Machines" }

            default        { $accnt = "" }
        }
    }

    if ([string]::IsNullOrEmpty($accnt))
    {
        switch ($key)
        {
            "EK"    { $accnt = "Enterprise Key Admins" }
            "KA"    { $accnt = "Domain Key Admins" }
            "DA"    { $accnt = "Domain Admins" }
            "DD"    { $accnt = "Domain Controllers" }
            "RU"    { $accnt = "PeW2KAccess" }
            "CN"    { $accnt = "Cloneable Domain Controllers" }
            "PA"    { $accnt = "Group Policy Administrators" }
            "AP"    {$accnt = "Protected Users" }
            "RS"    {$accnt = "RAS Servers Group" }
            "DG"    {$accnt = "Domain Guests" }
            "DU"    {$accnt = "Domain Users" }
            "DC"    {$accnt = "Domain Computers" }
            "SA"    {$accnt = "Schema Administrators" }
            "CA"    {$accnt = "Certificate Publishers" }
            "RO"    {$accnt = "Enterprise Read-only Domain Controllers" }
            "EA"    {$accnt = "Enterprise Administrators" }
            default { $accnt = "Unknown" }
        }
    }

    "`"$key`" = `"$accnt`""
}

#>
# maps SDDL SID to account
[hashtable]$Script:SMBSecSIDAccnt = @{
    ME = "Medium Mandatory Level"
    PU = "BUILTIN\Power Users"
    LG = "Guest"
    SO = "Server Operators"
    SU = "NT AUTHORITY\SERVICE"
    RE = "Replicator"
    EK = "Enterprise Key Admins"
    LW = "Low Mandatory Level"
    KA = "Domain Key Admins"
    DA = "Domain Admins"
    RA = "RDS Remote Access Servers"
    UD = "USER MODE DRIVERS"
    BU = "BUILTIN\Users"
    HA = "Hyper-V Administrators"
    LA = "Administrator"
    OW = "OWNER RIGHTS"
    ED = "ENTERPRISE DOMAIN CONTROLLERS"
    SS = "Service asserted identity"
    RD = "Remote Desktop Users"
    IS = "IIS_IUSRS"
    MU = "Performance Monitor Users"
    ES = "RDS Endpoint Servers"
    AA = "Access Control Assistance Operators"
    RM = "Remote Management Users"
    NU = "NETWORK"
    DD = "Domain Controllers"
    RU = "Pre-Windows 2000 Compatible Access"
    SI = "System Mandatory Level"
    CN = "Cloneable Domain Controllers"
    AO = "Account Operators"
    AC = "ALL APPLICATION PACKAGES"
    WR = "WRITE RESTRICTED"
    LS = "LOCAL SERVICE"
    NO = "Network Configuration Operators"
    MP = "Medium Plus Mandatory Level"
    PS = "SELF"
    CO = "CREATOR OWNER"
    CY = "Cryptographic Operators"
    AP = "Protected Users"
    AU = "NT AUTHORITY\Authenticated Users"
    CG = "CREATOR GROUP"
    CD = "Certificate Service DCOM Access"
    AN = "NT AUTHORITY\ANONYMOUS LOGON"
    PA = "Group Policy Administrators"
    SY = "NT AUTHORITY\SYSTEM"
    RS = "RAS Servers Group"
    LU = "Performance Log Users"
    PO = "Print Operators"
    DG = "Domain Guests"
    HI = "High Mandatory Level"
    IU = "NT AUTHORITY\INTERACTIVE"
    DU = "Domain Users"
    WD = "Everyone"
    DC = "Domain Computers"
    RC = "RESTRICTED"
    SA = "Schema Administrators"
    CA = "Certificate Publishers"
    BA = "BUILTIN\Administrators"
    NS = "NT AUTHORITY\NETWORK SERVICE"
    BO = "Backup Operators"
    RO = "Enterprise Read-only Domain Controllers"
    BG = "BUILTIN\Guests"
    EA = "Enterprise Administrators"
    ER = "Event Log Readers"
}

# well known SID to account
[hashtable]$Script:SMBSecWKSID2Account = @{
    'S-1-0-0' = "Null SID"
    'S-1-1-0' = "World"
    'S-1-2-0' = "Local"
    'S-1-2-1' = "Console Logon"
    'S-1-3-0' = "Creator Owner ID"
    'S-1-3-1' = "Creator Group ID"
    'S-1-3-2' = "Creator Owner Server"
    'S-1-3-3' = "Creator Group Server"
    'S-1-3-4' = "Owner Rights"
    'S-1-5-1' = "Dialup"
    'S-1-5-113' = "Local account"
    'S-1-5-114' = "Local account and member of Administrators group"
    'S-1-5-2' = "NT AUTHORITY\NETWORK"
    'S-1-5-3' = "NT AUTHORITY\BATCH"
    'S-1-5-4' = "NT AUTHORITY\INTERACTIVE"
    'S-1-5-5' = "Logon Session"
    'S-1-5-6' = "Service"
    'S-1-5-7' = "Anonymous Logon"
    'S-1-5-8' = "Proxy"
    'S-1-5-9' = "NT AUTHORITY\ENTERPRISE DOMAIN CONTROLLERS"
    'S-1-5-10' = "Self"
    'S-1-5-11' = "Authenticated Users"
    'S-1-5-12' = "Restricted Code"
    'S-1-5-13' = "Terminal Server User"
    'S-1-5-14' = "NT AUTHORITY\REMOTE INTERACTIVE LOGON"
    'S-1-5-15' = "This Organization"
    'S-1-5-17' = "IIS_USRS"
    'S-1-5-18' = "[SYSTEM|LocalSystem]"
    'S-1-5-19' = "[NT Authority|LocalService]"
    'S-1-5-20' = "Network Service"
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
    'S-1-5-64' = "[NTLM|SChannel|Digest] Authentication"
    'S-1-5-80' = "[NT|All] Service"
    'S-1-5-83' = "NT VIRTUAL MACHINE\Virtual Machines"
}

<#


$u = Invoke-WebRequest 'https://docs.microsoft.com/en-us/windows/win32/secauthz/ace-strings'
[regex]$findStr = '\"(?<str>[A-Z]{1,2})\"'
[regex]$findDesc = "(?<sddl>SDDL(?:_[A-Z]{1,10}){1,5})"

foreach ($el in ( $u.AllElements | where { $_.TagName -eq "TR" } ))
{
    $td = $el.innerHTML.Split("`n")
    
    if ($td[0] -match $findStr)
    {
        [string]$SDDL_SID = $matches.str

        if ($td[1] -match $findDesc)
        {
            $SDDLDesc = $matches.sddl
        }
    }
    
    

    "`"$SDDL_SID`" = `"$SDDLDesc`","
}

#>


# LanmanServer SecurityDescriptor value name to definition
[hashtable]$Script:SMBSecDescriptorDef = @{
    SrvsvcConfigInfo        = "Manage File and Print Sharing"
    SrvsvcConnection        = "Manage File/Print Server Connections"
    SrvsvcFile              = "Manage File Server Open Files"
    SrvsvcServerDiskEnum    = "Enumerate File Server Disks"
    SrvsvcSessionInfo       = "Manage File/Print Server Sessions"
    SrvsvcShareAdminConnect = "Connect to Administrative Shares"
    SrvsvcShareAdminInfo    = "Manage Administrative Shares"
    SrvsvcShareChange       = "Manage share permissions"
    SrvsvcShareConnect      = "Connect to File and Printer Shares"
    SrvsvcShareFileInfo     = "Manage File Shares"
    SrvsvcSharePrintInfo    = "Manage Printer Shares"
    SrvsvcStatisticsInfo    = "Read File/Print Server Statistics"
    SrvsvcTransportEnum     = "Enumerate Server Transport Protocols"
    SrvsvcDefaultShareInfo  = "Default Share Permissions"
}


[hashtable]$Script:SMBSecPermMap = @{
    SrvsvcConfigInfo        = "SMBSecSrvsvcConfigInfo"
    SrvsvcConnection        = "SMBSecSrvsvcConnection"
    SrvsvcFile              = "SMBSecSrvsvcFile"
    SrvsvcServerDiskEnum    = "SMBSecSrvsvcServerDiskEnum"
    SrvsvcSessionInfo       = "SMBSecSrvsvcSessionInfo"
    SrvsvcShareAdminConnect = "SMBSecSrvsvcShareAdminConnect"
    SrvsvcShareAdminInfo    = "SMBSecSrvsvcShareAdminInfo"
    SrvsvcShareChange       = "SMBSecSrvsvcShareChange"
    SrvsvcShareConnect      = "SMBSecSrvsvcShareConnect"
    SrvsvcShareFileInfo     = "SMBSecSrvsvcShareFileInfo"
    SrvsvcSharePrintInfo    = "SMBSecSrvsvcSharePrintInfo"
    SrvsvcStatisticsInfo    = "SMBSecSrvsvcStatisticsInfo"
    SrvsvcTransportEnum     = "SMBSecSrvsvcTransportEnum"
    SrvsvcDefaultShareInfo  = "SMBSecSrvsvcDefaultShareInfo"
}


## SrvsvcConfigInfo permissions ##
[hashtable]$Script:SMBSecSrvsvcConfigInfo = [ordered]@{
    FullControl                  = "CCDCLCRPSDRCWDWO"
    ReadServerInfo               = "CC"
    ReadAdvancedServerInfo       = "DC"
    ReadAdministrativeServerInfo = "LC"
    ChangeServerInfo             = "RP"
    Delete                       = "SD"
    ReadControl                  = "RC"
    WriteDAC                     = "WD"
    WriteOwner                   = "WO"
}



## SrvsvcConnection Permissions ##
[hashtable]$Script:SMBSecSrvsvcConnection = [ordered]@{
    FullControl                  = "CCSDRCWDWO"
    EnumerateConnections         = "CC"
    Delete                       = "SD"
    ReadControl                  = "RC"
    WriteDAC                     = "WD"
    WriteOwner                   = "WO"
}

## SrvsvcFile Permissions ##
[hashtable]$Script:SMBSecSrvsvcFile = [ordered]@{
    FullControl                  = "CCRPSDRCWDWO"
    EnumerateOpenFiles           = "CC"
    ForceFilesClosed             = "RP"
    Delete                       = "SD"
    ReadControl                  = "RC"
    WriteDAC                     = "WD"
    WriteOwner                   = "WO"
}


## SrvsvcServerDiskEnum Permissions ## 
[hashtable]$Script:SMBSecSrvsvcServerDiskEnum = [ordered]@{
    FullControl                  = "CCSDRCWDWO"
    EnumerateDisks               = "CC"
    Delete                       = "SD"
    ReadControl                  = "RC"
    WriteDAC                     = "WD"
    WriteOwner                   = "WO"
}

## SrvsvcSessionInfo Permissions ##
[hashtable]$Script:SMBSecSrvsvcSessionInfo = [ordered]@{
    FullControl                   = "CCDCRPSDRCWDWO"
    ReadSessionInfo               = "CC"
    ReadAdministrativeSessionInfo = "DC"
    ChangeServerInfo              = "RP"
    Delete                        = "SD"
    ReadControl                   = "RC"
    WriteDAC                      = "WD"
    WriteOwner                    = "WO"
}

## SrvsvcShareAdminInfo Permissions ##
[hashtable]$Script:SMBSecSrvsvcShareAdminInfo = [ordered]@{
    FullControl                   = "CCDCRPSDRCWDWO"
    ReadShareInfo                 = "CC"
    ReadAdministrativeShareInfo   = "DC"
    ChangeShareInfo               = "RP"
    Delete                        = "SD"
    ReadControl                   = "RC"
    WriteDAC                      = "WD"
    WriteOwner                    = "WO"
}

## SrvsvcShareFileInfo Permissions ##
[hashtable]$Script:SMBSecSrvsvcShareFileInfo = [ordered]@{
    FullControl                   = "CCDCRPSDRCWDWO"
    ReadShareInfo                 = "CC"
    ReadAdministrativeShareInfo   = "DC"
    ChangeShareInfo               = "RP"
    Delete                        = "SD"
    ReadControl                   = "RC"
    WriteDAC                      = "WD"
    WriteOwner                    = "WO"
}

## SrvsvcSharePrintInfo Permissions ##
[hashtable]$Script:SMBSecSrvsvcSharePrintInfo = [ordered]@{
    FullControl                   = "CCDCRPSDRCWDWO"
    ReadShareInfo                 = "CC"
    ReadAdministrativeShareInfo   = "DC"
    ChangeShareInfo               = "RP"
    Delete                        = "SD"
    ReadControl                   = "RC"
    WriteDAC                      = "WD"
    WriteOwner                    = "WO"
}


## SrvsvcShareConnect Permissions ##
[hashtable]$Script:SMBSecSrvsvcShareConnect = [ordered]@{
    FullControl                   = "CCDCSDRCWDWO"
    ConnectToServer               = "CC"
    ConnectToPausedServer         = "DC"
    Delete                        = "SD"
    ReadControl                   = "RC"
    WriteDAC                      = "WD"
    WriteOwner                    = "WO"
}


## SrvsvcShareAdminConnect Permissions ##
[hashtable]$Script:SMBSecSrvsvcShareAdminConnect = [ordered]@{
    FullControl                   = "CCDCSDRCWDWO"
    ConnectToServer               = "CC"
    ConnectToPausedServer         = "DC"
    Delete                        = "SD"
    ReadControl                   = "RC"
    WriteDAC                      = "WD"
    WriteOwner                    = "WO"
}

## SrvsvcStatisticsInfo Permissions ##
[hashtable]$Script:SMBSecSrvsvcStatisticsInfo = [ordered]@{
    FullControl                   = "CCSDRCWDWO"
    ReadStatistics                = "CC"
    Delete                        = "SD"
    ReadControl                   = "RC"
    WriteDAC                      = "WD"
    WriteOwner                    = "WO"
}


## SrvsvcDefaultShareInfo Permissions ##
[hashtable]$Script:SMBSecSrvsvcDefaultShareInfo = [ordered]@{
    FullControl                   = "FA"
    Change                        = "0x1301bf"
    Read                          = "0x1200a9"
}


## SrvsvcTransportEnum Permissions ##
[hashtable]$Script:SMBSecSrvsvcTransportEnum = [ordered]@{
    FullControl                   = "CCDCLCRPSDRCWDWO"
    Enumerate                     = "CC"
    AdvancedEnumerate             = "DC"
    SetInfo                       = "RP"
    Delete                        = "SD"
    ReadControl                   = "RC"
    WriteDAC                      = "WD"
    WriteOwner                    = "WO"
}

#### DELETE COMMENT ####
# $env:SDXROOT\onecore\ds\netapi\svcdlls\srvsvc\server\sssec.h
[hashtable]$Script:SMBSecSrvsvcShareChange = [ordered]@{
    FullControl                   = "CCDCRPSDRCWDWO"
    ReadShareUserInfo             = "CC"
    ReadAdminShareUserInfo        = "DC"
    SetShareInfo                  = "RP"
    Delete                        = "SD"
    ReadControl                   = "RC"
    WriteDAC                      = "WD"
    WriteOwner                    = "WO"
}

