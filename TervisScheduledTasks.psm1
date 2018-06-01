#requires -module TervisApplication

function Install-TervisScheduledTask {
    param (
        [Parameter(ParameterSetName="CredentialAndActionObject",Mandatory)]
        [Parameter(ParameterSetName="CredentialAndNewActionParameters",Mandatory)]
        $Credential,
        
        [Parameter(Mandatory)]
        $TaskName,
        
        [Parameter(ParameterSetName="CredentialAndActionObject",Mandatory)]
        $Action,
        
        [Parameter(ParameterSetName="CredentialAndNewActionParameters",Mandatory)]
        $Execute,
        
        [Parameter(ParameterSetName="CredentialAndNewActionParameters")]
        $Argument,
        
        [Parameter(ParameterSetName="CredentialAndNewActionParameters")]
        $WorkingDirectory,

        [Parameter(Mandatory)]
        [Alias("RepetitionInterval")]
        [ValidateScript({ $_ | Get-RepetitionInterval })]
        $RepetitionIntervalName,

        [Parameter(Mandatory)]$ComputerName
    )

    if (-Not $Action) {
        $ActionParameters = $PSBoundParameters | 
            ConvertFrom-PSBoundParameters -Property Execute,Argument,WorkingDirectory -AsHashTable

        $Action = New-ScheduledTaskAction @ActionParameters
    }

    $RepetitionInterval = $RepetitionIntervalName | Get-RepetitionInterval

    $RegisteredScheduledTaskParameters = @{
        TaskName = $TaskName
        TaskPath = "\"
        Action = $Action
        Trigger = $RepetitionInterval.ScheduledTaskTrigger
        User = $Credential.UserName
        Password = $Credential.GetNetworkCredential().password
        Settings = New-ScheduledTaskSettingsSet
        CimSession = New-CimSession -ComputerName $ComputerName
        Force = $true  
    } | Remove-HashtableKeysWithEmptyOrNullValues

    $Task = Register-ScheduledTask @RegisteredScheduledTaskParameters

    if ($RepetitionInterval.TaskTriggersRepetitionDuration) {
        $task.Triggers.Repetition.Duration = $RepetitionInterval.TaskTriggersRepetitionDuration
    }
    if ($RepetitionInterval.TaskTriggersRepetitionInterval) { 
        $task.Triggers.Repetition.Interval = $RepetitionInterval.TaskTriggersRepetitionInterval
    }

    $SetScheduledTaskParameters = @{
        User = $Credential.UserName
        Password = $Credential.GetNetworkCredential().password
    } | Remove-HashtableKeysWithEmptyOrNullValues

    $Task | Set-ScheduledTask @SetScheduledTaskParameters | Out-Null    
    Remove-CimSession -CimSession $RegisteredScheduledTaskParameters.CimSession
}

function Uninstall-TervisScheduledTask {
    param (
        [Parameter(Mandatory)]$TaskName,
        [Parameter(Mandatory)]$ComputerName,
        [Switch]$Force
    )
    $CimSession = New-CimSession -ComputerName $ComputerName
    $Task = Get-ScheduledTask -CimSession $CimSession | where taskname -match $TaskName
    $Task | Unregister-ScheduledTask -Confirm:$(-not $Force)
    Remove-CimSession -CimSession $CimSession
}

function Get-RepetitionInterval {
    param (
        [Parameter(ValueFromPipeline)]$Name
    )
    $RepetitionIntervals | 
    where {-Not $Name -or $_.Name -EQ $Name}
}

