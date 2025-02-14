terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.100.0"
    }
  }
}

terraform {
  backend "azurerm" {
    resource_group_name  = "rg-web-eus"
    storage_account_name = "strepac"
    container_name       = "conepac"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  skip_provider_registration = true

  features {}  # Include at least one "features" block
  client_id = "9c2e5200-9c57-46ad-aacd-b087b4c1c5be"
  client_secret = "4Qr8Q~oMYsyr4944u2D0a-W6Op7IScyoqoLBUdfi"
  tenant_id = "30bf9f37-d550-4878-9494-1041656caf27"
  subscription_id = "13ba43d9-3859-4c70-9f8d-182debaa038b"
}

resource "azurerm_management_group" "root" {
  name                       = "mgmt0"
  display_name               = "mgmt0"
  subscription_id           = ["b1af8833-cc76-47d5-ac29-4f7d63cdb243"]
}

resource "azurerm_policy_definition" "standard_naming_convention_policy" {
  name               = "StandardNamingConventionPolicy"
  policy_type        = "Custom"
  mode               = "All"
  display_name       = "Standard Naming Convention Policy"
  management_group_id = azurerm_management_group.root.id

  metadata = <<METADATA
  {
    "category": "General"
  }
  METADATA

  parameters = <<PARAMETERS
  {
    "namePattern_resourceGroups": {
      "type": "String",
      "metadata": {
        "displayName": "namePattern_resourceGroups",
        "description": "Naming pattern for resource groups."
      },
      "defaultValue": "rg-env-loc"
    },
    "namePattern_virtualNetworks": {
      "type": "String",
      "metadata": {
        "displayName": "namePattern_virtualNetworks",
        "description": "Naming pattern for virtual networks."
      },
      "defaultValue": "vnet-test-loc"
    },
    "namePattern_subnets": {
      "type": "String",
      "metadata": {
        "displayName": "namePattern_subnets",
        "description": "Naming pattern for subnets."
      },
      "defaultValue": "snet-appname-env-loc"
    },
    "namePattern_databases": {
      "type": "String",
      "metadata": {
        "displayName": "namePattern_databases",
        "description": "Naming pattern for databases."
      },
      "defaultValue": "db-env-appname"
    },
    "namePattern_virtualMachines": {
      "type": "String",
      "metadata": {
        "displayName": "namePattern_virtualMachines",
        "description": "Naming pattern for virtual machines."
      },
      "defaultValue": "vm-appname-env-loc"
    }
  }
  PARAMETERS

  policy_rule = <<POLICY_RULE
  {
    "if": {
      "allOf": [
        {
          "field": "type",
          "in": [
            "Microsoft.Resources/subscriptions/resourceGroups",
            "Microsoft.Network/virtualNetworks",
            "Microsoft.Network/virtualNetworks/subnets",
            "Microsoft.Sql/servers/databases",
            "Microsoft.Compute/virtualMachines"
          ]
        },
        {
          "anyOf": [
            {
              "allOf": [
                {
                  "field": "type",
                  "equals": "Microsoft.Resources/subscriptions/resourceGroups"
                },
                {
                  "not": {
                    "allOf": [
                      {
                        "value": "[equals(length(split(parameters('namePattern_resourceGroups'), '-')), length(split(field('name'), '-')))]",
                        "equals": true
                      },
                      {
                        "value": "[equals(toLower(first(split(field('name'), '-'))), 'rg')]",
                        "equals": true
                      }
                    ]
                  }
                }
              ]
            },
            {
              "allOf": [
                {
                  "field": "type",
                  "equals": "Microsoft.Network/virtualNetworks"
                },
                {
                  "not": {
                    "allOf": [
                      {
                        "value": "[equals(length(split(parameters('namePattern_virtualNetworks'), '-')), length(split(field('name'), '-')))]",
                        "equals": true
                      },
                      {
                        "value": "[equals(toLower(first(split(field('name'), '-'))), 'vnet')]",
                        "equals": true
                      }
                    ]
                  }
                }
              ]
            },
            {
              "allOf": [
                {
                  "field": "type",
                  "equals": "Microsoft.Network/virtualNetworks/subnets"
                },
                {
                  "not": {
                    "allOf": [
                      {
                        "value": "[equals(length(split(parameters('namePattern_subnets'), '-')), length(split(field('name'), '-')))]",
                        "equals": true
                      },
                      {
                        "value": "[equals(toLower(first(split(field('name'), '-'))), 'snet')]",
                        "equals": true
                      }
                    ]
                  }
                }
              ]
            },
            {
              "allOf": [
                {
                  "field": "type",
                  "equals": "Microsoft.Sql/servers/databases"
                },
                {
                  "not": {
                    "allOf": [
                      {
                        "value": "[equals(length(split(parameters('namePattern_databases'), '-')), length(split(field('name'), '-')))]",
                        "equals": true
                      },
                      {
                        "value": "[equals(toLower(first(split(field('name'), '-'))), toLower(first(split(parameters('namePattern_databases'), '-'))))]",
                        "equals": true
                      }
                    ]
                  }
                }
              ]
            },
            {
              "allOf": [
                {
                  "field": "type",
                  "equals": "Microsoft.Compute/virtualMachines"
                },
                {
                  "not": {
                    "allOf": [
                      {
                        "value": "[equals(length(split(parameters('namePattern_virtualMachines'), '-')), length(split(field('name'), '-')))]",
                        "equals": true
                      },
                      {
                        "value": "[equals(toLower(first(split(field('name'), '-'))), 'vm')]",
                        "equals": true
                      }
                    ]
                  }
                }
              ]
            }
          ]
        }
      ]
    },
    "then": {
      "effect": "audit"
    }
  }
  POLICY_RULE
}

resource "azurerm_management_group_policy_assignment" "standard_naming_convention_policy_assignment" {
  name                 = "Standard Naming Policy"
  management_group_id  = azurerm_management_group.root.id
  policy_definition_id = azurerm_policy_definition.standard_naming_convention_policy.id
  display_name         = "Standard Naming Convention Policy"
}
