<#
.SYNOPSIS
Imports a PowerProxy's configuration into a given Key Vault.

.DESCRIPTION
Writes a PowerProxy's configuration into the given Key Vault from the given file.

.PARAMETER KeyVaultName
Name of the Key Vault in which the configuration is stored.

.EXAMPLE
PS> .\Import-ConfigToAzure.ps1 -KeyVaultName abdefpowerproxyaoai -FromFile production.config.json -ResourceGroup PowerProxy-AOAI

Imports the PowerProxy config into the Key Vault 'abdefpowerproxyaoai' from JSON file 'production.config.json'.

.EXAMPLE
PS> .\Import-ConfigToAzure.ps1 -KeyVaultName abdefpowerproxyaoai -FromFile production.config.json -ResourceGroup PowerProxy-AOAI -KeyVaultSecretName PowerProxy-AOAI-config-string -SkipNewContainerAppRevision

Imports the PowerProxy config into the Key Vault 'abdefpowerproxyaoai' (secret 'PowerProxy-AOAI-config-string') from JSON file 'production.config.json' and skips the creation of a new revision for the container app.

.LINK
GitHub repo: https://github.com/timoklimmer/powerproxy-aoai

.NOTES
PowerShell version should be 7+. Also make sure your Azure CLI installation is up-to-date.
#>
param(
  [Parameter(mandatory=$true)]
  [string] $KeyVaultName,

  [Parameter(mandatory=$true)]
  [string] $FromFile,

  [Parameter(mandatory=$true)]
  [string] $ResourceGroup,

  [Parameter(mandatory=$false)]
  [string] $KeyVaultSecretName = "config-string",

  [Parameter(mandatory=$false)]
  [switch] $SkipNewContainerAppRevision
)

#---------------------------------------[Initialisation]--------------------------------------------
$ErrorActionPreference = "Stop"
Write-Host "Importing PowerProxy config into Key Vault '$KeyVaultName' (secret '$KeyVaultSecretName') from file '$FromFile'..."
$CONTAINER_APP_NAME = "powerproxyaoai"

#--------------------------------------------[Code]-------------------------------------------------
Write-Host "Updating config in Key Vault..."
az keyvault secret set `
    --name $KeyVaultSecretName `
    --vault-name $KeyVaultName `
    --file $FromFile `
    --output none

if (-not $SkipNewContainerAppRevision) {
  Write-Host "Creating new revision in Container App (required for the new config to come into effect)..."
  $random_revision_suffix = (`
    -join ((48..57) + (97..122) | Get-Random -Count 7 | ForEach-Object {[char]$_}) `
  )
  az containerapp revision copy `
    -n $CONTAINER_APP_NAME `
    -g $ResourceGroup `
    --revision-suffix $random_revision_suffix
}

#--------------------------------------------[Done]-------------------------------------------------
Write-Host "Done."
