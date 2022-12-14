using namespace System.Collections
using namespace System.Collections.Generic
using namespace System.Security.Principal

# CLI UI for restoring SMB SDs from file.
#
# This is a make shift UI until .NET MAUI and Microsoft.PowerShell.ConsoleGuiTools are done.
# https://github.com/PowerShell/GraphicalTools

[CmdletBinding()]
param ()


#############
# CONSTANTS #
#############

# tracks the tallest box size to prevent overlapping elements
$script:TheTallestBox = -1



###############
#  FUNCTIONS  #
###############
#region

function Add-YesNoPrompt
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $Title,

        [Parameter()]
        [string]
        $Question,

        [Parameter()]
        [ValidateRange(0,1)]
        [int]
        $Default = 0
    )
    
    $choices  = '&Yes', '&No'

    $decision = $Host.UI.PromptForChoice($title, $question, $choices, $Default)
    if ($decision -eq 0) 
    {
        return $true
    } 
    else 
    {
        return $false
    }
}


function Convert-Timestamp2DateTime
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $Filename
    )

    # initialize to empty string
    $tmpTime = ""

    # get the file timestamp, based on the filename not the last write time
    # this regex looks for <8 number>-<10 number>, which is the timestamp
    # the timestamp format is:
    #
    #    <2 digit day><2 digit month><4 digit year>-<2 digit 24 hour><2 digit minute><2 digit second><4 digit milisecond>
    #
    if ( $Filename -match "^.*(?<tm>\d{8}-\d{10}).*$")
    { 
        # get the timestamp match
        $tmpTM = $Matches['tm']

        # this regex match gets the timestamp digits and breaks them up into labeled matches
        if ($tmpTM -match '^(?<day>\d{2})(?<month>\d{2})(?<year>\d{4})-(?<HH>\d{2})(?<mm>\d{2})(?<ss>\d{2})(?<ffff>\d{4})')
        {
            # use the labeled matches to create a DateTime object
            # this method removes regional date time differences
            [datetime]$tmpTime = Get-Date -Year $Matches['year'] -Month $Matches['month'] -Day $Matches['day'] -Hour $Matches['HH'] -Minute $Matches['mm'] -Second $Matches['ss']
        }
    }

    # return the results
    return $tmpTime
}


function Write-TextAtCoordinate
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $text,

        [int]
        $x,

        [int]
        $y
    )

    # move the cursor
    $Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates $x, $y

    # write the text
    $Host.UI.Write("$text")
}


function Get-NumToPositiveInfinity
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [decimal]
        $num
    )

     <#
    https://github.com/dotnet/runtime/blob/9d6396deb02161f5ee47af72ccac52c2e1bae458/src/libraries/System.Private.CoreLib/src/System/Math.cs
    https://docs.microsoft.com/en-us/dotnet/api/system.midpointrounding?view=net-6.0

    The strategy of upwards-directed rounding, with the result closest to and no less than the infinitely precise result.

    #>

    # turns out [decimal] knows how to do this even in .NET Framework
    return ([decimal]::Ceiling($num))
    
}


function Get-NumToNegativeInfinity
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [decimal]
        $num
    )

    <#
    https://github.com/dotnet/runtime/blob/9d6396deb02161f5ee47af72ccac52c2e1bae458/src/libraries/System.Private.CoreLib/src/System/Math.cs
    https://docs.microsoft.com/en-us/dotnet/api/system.midpointrounding?view=net-6.0

    The strategy of downwards-directed rounding, with the result closest to and no greater than the infinitely precise result.

    #>

    # turns out [decimal] knows how to do this even in .NET Framework
    return ([decimal]::Floor($num))
    
}


function Get-NumToZero
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [decimal]
        $num
    )

    <#
    https://github.com/dotnet/runtime/blob/9d6396deb02161f5ee47af72ccac52c2e1bae458/src/libraries/System.Private.CoreLib/src/System/Math.cs
    https://docs.microsoft.com/en-us/dotnet/api/system.midpointrounding?view=net-6.0

    The strategy of directed rounding toward zero, with the result closest to and no greater in magnitude than the infinitely precise result.

    #>

    # turns out [decimal] knows how to do this even in .NET Framework
    return ([decimal]::Truncate($num))
    
}

