[CmdletBinding()]
 Param(
)

$ErrorActionPreference = “silentlycontinue”

#Determine script location
Function Get-ScriptDirectory {
    Return Split-Path -Parent $MyInvocation.PSCommandPath
}

# Determine script filename 
Function Get-Scriptfilename {
    $ScriptDir = Get-ScriptDirectory
    $Scriptfile = [io.path]::GetFileNameWithoutExtension($ScriptDir)
    Return $Scriptfile
}

### Log File script
$logFileFolder = $(Get-ScriptDirectory) +"\logs"   
$currDate = get-date -format "yyyyMMdd_hhmm"
$logfileName = "log"+"_"+$currDate +".txt" 
$CurrentDatetime = get-date
$logFile = $logFileFolder + "\"+$logfileName

#Check Log Directory exists
If(-not(Test-Path $logFileFolder)){
 New-Item -Path $logFileFolder -ItemType Directory -Verbose
 Write-Log -Message "Log Directory $logFileFolder Created..!..!" -Severity Information
}

function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Message,
 
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Information','Warning','Error')]
        [string]$Severity = 'Information'
    )
    $LogContent = (Get-Date -f g)+" " + $Severity +"  "+$Message
    Add-Content -Path $logFile -Value $LogContent -PassThru | Write-Host

 }

 #Check input exists
If(-not($csvpath = Get-ChildItem -Path $(Get-ScriptDirectory) -Filter *.csv)){
 Write-Log -Message "Input CSV file not found in $(Get-ScriptDirectory)..Pls check " -Severity Information
 Exit-PSSession 1
}

$userstoCheck = Import-Csv -Path $csvpath.FullName
$report = @()

foreach($user in $($userstoCheck.samaccountname)){

$usergroupmembers = ""
$usergroupmembers = (GET-ADUSER –Identity $user –Properties MemberOf | Select-Object MemberOf).MemberOf

    If($usergroupmembers){
        $usergroupmembers | % {

        $obj = New-Object -TypeName PSObject
        $obj | Add-Member -MemberType NoteProperty -Name "ADUserName" -Value $user
        $obj | Add-Member -MemberType NoteProperty -Name "GroupMember(DistinguishedName)" -Value $PSItem
        Write-Log "$user is part of group $PSItem"
        $report += $obj

        }
    }
    else{

        $obj = New-Object -TypeName PSObject
        $obj | Add-Member -MemberType NoteProperty -Name "ADUserName" -Value $user
        $obj | Add-Member -MemberType NoteProperty -Name "GroupMember(DistinguishedName)" -Value "No members Found"
        Write-Log "$user is not part of any groups"
        $report += $obj

    }

}



$report | Export-Csv -Path "$(Get-ScriptDirectory)\ADUserGroupMembers.csv" -NoTypeInformation


