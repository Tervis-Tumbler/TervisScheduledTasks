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
    Name = "OnceAWeekFridayMorning"
    ScheduledTaskTrigger = $(New-ScheduledTaskTrigger -Weekly -DaysOfWeek Friday -At 9am)
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
    Name = "EverWorkdayAt1PM"
    ScheduledTaskTrigger = $(New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday,Tuesday,Wednesday,Thursday,Friday -At 1pm)
},
[PSCustomObject][Ordered]@{
    Name = "EverWorkdayAt2PM"
    ScheduledTaskTrigger = $(New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday,Tuesday,Wednesday,Thursday,Friday -At 2pm)
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
},
[PSCustomObject][Ordered]@{
    Name = "EveryDayAt730am"
    ScheduledTaskTrigger = $(New-ScheduledTaskTrigger -Daily -At "7:30AM")
},
[PSCustomObject][Ordered]@{
    Name = "EveryDayAt330pm"
    ScheduledTaskTrigger = $(New-ScheduledTaskTrigger -Daily -At "3:30PM")
}
