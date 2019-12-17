$UniqueFirewallPrefix = "EtoHolydays_";
$UniqueUsername = "Vorona";
$UserPassword = "Vorona123!@#";
$AllowedDomains = @( "k11", "k12", "k13", "k14", "k21", "k22", "k23", "k24", "k31", "k32", "k33", "k34", "a11" );


function PrintStatus() {
	$partyUserExists = ((Get-LocalUser | ?{ $_.Name -like "Temp" }).Count -eq 1);
	$partyFirewallrules = (Get-NetFirewallRule | ?{ $_.DisplayName -like "$UniqueFirewallPrefix*" } | measure | select -ExpandProperty Count)
	$defaultFirewallProfiles = (Get-NetFirewallProfile | select -ExpandProperty DefaultOutboundAction)

	Write-Host "Is party user exists        : $partyUserExists"
	Write-Host "Count of party firewallRules: $partyFirewallrules"
	Write-Host "Default firewall profiles   : $defaultFirewallProfiles"
}

function StartPartymode() {
	function GetIp([String] $str) {
		$resolve = [System.Net.Dns]::GetHostAddresses($str).IPAddressToString;
		$ips = $resolve.Split(' ');
		
		if ($ips.Count -eq 1) {
			return $resolve;
		}

		$sortedIps = ($ips | ?{ $_.Length -gt 0 } | sort Length);
		$result = $sortedIps[0]; # in some cases it returns ipv4 and ipv6. Take ipv4.
		
		return $result;
	}

	$ips = ( $AllowedDomains | %{ GetIp $_ } )
	$ips | foreach -Process { New-NetFirewallRule -DisplayName "$UniqueFirewallPrefix$_" -Enabled True -RemoteAddress $_ };

	Set-NetFirewallProfile -Name Public -DefaultOutboundAction Block
	Set-NetFirewallProfile -Name Domain -DefaultOutboundAction Block
	Set-NetFirewallProfile -Name Private -DefaultOutboundAction Block

	$pw = ($UserPassword | ConvertTo-SecureString -AsPlainText -Force)
	New-LocalUser $UniqueUsername -Password $pw -PasswordNeverExpires
}

function StopPartymode() {
	Get-NetFirewallRule | ?{ $_.DisplayName -like "$UniqueFirewallPrefix*" } | Remove-NetFirewallRule

	Set-NetFirewallProfile -Name Public -DefaultOutboundAction Allow
	Set-NetFirewallProfile -Name Domain -DefaultOutboundAction Allow
	Set-NetFirewallProfile -Name Private -DefaultOutboundAction Allow

	Remove-LocalUser "Vorona"
	Remove-Item -Path C:\Users\Vorona -Recurse -Force
}

PrintStatus
$action = Read-Host -Prompt "Start Partymode? Write 'Start' or 'Stop'. There isn't any default value (: | "
if ($action -eq "Start") {	
	StartPartymode
}
if ($action -eq "Stop") {
	StopPartymode
}
