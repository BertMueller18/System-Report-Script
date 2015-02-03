# system_report - (C) 2015 Patrick Lambert - http://dendory.net
#
# This should be run on the Task Scheduler every hour as a local administrator. 
# Comment out any section you don't want. The only resource intensive one seems to be Windows Updates.
# The AntiVirus/AntiMalware section only work on workstations, they will return empty strings on Windows Server.
# Look near the bottom of the script to configure alarm report emails / notifications.
#
# The report will be saved in this file:
$HTML = "c:\system_report.html"

"<html>
<head>
<link rel=stylesheet href=https://maxcdn.bootstrapcdn.com/bootstrap/3.3.2/css/bootstrap.min.css>
<title>$env:COMPUTERNAME</title>
<style>
html, body
{
font-family: tahoma, arial;
font-size: 14px;
margin: 5px;
padding: 0px;
color: #2E1E2E;
}
table
{
border-collapse: collapse;
    width: 100%;
}
th
{
border: 1px solid #8899AA;
padding: 3px 7px 2px 7px;
font-size: 1.1em;
text-align: left;
padding-top: 5px;
padding-bottom: 4px;
background-color: #AABBCC;
color: #ffffff;
}
td
{
border: 1px solid #8899AA;
padding: 3px 7px 2px 7px;
    overflow: hidden;
}
h2
{
    text-align: center;
font-size: 22px;
    text-shadow: 1px 1px 1px rgba(150, 150, 150, 0.5);
}
h1
{
    margin-top: 20px;
    text-align: center;
font-size: 25px;
    text-shadow: 1px 1px 1px rgba(150, 150, 150, 0.5);
}
pre {
    white-space: pre-wrap;
    white-space: -moz-pre-wrap;
    white-space: -pre-wrap;
    white-space: -o-pre-wrap;
    word-wrap: break-word;
}
#sysinfo
{
    width: 49% !important;
    float: left;
    margin-bottom: 0px;
}
#action
{
    width: 49% !important;
    float: right;
}
#menu 
{
    position: fixed;
    right: 0;
    left: 0;
    top: 0;
    width: 100%;
    height: 25px;
    background: #AABBCC;
    color: #FFFFFF;
    text-align: center;
    overflow: hidden;
}
#menu a
{
    color: #FFFFFF;
    font-weight: bold;
}
@media screen and (max-width: 1010px)
{
    #sysinfo
    {
        float: none;
        margin-bottom: 20px;
        width: 100% !important;
    }
    #action
    {
        width: 100% !important;
        float: none;
    }
}
</style>
</head>
<body>
<div id='menu'>
<a href=#sysinfo>System</a> | <a href=#disks>Disks</a> | <a href=#processes>Processes</a> | <a href=#services>Services</a> | <a href=#network>Network</a>
</div>
<a name='sysinfo'></a><h1>$env:COMPUTERNAME System Report</h1>
" > $HTML

Write-Output "Fetching data:"
Write-Output "* Processor"
$processor = Get-WmiObject win32_processor
Write-Output "* System"
$sysinfo = Get-WmiObject win32_computersystem
Write-Output "* BIOS"
$bios = Get-WmiObject -Class win32_bios
Write-Output "* Operating System"
$os = Get-WmiObject win32_operatingsystem
Write-Output "* Users"
$users = Get-WmiObject win32_systemusers

