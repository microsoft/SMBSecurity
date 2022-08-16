#Requires -RunAsAdministrator
#Requires -Version 5.1

using namespace System.Collections
using namespace System.Collections.Generic
using namespace System.Security.Principal
#using namespace System.Security.Principal.NTAccount
#using namespace System.Security.Principal.SecurityIdentifier


<#

GENERAL MODULE GUIDELINES AND INFORMATION:

    - Err on the side of caution. When in doubt, fail the command and output an error.    
    - Use ArrayLists for collections. The Classes and Functions will expect them, and it helps a little with performance.
    - Classes are stored in .\bin\class.ps1 and are used to enforce data structures for the module.
    - Enums are stored in .\bin\enum.ps1.
    - Hashtables are stored in .\bin\hashtable.ps1.
    - Enums and hashtables are used for quick lookups of static data. Some consolidation of the two might be needed...
    - sddl_flags.json is a constructed list of ACE values based on crawling the SDDL docs: https://docs.microsoft.com/en-us/windows/win32/secauthz/security-descriptor-definition-language
    - Use Write-Verbose and Write-Debug to output optional troubleshooting information.
       - Add the function name to output.
       - Example:

            Write-[Verbose|Debug] "Function-Name - Comment about what's going on. What's in variable: $variable"

        - Use Verbose for output that is generally good for troubleshooting.
        - Use Debug for loops and when the information does not seem as helpful for general troubleshooting.
    - Document your code. The documentation can be in the form of a comment or Write-[Verbose|Debug], but make sure you tell other what's going on to ease debugging.
    - Do not use the Global variable scope! Local and Script scopes only!
    - Export only the functions that are required to perform SMB security work.
    - Use "$null = <command>" to prevent unwanted output to the console. Do not use Out-Null whenever possible. Example, when adding an element to an ArrayList: $null = $results.Add(...)
    - Test your inputs and outputs! Try-Catch[-Finally] is your friend: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_try_catch_finally
    - Avoid using "throw", use 'return (Write-Error "<error>" -EA Stop)' instead. Throw does some weird stuff with classes and layered commands.
    - Functions are sorted by verb (Get, Set, Add, New, etc.) regions.

#>


################
## LOAD FILES ##
################


# get the module path
[string]$Script:SMBSecModulePath = (Split-Path -Path (Get-Variable -Name myinvocation -Scope script).value.Mycommand.Definition -Parent)
Write-Verbose "ModulePath: $SMBSecModulePath"


Write-Verbose "Importing SDDL flags."
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



###############
## CONSTANTS ##
###############

### Do not use the Global variable scope! 

# path to the DefaultSecurity key, where the SMB security details are stored
$script:SMBSecRegPath = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\DefaultSecurity"

# location of the auto-backup path (AUTO mode path)
$script:BackupPath = "$ENV:LOCALAPPDATA\SMBSecurity"

# selected backups - this is a generic list on purpose, because ArrayList doesn't work right with the UI for some reason
$script:restoreFileSelection = [List[PSCustomObject]]::new()



<#
PURPOSE:  
EXPORTED: 
#>

###########
##  GET  ##
###########
#region


<#
PURPOSE:  Queries the registry and returns an array containing the current SDDL values.
EXPORTED: YES
#>
function Get-SMBSecurity
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [string]
        $SecurityDescriptor
    )

    Write-Verbose "Get-SMBSecurity - Begin"

    if (-NOT [string]::IsNullOrEmpty($SecurityDescriptor) -and $SecurityDescriptor -notin ([SMBSecurityDescriptor].GetEnumNames()))
    {
        Write-Error "'$SecurityDescriptor' is an invalid SecurityDescriptor. The valid names are $((Get-SMBSecDescriptorNames) -join ', ')"
        return $null
    }
    
    # stores the enumerated reqults in an ArrayList for performance and consistency
    $results = New-Object System.Collections.ArrayList

    Write-Verbose "Get-SMBSecurity - Converting binary reg values."
    if (-NOT [string]::IsNullOrEmpty($SecurityDescriptor))
    {
        Write-Verbose "Get-SMBSecurity - Single descriptor."
        Write-Debug "Get-SMBSecurity - Processing: $SecurityDescriptor"
        $null = $results.Add((Read-SMBSecDescriptor $SecurityDescriptor))
    }
    else
    {
        Write-Verbose "Get-SMBSecurity - Multiple descriptors."

        foreach ($name in [SMBSecurityDescriptor].GetEnumNames())
        {
            Write-Debug "Get-SMBSecurity - Processing: $SecurityDescriptor"
            $null = $results.Add((Read-SMBSecDescriptor $name))
        }
    }

    Write-Verbose "Get-SMBSecurity - Returning $($results.Count) objects:`n`n$($results | Format-Table Name, Owner, RawSDDL | Out-String)`n"
    Write-Verbose "Get-SMBSecurity - End"
    return $results
}


<#
PURPOSE:  Matches an SD value to a readable description
EXPORTED: YES
#>
function Get-SMBSecDescription
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $SecurityDescriptor
    )
    Write-Verbose "Get-SMBSecDesc - Begin"

    # test for a valid descriptor name
    if (-NOT [string]::IsNullOrEmpty($SecurityDescriptor) -and $SecurityDescriptor -notin ([SMBSecurityDescriptor].GetEnumNames()))
    {
        Write-Error "'$SecurityDescriptor' is an invalid SecurityDescriptor. The valid names are $((Get-SMBSecDescriptorNames) -join ', ')"
        return $null
    }

    # return all when no descriptor is passed
    if ([string]::IsNullOrEmpty($SecurityDescriptor))
    {
        Write-Verbose "Get-SMBSecDesc - Returning all descriptors and descriptions."
        $result = [List[PSObject]]::new()
        
        foreach ($element in $Script:SMBSecDescriptorDef.GetEnumerator())
        {
            Write-Debug "Get-SMBSecDesc - Name: $($element.Key), Description: $($element.Value)"
            $tmp = [PSCustomObject]@{
                Name        = $element.Key
                Description = $element.Value
            }

            # the Add method throws "You cannot call a method on a null-valued expression." in Windows PowerShell
            $result.Add($tmp)

            Remove-Variable tmp -EA SilentlyContinue
        }

        return $result
    }
    else
    {
        try 
        {
            Write-Verbose "Get-SMBSecDesc - Getting description."
            $desc = $Script:SMBSecDescriptorDef."$SecurityDescriptor"    
        }
        catch 
        {
            # do nothing, just surpressing the error    
        }

        if ($desc)
        {
            Write-Verbose "Get-SMBSecDesc - returning: $desc"
            Write-Verbose "Get-SMBSecDesc - End"
            return $desc
        }
        else 
        {
            Write-Verbose "Get-SMBSecDesc - Unknown reg property found. Returning error."
            Write-Verbose "Get-SMBSecDesc - End"
            return (Write-Error "Unknown SMB SecurityDescriptor." -EA Stop)
        }
    }

    

}

<#
PURPOSE:  Matches an well-known SID to a readable account description
EXPORTED: NO
#>
function Get-SMBSecAccount
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $SID
    )
    Write-Verbose "Get-SMBSecAccount - Begin"
    if (-NOT [string]::IsNullOrEmpty($SID))
    {
        $accnt = Find-UserAccount $SID

        Write-Verbose "Get-SMBSecAccount - Returning: $accnt"
        Write-Verbose "Get-SMBSecAccount - End"
        return $accnt
    }
    
    Write-Verbose "Get-SMBSecAccount - The SID was null or empty. Returning Unknown."
    Write-Verbose "Get-SMBSecAccount - End"
    return "Unknown"
}

<#
PURPOSE:  Returns a list of SMB Security Descriptors and their descriptions.
EXPORTED: YES
#>
function Get-SMBSecDescriptorNames
{
    return ([List[string]]( [SMBSecurityDescriptor].GetEnumNames() ))
}

<#
PURPOSE:  Returns the available rights for a security descriptor.
EXPORTED: YES
#>
function Get-SMBSecDescriptorRights
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $SecurityDescriptor
    )
    # test for a valid descriptor name
    if (-NOT [string]::IsNullOrEmpty($SecurityDescriptor) -and $SecurityDescriptor -notin ([SMBSecurityDescriptor].GetEnumNames()))
    {
        Write-Error "'$SecurityDescriptor' is an invalid SecurityDescriptor. The valid names are $((Get-SMBSecDescriptorNames) -join ', ')"
        return $null
    }

    # check for FullControl and single permission values
    $hashTable = Invoke-Expression "`$Script:SMBSec$SecurityDescriptor"

    return $hashTable
}

#endregion GET


###########
##  SET  ##
###########
#region

<#
PURPOSE:  Alters the owner of a SecurityDescriptor.
EXPORTED: YES
#>
function Set-SMBSecOwner
{
    [CmdletBinding()]
    param (
        ## needs to read from pipeline ##
        [Parameter( Mandatory=$true,
                    ValueFromPipeline=$true)]
        [PSCustomObject]
        $SecurityDescriptor,

        $Account,

        [switch]
        $PassThru
    )

    begin
    {
        # Write-Verbose "Set-SMBSecOwner - "
        Write-Verbose "Set-SMBSecOwner - Begin"
    }
    
    process
    {    

        Write-Verbose "Set-SMBSecOwner - Validating $Account"
        try
        {    
            $Owner = New-SMBSecOwner -Account $Account -EA Stop
            #Write-Verbose "Set-SMBSecOwner - Found $($Owner.Account.Value)"
            Write-Verbose "Set-SMBSecOwner - Setting the Security Descriptor to $Owner."

            $SecurityDescriptor.Owner.SetOwner($Owner)
            Write-Verbose "Set-SMBSecOwner - New owner set"

        }
        catch
        {
            return (Write-Error "Failed to validate the Owner account." -EA Stop)
        }
    }

    end
    {
        Write-Verbose "Set-SMBSecOwner - End"
        if ($PassThru.IsPresent)
        {
            return $SecurityDescriptor
        }
        else
        {
            return $null
        }
    }
}



