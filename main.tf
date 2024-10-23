data "azurerm_management_group" "this" {
  display_name = var.management_group_name
}

resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_user_assigned_identity" "this" {
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  name                = var.user_assigned_identity_name
}

resource "azurerm_role_assignment" "assignment" {
  scope                = data.azurerm_management_group.this.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.this.principal_id
}

resource "random_uuid" "this" {
  for_each = {
    for k, v in local.policies :
    basename(k) => v
  }
}

resource "azurerm_policy_definition" "this" {
  for_each = {
    for k, v in local.policies :
    basename(k) => jsondecode(file("${local.path_policies}${v}"))
  }

  name                = random_uuid.this[each.key].result
  policy_type         = each.value.properties.policyType
  mode                = each.value.properties.mode
  display_name        = each.value.properties.displayName
  description         = each.value.properties.description
  metadata            = jsonencode(each.value.properties.metadata)
  policy_rule         = jsonencode(each.value.properties.policyRule)
  parameters          = jsonencode(each.value.properties.parameters)
  management_group_id = data.azurerm_management_group.this.id
}

resource "azurerm_policy_set_definition" "this" {
  for_each = {
    for k, v in local.initiatives :
    k => jsondecode(file("${local.path_initiatives}${v}"))
  }

  name                = each.value.name
  policy_type         = "Custom"
  display_name        = each.value.properties.displayName
  description         = each.value.properties.description
  parameters          = jsonencode(each.value.properties.parameters)
  management_group_id = data.azurerm_management_group.this.id
  metadata            = jsonencode(each.value.properties.metadata)

  dynamic "policy_definition_reference" {
    for_each = each.value.properties.policyDefinitions

    content {
      policy_definition_id = azurerm_policy_definition.this[lookup(local.policy-reference-map, policy_definition_reference.value.policyDefinitionReferenceId)].id
      parameter_values     = jsonencode(policy_definition_reference.value.parameters)
    }

  }
}

resource "random_id" "this" {
  for_each = {
    for k, v in local.initiatives :
    basename(k) => v
  }
  byte_length = 16
}

resource "azurerm_management_group_policy_assignment" "this" {
  for_each = {
    for k, v in local.initiatives :
    k => jsondecode(file("${local.path_initiatives}${v}"))
  }

  name                = random_id.this[each.key].id
  management_group_id = data.azurerm_management_group.this.id
  policy_definition_id = azurerm_policy_set_definition.this[each.key].id
  description         = each.value.properties.description
  display_name        = each.value.properties.displayName
  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.this.id
    ]
  }
  location = var.location
  parameters = templatefile("${var.path_parameters}/${split(".", each.key)[0]}.param.json", {ALZMonitorResourceGroupName = var.resource_group_name, ALZMonitorResourceGroupLocation = var.location})
}