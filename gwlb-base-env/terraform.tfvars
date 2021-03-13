# Set in this file your deployment variables
region          = "eu-west-1"
aws-access-key  = "xxxxxxxxxxxx"
aws-secret-key  = "xxxxxxxxxxxx"
aws-account-id  = "xxxxxxxxxxxx"

vpc-checkpoint  = "checkpoint"
admin-pwd-hash  = "xxxxxxxxxxxx"
linux-keypair   = "key-xxxxx-ireland"
ckpgw-keypair   = "key-xxxxx-ireland"
dns-zone        = "aws.<yourdomain>.com"

spoke-env       = {
        0 = ["spoke-dev","10.10.0.0/22","10.10.0.0/24","10.10.1.0/24","10.10.2.0/24"]
        1 = ["spoke-prod","10.20.0.0/22","10.20.0.0/24","10.20.1.0/24","10.20.2.0/24"]
      # 2 = ["spoke-name","vpc-net/cidr","net-gwlbe/cidr","net-untrust/cidr","net-trust/cidr"]
    }