<#
PURPOSE:  Alters a SD DACL.
EXPORTED: YES
#>
function Set-SMBSecGroup
{
    [CmdletBinding()]
    param (
        ## needs to read from pipeline ##
        [Parameter( Mandatory=$true,
                    ValueFromPipeline=$true)]
        [PSCustomObject]
        $SecurityDescriptor,

        [string]
        $Account,

        [switch]
        $PassThru
    )

    begin
    {
        # Write-Verbose "Set-SMBSecGroup - "
        Write-Verbose "Set-SMBSecGroup - Begin"
    }
    
    process
    {    
        Write-Verbose "Set-SMBSecGroup - Setting the Security Descriptor to $Account."
        try 
        {
            $Group = New-SMBSecGroup -Account $Account -EA Stop
            Write-Verbose "Set-SMBSecOwner - Setting the Security Descriptor to $Group."

            $SecurityDescriptor.Group.SetGroup($Group)
            Write-Verbose "Set-SMBSecOwner - New Group set"
        }
        catch 
        {
            return (Write-Error "Failed to set the new Group account: $_" -EA Stop)
        }
    }

    end
    {
        Write-Verbose "Set-SMBSecGroup - End"
        if ($PassThru.IsPresent)
        {
            return $SecurityDescriptor
        }
        else
        {
            return $null
        }
    }
}

<#
PURPOSE:  Alters a single DACL. Used in conjunction with Set-SmbSecDescriptor to modify DACLs in an SD.
EXPORTED: YES
#>
function Set-SMBSecDACL
{
    [CmdletBinding()]
    param (
        [Parameter( Mandatory=$true )]
        [SMBSecDaclAce]
        $DACL,

        $Account = $null,
    
        [ValidateSet("Allow", "Deny")]
        $Access = $null,

        [string[]]
        $Right = $null,

        [switch]
        $PassThru
    )

    Write-Verbose "Set-SMBSecDACL - Begin"

    # Clone the DACL.
    # make changes to the clone and commit only once all changes are successful
    Write-Verbose "Set-SMBSecDACL - Cloning DACL."
    $copyDACL = $DACL


    # update the account
    if ($Account)
    {
        Write-Verbose "Set-SMBSecDACL - Updating Account from $($copyDACL.Account.ToString()) to $($Account.ToString())."
        # Keep it simple, don't bother checking if it's the same as there are too many variables. The user will be trusted on that aspect.
        # Let [SMBSecDaclAce].SetAccount() do the work of validation.
        try 
        {
            $copyDACL.SetAccount($Account)
            Write-Verbose "Set-SMBSecDACL - Account update successfully."
        }
        catch 
        {
            return (Write-Error "Failed to update the DACL account: $_" -EA Stop)
        }
    }

    # update the access
    if ($Access)
    {
        Write-Verbose "Set-SMBSecDACL - Updating Access from $($copyDACL.Access) to $($Access.ToString())."
        try 
        {
            # Let [SMBSecDaclAce].SetAccess() do the work
            $copyDACL.SetAccess($Access)
            Write-Verbose "Set-SMBSecDACL - Access update successfully."
        }
        catch 
        {
            return (Write-Error "Failed to update the DACL access: $_" -EA Stop)
        }
    }

    # update rights
    if ($Right)
    {
        Write-Verbose "Set-SMBSecDACL - Updating Right(s) from $($copyDACL.Right -join ',') to $($Right -join ',')."
        # add rights to the DACL
        # SetRights does all the validation work, rely on that rather than duplicating the code here.
        try 
        {
            $copyDACL.SetRights($Right)    
        }
        catch 
        {
            return (Write-Error "Failed to update the DACL rights: $_" -EA Stop)
        }
    }

    # return the modified DACL
    Write-Verbose "Set-SMBSecDACL - End"
    #return $copyDACL    
}




<#
PURPOSE:  Updates a single DACL in a SD. Used in conjunction with Set-SMBSecDACL, which modifies the DACL.
EXPORTED: YES
#>
function Set-SmbSecDescriptorDACL
{
    [CmdletBinding()]
    param (
        [Parameter( Mandatory=$true)]
        [PSCustomObject]
        $SecurityDescriptor,

        [Parameter( Mandatory=$true )]
        [SMBSecDaclAce]
        $DACL,

        [Parameter( Mandatory=$true )]
        [SMBSecDaclAce]
        $NewDACL
    )

    Write-Verbose "Set-SmbSecDescriptorDACL - Begin"
    # find the index of the DACL in the SD
    $index = $SecurityDescriptor.DACL.IndexOf($DACL)
    Write-Verbose "Set-SmbSecDescriptorDACL - Index of DACL: $index"

    if (-NOT $index -or $index -eq -1)
    {
        return (Write-Error "Could not find a matching DACL in the SecurityDescriptor." -EA Stop)
    }

    try 
    {
        Write-Verbose "Set-SmbSecDescriptorDACL - Removing DACL."
        # remove the DACL at the index
        $SecurityDescriptor.DACL.RemoveAt($index)

        Write-Verbose "Set-SmbSecDescriptorDACL - Inserting updated ACL."
        # insert the new DACL in the same spot
        $SecurityDescriptor.DACL.Insert($index, $NewDACL)
    }
    catch 
    {
        return (Write-Error "Failed to update the DACL: $_" -EA Stop)
    }
}


#endregion SET


###########
##  NEW  ##
###########
#region

<#
PURPOSE:  Creates a [PSCustomObject] containing all the details of an SMB security descriptor.
EXPORTED: NO
#>
function New-SMBSecDescriptor
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        #[ValidateScript({ $_ -in ([SMBSecurityDescriptor].GetEnumNames()) })]
        [SMBSecurityDescriptor]
        $SecurityDescriptor,

        [Parameter(Mandatory=$false)]
        [string]
        $SDDLString,

        [Parameter(Mandatory=$false)]
        $Owner,

        [Parameter(Mandatory=$false)]
        $Group,

        [Parameter(Mandatory=$false)]
        $DACL
    )

    Write-Verbose "New-SMBSecDescriptor - Begin"

    # use the SDDL string over other params
    if (-NOT [string]::IsNullOrEmpty($SDDLString))
    {
        # convert the SDDL to human readable text
        $SDDL = ConvertFrom-SddlString $SDDLString
        Write-Debug "New-SMBSecDescriptor - SecurityDescriptor Name: $SecurityDescriptor"
        Write-Debug "New-SMBSecDescriptor - SDDLString: $strSDDL"

        Write-Verbose "New-SMBSecDescriptor - Creating the DACL ACE object."

        $DACL = New-Object System.Collections.ArrayList
        # strip out the ACE string(s)
        [string[]]$ACEs = $SDDLString.Split(':')[-1].Split(')').Trim('(') | Where-Object { $_ -ne $null -and $_ -ne "" }
        Write-Verbose "New-SMBSecDescriptor - ACEs: $($ACEs -join ', ')"

        # this is really ugly ... :{ ... but it works
        $DACL = New-Object System.Collections.ArrayList
        try 
        {
            Write-Verbose "New-SMBSecDescriptor - First try."
            $DACL += Convert-SMBSecString2DACL $SecurityDescriptor $ACEs
        }
        catch 
        {
            Write-Verbose "New-SMBSecDescriptor - Second try."
            $DACL += Convert-SMBSecString2DACL $SecurityDescriptor $ACEs            

            #$null = $DACL.AddRange($tmpDACL)
        }
  
        Write-Verbose "New-SMBSecDescriptor - DACL count: $($DACL.Count)"

        if ($DACL)
        {
            Write-Verbose "New-SMBSecDescriptor - DACL:`n$($DACL | Format-Table * | Out-String) "
        }
        else
        {
            Write-Error "huh..."
        }


    }
     
    # need to make sure DACL is an ArrayList or it messes things up later on
    if ($DACL -isnot [System.Collections.ArrayList])
    {
        # convert array and generic lists to ArrayList.
        # The next version may switch to generic lists per: https://docs.microsoft.com/en-us/powershell/scripting/learn/deep-dives/everything-about-arrays?view=powershell-7.2
        if ($DACL -is [array] -or $DACL.GetType().Name -Match "List")
        {
            $tmpDACL = $DACL
            $DACL = New-Object System.Collections.ArrayList

            $null = $DACL.AddRange($tmpDACL)
        }
        elseif ($DACL -is [object] -and $DACL.GetType().Name -eq "SMBSecDaclAce")
        {
            $tmpDACL = $DACL
            $DACL = New-Object System.Collections.ArrayList

            $null = $DACL.Add($tmpDACL)
        }
        else 
        {
            return (Write-Error "New-SMBSecDescriptor - Unknown DACL type. The DACL must me an Array or ArrayList of, or a single, SMBSecDACL object (New-SMBSecDACL).")    
        }
    }    

    ## validate everything... bail on fail ##
    # description
    try 
    {
        Write-Verbose "New-SMBSecDescriptor - Get descriptor description."
        $desc = Get-SMBSecDescription -SecurityDescriptor $SecurityDescriptor -EA Stop
    }
    catch 
    {
        # the description is not important, but if this fails then something is broken so we terminate anyway.
        return (Write-Error "Failed to find a description. Possibly data integrity issue detected. $_" -EA Stop)
    }

    # owner
    try 
    {
        Write-Verbose "New-SMBSecDescriptor - Create owner."
        if ( -NOT [string]::IsNullOrEmpty($SDDL.Owner) )
        {
            Write-Debug "New-SMBSecDescriptor - Set Owner as part of SDDL: $($SDDL.Owner)"
            $OwnAccount = New-SMBSecOwner $SDDL.Owner
            #$tmpowner = [SMBSecOwner]::New($OwnAccount.Account)
        }
        elseif ($Owner -is [SMBSecAccount])
        {
            Write-Debug "New-SMBSecDescriptor - Manual set Owner as [SMBSecAccount]: $($Owner.ToString())"
            $OwnAccount = New-SMBSecOwner $Owner
        }
        elseif ($Owner -is [SMBSecOwner])
        {
            Write-Debug "New-SMBSecDescriptor - Manual set Owner as [SMBSecAccount]: $($Owner.ToString())"
            $OwnAccount = $Owner
        }
        elseif ( -NOT [string]::IsNullOrEmpty($Owner))
        {
            Write-Debug "New-SMBSecDescriptor - Manual set Owner as something else: $($Owner.ToString())"
            $OwnAccount = New-SMBSecOwner $Owner
            #$tmpowner = [SMBSecOwner]::New($OwnAccount.Account)
        }
        else 
        {
            return (Write-Error "Failed to find an owner." -EA Stop)
        }       
    }
    catch 
    {
        return (Write-Error "Failed to validate owner account: $_" -EA Stop)
    }
    
    # group
    try 
    {
        Write-Verbose "New-SMBSecDescriptor - Create group."
        if ( -NOT [string]::IsNullOrEmpty($SDDL.Group) )
        {
            Write-Debug "New-SMBSecDescriptor - Set Group as part of SDDL: $($SDDL.Group)"
            $GrpAccount = New-SMBSecGroup $SDDL.Group
            #$tmpgroup = [SMBSecGroup]::New($GrpAccount.Account)
        }
        elseif ($Group -is [SMBSecGroup])
        {
            Write-Debug "New-SMBSecDescriptor - Manual set Group as [SMBSecAccount]: $($Group.ToString())"
            $GrpAccount = $Group
        }
        elseif ($Group -is [SMBSecAccount])
        {
            Write-Debug "New-SMBSecDescriptor - Manual set Group as [SMBSecAccount]: $($Group.ToString())"
            $GrpAccount = New-SMBSecGroup $Group
        }
        elseif ( -NOT [string]::IsNullOrEmpty($Group))
        {
            Write-Debug "New-SMBSecDescriptor - Manual set Group as something else: $($Group.ToString())"
            $GrpAccount = $Group
            #$tmpgroup = [SMBSecGroup]::New($GrpAccount.Account)
        }
        else 
        {
            Write-Error "Failed to find a group." -EA Stop
        }
    }
    catch 
    {
        return (Write-Error "Failed to validate group account: $_" -EA Stop)
    }
    
    if ( -NOT $DACL )
    {
        return (Write-Error "Failed to find or create a DACL." -EA Stop)
    }

    Write-Verbose "New-SMBSecDescriptor - Create SMBSecurityDescriptor object."
    # create a results object
    $tmpObj = [PSCustomObject]@{
        PSTypeName       = 'SMBSec.Descriptor'
        Name             = $SecurityDescriptor
        Description      = $desc
        Owner            = $OwnAccount
        Group            = $GrpAccount
        DACL             = $DACL
    }

    # I decided to keep the descriptor object simplified so there are fewer things to update.
    # One of more of the following can be added back in the future, but will be skipped in the first iteration.
    #SDDL             = $SDDL
    #rawSDDL          = $SDDLString
    #rawBytes         = $rawBytes


    <# add ToString method
    $sd2Str = @'
