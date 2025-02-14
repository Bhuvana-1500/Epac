data "azurerm_management_group_policy_assignment" "mgmtrev" {
  name               = "mgmt0"
  management_group_id = "/providers/Microsoft.Management/managementGroups/mgmt0"
}