function Add-Box
{
    [CmdletBinding()]
    param (
        [Parameter()]
        $resObj,
        
        [Parameter()]
        [ValidateRange(1,14)]
        [int]
        $totalBoxes = 1,

        [int]
        $boxNumber = 1,

        [switch]
        $Box2Screen
    )

    
    if ($Box2Screen.IsPresent)
    {
        # BoxWidth is based on the largest possible filename plus whitespace and edge characters
        [int]$BoxWidth = (Get-ConsoleWidth) - 2

        # controls concatinating lines that are too long
        [int]$BoxCatWidth = $BoxWidth - 7
    }
    else
    {
        [int]$BoxWidth = 71
        [int]$BoxCatWidth = 67
    }
    

    if ($resObj -is [string])
    {
        $text = $resObj
    }
    elseif ($resObj.Type -eq "REG")
    {
        # only one box with REG type
        $text = @"
File: $($resObj.File.Name)
Date: $($resObj.Date.ToShortDateString()) $($resObj.Date.ToShortTimeString())
Type: Full Restore from REG Export File
"@

    }
    else 
    {
        # convert the timestamp to DateTime object
        $tmpTime = Convert-Timestamp2DateTime $resObj.File.Name

        $strDACL = ($resObj.SdObj.DACL | ForEach-Object { $_.ToString()}) -join ', '
        if ($strDACL.Length -gt $BoxCatWidth)
        {
            $strDACL = $strDACL.Substring(0,($BoxCatWidth - 6))
            $strDACL += "..."
        }

        # only one box with REG type
        $text = @"
File: $($resObj.File.Name)
Date: $(if ($tmpTime) { "$($tmpTime.ToShortDateString()) $($tmpTime.ToShortTimeString())" })
SD  : $($resObj.SD)
DACL: $($strDACL)
Type: Restore SecurityDescriptor from XML Export File
"@
    }

    # break the text into line and pad them
    # replace `t (tab char) with spaces so PadRight works properly later on
    $lines = $text.Split([Environment]::NewLine) | Where-Object { $_ -ne "" -and $null -ne $_ -and $_ -notmatch '^\s+$'} | ForEach-Object { $_.Replace("`t", "   ")}

    # set $script:TheTallestBox
    $tmpBoxTotalLines = $lines.Count + 2
    if ($tmpBoxTotalLines -gt $script:TheTallestBox)
    {
        $script:TheTallestBox = $tmpBoxTotalLines
    }

    # how wide is the terminal
    $consoleWidth = Get-ConsoleWidth

    if ($consoleWidth -lt $BoxWidth)
    {
        return (Write-Error "The minimum supported console/terminal width is $BoxWidth. The current width is $consoleWidth. Please resize and try again." -EA Stop)
    }

    <#
    
    The console in the main menu needs to be used efficiently to prevent boxes as many boxes from being pushed off screen as possible.

    #>

    if ($totalBoxes -eq 1)
    {
        #Write-Host $box
        #Write-Host

        Write-Host "$('┌'.PadRight($BoxWidth - 1, "─"))┐"
        $lines | ForEach-Object { 

            if ($_.Length -gt $BoxCatWidth)
            {
                $str = "$($_.Substring(0, $BoxCatWidth))..."
            }
            else
            {
                $str = $_
            }

            # make sure the pad number is non-negative to prevent evil red text
            $pad = $BoxWidth - ($_.Length) - 4
            if ($pad -le 0) {
                # do it this way to prevent the extra space caused by padding
                Write-Host "│ $str │" 
            }
            else {
                Write-Host "│ $($_)$(" ".PadRight($pad, ' ')) │" 
            }
        }
        Write-Host "$('└'.PadRight($BoxWidth - 1, "─"))┘"

        return $null
    }
    else 
    {
        ## get things ready ##

        # replaced by TheTallestBox
        #$BoxHeight = $lines.Count + 2

        # BoxSpacing controls how may spaces between boxes on the same line
        $BoxSpacing = 3

        # BoxLineSpace control how many whitespace lines betwee box rows
        $BoxLineSpace = 1
        
        # how many boxes can be fit on a row?
        # https://docs.microsoft.com/en-us/dotnet/api/system.midpointrounding?view=net-6.0 - Doesn't work in Windows PowerShell 5.1 :(
        #[int]$totalColumns = [math]::Round($consoleWidth / ($BoxWidth + $BoxSpacing) , 0, 2)
        [int]$totalColumns = Get-NumToZero ($consoleWidth / ($BoxWidth + $BoxSpacing))
        #Write-Host "`n`nconsoleWidth: $consoleWidth`ntotalColumns: $totalColumns"

        # find the total rows by always rounding up
        # https://docs.microsoft.com/en-us/dotnet/api/system.midpointrounding?view=net-6.0
        #[int]$totalRows = [math]::Round($totalBoxes / $totalColumns, 0, 4)
        
        # commenting out because its not used, but this is how it's calculated.
        #[int]$totalRows = Get-NumToPositiveInfinity ($totalBoxes / $totalColumns)
        #Write-Host "totalRows: $totalRows"

        # figure out the current row and column
        [int]$currRow = Get-NumToPositiveInfinity ($boxNumber / $totalColumns)
        #Write-Host "currRow: $currRow"

        [int]$currCol = $boxNumber - (($currRow - 1) * $totalColumns)
        #Write-Host "currCol: $currCol"

        # where is the cursor right now now
        $currPos = $Host.UI.RawUI.CursorPosition

        $startX = $currPos.X
        $startY = $currPos.Y

        # find the X position - only supports static width baces on the above calculations
        $xPos = ($currCol - 1) * ($BoxWidth + $BoxSpacing)
        #Write-Host "xPos: $xPos"


        # find the Y position
        # static box height
        #$yPos = ($currRow - 1) * ($BoxHeight + $BoxLineSpace) + $currPos.Y
        # dynamic box height formula
        $yPos = ($currRow - 1) * ($script:TheTallestBox + $BoxLineSpace) + $currPos.Y
        #Write-Host "yPos: $yPos"

        # write box top to console
        Write-TextAtCoordinate "$('┌'.PadRight($BoxWidth - 1, "─"))┐" $xPos $yPos
        $yPos = $yPos + 1

        Write-Verbose "y (above): $yPos"
        0..($script:TheTallestBox - 3) | ForEach-Object {
            # make sure the pad number is non-negative to prevent evil red text
            if ( [string]::IsNullOrEmpty($lines[$_]) )
            {
                Write-TextAtCoordinate "│ $(" ".PadRight($BoxCatWidth, ' ')) │" $xPos $yPos
            }
            else 
            {
                $pad = $BoxWidth - ($lines[$_].Length) - 4    
                
                # write the line
                if ($pad -le 0) {
                    # do it this way to prevent the extra space caused by padding
                    Write-TextAtCoordinate "│ $($lines[$_]) │" $xPos $yPos
                }
                else 
                {
                    Write-TextAtCoordinate "│ $($lines[$_])$(" ".PadRight($pad, ' ')) │" $xPos $yPos
                }
            }
            
            # next line
            $yPos = $yPos + 1
            Write-Verbose "y: $yPos"
        }

        Write-Verbose "y (below): $yPos"
        #$yPos = $startY + ($script:TheTallestBox * $currRow) - 1
        Write-TextAtCoordinate "$('└'.PadRight($BoxWidth - 1, "─"))┘" $xPos $yPos
        $yPos = $yPos + 1
        
        # set the cursor to the starting position
        $Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates $startX, $startY

        # return the Y position under the tallest box
        #return ($yPos + ($script:TheTallestBox - $tmpBoxTotalLines) + 1)
        #return ($yPos + $script:TheTallestBox + $BoxLineSpace)
        return ($yPos + $BoxLineSpace)
    }

}