Name        : {0}
Description : {1}
Owner       : {2}
Group       : {3}
DACL        : {4}
'@
#>

    $tmpObj | Add-Member -MemberType ScriptMethod -Name ToString -Value { "Name        : {0}`nDescription : {1}`nOwner       : {2}`nGroup       : {3}`nDACL        : {4}" -f $this.Name, `
                                                                                                                                                                             $this.Description, `
                                                                                                                                                                             $this.Owner.Account.ToString(), `
                                                                                                                                                                             $this.Group.Account.ToString(), `
                                                                                                                                                                             $(($this.DACL | ForEach-Object {$_.ToString()}) -join ', ') } -Force


    $tmpObj | Add-Member -MemberType ScriptMethod -Name ToBoxString -Value { "`tName        : {0}`n`tDescription : {1}`n`tOwner       : {2}`n`tGroup       : {3}`n`tDACL        : `n{4}" -f `
                                                                                                                                                                                $this.Name, `
                                                                                                                                                                                $this.Description, `
                                                                                                                                                                                $this.Owner.Account.ToString(), `
                                                                                                                                                                                $this.Group.Account.ToString(), `
                                                                                                                                                                                "`n`t`t$(($this.DACL | ForEach-Object {$_.ToString()}) -join "`n`t`t")" } -Force

    Write-Verbose "New-SMBSecDescriptor - Returning SMBSecurity object:`n $($tmpObj | Format-Table | Out-String)"
    Write-Verbose "New-SMBSecDescriptor - End"
    return $tmpObj
}

<#
PURPOSE:  Creates a DACL object which can be added to a SMBSec.Descriptor.
EXPORTED: YES

TO-DO:
   - Find a dynamic way of creating the $Rights ValidateSet, possibly with a ValidateScript?
#>
function New-SMBSecDACL
{
    [CmdletBinding()]
    param (
        [Parameter( Mandatory=$true,
                    Position=0)]
        #[ValidateScript({ $_ -in ([SMBSecurityDescriptor].GetEnumNames()) })]
        [SMBSecurityDescriptor]
        $SecurityDescriptor,

        [Parameter( Mandatory=$true,
                    Position=1)]
        #[ValidateSet("Allow","Deny")]
        [SMBSecAccess]
        $Access,

        # Parameter help description
        [Parameter( Mandatory=$true,
                    Position=2)]
        #[ValidateSet("AdvancedEnumerate","Change","ChangeServerInfo","ChangeShareInfo","ConnectToPausedServer","ConnectToServer","Delete","Enumerate","EnumerateConnections","EnumerateDisks","EnumerateOpenFiles","ForceFilesClosed","FullControl","Read","ReadAdministrativeServerInfo","ReadAdministrativeSessionInfo","ReadAdministrativeShareInfo","ReadAdminShareUserInfo","ReadAdvancedServerInfo","ReadControl","ReadServerInfo","ReadSessionInfo","ReadShareInfo","ReadShareUserInfo","ReadStatistics","SetInfo","SetShareInfo","WriteDAC","WriteOwner")]
        [string[]]
        $Rights,

        # Parameter help description
        [Parameter( Mandatory=$true,
                    Position=3)]
        $Account
    )

    # Write-Verbose "New-SMBSecDACL - "
    begin
    {
        Write-Verbose "New-SMBSecDACL - Begin"

        # create a DACL object
        Write-Verbose "New-SMBSecDACL - Create new SMBSecDaclAce."

        # tracks failures to ensure partial objects are not returned
        $failure = $false

        # create the SMBSecDaclAce object
        $tmpDACL = [SMBSecDaclAce]::new($SecurityDescriptor)
    }

    process
    {
        Write-Verbose "New-SMBSecDACL - Process"

        # loop through each parameter and add the value to the [SMBSecDaclAce] object.
        :key foreach ($key in $PSBoundParameters.Keys)
        {
            switch ($key)
            {
                "Access"
                {
                    Write-Verbose "Set-SMBSecRight - Setting Access."
                    try
                    {
                        $tmpDACL.SetAccess($Access)
                    }
                    catch
                    {
                        $failure = $true
                        Write-Error "Failed to set DACL access: $_"
                        break key
                    }
                    
                    break
                }

                "Rights"
                {
                    Write-Verbose "Set-SMBSecRight - Setting Rights."
                    try
                    {
                        $tmpDACL.SetRights($Rights)
                    }
                    catch
                    {
                        $failure = $true
                        Write-Error "Failed to set DACL rights: $_"
                        break key
                    }

                    break
                }

                "Account"
                {
                    Write-Verbose "Set-SMBSecRight - Setting Account."
                    try
                    {
                        if ($Account -is [SMBSecAccount])
                        {
                            $tmpDACL.SetAccount($Account)
                            break
                        }
                        
                        $SMBSecAccount = New-SmbSecAccount $Account
                        
                        $tmpDACL.SetAccount($SMBSecAccount)
                    }
                    catch
                    {
                        $failure = $true
                        Write-Error "Failed to set the DACL account: $_" -EA Stop
                        break key
                    }

                    break
                }

                "SecurityDescriptor" {break}

                default { Write-Error "Unknown parameter: $_`n $($PSBoundParameters | Format-List * | Out-String)" }

            }
        }

    }

    end
    {
        Write-Verbose "New-SMBSecDACL - End"
        if ($failure)
        {
            Write-Verbose "New-SMBSecDACL - Returning NULL due to failure."
            return $null
        }
        else
        {
            return $tmpDACL
        }
    }
}

<#
PURPOSE:  Validates the account on the system or domain, then returns a [System.Security.Principal.NTAccount] object.
EXPORTED: YES
#>
function New-SMBSecOwner
{
    [CmdletBinding()]
    param (
        ## needs to read from pipeline ##
        [Parameter( Mandatory=$true,
                    ValueFromPipeline=$true)]
        $Account,

        [switch]
        $ForceDomain
    )

    begin
    {
        # Write-Verbose "Set-SMBSecOwner - "
        Write-Verbose "New-SMBSecOwner - Begin"

        $skipCheck = $false
        if ($Account -is [System.Security.Principal.SecurityIdentifier] -or $Account -is [System.Security.Principal.NTAccount])
        {
            $Account = $Account.Value
        }
        elseif ($Account -is [SMBSecAccount]) 
        {
            # make sure there is an account in the object
            if ([string]::IsNullOrEmpty($Account.Owner.Account.Value))
            {
                $skipCheck = $true
            }
        }
    }
    
    process
    {    
        Write-Verbose "New-SMBSecOwner - Process"
        Write-Verbose "New-SMBSecOwner - Saving username as System.Security.Principal.NTAccount object."
        if ($skipCheck)
        {
            $fndAccount = $Account
        }
        else
        {
            try 
            {
                if ($ForceDomain.IsPresent)
                {
                    $fndAccount = Find-UserAccount $Account -ForceDomain
                }
                else
                {
                    $fndAccount = Find-UserAccount $Account
                }

                $Owner = [SMBSecOwner]::new($fndAccount)
            }
            catch 
            {
                return (Write-Error "Failed to validate the Owner account: $_" -EA Stop)
            }
        }
    }

    end
    {
        Write-Verbose "New-SMBSecOwner - End"
        Write-Verbose "New-SMBSecOwner - Returning: $($Owner.Account.Value)"
        return $Owner
    } 
}

