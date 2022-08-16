function Add-RegKeyMember {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ParameterSetName="ByKey", Position=0, ValueFromPipeline)]
        # Registry key object returned from Get-ChildItem or Get-Item
        [Microsoft.Win32.RegistryKey] $RegistryKey,

        [Parameter(Mandatory, ParameterSetName="ByPath", Position=0)]
        # Path to a registry key
        [string] $Path

    )

    begin {
         # Define the namespace (string array creates nested namespace):

        $Namespace = "HeyScriptingGuy"

        # Make sure type is loaded (this will only get loaded on first run):

        Add-Type @"
            using System;
            using System.Text;
            using System.Runtime.InteropServices;
    
            $($Namespace | ForEach-Object {

                "namespace $_ {"

            })

                public class advapi32 {
                    [DllImport("advapi32.dll", CharSet = CharSet.Auto)]
                    public static extern Int32 RegQueryInfoKey(
                        Microsoft.Win32.SafeHandles.SafeRegistryHandle hKey,
                        StringBuilder lpClass,
                        [In, Out] ref UInt32 lpcbClass,
                        UInt32 lpReserved,
                        out UInt32 lpcSubKeys,
                        out UInt32 lpcbMaxSubKeyLen,
                        out UInt32 lpcbMaxClassLen,
                        out UInt32 lpcValues,
                        out UInt32 lpcbMaxValueNameLen,
                        out UInt32 lpcbMaxValueLen,
                        out UInt32 lpcbSecurityDescriptor,
                        out System.Runtime.InteropServices.ComTypes.FILETIME lpftLastWriteTime
                    );
                }
            $($Namespace | ForEach-Object { "}" })
"@

        # Get a shortcut to the type:   
        $RegTools = ("{0}.advapi32" -f ($Namespace -join ".")) -as [type]
    }



    process {
        switch ($PSCmdlet.ParameterSetName) {
            "ByKey" {
    
                # Already have the key, no more work to be done 🙂
    
            }
    
            "ByPath" {
                # We need a RegistryKey object (Get-Item should return that)
                $Item = Get-Item -Path $Path -ErrorAction Stop
     
                # Make sure this is of type [Microsoft.Win32.RegistryKey]
                if ($Item -isnot [Microsoft.Win32.RegistryKey]) {
                    throw "'$Path' is not a path to a registry key!"
                }
                $RegistryKey = $Item
            }
        }

        # Initialize variables that will be populated:
        $ClassLength = 255 # Buffer size (class name is rarely used, and when it is, I've never seen
        
        # it more than 8 characters. Buffer can be increased here, though.
        $ClassName = New-Object System.Text.StringBuilder $ClassLength  # Will hold the class name
        $LastWriteTime = New-Object System.Runtime.InteropServices.ComTypes.FILETIME 

        switch ($RegTools::RegQueryInfoKey($RegistryKey.Handle,
                                    $ClassName,
                                    [ref] $ClassLength,
                                    $null,  # Reserved
                                    [ref] $null, # SubKeyCount
                                    [ref] $null, # MaxSubKeyNameLength
                                    [ref] $null, # MaxClassLength
                                    [ref] $null, # ValueCount
                                    [ref] $null, # MaxValueNameLength
                                    [ref] $null, # MaxValueValueLength
                                    [ref] $null, # SecurityDescriptorSize
                                    [ref] $LastWriteTime
                                    )) {

            0 { # Success
                # Convert to DateTime object:
                $UnsignedLow = [System.BitConverter]::ToUInt32([System.BitConverter]::GetBytes($LastWriteTime.dwLowDateTime), 0)
                $UnsignedHigh = [System.BitConverter]::ToUInt32([System.BitConverter]::GetBytes($LastWriteTime.dwHighDateTime), 0)

                # Shift high part so it is most significant 32 bits, then copy low part into 64-bit int:
                $FileTimeInt64 = ([Int64] $UnsignedHigh -shl 32) -bor $UnsignedLow

                # Create datetime object
                $LastWriteTime = [datetime]::FromFileTime($FileTimeInt64)

                # Add properties to object and output them to pipeline
                $RegistryKey | Add-Member -NotePropertyMembers @{
                    LastWriteTime = $LastWriteTime
                    ClassName = $ClassName.ToString()
                } -PassThru -Force
            }

            122  { # ERROR_INSUFFICIENT_BUFFER (0x7a)
                throw "Class name buffer too small"
                # function could be recalled with a larger buffer, but for
                # now, just exit
            }

            default {
                throw "Unknown error encountered (error code $_)"
            }
        }
    }

}