function Build-Box
{
    Write-Host "Selcted backups:"

    $currBox = 1

    $script:restoreFileSelection | & { process {

        if ($_.Type -eq "XML")
        {
            $script:y = Add-Box $_.ToBoxString() $script:restoreFileSelection.Count $currBox
        }
        else 
        {
            $script:y = Add-Box $_ $script:restoreFileSelection.Count $currBox
        }

        $currBox++
    } }
}

function New-LineSeperator
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $char = '─'
    )
    $w = $Host.UI.RawUI.WindowSize.Width

    $line = "".PadRight($w, $char)

    return $line
}


function New-RestoreObject 
{
    [CmdletBinding()]
    param (
        [Parameter()]
        $File
    )

    # convert string to FileSystemInfo
    if ($File -is [string])
    {
        try 
        {
            $File = Get-Item "$File" -EA Stop    
        }
        catch 
        {
            return (Write-Error "File not found or failed to access restore file ($($File.FullName)): $_" -EA Stop)
        }
        
    }

    # at this point there is a FileSystemInfo file so assume the file exists
    # is this an XML file?
    if ($File.Extension -eq ".xml")
    {
        
        try 
        {
            $restoreObj = Import-Clixml $File.FullName -EA Stop
        }
        catch 
        {
            return (Write-Error "Failed to import the restore CliXML file ($($File.FullName)): $_" -EA Stop)
        }

        [byte[]]$Binary = $restoreObj.Binary
        [string]$SD = $restoreObj.Name

        # convert the binary data to SDDL
        $converter = New-Object System.Management.ManagementClass Win32_SecurityDescriptorHelper

        # get the SDDL string
        $tmpSDDL = $converter.BinarySDToSDDL($Binary)
        if ($tmpSDDL)
        {
            [string]$strSDDL = $tmpSDDL.SDDL
        }
        else 
        {
            return (Write-Error "Failed to collect the SDDL string." -EA Stop)
        }

        try 
        {
            $SdObj = New-SMBSecDescriptor -SecurityDescriptor $SD -SDDLString $strSDDL -EA Stop
        }
        catch 
        {
            return (Write-Error "Failed to convert the SDDL to an SMBSecurity object: $_" -EA Stop)
        }

        $tmpDateTime = Convert-Timestamp2DateTime $File.Name

        $tmpRO = [pscustomobject] @{
            Type  = "XML"
            SD    = $SD
            Bin   = $Binary
            SDDL  = $strSDDL
            SdObj = $SdObj
            File  = $File
            Date  = $tmpDateTime
        }

        $tmpRO | Add-Member -MemberType ScriptMethod -Name ToString -Value { "Type  : {0}`nSD    : {1}`nBin   : {2}`nSDDL  : {3}`nSdObj :{4}`n`nFile  : {5}" -f $this.Type, `
                                                                                                                                                                $this.SD, `
                                                                                                                                                                [string]($this.Binary -join ','), `
                                                                                                                                                                $this.SDDL, `
                                                                                                                                                                $this.SdObj.ToString(), `
                                                                                                                                                                $this.File.Name } -Force
        
        $tmpRO | Add-Member -MemberType ScriptMethod -Name ToLongString -Value { "Type  : {0}`nSD    : {1}`nSdObj :`n{2}`nFile  : {3}" -f  `
                                                                                                                                            $this.Type, `
                                                                                                                                            $this.SD, `
                                                                                                                                            $(($this.SdObj.ToString()).Split([Environment]::NewLine) | ForEach-Object { "`t$_" }), `
                                                                                                                                            $this.File.Name } -Force
        
        $tmpRO | Add-Member -MemberType ScriptMethod -Name ToBoxString -Value { "File: {0}`nDate: {1}`nSDDL: `n{2}`nType: {3}" -f $this.File.Name, `
                                                                                                                                  $this.Date, `
                                                                                                                                  $this.SdObj.ToBoxString(), `
                                                                                                                                  "Restore SecurityDescriptor from XML Export File" } -Force

        Write-Verbose $tmpRO.ToLongString()

    }
    elseif ($File.Extension -eq ".reg") 
    {
        $tmpDateTime = Convert-Timestamp2DateTime $File.Name

        # nothing really to a reg restore since the restore is a simple "reg import" command
        $tmpRO =  [pscustomobject] @{
            Type  = "REG"
            File  = $File
            Date  = $tmpDateTime
        }

        $tmpRO | Add-Member -MemberType ScriptMethod -Name ToString -Value { "Type : {0}`nFile : {1}`nDate : {2}" -f $this.Type, $this.File.Name, $this.Date } -Force

        $tmpRO | Add-Member -MemberType ScriptMethod -Name ToLongString -Value { "Type : {0}`nFile : {1}`nDate : {2}" -f $this.Type, $this.File.Name, $this.Date } -Force

        Write-Verbose @"
Type  = "XML"
File  = $($tmpRO.File.Name)
"@

    }
    else
    {
        return (Write-Error "File extension is not XML or REG: $($File.FullName)" -EA Stop)
    }

    return $tmpRO
}