<#
PURPOSE:  Validates the account on the system or domain, then returns a [System.Security.Principal.NTAccount] object.
EXPORTED: YES
#>
function New-SMBSecGroup
{
    [CmdletBinding()]
    param (
        ## needs to read from pipeline ##
        [Parameter( Mandatory=$true,
                    ValueFromPipeline=$true)]
        $Account,

        [switch]
        $ForceDomain
    )

    begin
    {
        # Write-Verbose "New-SMBSecGroup - "
        Write-Verbose "New-SMBSecGroup - Begin"

        $skipCheck = $false
        if ($Account -is [System.Security.Principal.SecurityIdentifier] -or $Account -is [System.Security.Principal.NTAccount])
        {
            $Account = $Account.Value
        }
        # 
        elseif ($Account -is [SMBSecAccount]) 
        {
            # make sure there is an account in the object
            if ([string]::IsNullOrEmpty($Account.Owner.Account.Value))
            {
                $skipCheck = $true
            }
        }
    }
    
    process
    {    
        Write-Verbose "New-SMBSecGroup - Process"
        Write-Verbose "New-SMBSecGroup - Saving username as System.Security.Principal.NTAccount object."
        if ($skipCheck)
        {
            $fndAccount = $Account
        }
        else
        {
            try 
            {
                if ($ForceDomain.IsPresent)
                {
                    $fndAccount = Find-UserAccount $Account -ForceDomain
                }
                else
                {
                    $fndAccount = Find-UserAccount $Account
                }

                $Group = [SMBSecGroup]::new($fndAccount)
            }
            catch 
            {
                return (Write-Error "Failed to validate the Owner account: $_" -EA Stop)
            }
        }
    }

    end
    {
        Write-Verbose "New-SMBSecGroup - Returning: $($Group.Account.Value)"
        Write-Verbose "New-SMBSecGroup - End"
        return $Group
    } 
}


<#
PURPOSE:  
EXPORTED: 
#>
function New-SmbSecAccount
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        $Account,

        # The server name of a DC that can validate the account details.
        [Parameter(Mandatory=$false)]
        [string]
        $Server,

        [Parameter(Mandatory=$false)]
        [switch]
        $Group,

        [Parameter(Mandatory=$false)]
        [switch]
        $User
    )

    <#
    
    The SMBSecAccount needs a string Username, string Domain [computername], NTAccount Account, and SecurityIdentifier SID.

    The function input can be [string], [System.Security.Principal.NTAccount], or [System.Security.Principal.SecurityIdentifier]. 
    Some magic can be performed from there to validate the account complete the object.

    #>

    # Write-Debug "New-SmbSecAccount - "
    # Write-Verbose "New-SmbSecAccount - "

    Write-Debug "New-SmbSecAccount - Creating the [SMBSecAccount] object."
    
    # when there is no Server preset we let [SMBSecAccount] handle the work
    if ([string]::IsNullOrEmpty($Server))
    {
        $objAcnt = [SMBSecAccount]::New($Account)
    }
    # use the ActiveDirectory when a Server is set
    elseif (-NOT [string]::IsNullOrEmpty($Server))
    {
        Write-Verbose "New-SmbSecAccount - Server present. Using AD module method."
        # make sure the ActiveDirectory module is available when $Server is present
        try 
        {
            $null = Import-Module ActiveDirectory -Force -EA Stop
        }
        catch 
        {
            return (Write-Error "New-SmbSecAccount - This feature requires the ActiveDirectory module. Please make sure ActiveDirectory is installed and try again: $_" -EA Stop)
        }

        # Get-AD[Group|User] doesn't seem to like NTAccounts, so convert that to string before continuing
        if ($Account -is [System.Security.Principal.NTAccount])
        {
            [string]$Account = $Account.Value.ToString()
        }

        # if it's a string, strip out the username in case a domain is attached. Get-AD[Group|User] doesn't like that either.
        if ($Account -is [string])
        {
            try 
            {
                $Account = Get-UsernameDomain $Account -EA Stop | ForEach-Object { $_.Username }    
            }
            catch 
            {
                return (Write-Error "Failed to parse username from $Account`: $_" -EA Stop)
            }
            
        }

        # try to find the account on the domain using the provided Server.
        try 
        {
            # query the server for the AD Group attached to the SID
            if ($Group.IsPresent)
            {
                $accnt = Get-ADGroup $Account -Server $Server -EA Stop
            }
            elseif ($User.IsPresent) 
            {
                $accnt = Get-ADUser $Account -Server $Server -EA Stop
            }
            else
            {
                return (Write-Error "New-SmbSecAccount - The Server parameter requires either the Group or User switch be set." -EA Stop)
            }
           
            # get the domain details so the NetBIOS name can be identified
            $nbtName = Get-ADDomain -Server $Server -EA Stop 

            # save the results 
            $objAcnt = [SMBSecAccount]::new()
            $objAcnt.AddAccount("$($nbtName.NetBIOSName)\$($accnt.SamAccountName)")
            $objAcnt.AddSID($accnt.SID)
            $objAcnt.AddUserName($accnt.SamAccountName)
            $objAcnt.AddDomain($nbtName.NetBIOSName)
        }
        catch 
        {
            Write-Error "[SMBSecOwner] - Unable to find a matching account: $_" -EA Stop
        }
    }

    return $objAcnt

}


#endregion NEW


##########
## READ ##
##########
#region

<#
PURPOSE:  
EXPORTED: NO
#>
function Read-SMBSecDescriptor
{

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [ValidateScript({ $_ -in ([SMBSecurityDescriptor].GetEnumNames()) })]
        [string]
        $SecurityDescriptor
    )

    Write-Verbose "Read-SMBSecDescriptor - Begin"

    # SrvsvcDefaultShareInfo is not in the registry by default. Process special rules when SrvsvcDefaultShareInfo is selected.
    if ($SecurityDescriptor -eq "SrvsvcDefaultShareInfo")
    {
        Write-Verbose "Read-SMBSecDescriptor - Processing special rules for SrvsvcDefaultShareInfo."
        # this is value does not appear by default
        $properties = Get-ItemProperty $Script:SMBSecRegPath -Name $SecurityDescriptor -EA SilentlyContinue
        if (-NOT $properties)
        {
            Write-Verbose "Read-SMBSecDescriptor - SrvsvcDefaultShareInfo was not found in the registry. Returning the default values."
            # SrvsvcDefaultShareInfo not found, build a default SMB SecDesc object
            return ( New-SMBSecDescriptor -SecurityDescriptor $SecurityDescriptor -SDDLString 'O:SYG:SYD:(A;;FA;;;WD)' )
        }
    }

    # need this to convert bytes to an SDDL string
    # Thanks to olamotte: https://gist.github.com/olamotte/61f85246ec945087e715f849d7750546
    $converter = New-Object System.Management.ManagementClass Win32_SecurityDescriptorHelper

    # enumerate DefaultSecurity 
    try 
    {
        Write-Verbose "Read-SMBSecDescriptor - Reading $SecurityDescriptor registry properties."
        $properties = Get-ItemProperty $Script:SMBSecRegPath -Name $SecurityDescriptor -EA Stop
        
    }
    catch 
    {
        return (Write-Error "Failed to enumerate DefaultSecurity: $_" -EA Stop)
    }

    # get raw bytes from registry
    [byte[]]$rawBytes = $properties."$SecurityDescriptor"
    Write-Verbose "Read-SMBSecDescriptor - rawBytes: $($rawBytes.ToString())"

    # get the SDDL string
    $tmpSDDL = $converter.BinarySDToSDDL($rawBytes)
    if ($tmpSDDL)
    {
        [string]$strSDDL = $tmpSDDL.SDDL
    }
    else 
    {
        return (Write-Error "Failed to collect the SDDL string." -EA Stop)
    }

    Write-Verbose "Read-SMBSecDescriptor - SDDL String: $strSDDL"

    Write-Verbose "Read-SMBSecDescriptor - Calling and returning value from New-SMBSecDescriptor."
    Write-Verbose "Read-SMBSecDescriptor - End"
    return (New-SMBSecDescriptor -SecurityDescriptor $SecurityDescriptor -SDDLString $strSDDL)
}


#endregion READ


###########
##  ADD  ##
###########
#region

<#
PURPOSE:  Adds a DACL to a SecurityDescriptor.
EXPORTED: YES

TO-DO: 
   - Use SID-only.
   - Make sure no matching SIDs rather than just account name
#>
function Add-SMBSecDACL
{
    [CmdletBinding()]
    param (
        [Parameter( Mandatory = $true)]
        $SecurityDescriptor,

        [Parameter( Mandatory = $true, ValueFromPipeline = $true)]
        [SMBSecDaclAce]
        $DACL,

        [switch]
        $PassThru
    )

    begin
    {
        # Write-Verbose "Add-SMBSecDACL - "
        Write-Verbose "Add-SMBSecDACL - Begin"
    }
    
    process
    {
        # Make sure the required parts of the [SMBSecDaclAce] object there. Which is all the parts.
        if ( [string]::IsNullOrEmpty($DACL.SecurityDescriptor) )
        {
            return (Write-Error "The DACL is missing the SecurityDescriptor name. All components of the DACL must be populated prior to adding it to the SecurityDescriptor." -EA Stop)
        }

        #  make sure the DACL SD and the SD name match
        if ($SecurityDescriptor.Name -ne $DACL.SecurityDescriptor)
        {
            return (Write-Error "The DACL SecurityDescriptor does not match the SecurityDescriptor name. The SecurityDescriptor names are used to ensure that the appropriate rights are used and must match." -EA Stop)
        }

        # Test Account
        if ( [string]::IsNullOrEmpty($DACL.Account.Account.Value) )
        {
            return (Write-Error "The DACL is missing the Account. All components of the DACL must be populated prior to adding it to the SecurityDescriptor." -EA Stop)
        }

        # Test Access
        if ( [string]::IsNullOrEmpty($DACL.Access) )
        {
            return (Write-Error "The DACL is missing the Account. All components of the DACL must be populated prior to adding it to the SecurityDescriptor." -EA Stop)
        }

        # Test Right
        if ( $DACL.Right -isnot [string[]] -or $DACL.Right -lt 1 )
        {
            return (Write-Error "The DACL is missing the Right(s). All components of the DACL must be populated prior to adding it to the SecurityDescriptor." -EA Stop)
        }

        # do the work
        try 
        {
            # The Add() method fails sometimes, so use the += method.
            $SecurityDescriptor.DACL += $DACL
        }
        catch 
        {
            return (Write-Error "Failed to add the DACL to the SecurityDescriptor: $_" -EA Stop)
        }
    }
    
    end
    {
        Write-Verbose "Add-SMBSecDACL - End"
        if ($PassThru.IsPresent)
        {
            return $SecurityDescriptor
        }
    }
}