"<table id='sysinfo'><tr><th colspan=2>System Information</th></tr>" >> $HTML
"<tr><td>Computer Name</td><td>" + $sysinfo.Name + "</td></tr>" >> $HTML
"<tr><td>Computer Type</td><td>" + $sysinfo.SystemType + "</td></tr>" >> $HTML
"<tr><td>Computer Manufacturer</td><td>" + $sysinfo.Manufacturer + "</td></tr>" >> $HTML
"<tr><td>Computer Model</td><td>" + $sysinfo.Model + "</td></tr>" >> $HTML
"<tr><td>CPU Information</td><td>" + $processor.Name + "</td></tr>" >> $HTML
"<tr><td>Installed RAM</td><td>" + [math]::Round($sysinfo.TotalPhysicalMemory / 1000000000) + " GB</td></tr>" >> $HTML
"<tr><td>BIOS Manufacturer</td><td>" + $bios.Manufacturer + "</td></tr>" >> $HTML
"<tr><td>BIOS Name</td><td>" + $bios.Name + "</td></tr>" >> $HTML
"<tr><td>BIOS Serial</td><td>" + $bios.SerialNumber + "</td></tr>" >> $HTML
"<tr><td>Hostname</td><td>" + $sysinfo.DNSHostName + "</td></tr>" >> $HTML
"<tr><td>Domain</td><td>" + $sysinfo.Domain + "</td></tr>" >> $HTML
"<tr><td>Operating System</td><td>" + $os.Caption + " (" + $os.OSArchitecture + ")</td></tr>" >> $HTML
"<tr><td>Local Users</td><td>" >> $HTML
ForEach ($u in $users) { $u.PartComponent -match ".*Name=(?<username>.*),.*Domain=(?<domain>.*).*" | Out-Null; $matches.username >> $HTML; " " >> $HTML }
"</td></tr>" >> $HTML
"</table>" >> $HTML

Write-Output "* Action Center"
$as = Get-WmiObject -Namespace "root\SecurityCenter2" -Class AntiSpywareProduct
$av = Get-WmiObject -Namespace "root\SecurityCenter2" -Class AntiVirusProduct
$fw_std = Get-ItemProperty "HKLM:System\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\StandardProfile" | select -ExpandProperty EnableFirewall
$fw_dmn = Get-ItemProperty "HKLM:System\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\DomainProfile" | select -ExpandProperty EnableFirewall
$fw_pub = Get-ItemProperty "HKLM:System\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\PublicProfile" | select -ExpandProperty EnableFirewall
Write-Output "* Windows Update"
$lastupd = Get-HotFix | Sort InstalledOn | Select -Last 1 | Select -ExpandProperty InstalledOn
$wu_a = [activator]::CreateInstance([type]::GetTypeFromProgID("Microsoft.Update.Session"))
$wu_search = $wu_a.CreateUpdateSearcher()
$wu = $wu_search.Search("IsInstalled=0")
Write-Output "* System Load"
$cpuload = Get-Counter -Counter "\Processor(*)\% Processor Time" | Select -ExpandProperty CounterSamples | Select -ExpandProperty CookedValue | Measure-Object -Average | Select -ExpandProperty Average
$freemem = Get-Counter -Counter "\Memory\Available MBytes" | Select -ExpandProperty CounterSamples | Select -ExpandProperty CookedValue
$freemem = $freemem / 1000

"<table id='action'><tr><th colspan=2>Action Center</th></tr>" >> $HTML
"<tr><td>Anti-Virus Software</td><td>" + $av.displayName + " " + $av.VersionNumber + " (" + $av.timestamp + ")</td></tr>" >> $HTML
"<tr><td>Anti-Spyware Software</td><td>" + $as.displayName + " " + $as.VersionNumber + " (" + $as.timestamp + ")</td></tr>" >> $HTML
"<tr><td>Firewall Status</td><td>Domain: " + (&{If($fw_dmn -eq 1) {"On"} Else {"<font color=red>Off</font>"}}) + ", Private: " + (&{If($fw_std -eq 1) {"On"} Else {"<font color=red>Off</font>"}}) + ", Public: " + (&{If($fw_pub -eq 1) {"On"} Else {"<font color=red>Off</font>"}}) + "</td></tr>" >> $HTML
"<tr><td>Processor Load</td><td>" + (&{If($cpuload -lt 80) {[math]::Round($cpuload,2)} Else {"<font color=red>"+[math]::Round($cpuload,2)+"</font>"}}) + "%</td></tr>" >> $HTML
"<tr><td>Last Boot</td><td>" + $os.ConvertToDateTime($os.LastBootUpTime) + " (" + (&{If($sysinfo.BootupState -eq "Normal boot") {$sysinfo.BootupState} Else {"<font color=red>"+$sysinfo.BootupState+"</font>"}}) + ")</td></tr>" >> $HTML
"<tr><td>Free Memory</td><td>" + (&{If($freemem -gt 0.4) {"$freemem GB"} Else {"<font color=red>$freemem GB</font>"}}) + "</td></tr>" >> $HTML
"<tr><td>Last Windows Update</td><td>" + $lastupd + "</td></tr>" >> $HTML
"<tr><td>Available Critical Updates</td><td>" >> $HTML
For ($i=0; $i -lt $wu.Updates.Count; $i++)
{
    if($wu.Updates.Item($i).MsrcSeverity -eq "Critical") 
    { 
        "<font color=red>" >> $HTML
        $wu.Updates.Item($i) | Select -ExpandProperty Title >> $HTML
        "</font><br>" >> $HTML 
    }
}
"</td></tr>" >> $HTML
Write-Host "* Event log"
$events = Get-EventLog Security -EntryType FailureAudit -After (Get-Date).AddHours(-1)
if($events)
{
    ForEach($event in $events) 
    {
        $id = $event.InstanceID
        $msg = $event.Message
      	$tim = $event.TimeGenerated
        "<tr><td>Event Audit Failure ($id)</td><td><font color=red><pre>$msg</pre>Time Generated: $tim</font></td></tr>" >> $HTML
    }
}
"</table><div style='clear:both'></div>" >> $HTML

