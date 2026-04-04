#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: ./deploy.sh <workflow-folder> <resource-group> [--what-if] [key=value ...]"
  exit 1
fi

workflow_folder="$1"
resource_group="$2"
shift 2

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
template_file="$script_dir/$workflow_folder/template.json"

if [[ ! -f "$template_file" ]]; then
  echo "Template not found: $template_file"
  exit 1
fi

timestamp="$(date +%Y%m%d%H%M%S)"
safe_name="${workflow_folder//[^a-zA-Z0-9-]/-}"
deployment_name="$safe_name-$timestamp"

echo "Deploying $workflow_folder to resource group $resource_group"
az deployment group create \
  --resource-group "$resource_group" \
  --name "$deployment_name" \
  --template-file "$template_file" \
  "$@"