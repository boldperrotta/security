$APIKey = "XXXXXXXXXXXXXXXX"
$IPAddressList = Get-GSActivityReport -StartTime (Get-Date).AddDays(-1) -ApplicationName Login -UserKey "all" | Select IPAddress
ForEach ($IPAddress in $IPAddressList) {
$URL = "http://api.ipstack.com/" + $IPAddress.IpAddress + "?access_key=" + $APIKey + "&format=1"
Invoke-WebRequest $URL | ConvertFrom-Json | Select ip,country_name,region_code | Export-CSV c:\temp\ipgeo.csv -Append
}
