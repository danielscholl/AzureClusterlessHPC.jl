#!/usr/bin/env bash
#
#  Purpose: Create Azure Resources necessary for Azure Clusterless HPC.
#  Usage:
#    deploy.sh

###############################
## ARGUMENT INPUT            ##
###############################
usage() { echo "Usage: deploy.sh <unique> <region>" 1>&2; exit 1; }

AZURE_ACCOUNT=$(az account show --query '[tenantId, id, user.name]' -otsv 2>/dev/null)
AZURE_TENANT=$(echo $AZURE_ACCOUNT |awk '{print $1}')
AZURE_SUBSCRIPTION=$(echo $AZURE_ACCOUNT |awk '{print $2}')
AZURE_USER=$(echo $AZURE_ACCOUNT |awk '{print $3}')

if [ ! -z $1 ]; then UNIQUE=$1; fi
if [ -z $UNIQUE ]; then
  UNIQUE=$(echo $AZURE_USER | awk -F "@" '{print $1}')
fi

if [ ! -z $2 ]; then AZURE_LOCATION=$2; fi
if [ -z $AZURE_LOCATION ]; then
  AZURE_LOCATION="southcentralus"
fi

if [ -z $RANDOM_NUMBER ]; then
  RANDOM_NUMBER=$(echo $((RANDOM%9999+100)))
fi

if [ -z $AZURE_GROUP ]; then
  AZURE_GROUP="clusterless-hpc-${UNIQUE}"
fi

if [ -z $FILE_NAME ]; then
  FILE_NAME="credentials.json"
fi

###############################
## FUNCTIONS                 ##
###############################
function CreateResourceGroup() {
  # Required Argument $1 = RESOURCE_GROUP
  # Required Argument $2 = LOCATION

  if [ -z $1 ]; then
    tput setaf 1; echo 'ERROR: Argument $1 (RESOURCE_GROUP) not received'; tput sgr0
    exit 1;
  fi
  if [ -z $2 ]; then
    tput setaf 1; echo 'ERROR: Argument $2 (LOCATION) not received'; tput sgr0
    exit 1;
  fi

  local _result=$(az group show --name $1 2>/dev/null)
  if [ "$_result"  == "" ]
    then
      OUTPUT=$(az group create --name $1 \
        --location $2 \
        --tags "RANDOM=$RANDOM_NUMBER CONTACT=$AZURE_USER" \
        -ojsonc)
      LOCK=$(az group lock create --name "DELETE-PROTECTED" \
        --resource-group $1 \
        --lock-type CanNotDelete \
        -ojsonc)
    else
      tput setaf 3;  echo "Resource Group $1 already exists."; tput sgr0
      RANDOM_NUMBER=$(az group show --name $1 --query tags.RANDOM -otsv)
    fi
}
function CreateStorageAccount() {
  # Required Argument $1 = STORAGE_ACCOUNT
  # Required Argument $2 = RESOURCE_GROUP
  # Required Argument $3 = LOCATION

  if [ -z $1 ]; then
    tput setaf 1; echo 'ERROR: Argument $1 (STORAGE_ACCOUNT) not received' ; tput sgr0
    exit 1;
  fi
  if [ -z $2 ]; then
    tput setaf 1; echo 'ERROR: Argument $2 (RESOURCE_GROUP) not received' ; tput sgr0
    exit 1;
  fi
  if [ -z $3 ]; then
    tput setaf 1; echo 'ERROR: Argument $3 (LOCATION) not received' ; tput sgr0
    exit 1;
  fi

  local _storage=$(az storage account show --name $1 --resource-group $2 --query name -otsv 2>/dev/null)
  if [ "$_storage"  == "" ]
      then
      OUTPUT=$(az storage account create \
        --name $1 \
        --resource-group $2 \
        --location $3 \
        --sku Standard_LRS \
        --kind StorageV2 \
        --encryption-services blob \
        --query name -otsv)
      else
        tput setaf 3;  echo "Storage Account $1 already exists."; tput sgr0
      fi
}
function GetStorageAccountKey() {
  # Required Argument $1 = STORAGE_ACCOUNT
  # Required Argument $2 = RESOURCE_GROUP

  if [ -z $1 ]; then
    tput setaf 1; echo 'ERROR: Argument $1 (STORAGE_ACCOUNT) not received'; tput sgr0
    exit 1;
  fi
  if [ -z $2 ]; then
    tput setaf 1; echo 'ERROR: Argument $2 (RESOURCE_GROUP) not received'; tput sgr0
    exit 1;
  fi

  local _result=$(az storage account keys list \
    --account-name $1 \
    --resource-group $2 \
    --query '[0].value' \
    --output tsv)
  echo ${_result}
}
function CreateBatchAccount() {
  # Required Argument $1 = BATCH_ACCOUNT
  # Required Argument $2 = RESOURCE_GROUP
  # Required Argument $3 = LOCATION
  # Required Argument $4 = STORAGE_ACCOUNT

  if [ -z $1 ]; then
    tput setaf 1; echo 'ERROR: Argument $1 (BATCH_ACCOUNT) not received' ; tput sgr0
    exit 1;
  fi
  if [ -z $2 ]; then
    tput setaf 1; echo 'ERROR: Argument $2 (RESOURCE_GROUP) not received' ; tput sgr0
    exit 1;
  fi
  if [ -z $3 ]; then
    tput setaf 1; echo 'ERROR: Argument $3 (LOCATION) not received' ; tput sgr0
    exit 1;
  fi
  if [ -z $4 ]; then
    tput setaf 1; echo 'ERROR: Argument $4 (STORAGE_ACCOUNT) not received' ; tput sgr0
    exit 1;
  fi

  local _batch=$(az batch account show --name $1 --resource-group $2 --query name -otsv 2>/dev/null)
  if [ "$_batch"  == "" ]
      then
      OUTPUT=$(az batch account create \
        --name $1 \
        --resource-group $2 \
        --location $3 \
        --storage-account $4 \
        --query name -otsv)
      else
        tput setaf 3;  echo "Batch Account $1 already exists."; tput sgr0
      fi
}
function CreateADApplication() {
    # Required Argument $1 = APPLICATION_NAME
    # Required Argument $2 = RESOURCE_GROUP

    if [ -z $1 ]; then
        tput setaf 1; echo 'ERROR: Argument $1 (APPLICATION_NAME) not received'; tput sgr0
        exit 1;
    fi
    if [ -z $2 ]; then
        tput setaf 1; echo 'ERROR: Argument $2 (RESOURCE_GROUP) not received'; tput sgr0
        exit 1;
    fi

    local _result=$(az ad sp list --display-name $1 --query [].appId -otsv)
    if [ "$_result"  == "" ]
    then

      APP_SECRET=$(az ad sp create-for-rbac \
        --name $1 \
        --skip-assignment \
        --query password -otsv 2>/dev/null)

      APP_ID=$(az ad sp list \
        --display-name $1 \
        --query [].appId -otsv)

      az tag create --resource-id /subscriptions/$AZURE_SUBSCRIPTION/resourcegroups/$2 --tags RANDOM=$RANDOM_NUMBER APP_ID=$APP_ID CONTACT=$AZURE_USER -o none 2>/dev/null
      az role assignment create --assignee $APP_ID --role "Contributor" --scope "/subscriptions/${AZURE_SUBSCRIPTION}/resourceGroups/$2" -o none 2>/dev/null
    else
        tput setaf 3;  echo "AD Application $1 already exists."; tput sgr0
        APP_ID=$(az group show --name $2 --query tags.APP_ID -otsv 2>/dev/null)

        tput setaf 3;  echo "Resetting AD Application Key."; tput sgr0
        APP_SECRET=$(az ad app credential reset --id $APP_ID --credential-description $(date +%m-%d-%y) --append --query password -otsv 2>/dev/null)
        sleep 20 && tput setaf 3;  echo "Waiting for AD..."; tput sgr0 && sleep 20
    fi
}


