
az login
az account set -s 'Visual Studio Enterprise Subscription – MPN'
az group create --name rg-Infrab-avd --location westeurope

## Deploy Network
az deployment group create --resource-group rg-Infrab-avd --template-file .\Templates\Network\deploy-vnet-with-subnet.bicep --parameters .\Parameters\vnet-with-subnet.parameters.json -c

## Deploy SIG
az deployment group create --resource-group rg-Infrab-avd --template-file .\Templates\SIG\deploy-shared-image-gallery.bicep --parameters .\Parameters\shared-image-gallery.parameters.json -c

### VM Image ###
# Deploy WIndows Server 2022
az deployment group create --resource-group rg-Infrab-avd --template-file .\Templates\VM\deploy-vm-win22.bicep --parameters .\Parameters\vm-win22.parameters.json -c

# Add sysprep script to vm
az vm run-command invoke  --command-id RunPowerShellScript --name InfrabVm -g rg-Infrab-avd --scripts 'param([string]$sysprep,[string]$arg) Start-Process -FilePath $sysprep -ArgumentList $arg' --parameters "sysprep=C:\Windows\System32\Sysprep\Sysprep.exe" "arg=/generalize /oobe /shutdown /quiet /mode:vm" 

# Generalize VM
az vm generalize -g rg-Infrab-avd -n InfrabVm

# Create image version
$vm = az vm show --resource-group rg-Infrab-avd --name InfrabVm --query 'id'
az deployment group create --resource-group rg-Infrab-avd --template-file .\Templates\SIG\deploy-shared-image-gallery-version.bicep --parameters .\Parameters\shared-image-gallery-version.parameters.json versionName='2022.04.05' source=$vm

### ENd VM Image ###

# Deploy AVD env backend
az deployment group create --resource-group rg-Infrab-avd --template-file .\Templates\AVD\deploy-avd-environment.bicep --parameters .\Parameters\avd-enviroment.parameters.json -c

# Deploy Log Analytics Monitoring
az deployment group create --resource-group rg-Infrab-avd --template-file .\Templates\AVD\deploy-avd-diagnostics.bicep --parameters .\Parameters\avd-diagnostics.parameters.json -c

# Azure Key vault
$objectId = az ad signed-in-user show --query objectId
az deployment group create --resource-group rg-Infrab-avd --template-file .\Templates\KeyVault\deploy-keyvault-with-secret.bicep --parameter .\Parameters\keyvault-parameters.json objectId=$objectId -c

# Create session host
$expirationtime = $((get-date).ToUniversalTime().AddHours(20).ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ'))
$hostpoolToken = az desktopvirtualization hostpool update --resource-group rg-Infrab-avd --name Infrab-Hostpool --registration-info expiration-time=$expirationtime registration-token-operation="Update" --query 'registrationInfo.token'
$adminpassword = az KeyVault secret show --vault-name InfrabKeyVault --name vmJoinerPassword --query value
az deployment group create --resource-group rg-Infrab-avd --template-file .\Templates\AVD\deploy-avd-sessionhosts.bicep --parameters .\Parameters\avd-sessionhost.parameters.json administratorAccountPassword=$adminpassword hostpoolToken=$hostpoolToken