#endregion ADD


##############
##  REMOVE  ##
##############
#region

<#
PURPOSE:  Removes a DACL from a SecurityDescriptor.
EXPORTED: YES
#>
function Remove-SMBSecDACL
{
    [CmdletBinding()]
    param (
        [Parameter( Mandatory = $true)]
        $SecurityDescriptor,

        [Parameter( Mandatory = $true, ValueFromPipeline = $true)]
        [SMBSecDaclAce]
        $DACL,

        [switch]
        $PassThru
    )

    begin
    {
        # Write-Verbose "Remove-SMBSecDACL - "
        Write-Verbose "Remove-SMBSecDACL - Begin"
    }

    process
    {
        # find the index of the DACL in the SD
        $index = $SecurityDescriptor.DACL.IndexOf($DACL)
        Write-Verbose "Set-SmbSecDescriptorDACL - Index of DACL: $index"

        if (-NOT $index -or $index -eq -1)
        {
            return (Write-Error "Could not find a matching DACL in the SecurityDescriptor." -EA Stop)
        }

        # process the removal
        try 
        {
            Write-Verbose "Remove-SMBSecDACL - Removing DACL."
            # remove the DACL at the index
            $SecurityDescriptor.DACL.RemoveAt($index)
        }
        catch 
        {
            return (Write-Error "Failed to update the DACL: $_" -EA Stop)
        }
    }
    
    end
    {
        Write-Verbose "Remove-SMBSecDACL - End"
        if ($PassThru.IsPresent)
        {
            return $SecurityDescriptor
        }    
    }
    
}


#endregion REMOVE



##########
## COPY ##
##########
#region


function Copy-SMBSecDACL
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [SMBSecDaclAce]
        $DACL
    )

    return ($DACL.Clone())
}



#endregion




#########################
## SAVE\BACKUP\RESTORE ##
#########################
#region

<#
PURPOSE:  
EXPORTED: 

TO-DO:
   - Allow pipelining from Add-SMBSecDACL

#>
function Save-SMBSecurity
{
    [CmdletBinding()]
    param (
        [Parameter()]
        $SecurityDescriptor,

        [switch]
        $Force
    )

    # Write-Verbose "Save-SMBSecurity - "
    Write-Verbose "Save-SMBSecurity - Begin"

    # convert SecurityDescriptor to a [string[]]
    # the two used by the module is ArrayList and string[].
    if ($SecurityDescriptor -is [ArrayList])
    {
        # detect a SecurityDescriptor by looking for the Name property
        if ( -NOT [string]::IsNullOrEmpty( $SecurityDescriptor[0].Name ) )
        {
            Write-Verbose "Save-SMBSecurity - Converting SecurityDescriptor to string[]."
            [string[]]$sdList = $SecurityDescriptor.Name
            Write-Verbose "Save-SMBSecurity - result: $($sdList -join ',')"
        }
    }
    elseif ($SecurityDescriptor -is [string] -or $SecurityDescriptor -is [string[]]) 
    {
        Write-Verbose "Save-SMBSecurity - SecurityDescriptor is a string or string[]."
        [string[]]$sdList = $SecurityDescriptor
        Write-Verbose "Save-SMBSecurity - result: $($sdList -join ',')"
    }
    else
    {
        Write-Verbose "Save-SMBSecurity - SecurityDescriptor type is $($SecurityDescriptor.GetType().Name). Trying to convert to string[]."
        try 
        {
            [string[]]$sdList = $SecurityDescriptor    
        }
        catch 
        {
            return (Write-Error "Failed to convert SecurityDescriptor to a string[].")    
        }
        
        Write-Verbose "Save-SMBSecurity - result: $($sdList -join ',')"
    }

    # execute a registry back
    # bail if the backup fails, unless Force is set
    try
    {
        $null = Backup-SMBSecurity -SecurityDescriptor $SecurityDescriptor.Name -EA Stop
    }
    catch
    {
        if ( -NOT $Force.IsPresent )
        {
            return (Write-Error "Failed to backup: $_" -EA Stop)
        }
        else 
        {
            Write-Verbose "Failed to backup: $_"
        }
    }

    foreach ($sd in $SecurityDescriptor)
    {
        Write-Verbose "Save-SMBSecurity - sd: $sd"
        # convert SMBSec SD to binary SD
        try
        {
            $binSD = Convert-SMBSecDesc2Binary $sd
        }
        catch
        {
            return (Write-Error "Failed to convert the SecurityDescriptor to BinarySD format: $_" -EA Stop)
        }

        # write binary SD to registry
        try 
        {
            $null = Write-SMBSecDescriptor -SecurityDescriptor $sd.Name -BinSD $binSD
        }
        catch 
        {
            return (Write-Error "Failed to write BinarySD to the registry: $_" -EA Stop)
        }
        
    }

    Write-Verbose "Save-SMBSecurity - End"
    return $null
}


<#
PURPOSE:  
EXPORTED: 
#>
function Backup-SMBSecurity
{
    [CmdletBinding()]
    param (
        [Parameter()]
        $SecurityDescriptor,

        [Parameter()]
        [string]
        $Path,

        [switch]
        $RegOnly,

        [switch]
        $WithReg
    )

    <#
        Why not export to REG file by default?

        Saving the individual binary values allows a user to backup and restore individual SDs.
        This gives users more control over testing and reverting changes if, for example, one SD
        is working properly but a different one is working as expected.

        The -RegFile option will save backup the entire DefaultSecurity key to REG file. 
        This is in addition to the CliXML backup, not instead of.
    
    #>


    # Write-Verbose "Backup-SMBSecurity - "
    Write-Verbose "Backup-SMBSecurity - Begin"
    
    # save to %LOCALAPPDATA%\SMBSecurity by default        
    # set default path if one wasn't provides
    if ( [string]::IsNullOrEmpty( $Path ) )
    {
        Write-Verbose "Backup-SMBSecurity - Save path set to $ENV:LOCALAPPDATA\SMBSecurity"
        $Path = "$ENV:LOCALAPPDATA\SMBSecurity"
    }

    # timestamp for file uniqueness
    $tmStmp = Get-Date -Format "ddMMyyy-HHmmssffff"

    # create the path
    $null = mkdir "$Path" -Force -EA SilentlyContinue

    if (-NOT $RegOnly.IsPresent)
    {
        # if SecurityDescriptor is empty all SDs are backed up
        if ( [string]::IsNullOrEmpty( $SecurityDescriptor ) -or $SecurityDescriptor.Count -le 0 )
        {
            Write-Verbose "Backup-SMBSecurity - Backing up all SDs."
            [string[]]$SecurityDescriptor = [SMBSecurityDescriptor].GetEnumNames()
        }
        else
        {
            Write-Verbose "Backup-SMBSecurity - Backing up $($SecurityDescriptor -join '_')`."
        }

        $results = New-Object System.Collections.ArrayList

        # get the SecurityDescriptor properties for LanmanServer. Read once to optimize registry reads.
        $sdRegProp = Get-ItemProperty -Path $Script:SMBSecRegPath -EA SilentlyContinue

        # save individual SDs as CliXML exports of the binary reg data
        foreach ($sd in $SecurityDescriptor)
        {
            Write-Verbose "Backup-SMBSecurity - Reading $sd."
            
            # get the bytes
            try
            {
                Write-Verbose "Backup-SMBSecurity - Read registry. Name: $sd  Path: $Script:SMBSecRegPath"

                if ($sd -ne "SrvsvcDefaultShareInfo" -or ($sd -eq "SrvsvcDefaultShareInfo" -and $sdRegProp.SrvsvcDefaultShareInfo))
                {
                    [byte[]]$tmpBin = $sdRegProp."$sd"
                }
                else
                {
                    # create the default descriptor for SrvsvcDefaultShareInfo and backup that
                    $dfltInfo = 'O:SYG:SYD:(A;;FA;;;WD)'
                    [byte[]]$tmpBin = Convert-SMBSecDesc2Binary $dfltInfo
                }
                Write-Verbose "Backup-SMBSecurity - Result: $($tmpBin -join ',')"

                $tmpObj = [PSCustomObject]@{
                    Name   = $sd
                    Binary = $tmpBin
                }

                # create a unique filename
                $fileName = "Backup-$($SecurityDescriptor -join '_')-SMBSec-$tmStmp"

                # export the object to CliXML
                Write-Verbose "Backup-SMBSecurity - Exporting data to CliXML:`n$($results.Name)`n$($results.Binary)"
                $tmpObj | Export-Clixml -Path "$path\$fileName`.xml" -Depth 20 -Force -Encoding utf8    
                Write-Verbose "Backup-SMBSecurity - XML export saved to $path\$fileName`.xml"

            }
            catch
            {
                return (Write-Error "Backup-SMBSecurity - Failed to backup the $sd SecurityDescriptor: $_" -EA Stop)
            }
        }
    }
    
    
    # export REG file
    if ($RegOnly.IsPresent -or $WithReg.IsPresent)
    {
        $regBckpFilename = "SMBSec-Full-Backup-$tmStmp`.reg"
        Write-Verbose "Backup-SMBSecurity - Saving DefaultSecurity to REG file."
        $regResult = reg.exe EXPORT $($Script:SMBSecRegPath.replace(':','')) "$path\$regBckpFilename" /y

        if ( -NOT (Test-Path "$path\$regBckpFilename") -and $regResult -notmatch "success")
        {
            return (Write-Error "Failed to write the reg file backup to '$path': $_" -EA Stop)
        }

        Write-Verbose "Backup-SMBSecurity - REG export saved to $path\$regBckpFilename"
    }

    # return true if everything worked 
    Write-Verbose "Backup-SMBSecurity - End"
    return $true
}

