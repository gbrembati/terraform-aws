variable region {
    description = "Where do you want to connect the datacenter"
    type = string
    default = "eu-west-1"
}

variable api-username {
    description = "Set the username used to call the APIs"
    type = string
    default= "admin"
}
variable api-password {
    description = "Set the secret to auth to the mgmt server"
    type = string
    default = "xxxxxx"
}
variable provider-context {
    description = "It can be used either web_api or gaia_api"
    type = string
    default= "web_api"
}

variable gateway-sic {
    description = "Choose the SIC"
    type = string
    default = "xxxxxx"
}

variable ckp-mgmt-ip {
    description = "Put your public-ip"
    type = string
    default = "xx.xx.xx.xx"
}

variable new-policy-pkg {
    description = "Define the name of your azure policy package"
    type = string
    default = "pkg-gwlb-ingress"
}

variable aws-dc-name {
    description = "Define the name of your azure datacenter-object"
    type = string
    default = "aws-dc"
}

variable ckp-mgmt-template {
    description = "Provide the template name to configure the CME"
    type = string
    default = "ckpgwlb-template"
}
variable ckp-mgmt-controller {
    description = "Provide the controller name to configure the CME"
    type = string
    default = "ckpgwlb-controller"
}
variable ckp-mgmt-name {
    description = "Choose the name"
    type = string
    default = "ckpmgmt"
}
variable last-jhf {
    description = "Provide the name of the JHF to be installed"
    type = string
    default = "Check_Point_R80_40_JUMBO_HF_Bundle_T94_sk165456_FULL.tgz"
}
variable gwlb-subnets-range {
    description = "Specify the GWLB subnets ranges"
    type = string
    default = "{<10.60.0.0,10.60.0.255>, <10.60.1.0,10.60.1.255>}"
}