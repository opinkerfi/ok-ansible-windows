param (
    [Parameter(Mandatory = $true)][string]$dateOffset,
    [Parameter(Mandatory = $true)][string]$domainName,
    [string]$ipv6_subnetRangeEnd
)
########################################################################
#   PreFlight checks
########################################################################
# Exit the script if parameters are missing
if ($incompleteListOfParameters) {
    exit
}

########################################################################
#   Main Logic Begins
########################################################################

#Dagsetningin hvenær skýrslan var gerð
$date = get-date -Format dd.MM.yyyy
#Nafnið á fyrirtækinu sem verið er að keyra skýrsluna
$domainName = "BSRB"
#OU sem á að leita að notendum
$OU = "OU=Users,OU=MyBusiness,DC=BSRB,DC=local"
#Samningsnúmerið hjá V.V.
$contract = "N0957"
#Fjöldi daga sem á að telja aftur í tímann
$dateRange = (get-date).AddDays(-30)
#Nafnið á skýrslunni sem verður til fyrir notendur.
$UsersReport = "C:\Skyrslur\" + $domainName + "-Users-" + $date + ".csv"
#Nafnið á skýrslunni sem verður til fyrir Tölvur.
$ComputerReport = "C:\Skyrslur\" + $domainName + "-Computers-" + $date + ".csv"

#athuga hvort folder c:\Skyrslur sé til ef ekki þá búa hann til.
$path = Get-Item c:\skyrslur -ErrorAction SilentlyContinue
if ($path) {
    Write-Host "Folder c:\skyrslur er til"
}
else {
    New-Item -Path c:\ -Name skyrslur -ItemType directory -Force
}
#AD Leit að notendum
function GenerateUserReport ($OU) {
    $users = Get-ADUser -Filter * -Properties LastLogonDate -SearchBase $OU | 
    Where-Object {
        $_.Enabled -eq $true 
        -and ($_.DistinguishedName -notlike "*OU=Adrir,*") 
        -and ($_.DistinguishedName -notlike "*OU=Contractors,*") 
        -and ($_.DistinguishedName -notlike "*OU=Disabled,*") 
        -and ($_.DistinguishedName -notlike "*OU=Félag flugmálastarfsmanna ríkisins,*") 
        -and ($_.DistinguishedName -notlike "*OU=Félag íslenskra flugumferðarstjóra,*") 
        -and ($_.DistinguishedName -notlike "*OU=FOSS,*") 
        -and ($_.DistinguishedName -notlike "*OU=Fundarherbergi,*") 
        -and ($_.DistinguishedName -notlike "*OU=Gesta aðgangar,*") 
        -and ($_.DistinguishedName -notlike "*OU=Service Users,*")
    }  

    $addInfo = Import-Csv $UsersReport -Encoding UTF8 -Delimiter ";"
    foreach ($record in $addInfo) {
        $record = Add-Member -InputObject $record -MemberType NoteProperty -Name "SamningsNR" -Value $contract
        $record = Add-Member -InputObject $record -MemberType NoteProperty -Name "Dags" -Value $date
    }

    $addInfo | Export-Csv -Encoding UTF8 -Delimiter ";" -Path $UsersReport -NoTypeInformation
    $UsrHeildarfjoldi = $users.Count

    Add-Content $UsersReport -Value "" -Encoding UTF8
    Add-Content $UsersReport -Value "Total Users: $UsrHeildarfjoldi" -Encoding UTF8

    return $users
}

function FunctionName ($OU) {
    #AD Leit að öllum vélum sem eru ekki serverar.
    $computers = Get-ADComputer -Filter ("operatingsystem -notlike '*server*'") -Properties LastlogonDate, OperatingSystem, whenCreated, DistinguishedName | 
    Where-Object { 
        $_.LastLogonDate -ge $dateRange 
        -and ($_.DistinguishedName -notlike "*NoAutoupdate*") 
        -and ($_.DistinguishedName -notlike "*Rannsoknarvelar*") 
    }

    #Exporta lista í .CSV skrá og telja notendur og vélar.
    Add-Content $UsersReport -Value "BSRB:" -Encoding UTF8
    $BSRB | Select-Object Name, UserPrincipalName, Enabled, LastLogonDate, DistinguishedName | Export-Csv -Encoding UTF8 -Delimiter ";" -Path $UsersReport

    #Vélar
    $computers | Select-Object Name, LastLogonDate, Enabled, OperatingSystem, whenCreated, DistinguishedName | Export-Csv -Encoding UTF8 -Delimiter ";" -Path $ComputerReport -NoTypeInformation
    $addCompInfo = Import-Csv $ComputerReport -Encoding UTF8 -Delimiter ";"
    
    foreach ($record in $addCompInfo) {
        $record = Add-Member -InputObject $record -MemberType NoteProperty -Name "Samningsnr" -Value $contract
        $record = Add-Member -InputObject $record -MemberType NoteProperty -Name "Dags" -Value $date
    }

    $addCompInfo | Export-Csv -Encoding UTF8 -Delimiter ";" -Path $ComputerReport -NoTypeInformation
    $CompHeildarfjoldi = $computers.Count
    Add-Content $ComputerReport -Value "Total Computers: $CompHeildarfjoldi" -Encoding UTF8
    
}


#Senda út póst á OK með afriti af skýrslunni og tölu yfir fjölda notanda sem fannst
$SMTP = "smtp.okhysing.is"                                       #Nafnið á póstþjóninum sem á að senda póstinn, hægt að nota O365
$From = "BSRB<noreply@bsrb.is>"                               #Nafnið á sendandanum
$To = "talning@ok.is"          #Nafnið á móttakandanum, hægt að senda á mörg netföng með því að setja "," á milli t.d. "Email@email.is","2email@email.is"

Send-MailMessage -Attachments $UsersReport, $ComputerReport -From $From -To $To -SmtpServer $SMTP -Subject "$domainName User Report" -Encoding UTF8 -BodyAsHtml "
Hér er skýrsla yfir notendur og útstöðvar.<br>
<br>
Fyrir samning $contract<br>
<br>
Þetta er heildar fjöldi notanda: $UsrHeildarfjoldi<br>
<br>
Það skiptist eftirfarandi:<br>
BSRB: $BSRBHeildarfjoldi<br>
Landssamband Lögreglumanna: $LandsLogHeildarfjoldi<br>
Póstmannafélag Íslands: $PostIslandsHeildarfjoldi<br>
Sameyki: $SameykiHeildarfjoldi<br>
Styrkarsjóður: $StyrktarsjodurHeildarfjoldi<br>
Virk: $VirkHeildarfjoldi<br>
<br>
Heildar fjöldi útstöðva: $CompHeildarfjoldi<br>
<br>
Kveðja<br>
Kerfisstjóri $domainName"