<#
PURPOSE:  
EXPORTED: 
#>
function Restore-SMBSecurity
{
    # Only a single file allowed for v1 of SMBSecurity, maybe forever.
    [CmdletBinding()]
    param (
        [Parameter()]
        $File = $null
    )

    # use the UI when no file is passed
    if ($null -eq $File)
    {
        Start-SuperFancyUI
    }
    else
    {
        # if File is not FileInfo (from Get-Item, Get-ChildItem, etc.) then try to convert it.
        if ($File -isnot [System.IO.FileInfo])
        {
            try 
            {
                $objFile = Get-Item "$File" -EA Stop
            }
            catch 
            {
                return (Write-Error "Failed to create the file object, or file not found: $_" -EA Stop)
            }
        }

        # convert the file into a restore object
        $script:restoreFileSelection = New-RestoreObject $objFile
    }
    
    # restore from file(s)
    foreach ($rFile in $script:restoreFileSelection)
    {
        if ($rFile.Type -eq "XML")
        {
            # restore from XML using the SdObj in the RestoreObject
            Save-SMBSecurity -SecurityDescriptor $rFile.SdObj
        }
        elseif ($rFile.Type -eq "REG")
        {
            # doing some security stuff
            # first, read the REG file to make sure the only path is HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\LanmanServer\DefaultSecurity
            try 
            {
                [array]$rPath = Get-Content "$($rFile.File.Fullname)" -EA Stop | Where-Object { $_ -match "\[.*\]" } | ForEach-Object { $_.Trim(' ') }    
            }
            catch 
            {
                return (Write-Error "Failed to read the file ($($rFile.File.FullName)): $_" -EA Stop)
            }
            

            if ($rPath.Count -gt 1)
            {
                return (Write-Error "Restore reg files can only contain a single path. This reg file contains $($rPath.Count): $($rPath -join ', ')" -EA Stop)
            }

            # is the path the required one?
            if ($rPath[0] -ne '[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\LanmanServer\DefaultSecurity]')
            {
                return (Write-Error "Restore reg path is invalid. Path in file: $($rPath[0])" -EA Stop)
            }

            # final check, verify Srvsvc names
            $rValname = Get-Content "$($rFile.File.Fullname)" -EA SilentlyContinue | Where-Object { $_ -match '"Srvsvc' } | & { process {
                if ($_ -match '(?<srv>Srvsvc.*)"=')
                {
                    "$($Matches.srv)"
                }
            }}

            # there should be 13 or 14 (SrvsvcDefaultShareInfo is not in the registry by default)
            if ($rValname.Count -lt 1)
            {
                return (Write-Error "No valid Security Descriptors were found." -EA Stop)
            }

            # names must all be valid
            $rValname | & { process {
                if ($_ -notin (Get-SMBSecDescriptorNames))
                {
                    return (Write-Error "Invalid Security Descriptor found in the reg file: $_" -EA Stop)
                }
                else { Write-Host "Match: $_"}
            }}

            # restore the REG file ... at long last
            # there's no good way to get the output of reg.exe in PowerShell, so let the customer 
            Write-Host "Regsitry restore result: " -NoNewline
            reg.exe import "$($rFile.File.Fullname)"
        }
        else 
        {
            # this should never happen...
            return (Write-Error "Unknown restore object type: $($rFile.Type) $($rFile.File.Name)" -EA Stop)
        }
    }

    # reinitialize $script:restoreFileSelection
    Remove-Variable restoreFileSelection -Scope Script -EA SilentlyContinue
    $script:restoreFileSelection = [List[PSCustomObject]]::new()
}



<#
PURPOSE:  
EXPORTED: 
#>
function Write-SMBSecDescriptor
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $SecurityDescriptor,

        [byte[]]
        $BinSD
    )

    # Write-Verbose "Write-SMBSecDescriptor - "
    Write-Verbose "Write-SMBSecDescriptor - Begin"

    Write-Verbose "Write-SMBSecDescriptor - Writing BinarySD to $SecurityDescriptor."
    try 
    {
        Set-ItemProperty -Path $Script:SMBSecRegPath -Name $SecurityDescriptor -Value $BinSD
    }
    catch 
    {
        return (Write-Error "Failed to write changes to $SecurityDescriptor`: $_" -EA Stop)        
    }

    Write-Verbose "Write-SMBSecDescriptor - End"
    return $null
}


#endregion SAVE


##############
## CONVERT* ##
##############
#region

<#
PURPOSE:  
EXPORTED: 
#>
function ConvertTo-SMBSecSDDLString
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [System.Collections.ArrayList]
        $SecurityDescriptor
    )

    # Write-Verbose "ConvertTo-SMBSecSDDLString - "
    Write-Verbose "ConvertTo-SMBSecSDDLString - Begin"

    $strSDDL = ""

    foreach ($secDesc in $SecurityDescriptor)
    {
        Write-Verbose "ConvertTo-SMBSecSDDLString - secDesc: $secDesc"
        # add the owner
        $Owner = $Script:SMBSecSIDAccnt.GetEnumerator() | Where-Object { $_.Value -eq $secDesc.Owner.Account.Value }
        Write-Verbose "ConvertTo-SMBSecSDDLString - Converting the owner, $owner, to SDDL value."

        # the hashtable only contains well-known SDDL accou
        if (-NOT $Owner)
        {
            # use the SID 
            $strSDDL += "O:$($secDesc.Owner.SID.Value)"
            Write-Verbose "ConvertTo-SMBSecSDDLString - Using owner SID value: $($secDesc.Owner.SID.Value)"
        }
        else 
        {
            $strSDDL += "O:$($Owner.Name)"
            Write-Verbose "ConvertTo-SMBSecSDDLString - Using owner code: $($Owner.Name)"
        }

        # add the group
        $Group = $Script:SMBSecSIDAccnt.GetEnumerator() | Where-Object { $_.Value -eq $secDesc.Group.Account.Value }
        Write-Verbose "ConvertTo-SMBSecSDDLString - Converting the group, $Group, to SDDL value."

        if (-NOT $Group)
        {
            $strSDDL += "G:$($secDesc.Group.SID.Value)"
            Write-Verbose "ConvertTo-SMBSecSDDLString - Using group SID value: $($secDesc.Group.SID.Value)"
        }
        else 
        {
            $strSDDL += "G:$($Group.Name)"  
            Write-Verbose "ConvertTo-SMBSecSDDLString - Using group code: $($Group.Name)"  
        }

        # SMBSec ACE layout
        # (ace_type;;rights;object_guid;;;account_sid)
        $hashTable = Invoke-Expression "`$Script:SMBSec$($SecurityDescriptor.Name)"
        Write-Verbose "ConvertTo-SMBSecSDDLString - Rights hashtable for $Script:SMBSec$($SecurityDescriptor.Name):`n$($hashTable | Format-Table | Out-String)"

        $strSDDL += "D:"
        foreach ($right in $secDesc.DACL) 
        {
            $strRight = "("

            # add access
            Write-Verbose "ConvertTo-SMBSecSDDLString - Raw Access: $($right.Access)"
            switch ($right.Access) 
            {
                "Allow" { $strRight += "A;;" }
                "Deny"  { $strRight += "D;;" }
                Default { return (Write-Error "Faulire processing ACE access." -EA Stop) }
            }

            # add right
            Write-Verbose "ConvertTo-SMBSecSDDLString - Raw rights: $($right.Right)"
            foreach ($perm in $right.Right)
            {
                Write-Verbose "ConvertTo-SMBSecSDDLString - Translating $perm ACE right."
                [string]$tmp = $hashTable[$perm]
                Write-Verbose "ConvertTo-SMBSecSDDLString - Translation: $tmp"
                $strRight += "$tmp"

                Remove-Variable tmp -EA SilentlyContinue
            }

            # separator
            $strRight += ';;;'

            $rAccnt = $right.Account.Account.Value
            Write-Verbose "ConvertTo-SMBSecSDDLString - Raw account: $rAccnt"
            # add account
            $rightAccount = $Script:SMBSecSIDAccnt.GetEnumerator() | Where-Object { $_.Value -eq $rAccnt }

            # the hashtable only contains well-known SDDL accounts
            if (-NOT $rightAccount)
            {
                # use the SID 
                if ($rAccnt -match "S-1-\d-\d{1,3}")
                {
                    $strRight += "$($rAccnt))"
                }
                # convert the account to a SID
                else 
                {
                    $SID = ([System.Security.Principal.NTAccount]"$($rAccnt)").Translate([System.Security.Principal.SecurityIdentifier])    
                    $strRight += "$($SID.Value))"
                }
            }
            else 
            {
                $strRight += "$($rightAccount.Name))"
            }

            Write-Verbose "ConvertTo-SMBSecSDDLString - ACE string: $strRight"
            $strSDDL += $strRight
        }
    }

    Write-Verbose "ConvertTo-SMBSecSDDLString - Returning $strSDDL"
    Write-Verbose "ConvertTo-SMBSecSDDLString - End"
    return $strSDDL
}