###############################
## EXECUTION                 ##
###############################
printf "\n"
tput setaf 2; echo "Creating Azure Resources" ; tput sgr0
tput setaf 3; echo "------------------------------------" ; tput sgr0

tput setaf 2; echo 'Creating a Resource Group...' ; tput sgr0
CreateResourceGroup $AZURE_GROUP $AZURE_LOCATION

if [ -z $ITEM_NAME ]; then
  ITEM_NAME="clusterlesshpc${RANDOM_NUMBER}"
fi

tput setaf 2; echo "Creating a Storage Account..." ; tput sgr0
CreateStorageAccount $ITEM_NAME $AZURE_GROUP $AZURE_LOCATION

tput setaf 2; echo "Retrieving a Storage Account Key..." ; tput sgr0
STORAGE_KEY=$(GetStorageAccountKey $ITEM_NAME $AZURE_GROUP)

tput setaf 2; echo "Creating a Batch Account..." ; tput sgr0
CreateBatchAccount $ITEM_NAME $AZURE_GROUP $AZURE_LOCATION $ITEM_NAME

tput setaf 2; echo 'Creating an AD Application...' ; tput sgr0
CreateADApplication "${ITEM_NAME}" $AZURE_GROUP

# Write to credential file
tput setaf 2; echo 'Generating' ${FILE_NAME}'...' ; tput sgr0
echo "{
    \"_AD_TENANT\": \"${AZURE_TENANT}\",
    \"_AD_BATCH_CLIENT_ID\": \"${APP_ID}\",
    \"_AD_SECRET_BATCH\": \"${APP_SECRET}\",
    \"_BATCH_ACCOUNT_URL\": \"https://${ITEM_NAME}.${AZURE_LOCATION}.batch.azure.com\",
    \"_BATCH_RESOURCE\": \"https://batch.core.windows.net/\",
    \"_REGION\": \"${AZURE_LOCATION}\",
    \"_STORAGE_ACCOUNT_NAME\": \"${ITEM_NAME}\",
    \"_STORAGE_ACCOUNT_KEY\": \"${STORAGE_KEY}\"
}" > $FILE_NAME

# Write to credential file
if command -v julia &> /dev/null
then
  export CREDENTIALS="credentials.json"
  tput setaf 2; echo 'Validating Azure Connection...' ; tput sgr0  
  julia -e 'using Pkg; using AzureClusterlessHPC;'
  if [ $? -eq 0 ]; then
    tput setaf 4; echo 'Successful Connection to Azure from Julia!' ; tput sgr0
    mv credentials.json /home/vscode/.julia/dev/AzureClusterlessHPC/credentials.json
  else
    tput setaf 1; echo 'Julia Connection to Azure Failure' ; tput sgr0
  fi
fi