"<a name='disks'></a><h2>Disk Space</h2>" >> $HTML
Write-Output "* Disks"
$disks = Get-WmiObject -Class win32_logicaldisk

"<table><tr><th>Drive</th><th>Type</th><th>Size</th><th>Free Space</th></tr>" >> $HTML
ForEach($d in $disks)
{
    $drive = $d.Name
    $type = $d.Description
    $size = [math]::Round($d.Size / 1000000000,1)
    $freespace = [math]::Round($d.FreeSpace / 1000000000,1)
    If($freespace -le 1 -And $freespace -ne 0) { "<tr><td>$drive</td><td>$type</td><td>$size GB</td><td><font color=red>$freespace GB</font></td></tr>" >> $HTML }
    Else { "<tr><td>$drive</td><td>$type</td><td>$size GB</td><td>$freespace GB</td></tr>" >> $HTML }
}
"</table>" >> $HTML

"<a name='processes'></a><h2>Running Processes</h2>" >> $HTML
Write-Output "* Processes"
Get-WmiObject -Class win32_process | Sort -Property WorkingSetSize -Descending | Select @{Name='ID';Expression={$_.ProcessId}},@{Name='Name';Expression={$_.ProcessName}},@{Name='Path';Expression={$_.CommandLine}},@{Name='Memory Usage (MB)';Expression={[math]::Round($_.WorkingSetSize / 1000000, 3)}} | ConvertTo-Html -Fragment >> $HTML

"<a name='services'></a><h2>Running Services</h2>" >> $HTML
Write-Output "* Services"
Get-WmiObject -Class win32_service -Filter 'Started=True' | Sort -Property DisplayName | Select @{Name='Name';Expression={$_.DisplayName}},@{Name='Mode';Expression={$_.StartMode}},@{Name='Path';Expression={$_.PathName}},Description | ConvertTo-Html -Fragment >> $HTML

"<a name='network'></a><h2>Network Addresses</h2>" >> $HTML
Write-Output "* Network"
Get-WmiObject -Class 'Win32_NetworkAdapterConfiguration' -Filter 'IPEnabled = True' | Select @{Name='Interface';Expression={$_.Description}},@{Name='IP Addresses';Expression={$_.IPAddress}} | ConvertTo-Html -Fragment >> $HTML

$date = Get-Date
"<p><i>Report produced: $date</i></p>" >> $HTML

if((Get-Content $HTML | Select-String -Pattern "color=red"))
{
    Write-Output "*** Alarms were raised!"
    # Uncomment this out to send an email:
    #Send-MailMessage -From "noreply@example.com" -To "somewhere@example.com" -Subject "System Report" -Body (Get-Content $HTML) -BodyAsHtml -SmtpServer "localhost"
    # Uncomment this out to use pushbullet to send a notification:
    #pushbullet.exe -apikey APIKEY -title "System Report" -link "http://link/to/this/report.html"
}

Write-Output "Done! Report at: $HTML"