function Get-ConsoleHeight
{
    return $Host.UI.RawUI.WindowSize.Height
}


function Get-ConsoleWidth
{
    return $Host.UI.RawUI.WindowSize.Width
}


function Update-AutoBackupfiles
{
    # Get all the files in the auto backup dir
    # this does not recurse!
    [array]$script:xmlFiles = Get-ChildItem $script:BackupPath -Filter "Backup-*-SMBSec-*.xml"
    [array]$script:regFiles = Get-ChildItem $script:BackupPath -Filter "SMBSec-Full-Backup-*.reg"

    # use regex to get the SDs that have been backed up
    [regex]$sdPattern = "^Backup-(?<sd>\w{10,23}.*)-SMBSec.*$"
    $script:list = [List[string]]::new()
    $script:xmlFiles | ForEach-Object { 
        if ($_.Name -match $sdPattern)
        {
            $tmpSD = $matches['sd']

            # exclude SDs that already have a backup file selected
            if ($tmpSD -notin $script:restoreFileSelection.SD)
            {
                $script:list.Add($tmpSD)
            }
            
            Remove-Variable tmpSD -EA SilentlyContinue
        }
    }

    # get unique SD backups
    $script:list = $script:list | Sort-Object -Unique
}


function Add-RestoreMainMenu
{
    # start drawing main menu
    Write-Host "`n$(New-LineSeperator '=')`n"
        
    if ($script:restoreFileSelection.Count -gt 0)
    {
        Build-Box
    }

    # set the cursor to below the boxes
    if ($script:y) { 
        $Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates 0, $y 
        Remove-Variable y -Scope Script
    }
    
    Write-Host "`n$(New-LineSeperator)`n"

    # Only show this menu item if there is no REG type selected, and the count is < 14 (total number of SMB SDs)
    Update-AutoBackupfiles
    #Write-Host "list: $($script:list -join ',')"
    if ($script:restoreFileSelection.Type -notcontains "REG" -and $script:list.Count -gt 0)
    {
        Write-Host "[F] - Find backup"
        $script:disableF = $false
    }
    else
    {
        $script:disableF = $true
    }
    
    # don't show this option when a reg file is already selected.
    # user MUST us M to remove the reg file before changing directories.
    if ($script:restoreFileSelection.Type -notcontains "REG")
    {
        Write-Host "[S] - Switch backup path (Current: $script:BackupPath)"

        $script:disableS = $false
    }
    else 
    {
        $script:disableS = $true
    }
    
    if ($script:restoreFileSelection.Count -gt 0)
    {
        Write-Host "[M] - Modify selection(s)"
        Write-Host "[R] - Restore selected backups"

        $script:disableM = $false
        $script:disableR = $false
    }
    else
    {
        $script:disableM = $true
        $script:disableR = $true
    }
    
    Write-Host "[U] - Update UI (redraw main menu)"
    Write-Host "[Q] - Quit [WARNING! Nothing will be restored!]"
    Write-Host "[?] - Help"
    
    $selection = Read-Host "`nSelection"

    $selection = $selection.ToLower()

    return $selection
}




