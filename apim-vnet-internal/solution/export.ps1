#param(
#    [Parameter(Mandatory=$true)][string]$NsgName = "apimnsgtkmxgagtmos7k",
#    [Parameter(Mandatory=$true)][string]$CsvPathToSave = "nsg"
#)

$NsgName = "apimnsgtkmxgagtmos7k";
$CsvPathToSave = "nsg";
 
$nsg = Get-AzNetworkSecurityGroup -Name $NsgName | Get-AzNetworkSecurityRuleConfig
 
$NsgRuleSet = @()

#$NsgRuleSet = [pscustomobject]@{
#Name = "Name";
#Protocol = "Protocol";
#SourcePortRange = "SourcePortRange";
#DestinationPortRange =  "DestinationPortRange";
#ourceAddressPrefix = "SourceAddressPrefix";
#DestinationAddressPrefix = "DestinationAddressPrefix";
#SourceApplicationSecurityGroups = "SourceApplicationSecurityGroups";
#DestinationApplicationSecurityGroups = "DestinationApplicationSecurityGroups";
#Access = "Access";
#Priority = "Priority";
#Direction = "Direction";
#}
 
foreach ($rule in $nsg) {
 
    $ASGGroupNameSource = $rule.SourceApplicationSecurityGroups.id -replace '.*/'
    $ASGGroupNameDestination = $rule.DestinationApplicationSecurityGroups.id -replace '.*/'

      
     
    $NsgRuleSet += (
 
        [pscustomobject]@{ 
                        Name =  $rule.Name; 
                        Protocol = $rule.Protocol;
                        SourcePortRange = "$($rule.SourcePortRange -join ",")"; 
                        DestinationPortRange = "$($rule.DestinationPortRange -join ",")"; 
                        SourceAddressPrefix = "$($rule.SourceAddressPrefix -join ",")";
                        DestinationAddressPrefix = "$($rule.DestinationAddressPrefix -join ",")";
                        SourceApplicationSecurityGroups = $ASGGroupNameSource;
                        DestinationApplicationSecurityGroups = $ASGGroupNameDestination;
                        Access = $rule.Access;
                        Priority = $rule.Priority; 
                        Direction = $rule.Direction;
                        }
 
    )
} 
 
$NsgRuleSet | export-csv -Path "$($CsvPathToSave).csv" -Delimiter '|'