$RepetitionIntervals = [PSCustomObject][Ordered]@{
    Name = "EveryMinuteOfEveryDay"
    ScheduledTaskTrigger = $(New-ScheduledTaskTrigger -Daily -At 12am)
    TaskTriggersRepetitionDuration = "P1D"
    TaskTriggersRepetitionInterval = "PT1M"
},
[PSCustomObject][Ordered]@{
    Name = "EveryDayEver5Minutes"
    ScheduledTaskTrigger = $(New-ScheduledTaskTrigger -Daily -At 12am)
    TaskTriggersRepetitionDuration = "P1D"
    TaskTriggersRepetitionInterval = "PT5M"
},
[PSCustomObject][Ordered]@{
    Name = "OnceAWeekMondayMorning"
    ScheduledTaskTrigger = $(New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At 8am)
},
[PSCustomObject][Ordered]@{
    Name = "EveryDayAt3am"
    ScheduledTaskTrigger = $(New-ScheduledTaskTrigger -Daily -At 3am)
},
[PSCustomObject][Ordered]@{
    Name = "EveryDayAt6am"
    ScheduledTaskTrigger = $(New-ScheduledTaskTrigger -Daily -At 6am)
},
[PSCustomObject][Ordered]@{
    Name = "OnceAWeekTuesdayMorning"
    ScheduledTaskTrigger = $(New-ScheduledTaskTrigger -Weekly -DaysOfWeek Tuesday -At 8am)
},
[PSCustomObject][Ordered]@{
    Name = "EverWorkdayDuringTheDayEvery15Minutes"
    ScheduledTaskTrigger = $(New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday,Tuesday,Wednesday,Thursday,Friday -At 7am)
    TaskTriggersRepetitionDuration = "PT12H"
    TaskTriggersRepetitionInterval = "PT15M"
},
[PSCustomObject][Ordered]@{
    Name = "EverWorkdayOnceAtTheStartOfTheDay"
    ScheduledTaskTrigger = $(New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday,Tuesday,Wednesday,Thursday,Friday -At 7am)
},
[PSCustomObject][Ordered]@{
    Name = "EveryDayEvery15Minutes"
    ScheduledTaskTrigger = $(New-ScheduledTaskTrigger -Daily -At 12am)
    TaskTriggersRepetitionDuration = "P1D"
    TaskTriggersRepetitionInterval = "PT15M"
},
[PSCustomObject][Ordered]@{
    Name = "EveryDayAt2am"
    ScheduledTaskTrigger = $(New-ScheduledTaskTrigger -Daily -At 2am)
},
[PSCustomObject][Ordered]@{
    Name = "EveryDayAt5amEvery3HoursFor18Hours"
    ScheduledTaskTrigger = $(New-ScheduledTaskTrigger -Daily -At 5am)
    TaskTriggersRepetitionDuration = "PT18H"
    TaskTriggersRepetitionInterval = "PT3H"
},
[PSCustomObject][Ordered]@{
    Name = "EveryDayAt7am3pm11pm"
    ScheduledTaskTrigger = $(New-ScheduledTaskTrigger -Daily -At 7am),
    $(New-ScheduledTaskTrigger -Daily -At 3pm),
    $(New-ScheduledTaskTrigger -Daily -At 11pm)
},
[PSCustomObject][Ordered]@{
    Name = "Every12HoursEveryDay"
    ScheduledTaskTrigger = $(New-ScheduledTaskTrigger -Daily -At 12am)
    TaskTriggersRepetitionDuration = "P1D"
    TaskTriggersRepetitionInterval = "PT12H"
}

function Invoke-ScheduledTasksProvision {
    param (
        $EnvironmentName
    )
    Invoke-ApplicationProvision -ApplicationName ScheduledTasks -EnvironmentName $EnvironmentName
    $Nodes = Get-TervisApplicationNode -ApplicationName ScheduledTasks -EnvironmentName $EnvironmentName
    $Nodes | Push-TervisPowershellModulesToRemoteComputer
    $Nodes | Install-TervisPowershellModulesForScheduledTasks
    $Nodes | Install-StoresRDSRemoteDesktopPrivilegeScheduledTasks
    $Nodes | Install-ExplorerFavoritesScheduledTasks
    $Nodes | Install-RMSHQLogFileUtilizationScheduledTasks
    $Nodes | Install-MoveSharedMailboxObjectsScheduledTasks
    $Nodes | Install-TervisActiveDirectoryCleanup
    $Nodes | Install-InvokeEBSWebADIServer2016CompatibilityHackScheduledTask
    $Nodes | Install-TervisSOAMonitoringApplication
} 

function Install-TervisPowershellModulesForScheduledTasks {
    param (
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]$ComputerName
    )
    Begin {
        $APIKey = Get-PasswordStateAPIKey
        $ScheduledTaskCredential = Get-PasswordstateCredential -PasswordID 259
        $ScheduledTaskUserName = (($ScheduledTaskCredential).UserName.Split("@"))[0]
        if (-NOT ((Get-ADGroupMember Privilege_InfrastructureScheduledTasksAdministrator -ErrorAction SilentlyContinue) -contains $ScheduledTaskUserName)) {
            Add-ADGroupMember -Identity Privilege_InfrastructureScheduledTasksAdministrator -Members $ScheduledTaskUserName
        }
        $PathToPaylocityDataExport = Get-PathToPaylocityDataExport
        $PaylocityDepartmentsWithNiceNamesJsonPath = Get-PaylocityDepartmentsWithNiceNamesJsonPath
    }
    Process {
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {Enable-WSManCredSSP -Role Server}
        Enable-WSManCredSSP -Role Client -DelegateComputer $ComputerName
        Invoke-Command `
            -Authentication Credssp `
            -ComputerName $ComputerName `
            -Credential $ScheduledTaskCredential `
            -ScriptBlock {
                Set-PasswordStateAPIKey -PasswordStateAPIKey $Using:APIKey
                Install-TervisPaylocity -PathToPaylocityDataExport $Using:PathToPaylocityDataExport -PaylocityDepartmentsWithNiceNamesJsonPath $Using:PaylocityDepartmentsWithNiceNamesJsonPath
                Install-TervisMSOnline -ExchangeOnlineCredential $Using:ScheduledTaskCredential
                Install-TervisTechnicalServices
                Install-TervisAzure
            }
    }
}