<#
PURPOSE:  
EXPORTED: 
#>
function Convert-SMBSecString2DACL
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [SMBSecurityDescriptor]
        $SecurityDescriptor,

        [Parameter()]
        [string[]]
        $AceString
    )

    Write-Verbose "Convert-SMBSecString2DACL - Begin"
    $ACEs = New-Object System.Collections.ArrayList
    $DACL = New-Object System.Collections.ArrayList

    Write-Verbose "Convert-SMBSecString2DACL - Loop through ACLs."
    foreach ($ace in $AceString)
    {
        Write-Verbose "Convert-SMBSecString2DACL - Processing ACE: $($ace)"
        if ( [string]::IsNullOrEmpty( $ace ) )
        {
            Write-Verbose "Convert-SMBSecString2DACL - NULL ACE detected!"
            continue
        }

        ## clean up the string ##
        # sample DACL string: D:(A;;CCDCLCRPSDRCWDWO;;;BA)(A;;CCDCLCRPSDRCWDWO;;;SO)(A;;CCDCLCRPSDRCWDWO;;;SY)(A;;CCDC;;;PU)(A;;CC;;;WD)(A;;CC;;;AN)
        # remove D: from the start
        if ($ace.Substring(0,2) -eq 'D:')
        {
            $ace = $ace.Substring(2)
            Write-Debug "Convert-SMBSecString2DACL - ACE: $ace"
        }

        # if there are parantheses then break up the ACEs in the DACL
        if ($ace.Contains('(') -and $ace.Contains(')') )
        {
            $ace.Split(')').Trim('(') | Where-Object { $_ -ne $null -and $_ -ne "" } | ForEach-Object {
                $null = $ACEs.Add($_)    
            }
            Write-Debug "Convert-SMBSecString2DACL - $($ACEs -join ',')"
        }
        else 
        {
            $null = $ACEs.Add($ace)
            Write-Debug "Convert-SMBSecString2DACL - Ready ACE."
        }
    }


    # convert the ACE string to SMB Security objects
    foreach ($ace in $ACEs)
    {
        Write-Verbose "Convert-SMBSecString2DACL - ACE: ($ace)"
        # https://docs.microsoft.com/en-us/windows/win32/secauthz/ace-strings
        # [0] ace_type            [used]
        # [1] ace_flags           [not used]
        # [2] rights              [used]
        # [3] object_guid         [not used]
        # [4] inherit_object_guid [not used]
        # [5] account_sid         [used]
        # (resource_attribute)    [not implemented]
        $tmp = $ace.Split(';')

        # check type (Allow or Deny)
        switch ($tmp[0])
        {
            "A" {$access = [SMBSecAccess]"Allow"; break}
            "D" {$access = [SMBSecAccess]"Deny"; break}
            default { return (Write-Error "This ACE has implemented a Type value that is not supported by SMBSecurity. The valid options are A (Allow) and D (Deny). Value passed: $($tmp[0])" -EA Stop) }
        }
        Write-Debug "Convert-SMBSecString2DACL - ACE Type: $($access.ToString())"

        # check rights\permissions
        $strPerms = $tmp[2]
        Write-Debug "Convert-SMBSecString2DACL - Raw ACE Rights: $strPerms"
        
        #$arrRights = New-Object System.Collections.ArrayList

        # SrvsvcDefaultShareInfo only has a single right per ACE (FullConttrol, Change, Read), do not split!
        if ($SecurityDescriptor -eq "SrvsvcDefaultShareInfo")
        {
            $tmpRight = $Script:SMBSecSrvsvcDefaultShareInfo.Keys | Where-Object { $Script:SMBSecSrvsvcDefaultShareInfo[$_] -eq $strPerms }
            Write-Debug "Convert-SMBSecString2DACL - Translated ACE Rights: $tmpRight"
            if ($tmpRight)
            {
                [string[]]$arrRights = $tmpRight
            }
            elseif ( [string]::IsNullOrEmpty($strPerms))
            {
                Write-Warning "The SDDL string could not be translated."
            }
        }
        # everything else gets split up into 2 char strings
        else
        {
            # check for FullControl and single permission values
            $hashTable = Invoke-Expression "`$Script:SMBSec$SecurityDescriptor"
            Write-Debug "Convert-SMBSecString2DACL - Hashtable: `n$($hashTable | Out-String)"

            if (-NOT $hashTable)
            {
                return (Write-Error "Convert-SMBSecString2DACL - Failed to load $SecurityDescriptor hashtable SMBSec$SecurityDescriptor." -EA Stop)
            }

            if ($hashTable.ContainsValue($strPerms))
            {
                $tmpRight = $hashTable.Keys | Where-Object { $hashTable[$_] -eq $strPerms }
                Write-Debug "Convert-SMBSecString2DACL - Translated ACE Rights: $tmpRight"
                if ($tmpRight)
                {
                    Write-Debug "Convert-SMBSecString2DACL - Adding $tmpRight to rights. [1]"
                    [string[]]$arrRights = $tmpRight
                }
                elseif ( [string]::IsNullOrEmpty($strPerms))
                {
                    Write-Warning "The SDDL string could not be translated."
                }
            }
            # chop up the string and build permissions list
            else 
            {
                for ($i = 0; $i -lt $strPerms.Length; $i += 2)
                {
                    $right = $strPerms.Substring($i, 2)
                    Write-Debug "Convert-SMBSecString2DACL - Adding $right to rights. [2]"
                    $arrRights += ($hashTable.Keys | Where-Object { $hashTable[$_] -eq $right })
                    Remove-Variable right -EA SilentlyContinue
                }    
            }
            
        }
        Write-Debug "Convert-SMBSecString2DACL - ACE Rights:`n $($arrRights -join ", ")"


        <# try to match the account or SID
        $account_sid = $tmp[5]

       
        #>
        $account_sid = $tmp[5]
        try 
        {
            $account = Find-UserAccount -Username $account_sid -EA Stop
            Write-Debug "Convert-SMBSecString2DACL - ACE Account: $account"    
        }
        catch 
        {
            return (Write-Error "Failed to find a valid account for $account_sid`: $_" -EA Stop)    
        }
        


        Write-Verbose "Convert-SMBSecString2DACL - Create DACL object for $SecurityDescriptor."
        Write-Debug @"
Convert-SMBSecString2DACL - DACL parts:
SecurityDescriptor : $SecurityDescriptor ( $($SecurityDescriptor.GetType().Name) )
account            : $($account.Account) ( $($account.GetType().Name) )
access             : $access ( $($access.GetType().Name) )
arrRights          : $arrRights ( $($arrRights.GetType().Name) )
"@

        try 
        {
            $DaclAce = [SMBSecDaclAce]::New($SecurityDescriptor, $account, $access, $arrRights)
            Write-Verbose "Convert-SMBSecString2DACL - DaclAce:`n`n$($DaclAce.ToStringList())"
            $DACL += $DaclAce
            Write-Verbose "Convert-SMBSecString2DACL - Currently $($DACL.Count) DACLs."
        }
        catch 
        {
            return (Write-Error "Failed to create the [SMBSecDaclAce] object: $_" -EA Stop)
        }

        Remove-Variable tmp, strPerms, rights, hashTable, account_sid, DaclAce, tmpRight -EA SilentlyContinue
    }

    Write-Verbose "Convert-SMBSecString2DACL - Returning $($DACL.Count) DACLs."
    return $DACL
}

<#
PURPOSE:  
EXPORTED: 
#>
function Convert-SMBSecDesc2Binary
{
    [CmdletBinding()]
    param (
        [Parameter()]
        $SecurityDescriptor
    )

    Write-Verbose "Convert-SMBSecDesc2Binary - Begin"
    # start by converting the SD to SDDL string
    if ($SecurityDescriptor -is [PSCustomObject])
    {
        Write-Verbose "Convert-SMBSecDesc2Binary - Convert the SMBSec SD to string SDDL format."
        $strSDDL = ConvertTo-SMBSecSDDLString $SecurityDescriptor
    }
    else
    {
        $strSDDL = $SecurityDescriptor
    }
    

    Write-Verbose "Convert-SMBSecDesc2Binary - strSDDL: $strSDDL"
    # need this to convert the SDDL string back to bytes
    $converter = New-Object System.Management.ManagementClass Win32_SecurityDescriptorHelper

    # convert to binary
    try 
    {
        Write-Verbose "Convert-SMBSecDesc2Binary - Convert string SDDL to binary SD."
        $binSD = $converter.SDDLToBinarySD($strSDDL)    
    }
    catch 
    {
        return (Write-Error "Failed to convert the SDDL to binary: $_" -EA Stop)
    }
    
    Write-Debug "Convert-SMBSecDesc2Binary - Binary SD: $($binSD.BinarySD.ToString() -join ',')"
    Write-Verbose "Convert-SMBSecDesc2Binary - end"
    return ($binSD.BinarySD)
}


#endregion CONVERT*


##########
## MISC ##
##########
#region