function Start-SuperFancyUI
{    
    # used to end the UI loop
    $complete = $false

    # this is the main control loop for the menu
    :outerLoop do {

        # add main restore menu
        $selection = Add-RestoreMainMenu

        #endregion DRAW MENU

        switch -Regex ($selection) 
        {
            "f"
            {
                if ($script:disableF)
                {
                    continue outerLoop
                    break
                }

                Update-AutoBackupfiles

                # determine available restore types
                $rType = @()

                # "Individual SecurityDescriptor" menu appears when:
                #   - XML backup file was found
                #   - No REG type of restore has been selected
                if ($script:xmlFiles.Count -gt 0 -and "REG" -notin $script:restoreFileSelection.Type)
                {
                    $rType += "[I] - Individual SecurityDescriptor"
                }

                # "Full Restore" menu appears when:
                #   - REG backup file was found
                #   - No XML type of restore has been selected
                if ($script:regFiles.Count -gt 0 -and "XML" -notin $script:restoreFileSelection.Type)
                {
                    $rType += "[F] - Full Restore"
                }

                Write-Host "`n$(New-LineSeperator '=')`n"

                if ($rType.Count -gt 1)
                {
                    # prompt user to select restore type
                    $rType | ForEach-Object { Write-Host "$_" }
                    Write-Host "[X] - Exit"

                    $lclQuit = $false
                    do
                    {
                        Remove-Variable lclSel -Force -EA SilentlyContinue
                        $lclSel = Read-Host "`nSelection"
                        $lclSel = $lclSel.ToLower()
                        switch ($lclSel)
                        {
                            'i' { $type = "Individual"; $lclQuit = $true; break }
                            'f' { $type = "Full"; $lclQuit = $true; break }
                            'x' { $lclQuit = $true; break }
                            default { $lclQuit = $false; break }
                        }
                    } until ($lclQuit)

                }
                elseif ($rType.Count -eq 1)
                {
                    # set restore type to the only backup type found
                    [string]$type = $rType[0]
                }
                else
                {
                    Write-Error "Failed to find a valid backup option."

                    continue outerLoop
                    break
                }

                # quit submenu if no valid selection
                if ([string]::IsNullOrEmpty($type))
                {
                    Write-Warning "User exit."

                    # cleanup
                    Remove-Variable xmlFiles, regFiles, rType, type, lclQuit, lclSel -EA SilentlyContinue

                    # back to the top menu
                    continue outerLoop
                    break
                }

                # pick a backup

                # the number of backups to show per screen is based on UI height, minus 5, minimum of 10
                # the lines needed are: empty line, Select a file, empty line, Previous, Next, Exit, empty line, Selection,
                $numVizBackups = (Get-ConsoleHeight) - 8
                if ($numVizBackups -lt 10)
                {
                    $numVizBackups = 10
                }

                # get the file list
                if ($type -eq "Full")
                {
                    [array]$files = $script:regFiles
                }
                # individual XML
                else 
                {
                    if ($script:list.Count -gt 1)
                    {
                        # prompt the user to select the SD to restore
                        Write-Host -Fore Green "`nSelect a SecurityDescriptor:`n"

                        1..($script:list.Count) | ForEach-Object { Write-Host "[$_] - $($script:list[($_ - 1)])" }
                        Write-Host "[X] - Exit"

                        $lclQuit = $false
                        do
                        {
                            Remove-Variable lclSel -Force -EA SilentlyContinue
                            $lclSel = Read-Host "`nSelection [1-$($script:list.Count)]"
                            $lclSel = $lclSel.ToLower()
                            
                            switch -Regex ($lclSel)
                            {
                                '\d{1,2}' 
                                { 
                                    try {
                                        [int]$lclSel = [int]::Parse($lclSel)
                                    }
                                    catch {
                                        Write-Host -ForegroundColor Yellow "The acceptable values are 1 thru $($script:list.Count), and X (eXit)."
                                    }

                                    if ($lclSel -ge 1 -and $lclSel -le $script:list.Count)
                                    {
                                        $sdSelction = $script:list[($lclSel - 1)]
                                        $lclQuit = $true
                                        break 
                                    }
                                    else 
                                    {
                                        Write-Host -ForegroundColor Yellow "The acceptable values are 1 thru $($script:list.Count), and X (eXit)."
                                        $lclQuit = $false
                                        break
                                    }
                                    
                                }
                                'x' { $lclQuit = $true; break }
                                default { $lclQuit = $false; break }
                            }
                        } until ($lclQuit)
                    }
                    elseif ($script:list.Count -eq 1)
                    {
                        Write-Host "List count = 0"
                        if ($script:list -is [array])
                        {
                            $sdSelction = $script:list[0]
                        }
                        elseif ($script:list -is [string])
                        {
                            $sdSelction = $script:list
                        }
                        else
                        {
                            # bail on unknown list data type
                            $sdSelction = $null
                        }
                        
                        Write-Host "sdSelction: $sdSelction"
                    }
                    elseif ($script:list.Count -eq 0) 
                    {
                        Write-Host -ForegroundColor Yellow "All available backups have been selected."

                        # cleanup
                        Remove-Variable xmlFiles, regFiles, rType, type, lclQuit, lclSel, list, sdPattern, files, numVizBackups -EA SilentlyContinue

                        # back to the top menu
                        continue
                        break
                    }
                    else 
                    {
                        # this should never happen, but just in case...
                        Write-Warning "Unknown error. Individual SD files were found but the regex expression may have failed to parse them."

                        # cleanup
                        Remove-Variable xmlFiles, regFiles, rType, type, lclQuit, lclSel, list, sdPattern, files, numVizBackups -EA SilentlyContinue

                        # back to the top menu
                        continue
                        break
                    }

                    # bail when sdSelction is empty
                    if ([string]::IsNullOrEmpty($sdSelction))
                    {
                        Write-Warning "SecurityDescriptor selection exited by user."

                        # cleanup
                        Remove-Variable xmlFiles, regFiles, rType, type, lclQuit, lclSel, list, sdPattern, files, numVizBackups, sdSelction -EA SilentlyContinue

                        # back to the top menu
                        continue
                        break
                    }

                    # filter VML files by selected SD
                    [array]$files = $script:xmlFiles | Where-Object Name -match "^Backup-$sdSelction-SMBSec.*$"
                }

                $startIdx = 0
                $firstScreen = $true
                $endScreen = $false

                if ($files.Count -eq 1)
                {
                    $selectedfile = $files[0]
                }
                elseif ($files.Count -le 0) {
                    Write-Error "Unknown error. Backup file count is 0."
                    Start-Sleep -m 500
                    continue outerLoop
                }
                else
                {
                    :innerMenu do
                    {
                        # update $numVizBackups
                        $numVizBackups = (Get-ConsoleHeight) - 8

                        # controls the More option
                        $multipleScreensNeeded = $false
                        if ($files.Count -gt $numVizBackups)
                        {
                            $multipleScreensNeeded = $true
                        }

                        # calc the end index
                        # file count = 20
                        # numVizBackups = 14
                        $endIdx = $startIdx + $numVizBackups # 14
                        if ($endIdx -gt ($files.Count - 1)) # 14 > 19 = false
                        {
                            $endIdx = $files.Count - 1 # 
                            $endScreen = $true
                        }
                        elseif (($files.Count - 1) -gt $endIdx) # 19 > 14 = $true
                        {
                            $endScreen = $false
                        }

                        # start writing menu items
                        Write-Host -ForegroundColor Green "`nSelect a file:`n"

                        if ($multipleScreensNeeded) # true
                        {
                            if (-NOT $firstScreen) # !true = false
                            {
                                $prevAllowed = $true
                                Write-Host "[P] - Previous screen"  
                            }
                            else 
                            {
                                $prevAllowed = $false
                            }
                        }

                        $startIdx..$endIdx | & { process { 
                            # get the filename
                            $tmpFN = $files[$_].Name

                            $tmpTime = Convert-Timestamp2DateTime $tmpFN

                            $tmpIdx = $_ + 1
                            Write-Host "[$tmpIdx] - $tmpFN ($($tmpTime.ToShortDateString()) $($tmpTime.ToShortTimeString()))"
                            
                        } }

                        if ($multipleScreensNeeded) # true
                        {
                            if (-NOT $endScreen) # !$false = $true
                            {
                                $nextAllowed = $true
                                Write-Host "[N] - Next screen"
                            }
                            else 
                            {
                                $nextAllowed = $false
                            }
                        }

                        Write-Host "[X] - Exit"

                        Remove-Variable lclSel -Force -EA SilentlyContinue
                        [string]$lclSel = Read-Host "`nSelection"
                        $lclSel = $lclSel.ToLower()

                        switch -Regex ($lclSel)
                        {
                            '\d{1,4}'
                            {
                                try {
                                    [int]$lclSel = [int]::Parse($lclSel) 
                                }
                                catch {
                                    Write-Host -ForegroundColor Yellow "The acceptable values are $startIdx thru $endIdx$(if ($nextAllowed) {"N (Next), "})$(if ($prevAllowed) {"P (Previous), "}) and X (eXit)."
                                    Start-Sleep -m 500
                                    continue innerMenu
                                }

                                if ($lclSel -ge ($startIdx + 1) -and $lclSel -le ($endIdx + 1))
                                {
                                    [int]$fileNum = $lclSel - 1
                                    $selectedfile = $files[$fileNum]
                                    break innerMenu
                                    break
                                }
                                else 
                                {
                                    Write-Host -ForegroundColor Yellow "The acceptable values are $startIdx thru $endIdx$(if ($nextAllowed) {"N (Next), "})$(if ($prevAllowed) {"P (Previous), "}) and X (eXit)."
                                    Start-Sleep -m 500
                                    continue innerMenu
                                    break
                                }
                            }

                            'p' 
                            {  
                                if ($prevAllowed)
                                {
                                    # take start index, subtract numVizBackups, subtract one more
                                    $startIdx = $startIdx - $numVizBackups - 1

                                    if ($startIdx -le 0)
                                    {
                                        # back at the first screen
                                        $firstScreen = $true

                                        # make sure startidx is not negative
                                        if ($startIdx -lt 0)
                                        {
                                            # calculations are based on startIdx initialized to 0
                                            $startIdx = 0
                                        }

                                    }
                                }
                                break 
                            }

                            'n' 
                            { 
                                if ($nextAllowed)
                                {
                                    # set the new start index to the endIdx plus 1
                                    $startIdx = $endIdx + 1

                                    # regardless of where we are, we aren't on the first screen if Next was used
                                    $firstScreen = $false

                                    # restart the loop with the new index position
                                    continue innerMenu
                                    break
                                }
                                break 
                            }
                            
                            'x' { break innerMenu; break }
                            default { $lclQuit = $false; break }
                        }


                    } until ($false)
                }
                
                Write-Host "File selected: $($selectedfile.FullName)"
                
                # add the file to the list
                try 
                {
                    $tmpRO = New-RestoreObject $selectedfile -EA Stop
                    $script:restoreFileSelection.Add($tmpRO)
                }
                catch 
                {
                    return (Write-Error "Failed to create restore object: $_" -EA Stop)
                }
                finally
                {
                    Remove-Variable tmpRO -EA SilentlyContinue
                }

                break

            }

            "s"
            {
                if ($script:disableS)
                {
                    continue outerLoop
                    break
                }

                # switch between file paths

                $c = 0
                
                Write-Host -ForegroundColor Green "`nMenu options`n"
                Write-Host "[A] - Use the automatic backup path ($ENV:LOCALAPPDATA\SMBSecurity)."
                Write-Host "[X] - Exit without changing the path."
                Write-Host "Enter a custom path to SMBSecurity generated backup files."
                
                do
                {
                    $select = Read-Host "Selection"

                    switch ($select)
                    {
                        'a'
                        {
                            $script:BackupPath = "$ENV:LOCALAPPDATA\SMBSecurity"
                            
                            continue outerLoop
                            break
                        }

                        'x'
                        {
                            continue outerLoop
                            break
                        }

                        default
                        {
                            if ((Test-Path "$select"))
                            {
                                try 
                                {
                                    $pathTest = Get-Item "$select" -EA Stop
                                }
                                catch 
                                {
                                    Write-Error "Failed to parse the path ($select): $_"

                                    continue outerLoop
                                    break
                                }
                                
                                $script:BackupPath = $pathTest.FullName

                                
                                continue outerLoop
                                break
                            }
                        }
                    }
                     
                    $c++
                } until ($c -ge 4)

                Write-Warning "No valid option or path was selected. Defaulting to the automatic backup path."

                $script:BackupPath = "$ENV:LOCALAPPDATA\SMBSecurity"

                break
            }

            "m"
            {
                if ($script:disableM)
                {
                    continue outerLoop
                    break
                }

                #region FILE SELECT
                New-LineSeperator
                # it shouldn't be possible to get this far with restoreFileSelection.Count -le 0
                # if there's a single file selected, select that
                if ($script:restoreFileSelection.Count -eq 1)
                {
                    if ($script:restoreFileSelection -is [array] -or $script:restoreFileSelection -is [ArrayList])
                    {
                        $selectedBackup = $script:restoreFileSelection[0]
                    }
                    else
                    {
                        $selectedBackup = $script:restoreFileSelection
                    }

                    # RemoveAt is used to update the array, so lclSel needs to be updated with (index (0) + 1) 
                    [int]$lclSel = 1
                }
                else
                {
                    Write-Host -ForegroundColor Green "`nSelect a backup:`n"

                    # only a single REG type can be selected, so the if() covers that.
                    # which means this code only happens when more than one XML backup has been selected
                    1..($script:restoreFileSelection.Count) | ForEach-Object { Write-Host "[$_] - $(($script:restoreFileSelection[($_ - 1)].SD).PadRight(23, " ")) - $(($script:restoreFileSelection[($_ - 1)].File.Name).PadRight(61, " ")) ($(Convert-Timestamp2DateTime $script:restoreFileSelection[($_ - 1)].File))" }

                    Write-Host "[X] - Exit"

                    :innerModifyLoop do
                    {
                        Remove-Variable lclSel -EA SilentlyContinue
                        $lclSel = Read-Host "`nSelect: "

                        switch ($lclSel)
                        {
                            'x' { 
                                continue outerLoop
                                break
                            }

                            default
                            {
                                try {
                                    [int]$lclSel = [int]::Parse($lclSel)
                                }
                                catch {
                                    Write-Host -ForegroundColor Yellow "The acceptable values are 1 thru $($script:restoreFileSelection.Count), and X (eXit)."

                                    continue innerModifyLoop
                                    break
                                }

                                $selectedBackup = $script:restoreFileSelection[($_ - 1)]

                                Write-Host "selected: $($selectedBackup.ToString())"
                            }
                        }
                    } until ($selectedBackup)

                }

                #Write-Host "Selected backup: $($selectedBackup.Filename)"

                #endregion FILE SELECT

                #region MODIFY FILE
                New-LineSeperator

                Write-Host -ForegroundColor Green "`n`nSelected backup`n"

                Add-Box ($selectedBackup.ToLongString()) -Box2Screen

                Write-Host -ForegroundColor Green "`n Select an option:`n"
                Write-Host "[R] - Remove [No confirmation]"
                Write-Host "[X] - Exit without modifying"

                $done = $false
                do
                {
                    # don't use lclSel or it will overwrite the index of the backup
                    $newSel = Read-Host "Selection"

                    switch ($newSel)
                    {
                        'r'
                        {
                            try
                            {
                                $script:restoreFileSelection.RemoveAt(($lclSel - 1))
                            }
                            catch
                            {
                                Write-Error "Failed to remove the backup: $_"
                            }

                            $done = $true
                        }

                        'x'
                        {
                            continue outerLoop
                            break
                        }

                        default
                        {
                            Write-Warning "Invalid option."
                        }
                    }

                } until ($done)

                #endregion MODIFY FILE

                break
            }

            "r"
            {
                if ($script:disableR)
                {
                    continue outerLoop
                    break
                }

                # The list of Restore Objects is a Script/Module wide variable, which is $script:restoreFileSelection
                # So... just end the loop and it's done
                $complete = $true
            }

            "q"
            {
                # this exits outerLoop
                $complete = $true
                
                # clear restoreFileSelection by re-initializing it
                Remove-Variable restoreFileSelection -Scope Script -EA SilentlyContinue
                $script:restoreFileSelection = [List[PSCustomObject]]::new()

                break
            }
            "\?"
                {
                    #Clear-Host
                    Write-Host -ForegroundColor Green "`nHow to use the Restore SMB Security Descriptor from back menu:`n"
                    Write-Host @"
    - Enter F to find a backup from automaticaly created files.
      o This menu item will not appear under the following conditions:
        1. A Full Backup from a REG file has been selected.
        2. One of each available SecurityDescriptors has been selected.
        3. No supported backup files were found in the path.

      o No additional menus will appear if when there in only a single viable file.
        The single viable file will be automatically selected.

    - Enter S to switch between using the automatic or a custom backup path.
      o All backup files must have been created by [Save|Backup]-SMBSecurity.
      o Will not appear when a registry backup file has been select.
        Use M to Modify then R to Remove remove the backup first.
        Or use R to restore the backup before restoring something else.

    - Enter M to modify existing selections.
      o Will not appear if there are no backups selected.
      o The only option is to remove a backup from the list.
    
    - Enter R to commit all selected backups.
    o Will not appear if there are no backups selected.

    - Enter Q to quit without restoring any backups.

    - All menu options are case insensitive.
"@
                }
            "u"
            {
                continue outerLoop
                break
            }
            default
            {
                Write-Host -ForegroundColor Yellow "Invalid menu option."
                Start-Sleep -m 500
                continue outerLoop
                break
            }
        }
        
    } until ($complete)

    Remove-Variable restoreFileSelection -EA SilentlyContinue
    return $null
}
