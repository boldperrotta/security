#$Trigger= New-ScheduledTaskTrigger -Daily -At 1am
#$User= "NT AUTHORITY\SYSTEM"
#$Action= New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "C:\Git\it\HaveIBeenPwned.ps1"
#Register-ScheduledTask "Data Breach Check" -Trigger $Trigger -User $User -Action $Action -RunLevel "Highest" -Force


#Requires -modules HaveIBeenPwned

$APIKey = <#Insert API Key Here#>

#Get GMail email list, convert csv
Get-GSUser -Filter * | Select-Object User | Export-CSV c:\temp\emaillist.csv -NoTypeInformation
(Get-Content C:\temp\emaillist.csv) | % {$_ -replace '"',""} | Out-File -FilePath C:\temp\emaillist.csv -Force -Encoding ascii

#Run breach check against all emails and output to CSV, ignoring null value responses
$emails = Import-Csv C:\temp\emaillist.csv
foreach ($email in $emails) {
    $email = $email.User
    $results = Get-PwnedAccount -EmailAddress $email -apiKey $APIKey 
        foreach ($result in $results) { 
            $breach = $result.title
            if ($Null -ne $breach) {
                $result | Add-Member -MemberType NoteProperty -Name Email -value $email
                $result |  Export-CSV -LiteralPath C:\temp\BreachList.csv -Append -NoTypeInformation
            }
    }
    Start-Sleep -Milliseconds 1700
}

#Sort Data by data breach occured
Import-CSV C:\temp\BreachList.csv | Sort-Object -Property AddedDate -Descending | Export-Csv -Path c:\temp\BreachListSorted.csv -NoTypeInformation

#Grab first row of previous run and current run
$BreachDate = Import-CSV "C:\Temp\BreachListOrig.csv" | Select-Object -first 1
$LastRun = Import-CSV "C:\Temp\BreachListSorted.csv" | Select-Object -first 1

#Compare results of previous run to current run, if new breach is found, send email
If ($LastRun.AddedDate -gt $BreachDate.AddedDate) {
    $From = #From Email
    $To = #To Email
    $Subject = "Email Found in Database Compromise"
    $SMTPServer = #SMTP Server Address
    $SMTPPort = #SMTP Port
    $SMTPUsername = #SMTP Authentication Username
    $GetPassword = Get-Content "C:\temp\password.txt" #SMTP Server Password
    $SMTPPassword = $GetPassword | ConvertTo-SecureString  -AsPlainText -Force
    $SMTPCredentials = new-object Management.Automation.PSCredential $SMTPUsername, $SMTPPassword
    $Body = "Attached is a report of emails associated with potential data breaches"
    $Attachment = "C:\Temp\BreachListSorted.csv"

    Send-MailMessage  -From $From -to $To -Subject $Subject -Body $Body -SmtpServer $SMTPServer -port $SMTPPort -UseSsl -Attachments $Attachment -Credential $SMTPCredentials -DeliveryNotificationOption OnSuccess
    
    Remove-Item "C:\Temp\BreachListOrig.csv"
    Copy-Item -Path "C:\Temp\BreachListSorted.csv" -Destination "C:\Temp\BreachListOrig.csv"
}

Remove-Item "C:\temp\BreachList.csv"
Remove-Item "C:\temp\emaillist.csv"
Remove-Item "c:\temp\BreachListSorted.csv"