function Get-UsernameDomain
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $strAccount
    )

    # check for domain\user formatting. '\\' is needed for the regex -match to work
    # Match \ first in case AzureAD\user@domain.com was passed
    # AzureAD is not fully supported, hybrid might work, and Find-UserAccount needs to know if this is pure AzureAD.
    if ($strAccount -match '\\')
    {
        $Username = $strAccount.Split('\')[1]
        $Domain   = $strAccount.Split('\')[0]
    }
    # check for user@domain formatting.
    elseif ($strAccount -match '@')
    {
        $Username = $strAccount.Split('@')[0]
        $Domain   = $strAccount.Split('\')[1]
    }
    # treat everything else as a standalone username
    else
    {
        $Username = $strAccount
        $Domain   = $env:COMPUTERNAME
    }

    return ([PSCustomObject]@{
        Username = $Username
        Domain   = $Domain
    })
}

<#
PURPOSE:  
EXPORTED: 
#>
function Get-DomainJoinStatus
{
    [CmdletBinding()]
    param ()

    <# 
    https://docs.microsoft.com/en-us/azure/active-directory/devices/troubleshoot-hybrid-join-windows-current

    If these fields are YES then...

    EnterpriseJoined             = Workplace Joined.
    DomainJoined                 = Joined to on-prem AD domain.
    AzureAdJoined                = Azure AD joined, but not on-prem AD joined.
    AzureAdJoined + DomainJoined = Hybrid (AAD + AD) joined

    When all NO then it is in a workgroup.
    
    #>

    # use dsregcmd rather than reinventing the wheel
    $domainStatus = dsregcmd /status | Where-Object { $_ -match "AzureAdJoined|EnterpriseJoined|DomainJoined" } | ForEach-Object { 
        $tmp = ($_ -replace "\s+","").split(':')

        if ($tmp[1] -eq "YES") { $status = $true } else { $status = $false }

        [PSCustomObject]@{
            "$($tmp[0])" = $status
        }
    }

    return $domainStatus
}

<#
PURPOSE:  
EXPORTED: 
#>
function Find-UserAccount
{
    [CmdletBinding()]
    param (
        [string]
        $Username,

        [switch]
        $ForceDomain
    )

    #$SmbSecObj = [SMBSecAccount]::New()

    # Write-Verbose "Find-UserAccount - "
    Write-Verbose "Find-UserAccount - Begin"
    Write-Verbose "Find-UserAccount - Validating the existence of $Username."

    # bypass local checks when ForceDomain is set
    if (-NOT $ForceDomain.IsPresent)
    {

        # handles 2-char DACL/SDDL style accounts
        if ($Username.Length -eq 2)
        {
            Write-Verbose "Find-UserAccount - Checking against the list of well known DACL accounts."
            # the account is validated by the [SMBSecDaclAce] class
            $account = $Script:SMBSecSIDAccnt.$Username

            # do some additional work if this $account isn't populated
            if ($account)
            {
                Write-Verbose "Find-UserAccount - Found $account."

                try 
                {
                    Write-Verbose "Find-UserAccount - Converting to SMBSecAccount."
                    $SmbSecObj = New-SmbSecAccount $account -EA Stop
                    Write-Verbose "Find-UserAccount - Result $($SmbSecObj.ToString())"
                }
                catch 
                {
                    return (Write-Error "Failed to convert SDDL account to an SMBSecAccount: $_" -EA Stop)    
                }
                
                return $SmbSecObj
            }
        }

        # try to skip all the backup logic and see if [SMBSecAccount] can figure it out
        try
        {
            Write-Verbose "Find-UserAccount - Can [SMBSecAccount] logic figure this out without going through the full logic tree?"
            $tmpAccount = [SMBSecAccount]::new($Username)

            if ($tmpAccount -and $tmpAccount -is [SMBSecAccount])
            {
                Write-Verbose "Find-UserAccount - [SMBSecAccount] figured it out. Returning $($tmpAccount.Account.Value)."
                return $tmpAccount
            }
        }
        catch
        {
            Write-Verbose "Find-UserAccount - [SMBSecAccount] could not figure it out. Trying the backup logic path."
        }

        

        # check for SIDs
        if ($Username -match "S-1-\d{1,3}-\d{1,3}")
        {
            Write-Debug "Find-UserAccount - Look for well-known SID $Username."
            # attempt to match against the static list
            $tmpAccnt = $Script:SMBSecWKSID2Account.GetEnumerator() | Where-Object { $SID -match $_.Name }

            <# SIDs can be hard to translate on a domain, so we 
            if ( [string]::IsNullOrEmpty($tmpAccnt.Value) )
            {
                # try to translate the SID to account
                [System.Security.Principal.SecurityIdentifier]$SID = $Username
                Write-Debug "Find-UserAccount - Trying to convert SID ($Username). "
                try 
                {
                    $tmpAccnt = $SID.Translate([System.Security.Principal.NTAccount])    
                    Write-Debug "Find-UserAccount - Found an account: $($tmpAccnt.Value)"
                }
                catch 
                {
                    Write-Verbose "Find-UserAccount - Failed to convert SID ($account_sid) to an account: $_"
                }
            }

            if ([string]::IsNullOrEmpty($tmpAccnt.Value))
            {
                $accnt = $Username
            }
            else 
            {
                $accnt = $tmpAccnt.Value 
            }
            #>

            # attempt to translate the SID 
            try 
            {
                if ($tmpAccnt)
                {
                    Write-Debug "Find-UserAccount - Create the SMBSecAccount object using account string."
                    $SmbSecObj = New-SmbSecAccount $tmpAccnt -EA Stop    
                }
                else
                {
                    Write-Debug "Find-UserAccount - Create the SMBSecAccount object using SID."
                    $SmbSecObj = New-SmbSecAccount $Username -EA Stop
                }
                
            }
            catch 
            {
                return (Write-Error "Failed to convert SID to an SMBSecAccount: $_" -EA Stop)    
            }
                
            return $SmbSecObj
        }


        # if the username is a value match to something in the $Script:SMBSecWellKnownAccounts array then we're golden
        # this should always come first or some legacy and special accounts won't work (i.e. Power Users, Server Operators, Print Operators, etc.)
        Write-Verbose "Find-UserAccount - Checking against the list of well known account names."
        Write-Debug "Find-UserAccount - Number of well known accounts: $($Script:SMBSecWellKnownAccounts.Count)"
        if ($Username -in $Script:SMBSecWellKnownAccounts)
        {
            Write-Verbose "Find-UserAccount - Found an account match in the well-known accounts list: $Username"
            try 
            {
                $SmbSecObj = New-SmbSecAccount $Username -EA Stop    
            }
            catch 
            {
                Write-Verbose "Failed to create an SMBSecAccount using the well-known account $Username, trying other methods: $_"
            }
            Write-Verbose "Find-UserAccount - End"    
            return $SmbSecObj
            
        }    


        # try a simple local user lookup
        Write-Verbose "Find-UserAccount - Checking against Get-LocalUser."
        # try asking nicely for the local account
        # it is possible that a local user will be in <hostname>\<user> format, which  Get-LocalUser doesn't like, so we separate them first
        # we make this call no matter what to make domain work later on easier.
        $tmpUDObj = Get-UsernameDomain $Username
        $user = $tmpUDObj.Username
        $domain = $tmpUDObj.Domain

        Remove-Variable tmpUDObj -EA SilentlyContinue

        try 
        {
            $null = Get-LocalUser $user -EA Stop
            
            # this line won't run if Get-LocalUser fails
            Write-Verbose "Find-UserAccount - Found a local account."
            # return the local account prefixed by the computername to maintain consistency with DACL translation
            # this shouldn't conflict with special accounts likeshould be detected by this point or are compatible with computername\account
            $SmbSecObj = New-SmbSecAccount $user -EA Stop
            return $SmbSecObj
        }
        catch 
        {
            Write-Verbose "Find-UserAccount - Did not find an account, $Username, using Get-LocalUser."
        }

        # try asking nicely for the local group
        Write-Verbose "Find-UserAccount - Checking against Get-LocalGroup."
        try 
        {
            $null = Get-LocalGroup $user -EA Stop
            
            # this line won't run if Get-LocalUser fails
            Write-Verbose "Find-UserAccount - Found a local group."
            $SmbSecObj = New-SmbSecAccount $user -EA Stop
            return $SmbSecObj
        }
        catch 
        {
            Write-Verbose "Find-UserAccount - Did not find an account, $Username, using Get-LocalGroup."
        }

        # try searching in the domain
        Write-Verbose "Find-UserAccount - Looking for an AD domain."

        # AzureAD?
        if ($domain -eq "AzureAD")
        {      
            return (Write-Error "AzureAD accounts are currently not supported." -EA Stop)
        }

        # fail if $domain is reserved word
        if ($domain -in $Script:SMBSecReservedDomainWords)
        {
            return (Write-Error "Invalid domain name detected. The domain matched a list of reserved words. This could mean that a local account was used but not found.")
        }
    }

    Write-Verbose "Find-UserAccount - Processing domain account. Domain $domain, User: $user"

    if ($ForceDomain.IsPresent)
    {
        # this is skipped when ForceDomain set
        $tmpUDObj = Get-UsernameDomain $Username
        $user = $tmpUDObj.Username
        $domain = $tmpUDObj.Domain
    }

    # try the domain... unless it's workplace joined ($isJoined.EnterpriseJoined), which is untested/unsupported.
    $isJoined = Get-DomainJoinStatus
    if ($isJoined.AzureAdJoined -or $isJoined.DomainJoined)
    {
        # try letting [SMBSecAccount] handle this before using the AD module
        try
        {
            Write-Verbose "Find-UserAccount - Trying to find $user using non-AD module method."
            #$objSecAccount = [SMBSecAccount]::new($user)
            $objSecAccount = New-SMBSecAccount $user
            return $objSecAccount
        }
        catch
        {
            Write-Verbose "Find-UserAccount - Could not resolve the domain account using [SMBSecAccount]"
        }

        # if the system is AD joined then the ActiveDirectory module should be available... make sure
        try
        {
            Import-Module ActiveDirectory -EA Stop
        }
        catch
        {
            Write-Warning "The system is domain joined but the ActiveDirectory module was not found. Please install the ActiveDirectory module and try again. Server: 'Install-WindowsFeature RSAT-AD-PowerShell', Client: 'Add-WindowsCapability -Name Rsat.ActiveDirectory.DS-LDS.Tools* -Online'"
            

            
            # bail at this point
            return $null
        }

        # find the domain's PDCEmulator and query against that
        try
        {
            $domainDeets = Get-ADDomain -EA Stop
        }
        catch
        {
            return (Write-Verbose "Failed to contact the domain ($domain), account lookup has failed: $_" -EA Stop)
        }

        $Server = $domainDeets.PDCEmulator

        # rely on the New-SMBSecAccount function to do the work
        # check for a user first
        try 
        {
            $SmbSecObj = New-SmbSecAccount -Account $user -Server $Server -User -EA Stop
            return $SmbSecObj
        }
        catch 
        {
            Write-Verbose "Find-UserAccount - Not a user. Trying as a group."
        }

        # is it a group?
        try 
        {
            $SmbSecObj = New-SmbSecAccount -Account $user -Server $Server -Group -EA Stop
            return $SmbSecObj
        }
        catch 
        {
            Write-Verbose "Find-UserAccount - Not a group either."
        }
    }

    Write-Verbose "Find-UserAccount - No valid account found."
    Write-Verbose "Find-UserAccount - End"
    return $null    

}


#endregion MISC


#############
## EXPORTS ##
#############

# SecurityDescriptor
Export-ModuleMember -Function Get-SMBSecurity
Export-ModuleMember -Function New-SMBSecDescriptor

# Owner
Export-ModuleMember -Function Set-SMBSecOwner
Export-ModuleMember -Function New-SMBSecOwner

# Group
Export-ModuleMember -Function Set-SMBSecGroup
Export-ModuleMember -Function New-SMBSecGroup

# DACL
Export-ModuleMember -Function Set-SMBSecDACL
Export-ModuleMember -Function Set-SmbSecDescriptorDACL
Export-ModuleMember -Function New-SMBSecDACL
Export-ModuleMember -Function Add-SMBSecDACL
Export-ModuleMember -Function Remove-SMBSecDACL
Export-ModuleMember -Function Copy-SMBSecDACL

# list constants
Export-ModuleMember -Function Get-SMBSecDescriptorNames
Export-ModuleMember -Function Get-SMBSecDescriptorRights
Export-ModuleMember -Function Get-SMBSecDescription

# backup and restore
Export-ModuleMember -Function Save-SMBSecurity
Export-ModuleMember -Function Backup-SMBSecurity
Export-ModuleMember -Function Restore-SMBSecurity

# auxillery functions
Export-ModuleMember -Function ConvertTo-SMBSecSDDLString
Export-ModuleMember -Function Convert-SMBSecString2DACL
Export-ModuleMember -Function Convert-SMBSecDesc2Binary
