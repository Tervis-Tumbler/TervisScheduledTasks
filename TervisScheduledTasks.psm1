#requires -module TervisApplication

function Install-TervisScheduledTask {
    param (
        [Parameter(ParameterSetName="NoCredentialAndAction")]
        [Parameter(ParameterSetName="NoCredentialAndActionParameter")]
        $User = "$env:USERDOMAIN\$env:USERNAME",
        
        [Parameter(ParameterSetName="NoCredentialAndAction")]
        [Parameter(ParameterSetName="NoCredentialAndActionParameter")]     
        $Password,
        
        [Parameter(ParameterSetName="CredentialAndAction",Mandatory)]
        [Parameter(ParameterSetName="CredentialAndActionParameter",Mandatory)]
        $Credential,
        
        [Parameter(Mandatory)]
        $TaskName,
        
        [Parameter(ParameterSetName="CredentialAndAction",Mandatory)]
        [Parameter(ParameterSetName="NoCredentialAndAction",Mandatory)]
        $Action,
        
        [Parameter(ParameterSetName="CredentialAndActionParameter",Mandatory)]        
        [Parameter(ParameterSetName="NoCredentialAndActionParameter",Mandatory)]
        $Execute,
        
        [Parameter(ParameterSetName="CredentialAndActionParameter")]        
        [Parameter(ParameterSetName="NoCredentialAndActionParameter")]   
        $Argument,
        
        [Parameter(ParameterSetName="CredentialAndActionParameter")]        
        [Parameter(ParameterSetName="NoCredentialAndActionParameter")]     
        $WorkingDirectory,

        [Parameter(Mandatory)]
        [Alias("RepetitionInterval")]
        [ValidateScript({ $_ | Get-RepetitionInterval })]
        $RepetitionIntervalName,

        [Parameter(Mandatory)]$ComputerName
    )
    if ($Credential) {
        $User = $Credential.UserName
        $Password = $Credential.GetNetworkCredential().password
    }
    $ActionObject = if ($Action) {
        $Action
    } else {
        $ActionParameters = @{
            Execute = $Execute
            Argument = $Argument
            WorkingDirectory = $WorkingDirectory
        } | Remove-HashtableKeysWithEmptyOrNullValues
        New-ScheduledTaskAction @ActionParameters
    }    
    $RepetitionInterval = $RepetitionIntervalName | Get-RepetitionInterval    
    $Trigger = $RepetitionInterval.ScheduledTaskTrigger 
    $CimSession = New-CimSession -ComputerName $ComputerName
    $RegisteredScheduledTaskParameters = @{
        TaskName = $TaskName
        TaskPath = "\"
        Action = $ActionObject
        Trigger = $Trigger
        User = $User
        Password = $Password
        Settings = New-ScheduledTaskSettingsSet
        CimSession = $CimSession
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
        User = $User
        Password = $Password
    } | Remove-HashtableKeysWithEmptyOrNullValues
    $Task | Set-ScheduledTask @SetScheduledTaskParameters | Out-Null    
    Remove-CimSession -CimSession $CimSession
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
    where Name -EQ $Name
}

$RepetitionIntervals = [PSCustomObject][Ordered]@{
    Name = "EveryMinuteOfEveryDay"
    ScheduledTaskTrigger = $(New-ScheduledTaskTrigger -Daily -At 12am)
    TaskTriggersRepetitionDuration = "P1D"
    TaskTriggersRepetitionInterval = "PT1M"
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
    $Nodes | Install-InvokeSyncGravatarPhotosToADUsersInAD
    $Nodes | Install-DisableInactiveADComputersScheduledTask
    $Nodes | Install-DisableInactiveADUsersScheduledTask
    $Nodes | Install-RemoveInactiveADComputersScheduledTask
    $Nodes | Install-RemoveInactiveADUsersScheduledTask
    $Nodes | Install-MoveMESUsersToCorrectOUScheduledTask
    $Nodes | Install-SendTervisInactivityNotification
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
            }
    }
}