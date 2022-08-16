

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















<#
[Flags()]
enum DefaultSecurity 
{
    AnonymousDescriptorsUpgraded         = 1    
    InteractiveDescriptorsRegenerated    = 2    
    PreviousAnonymousRestriction         = 4    
    SessionSecurityDescriptorRegenerated = 8    
    SrvsvcConfigInfo                     = 16 
    SrvsvcConnection                     = 32   
    SrvsvcFile                           = 64   
    SrvsvcServerDiskEnum                 = 128  
    SrvsvcSessionInfo                    = 256  
    SrvsvcShareAdminConnect              = 512  
    SrvsvcShareAdminInfo                 = 1024 
    SrvsvcShareChange                    = 2048 
    SrvsvcShareConnect                   = 4096 
    SrvsvcShareFileInfo                  = 8192 
    SrvsvcSharePrintInfo                 = 16384
    SrvsvcStatisticsInfo                 = 32768
    SrvsvcTransportEnum                  = 65536
}
#>