#!/bin/bash
# Interactive script to set up Azure resources for ARO Migration Hackathon
# This script will create:
# - Resource Group
# - Virtual Network and Subnets
# - Azure Red Hat OpenShift Cluster
# - Azure Container Registry

set -e

# Text formatting
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BOLD}Welcome to the ARO Migration Hackathon Setup!${NC}"
echo -e "This script will help you set up the necessary Azure resources."
echo -e "You'll be prompted for information along the way.\n"

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo -e "${YELLOW}Azure CLI is not installed. Please install it first.${NC}"
    echo "Visit: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check if logged in to Azure
echo -e "${BLUE}Checking Azure login status...${NC}"
az account show &> /dev/null
if [ $? -ne 0 ]; then
    echo -e "${YELLOW}You are not logged in to Azure. Please log in now.${NC}"
    az login
    if [ $? -ne 0 ]; then
        echo "Failed to log in to Azure. Please try again."
        exit 1
    fi
fi

# List subscriptions and prompt for selection
echo -e "\n${BLUE}Available Azure Subscriptions:${NC}"
az account list --query "[].{name:name, id:id, isDefault:isDefault}" --output table

echo -e "\n${BOLD}Enter the Subscription ID you want to use:${NC}"
read -p "> " SUBSCRIPTION_ID

# Set the selected subscription
echo -e "${BLUE}Setting the subscription...${NC}"
az account set --subscription "$SUBSCRIPTION_ID"
if [ $? -ne 0 ]; then
    echo "Failed to set subscription. Please check the ID and try again."
    exit 1
fi

# Prompt for resource group name and location
echo -e "\n${BOLD}Enter a name for your resource group:${NC}"
echo "Default: aro-hackathon-rg"
read -p "> " RESOURCE_GROUP
RESOURCE_GROUP=${RESOURCE_GROUP:-aro-hackathon-rg}

echo -e "\n${BOLD}Enter the Azure region to deploy to:${NC}"
echo "Examples: eastus, westeurope, australiaeast"
echo "Default: eastus"
read -p "> " LOCATION
LOCATION=${LOCATION:-eastus}

# Create resource group
echo -e "\n${BLUE}Creating resource group ${RESOURCE_GROUP} in ${LOCATION}...${NC}"
az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --output none

# Prompt for cluster name
echo -e "\n${BOLD}Enter a name for your ARO cluster:${NC}"
echo "Default: aro-cluster"
read -p "> " CLUSTER_NAME
CLUSTER_NAME=${CLUSTER_NAME:-aro-cluster}

# Setting up variables for networking
VNET_NAME="${CLUSTER_NAME}-vnet"
MASTER_SUBNET="${CLUSTER_NAME}-master-subnet"
WORKER_SUBNET="${CLUSTER_NAME}-worker-subnet"

# Create virtual network
echo -e "\n${BLUE}Creating virtual network ${VNET_NAME}...${NC}"
az network vnet create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$VNET_NAME" \
  --address-prefixes 10.0.0.0/16 \
  --output none

# Create master subnet
echo -e "${BLUE}Creating master subnet ${MASTER_SUBNET}...${NC}"
az network vnet subnet create \
  --resource-group "$RESOURCE_GROUP" \
  --vnet-name "$VNET_NAME" \
  --name "$MASTER_SUBNET" \
  --address-prefixes 10.0.0.0/23 \
  --service-endpoints Microsoft.ContainerRegistry \
  --output none

# Create worker subnet
echo -e "${BLUE}Creating worker subnet ${WORKER_SUBNET}...${NC}"
az network vnet subnet create \
  --resource-group "$RESOURCE_GROUP" \
  --vnet-name "$VNET_NAME" \
  --name "$WORKER_SUBNET" \
  --address-prefixes 10.0.2.0/23 \
  --service-endpoints Microsoft.ContainerRegistry \
  --output none

# Update master subnet to disable private endpoint network policies
echo -e "${BLUE}Updating master subnet...${NC}"
az network vnet subnet update \
  --name "$MASTER_SUBNET" \
  --resource-group "$RESOURCE_GROUP" \
  --vnet-name "$VNET_NAME" \
  --disable-private-link-service-network-policies true \
  --output none

# Prompt for ACR name
echo -e "\n${BOLD}Enter a name for your Azure Container Registry:${NC}"
echo "Must be globally unique, use only lowercase letters and numbers"
echo "Default: ${CLUSTER_NAME}acr (will be lowercased)"
read -p "> " ACR_NAME
ACR_NAME=${ACR_NAME:-${CLUSTER_NAME}acr}
ACR_NAME=$(echo "$ACR_NAME" | tr '[:upper:]' '[:lower:]')

# Register resource providers
echo -e "\n${BLUE}Registering necessary resource providers...${NC}"
az provider register -n Microsoft.RedHatOpenShift --wait --output none
az provider register -n Microsoft.Compute --wait --output none
az provider register -n Microsoft.Storage --wait --output none
az provider register -n Microsoft.Authorization --wait --output none
az provider register -n Microsoft.ContainerRegistry --wait --output none

# Create ACR
echo -e "\n${BLUE}Creating Azure Container Registry ${ACR_NAME}...${NC}"
az acr create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$ACR_NAME" \
  --sku Standard \
  --admin-enabled true \
  --output none

# Ask if the user wants to create the ARO cluster (it takes time)
echo -e "\n${BOLD}Do you want to create the ARO cluster now? This will take 30-40 minutes.${NC}"
echo "If you choose no, instructions will be provided for creating it later."
echo "1) Yes, create it now"
echo "2) No, I'll create it later"
read -p "> " CREATE_CLUSTER_CHOICE

