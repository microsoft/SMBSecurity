# https://docs.microsoft.com/en-us/windows/win32/api/lmserver/nf-lmserver-netserverdiskenum

<#

NET_API_STATUS NET_API_FUNCTION NetServerDiskEnum(
  [in]      LMSTR   servername,
  [in]      DWORD   level,
  [out]     LPBYTE  *bufptr,
  [in]      DWORD   prefmaxlen,
  [out]     LPDWORD entriesread,
  [out]     LPDWORD totalentries,
  [in, out] LPDWORD resume_handle
);

[out] bufptr

A pointer to the buffer that receives the data. The data is an array of three-character strings (a drive letter, a colon, and a terminating null character). 
This buffer is allocated by the system and must be freed using the NetApiBufferFree function. Note that you must free the buffer even if the function fails with ERROR_MORE_DATA.

#>



Add-Type -MemberDefinition @"

[DllImport("netapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
public static extern uint NetApiBufferFree(IntPtr Buffer);

[DllImport("netapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
public static extern int NetServerDiskEnum(
  [MarshalAs(UnmanagedType.LPWStr)] string servername,
  uint level,
  ref IntPtr bufptr,
  uint prefmaxlen,
  ref uint entriesread,
  ref uint totalentries,
  ref uint resume_handle);

"@ -Namespace Win32Api -Name NetApi32

# execute the API call
$computerName = "."

$MAX_PREFERRED_LENGTH = [BitConverter]::ToUInt32([BitConverter]::GetBytes(-1), 0)
$Level = 0 # A value of zero is the only valid level.
$pBuffer = [IntPtr]::Zero
$entriesRead = $totalEntries = $resumeHandle = 0

$apiResult = [Win32Api.NetApi32]::NetServerDiskEnum(
    $computerName,          # servername
    $Level,                 # level
    [Ref] $pBuffer,         # bufptr
    $MAX_PREFERRED_LENGTH,  # prefmaxlen
    [Ref] $entriesRead,     # entriesread
    [Ref] $totalEntries,    # totalentries
    [Ref] $resumeHandle     # resumehandle
)

if ($apiResult -eq 0)
{
    $offset = $pBuffer.ToInt64()
    $numDrives = 0
    $disks = @()

    while ($numDrives -lt $totalEntries)
    {
        $pEntry = New-Object IntPtr($offset)
        # Copy unmanaged buffer to managed variable
        $disk = [Runtime.InteropServices.Marshal]::PtrToStringAuto($pEntry)
        $offset += 3 # each drive letter is 3 [char] long: <letter>, colon (:), /NULL

        if ( -NOT [string]::IsNullOrEmpty($disk) )
        {
            $disks += $disk
            $numDrives++
        }

        Remove-Variable disk
    }
    
    # Free unmanaged buffer
    [Void] [Win32Api.NetApi32]::NetApiBufferFree($pBuffer)
}
else 
{
    #$errorID = (Get-Variable MyInvocation -Scope 1).Value.MyCommand.Name
    $exception = New-Object ComponentModel.Win32Exception $apiResult
    Write-Host "Failed to enumerate file server disks : $exception (0x$("{0:X}" -f $apiResult))"
}


return $disks