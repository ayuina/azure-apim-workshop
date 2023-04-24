param(                                  
    [Parameter(Mandatory=$true)][string]$NsgName,
    [Parameter(Mandatory=$true)][string]$ResourceGroup,
    [Parameter(Mandatory=$true)][string]$FilePath
)

#$NsgName = "testng"
#$ResourceGroup = "apim"
#$FilePath = "./nsg.csv"

New-AzNetworkSecurityGroup -Name $NsgName -ResourceGroupName $ResourceGroup  -Location "japaneast"
 
$NSG = Get-AzNetworkSecurityGroup -Name $NsgName -ResourceGroupName $ResourceGroup
$CSV = Import-CSV $FilePath -Encoding UTF8 -Delimiter '|'

$CSV | foreach{
Add-AzNetworkSecurityRuleConfig `
-Name $_.Name `
-NetworkSecurityGroup $NSG `
-Protocol $_.Protocol `
-SourcePortRange ($_.SourcePortRange  -split ",") `
-DestinationPortRange ($_.DestinationPortRange -split ",") `
-SourceAddressPrefix ($_.SourceAddressPrefix -split “,”) `
-DestinationAddressPrefix ($_.DestinationAddressPrefix -split “,”) `
-Access $_.Access `
-Priority $_.Priority `
-Direction $_.Direction `
}
Set-AzNetworkSecurityGroup -NetworkSecurityGroup $NSG
