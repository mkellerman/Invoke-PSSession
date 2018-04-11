function Invoke-PSSession {

<#
    .SYNOPSIS
    By Marc R Kellerman (mkellerman@outlook.com)

    Create a New-PSSession and Regsiter-PSSessionConfiguration to eliminate the double hop issue. 

    Adaptation from code found:
    https://blogs.msdn.microsoft.com/sergey_babkins_blog/2015/03/18/another-solution-to-multi-hop-powershell-remoting/

    .PARAMETER ComputerName
    Array of ComputerName to create a session to.
           
    .PARAMETER Credential 
    Credential for PSSession. Same credentials are used for the RunAsCredentail within the session.

    .PARAMETER SkipCACheck 
    Advanced options for a PSSession

    .PARAMETER SkipCNCheck 
    Advanced options for a PSSession

    .PARAMETER SkipRevocationCheck 
    Advanced options for a PSSession

    .PARAMETER SkipRevocationCheck 
    If PSSession is already estabilished, remove it and recreate it.

#>

    [CmdletBinding()]
    Param(
        [parameter(Mandatory)][string[]]$ComputerName, 
        [parameter(Mandatory)][pscredential]$Credential,
        [switch]$SkipCACheck,
        [switch]$SkipCNCheck,
        [switch]$SkipRevocationCheck,
        [switch]$Unique
    )

    Begin   { Write-Verbose "$(Get-Date) - $($MyInvocation.MyCommand): Begin" }

    Process {

    If ($Unique) { Get-PSSession -EA 0 | Where { $ComputerName -contains $_.ComputerName } | Remove-PSSession -Confirm:$False }

    $PSSessionOption = New-PSSessionOption -SkipCACheck:$SkipCACheck.IsPresent -SkipCNCheck:$SkipCNCheck.IsPresent -SkipRevocationCheck:$SkipRevocationCheck.IsPresent

    $ConfigurationName = $Credential.GetNetworkCredential().Username

    Write-Verbose "$(Get-Date) [Invoke-Command] Start"
    [object[]]$PSSessionConfiguration = Invoke-Command -ComputerName $ComputerName -Credential $Credential -SessionOption $PSSessionOption -EA 0 -Verbose -ScriptBlock { 

        [CmdletBinding()]Param()
        Write-Verbose "[${Env:ComputerName}] Get-PSSessionConfiguration"
        $PSSessionConfiguration = Get-PSSessionConfiguration -Name $Using:ConfigurationName -EA 0 
        if ($PSSessionConfiguration) { Return $PSSessionConfiguration }
        Write-Verbose "[${Env:ComputerName}] Register-PSSessionConfiguration"
        $PSSessionConfiguration = Register-PSSessionConfiguration -Name $Using:ConfigurationName -RunAsCredential $Using:Credential -MaximumReceivedDataSizePerCommandMB 1000 -MaximumReceivedObjectSizeMB 1000 -Force:$True -WA 0
        if ($PSSessionConfiguration) { Return $PSSessionConfiguration }

    }
    Write-Verbose "$(Get-Date) [Invoke-Command] End"

    if ($PSSessionConfiguration) { 
        Write-Verbose "$(Get-Date) [New-PSSession] Start"
        New-PSSession -ComputerName ($ComputerName | Where { $PSSessionConfiguration.PSComputerName -Contains $_ }) -Credential $Credential -SessionOption $PSSessionOption -ConfigurationName $ConfigurationName -EA 1 
        Write-Verbose "$(Get-Date) [New-PSSession] End"
    }
   
    }

    End     { Write-Verbose "$(Get-Date) - $($MyInvocation.MyCommand): End" }

}
