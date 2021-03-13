# Set in this file your deployment variables
region          = "eu-west-1"
aws-access-key  = "xxxxxxxxxxxx"
aws-secret-key  = "xxxxxxxxxxxx"

linux-keypair   = "key-xxxxxxx"
dns-zone        = "aws.<yourdomain>.com"

spoke-env       = {
        0 = ["spoke-dev","10.10.0.0/22","10.10.0.0/24","10.10.1.0/24","10.10.2.0/24"]
        1 = ["spoke-prod","10.20.0.0/22","10.20.0.0/24","10.20.1.0/24","10.20.2.0/24"]
      # 2 = ["spoke-name","vpc-net/cidr","net-gwlbe/cidr","net-untrust/cidr","net-trust/cidr"]
    }

gateway-connection = "private"
gateway-name       = "gwlb-ckpgateway"
gateway-size       = "c5.xlarge"
gateway-version    = "R80.40-BYOL"
gateway-sic        = "xxxxxxx"
ckpgw-keypair      = "key-xxxxxxx"
admin-pwd-hash     = "xxxxxxxxxxxx"

mgmt-name          = "ckpmgmt"
mgmt-size          = "m5.xlarge"
mgmt-version       = "R80.40-BYOL"
iam-role-mgmt      = "Create with read permissions"

vpc-checkpoint     = "checkpoint"
vpc-checkpoint-cidr = "10.60.0.0/22"
policy-pkg-gwlb    = "pkg-gwlb-ingress"
cme-provision-tag  = "ckpgwlb"