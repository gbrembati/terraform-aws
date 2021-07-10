variable gateway-connection {
    description = "Where do you want to manage the gw from? private or public"
    type = string
    default = "private"
}
variable gateway-name {
    description = "Choose the name"
    type = string
    default = "gwlb-ckpgateway"
}
variable gateway-size {
    description = "Choose the size"
    type = string
    default = "c5.xlarge"
}
locals { // locals for 'gateway-size' allowed values
    gateway-size_allowed_values = ["c5.large", "c5.xlarge", "c5.2xlarge", "c5.4xlarge", "c5.9xlarge", "c5.18xlarge", "c5n.large", "c5n.xlarge", "c5n.2xlarge", "c5n.4xlarge", "c5n.9xlarge", "c5n.18xlarge"]
    // will fail if [var.gateway-size] is invalid:
    validate_gateway-size = index(local.gateway-size_allowed_values, var.gateway-size)
}
variable gateway-version {
    description = "Choose the Release"
    type = string
    default = "R80.40-BYOL"
}
locals { // locals for 'gateway-version' allowed values
    gateway-version_allowed_values = ["R80.40-BYOL", "R80.40-PAYG-NGTP", "R80.40-PAYG-NGTX", "R81-BYOL", "R81-PAYG-NGTP", "R81-PAYG-NGTX"]
    // will fail if [var.gateway-version] is invalid:
    validate_gateway-version = index(local.gateway-version_allowed_values, var.gateway-version)
}

variable gateway-sic {
    description = "Choose the SIC"
    type = string
    sensitive = true
    default = "xxxxxxx"
}

variable ckpgw-keypair {
    description = "Choose the name of the keypair created"
    type = string
    default = "key-xxxxxx"
}

variable mgmt-name {
    description = "Choose the name"
    type = string
    default = "ckpmgmt"
}
variable mgmt-size {
    description = "Choose the size"
    type = string
    default = "m5.xlarge"
}
locals { // locals for 'mgmt-size' allowed values
    mgmt-size_allowed_values = ["m5.large", "m5.xlarge", "m5.2xlarge", "m5.4xlarge", "m5.12xlarge", "m5.24xlarge"]
    // will fail if [var.mgmt-size] is invalid:
    mgmt-size = index(local.mgmt-size_allowed_values, var.mgmt-size)
}

variable mgmt-version {
    description = "Choose the Release"
    type = string
    default = "R80.40-BYOL"
}
variable admin-pwd-hash {
    description = "The hash can be get with 'openssl passwd -1 PASSWORD'"
    type = string
    default = "xxxxxxxx"
}
variable iam-role-mgmt {
    description = "Choose which type of IAM Role you want to build"
    type = string
    default = "Create with read permissions"
}
locals { // locals for 'iam-role-mgmt' allowed values
    iam-role-mgmt_allowed_values = ["Create with read permissions", "Create with read-write permissions", "Create with assume role permissions (specify an STS role ARN)"]
    // will fail if [var.iam-role-mgmt] is invalid:
    iam-role-mgmt = index(local.iam-role-mgmt_allowed_values, var.iam-role-mgmt)
}

variable vpc-checkpoint {
    description = "Choose the name of the Management VPC"
    type = string
    default = "checkpoint"
}
variable vpc-checkpoint-cidr {
    description = "Choose the CIDR of the Management VPC"
    type = string
    default = "10.60.0.0/22"
}
variable "policy-pkg-gwlb" {
    description = "Define the name of your aws policy package"
    type = string
    default = "pkg-gwlb-ingress"
}
variable "cme-provision-tag" {
    description = "Define the name of your aws cme template"
    type = string
    default = "ckpgwlb"
}