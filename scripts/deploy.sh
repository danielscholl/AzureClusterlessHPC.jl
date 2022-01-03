#!/bin/bash

AZURE_LOCATION="centralus"

WHAT_IF=0
VALIDATE_TEMPLATE=1

# ARM template and parameters file
TEMPLATE="../main.bicep"
PARAMETERS="../parameters.json"


# Validate the ARM template
if [[ $VALIDATE_TEMPLATE == 1 ]]; then
  if [[ $WHAT_IF == 1 ]]; then
    # Execute a deployment What-If operation at resource group scope.
    echo "Previewing changes deployed by [$TEMPLATE] ARM template..."
    az deployment sub what-if --template-file $TEMPLATE \
      --location $AZURE_LOCATION \
      -ojson

    if [[ $? == 0 ]]; then
      echo "[$TEMPLATE] ARM template validation succeeded"
    else
      echo "Failed to validate [$TEMPLATE] ARM template"
      exit
    fi
  else
    # Validate the ARM template
    echo "Validating [$TEMPLATE] ARM template..."
    output=$(az deployment sub validate --template-file $TEMPLATE \
      --location $AZURE_LOCATION \
      -ojson)

    if [[ $? == 0 ]]; then
      echo "[$TEMPLATE] ARM template validation succeeded"
    else
      echo "Failed to validate [$TEMPLATE] ARM template"
      echo $output
      exit
    fi
  fi
fi

# Deploy the ARM template
echo "Deploying [$TEMPLATE] ARM template..."
az deployment sub create --template-file $TEMPLATE \
      --location $AZURE_LOCATION \
      -ojson 1>/dev/null

if [[ $? == 0 ]]; then
  echo "[$TEMPLATE] ARM template successfully provisioned"
else
  echo "Failed to provision the [$TEMPLATE] ARM template"
  exit
fi
