#!/usr/bin/env bash
#
#  Purpose: Create a Resource Group with a KeyVault, IoT Hub and DPS
#  Usage:
#    provision.sh


###############################
## ARGUMENT INPUT            ##
###############################

usage() { echo "Usage: provision.sh " 1>&2; exit 1; }

if [ -f ./.envrc ]; then source ./.envrc; fi

if [ ! -z $1 ]; then PREFIX=$1; fi
if [ -z $PREFIX ]; then
  PREFIX="pp"
fi

if [ -z $AZURE_LOCATION ]; then
  AZURE_LOCATION="westus"
fi

# if [ -z $AZURE_GROUP ]; then
#   AZURE_GROUP="iot-resources"
# fi

if [ -z $ORGANIZATION ]; then
  ORGANIZATION="testonly"
fi

if [ -z $ROOT_CA_PASSWORD ]; then
  ROOT_CA_PASSWORD="azure@rootca"
fi

if [ -z $INT_CA_PASSWORD ]; then
  INT_CA_PASSWORD="azure@azure@intermediateca"
fi

USER_ID=$(az ad user show \
        --id $(az account show --query user.name -otsv) \
        --query objectId -otsv)


##############################
## Deploy ARM Resources     ##
##############################

printf "\n"
tput setaf 2; echo "Defining the Resource Group" ; tput sgr0
tput setaf 3; echo "------------------------------------" ; tput sgr0
AZURE_GROUP="$PREFIX-resources"
tput setaf 3; echo "Resource Group = $AZURE_GROUP"

printf "\n"
tput setaf 2; echo "Deploying the ARM Templates" ; tput sgr0
tput setaf 3; echo "------------------------------------" ; tput sgr0
if [ -f ./params.json ]; then PARAMS="params.json"; else PARAMS="azuredeploy.parameters.json"; fi

az deployment create --template-file azuredeploy.json  \
  --name iot-resources \
  --location $AZURE_LOCATION \
  --parameters userObjectId=$USER_ID group=$AZURE_GROUP location=$AZURE_LOCATION \
  -oyaml

##############################
## Deploy .envrc File       ##
##############################
printf "\n"
tput setaf 2; echo "Creating the Environment File .envrc" ; tput sgr0
tput setaf 3; echo "------------------------------------" ; tput sgr0

VAULT=$(az keyvault list --resource-group $AZURE_GROUP --query [].name -otsv)
HUB=$(az iot hub list --resource-group $AZURE_GROUP --query [].name -otsv)
DPS=$(az iot dps list --resource-group $AZURE_GROUP --query [].name -otsv)
DPS_GROUP=$AZURE_GROUP

cat > .envrc << EOF
# Azure Resources
export VAULT="${VAULT}"
export HUB="${HUB}"
export DPS="${DPS}"
export DPS_GROUP="${DPS_GROUP}"

# Certificate Authority
export ORGANIZATION="testonly"
export ROOT_CA_PASSWORD="azure@rootca"
export INT_CA_PASSWORD="azure@intermediateca"
EOF
