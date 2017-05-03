function Install-TervisScheduledTask {
    param (
        [Parameter(ParameterSetName="NoCredentialAndScheduledTaskActionObject")]
        [Parameter(ParameterSetName="NoCredentialAndScheduledTaskActionFile")]
        $ScheduledTaskUsername = "$env:USERDOMAIN\$env:USERNAME",
        
        [Parameter(ParameterSetName="NoCredentialAndScheduledTaskActionObject",Mandatory)]
        [Parameter(ParameterSetName="NoCredentialAndScheduledTaskActionFile",Mandatory)]     
        $ScheduledTaskUserPassword,
        
        [Parameter(ParameterSetName="CredentialAndScheduledTaskActionObject",Mandatory)]
        [Parameter(ParameterSetName="CredentialAndScheduledTaskActionFile",Mandatory)]
        $Credential,
        
        [Parameter(Mandatory)]
        $ScheduledTaskName,
        
        [Parameter(ParameterSetName="CredentialAndScheduledTaskActionObject",Mandatory)]
        [Parameter(ParameterSetName="NoCredentialAndScheduledTaskActionObject",Mandatory)]
        [Alias("ScheduledTaskAction")]
        $ScheduledTaskActionObject,
        
        [Parameter(ParameterSetName="CredentialAndScheduledTaskActionFile",Mandatory)]        
        [Parameter(ParameterSetName="NoCredentialAndScheduledTaskActionFile",Mandatory)]
        $ScheduledTaskActionExecuteFilePath,
        
        [Parameter(ParameterSetName="CredentialAndScheduledTaskActionFile")]        
        [Parameter(ParameterSetName="NoCredentialAndScheduledTaskActionFile")]   
        $ScheduledTaskActionArgument,
        
        [Parameter(ParameterSetName="CredentialAndScheduledTaskActionFile")]        
        [Parameter(ParameterSetName="NoCredentialAndScheduledTaskActionFile")]     
        $ScheduledTaskActionWorkingDirectory,

        [Parameter(Mandatory)]
        [Alias("RepetitionInterval")]
        [ValidateScript({ $_ | Get-RepetitionInterval })]
        $RepetitionIntervalName,

        [Parameter(Mandatory)]$ComputerName
    )
    if ($Credential) {
        $ScheduledTaskUsername = $Credential.UserName
        $ScheduledTaskUserPassword = $Credential.GetNetworkCredential().password
    }
    if ($ScheduledTaskActionObject) {
        $ScheduledTaskAction = $ScheduledTaskActionObject
    } elseif ($ScheduledTaskActionExecuteFilePath) {
        $ScheduledTaskAction = New-ScheduledTaskAction -Execute $ScheduledTaskActionExecuteFilePath `
            -Argument $ScheduledTaskActionArgument `
            -WorkingDirectory $ScheduledTaskActionWorkingDirectory
    }    
    $RepetitionInterval = $RepetitionIntervalName | Get-RepetitionInterval    
    $ScheduledTaskTrigger = $RepetitionInterval.ScheduledTaskTrigger
    $ScheduledTaskSettingsSet = New-ScheduledTaskSettingsSet
    $CimSession = New-CimSession -ComputerName $ComputerName
    $Task = Register-ScheduledTask -TaskName $ScheduledTaskName `
                    -TaskPath "\" `
                    -Action $ScheduledTaskAction `
                    -Trigger $ScheduledTaskTrigger `
                    -User $ScheduledTaskUsername `
                    -Password $ScheduledTaskUserPassword `
                    -Settings $ScheduledTaskSettingsSet `
                    -CimSession $CimSession `
                    -Force
    if ($RepetitionInterval.TaskTriggersRepetitionDuration) {
        $task.Triggers.Repetition.Duration = $RepetitionInterval.TaskTriggersRepetitionDuration
    }
    if ($RepetitionInterval.TaskTriggersRepetitionInterval) { 
        $task.Triggers.Repetition.Interval = $RepetitionInterval.TaskTriggersRepetitionInterval
    }
    $Task.Triggers[0].ExecutionTimeLimit = "PT30M"
    $task | Set-ScheduledTask -Password $ScheduledTaskUserPassword -User $ScheduledTaskUsername | Out-Null    
    Remove-CimSession -CimSession $CimSession
}

function Uninstall-TervisScheduledTask {
    param (
        [Parameter(Mandatory)]$ScheduledTaskName,
        [Parameter(Mandatory)]$ComputerName
    )
    $CimSession = New-CimSession -ComputerName $ComputerName
    $Task = Get-ScheduledTask -CimSession $CimSession | where taskname -match $ScheduledTaskName
    $Task | Unregister-ScheduledTask
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
