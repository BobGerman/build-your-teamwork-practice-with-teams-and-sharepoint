

#Connect to: Msol, AzureAD Preview, Skype for Business, Microsoft Teams Powershell Modules
$credential = get-credential
$credential.Password.MakeReadOnly()  # Prevent commands from clearing the password
Connect-MsolService -Credential $credential
Connect-AzureAD -Credential $credential
Write-Host After Connect-AzureAD $credential.Password.Length
Connect-MicrosoftTeams -credential $credential
Import-Module SkypeOnlineConnector
$sfbSession = New-CsOnlineSession -Credential $credential
Import-PSSession $sfbSession


#get the unified group template
$template = Get-AzureADDirectorySettingTemplate | where-object {$_.displayname -eq "Group.Unified"}
$setting = $template.CreateDirectorySetting()

#If you tenant is new and you don't have any directory settings yet, a new directory setting will need to be created.
New-AzureADDirectorySetting -DirectorySetting $setting

$setting["UsageGuidelinesUrl"] = "https://guidelines.contoso.com"
$setting["PrefixSuffixNamingRequirement"] = "GRP_[GroupName]"
$setting["CustomBlockedWordsList"] = "Payroll,CEO,HR"
$setting["ClassificationList"] = "Highly Confidential,Confidential,Public"
$setting["DefaultClassification"] = "Confidential"
$setting["ClassificationDescriptions"] ="Highly Confidential:Very sensitive business data that would cause damage to the business if it was shared with unauthorized people.,Confidential:Sensitive business data that could cause damage to the business if shared with unauthorized people.,Public:Business data that is specifically prepared and approved for public consumption."
Set-AzureADDirectorySetting -Id (Get-AzureADDirectorySetting | where -Property DisplayName -Value "Group.Unified" -EQ).id -DirectorySetting $setting


#View the group settings:
$settings = Get-AzureADDirectorySetting
$settings.Values | fl

#Set lifecycle policy for group lifetime for a year
#*** note: update AlternateNotificationEmails with your teanant email address below *** 
New-AzureADMSGroupLifecyclePolicy -GroupLifetimeInDays 365 -ManagedGroupTypes All -AlternateNotificationEmails "admin@M365x695118.onmicrosoft.com"
Get-AzureADMSGroupLifecyclePolicy
#Review how those settings will now apply to users/groups on creation


#Almost ready to go, but you want to make sure the pilot is successful and business focused:
#Create a Teams messaging policy
New-CsTeamsMessagingPolicy -Identity "Pilot Messaging" -Description "Teams policy for our pilot group"
Set-CsTeamsMessagingPolicy -Identity "Pilot Messaging" -AllowGiphy $false -AllowStickers $false
Get-CsTeamsMessagingPolicy -Identity "Pilot Messaging"
#Capability is future:
Grant-CsTeamsMeetingPolicy -PolicyName "Pilot Messaging" -Identity "LeeG@M365x695118.OnMicrosoft.com"


#Provision a team for your pilot users
$team = New-Team -DisplayName "All Company" -Alias companyteam -AccessType Private -Classification "Confidential" -Description "Broad team for full company"
New-TeamChannel -GroupId $team.GroupId -DisplayName "Announcements" -Description "All company announcements"
New-TeamChannel -GroupId $team.GroupId -DisplayName "Free food"
New-TeamChannel -GroupId $team.GroupId -DisplayName "HR"
New-TeamChannel -GroupId $team.GroupId -DisplayName "Project tracking"
New-TeamChannel -GroupId $team.GroupId -DisplayName "Sales leads"

#dont need to include admin who is creating the group as a member
$users = Get-MsolUser | Where-Object {$_.IsLicensed -eq $true} | where-object {$_.UserPrincipalName -notlike "admin*"}
$users | Add-TeamUser -GroupId $team.GroupId -User {$_.UserPrincipalName}