if [ "$CREATE_CLUSTER_CHOICE" == "1" ]; then
    # Check if user has a pull secret file
    echo -e "\n${BOLD}Do you have a Red Hat pull secret file?${NC}"
    echo "This is required for creating an ARO cluster."
    echo "If you don't have one, you can get it from: https://console.redhat.com/openshift/install/pull-secret"
    echo "1) Yes, I have it"
    echo "2) No, I'll get it later"
    read -p "> " PULL_SECRET_CHOICE
    
    PULL_SECRET_OPTION=""
    if [ "$PULL_SECRET_CHOICE" == "1" ]; then
        echo -e "${BOLD}Enter the path to your pull secret file:${NC}"
        read -p "> " PULL_SECRET_PATH
        PULL_SECRET_OPTION="--pull-secret @$PULL_SECRET_PATH"
    fi
    
    echo -e "\n${BLUE}Creating ARO cluster ${CLUSTER_NAME}...${NC}"
    echo -e "${YELLOW}This will take 30-40 minutes to complete.${NC}"
    
    # Create the ARO cluster
    az aro create \
      --resource-group "$RESOURCE_GROUP" \
      --name "$CLUSTER_NAME" \
      --vnet "$VNET_NAME" \
      --master-subnet "$MASTER_SUBNET" \
      --worker-subnet "$WORKER_SUBNET" \
      $PULL_SECRET_OPTION
    
    # Get ARO cluster credentials and information
    echo -e "\n${GREEN}Getting ARO cluster credentials...${NC}"
    CLUSTER_CREDS=$(az aro list-credentials \
      --name "$CLUSTER_NAME" \
      --resource-group "$RESOURCE_GROUP")
    
    ADMIN_USERNAME=$(echo $CLUSTER_CREDS | jq -r .kubeadminUsername)
    ADMIN_PASSWORD=$(echo $CLUSTER_CREDS | jq -r .kubeadminPassword)
    
    CONSOLE_URL=$(az aro show \
      --name "$CLUSTER_NAME" \
      --resource-group "$RESOURCE_GROUP" \
      --query "consoleProfile.url" -o tsv)
    
    API_URL=$(az aro show \
      --name "$CLUSTER_NAME" \
      --resource-group "$RESOURCE_GROUP" \
      --query apiserverProfile.url -o tsv)
    
    echo -e "\n${GREEN}ARO Cluster created successfully!${NC}"
    echo -e "Console URL: ${BOLD}$CONSOLE_URL${NC}"
    echo -e "API Server URL: ${BOLD}$API_URL${NC}"
    echo -e "Admin Username: ${BOLD}$ADMIN_USERNAME${NC}"
    echo -e "Admin Password: ${BOLD}$ADMIN_PASSWORD${NC}"
    
    echo -e "\n${BOLD}To connect using OpenShift CLI:${NC}"
    echo "oc login $API_URL -u $ADMIN_USERNAME -p $ADMIN_PASSWORD"
else
    echo -e "\n${YELLOW}Skipping ARO cluster creation.${NC}"
    echo -e "To create the ARO cluster later, run the following command:"
    echo "az aro create \\"
    echo "  --resource-group $RESOURCE_GROUP \\"
    echo "  --name $CLUSTER_NAME \\"
    echo "  --vnet $VNET_NAME \\"
    echo "  --master-subnet $MASTER_SUBNET \\"
    echo "  --worker-subnet $WORKER_SUBNET \\"
    echo "  --pull-secret @pull-secret.txt"
fi

# Get ACR credentials
echo -e "\n${BLUE}Getting ACR credentials...${NC}"
ACR_USERNAME=$(az acr credential show --name $ACR_NAME --query username --output tsv)
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query "passwords[0].value" --output tsv)
ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --query loginServer --output tsv)

# Save environment variables to file
echo -e "\n${BLUE}Saving environment variables to .env file...${NC}"
cat > .env << EOF
# ARO Hackathon Environment Variables
# Created on $(date)

# Azure Resources
RESOURCE_GROUP=$RESOURCE_GROUP
LOCATION=$LOCATION
CLUSTER_NAME=$CLUSTER_NAME
ACR_NAME=$ACR_NAME

# Azure Container Registry
REGISTRY_URL=$ACR_LOGIN_SERVER
REGISTRY_USERNAME=$ACR_USERNAME
REGISTRY_PASSWORD=$ACR_PASSWORD

# ARO Cluster
$([ "$CREATE_CLUSTER_CHOICE" == "1" ] && echo "OPENSHIFT_API_URL=$API_URL")
$([ "$CREATE_CLUSTER_CHOICE" == "1" ] && echo "OPENSHIFT_CONSOLE_URL=$CONSOLE_URL")
$([ "$CREATE_CLUSTER_CHOICE" == "1" ] && echo "OPENSHIFT_USERNAME=$ADMIN_USERNAME")
$([ "$CREATE_CLUSTER_CHOICE" == "1" ] && echo "OPENSHIFT_PASSWORD=$ADMIN_PASSWORD")
EOF

echo -e "\n${GREEN}Setup completed successfully!${NC}"
echo -e "Container registry details:"
echo -e "  Registry URL: ${BOLD}$ACR_LOGIN_SERVER${NC}"
echo -e "  Username: ${BOLD}$ACR_USERNAME${NC}"
echo -e "  Password: ${BOLD}$ACR_PASSWORD${NC}"

echo -e "\n${BOLD}To log in to your container registry:${NC}"
echo "docker login $ACR_LOGIN_SERVER -u $ACR_USERNAME -p $ACR_PASSWORD"

echo -e "\n${BOLD}Next steps:${NC}"
echo "1. Use docker-compose to run and test the application locally"
echo "2. Complete the migration challenges outlined in the hackathon guide"
echo -e "\nEnvironment variables have been saved to: ${BOLD}.env${NC}"
echo "You can load them using: source .env"