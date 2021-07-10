variable region {
    description = "Where do you want to create stuff"
    type = string
    default = "eu-west-1"
}
variable aws-access-key {
    description = "AWS Access Key"
    type = string
    sensitive = true
    default = "xxxxxxxxxxxxx"
}
variable aws-secret-key {
    description = "AWS Secret Key"
    type = string
    sensitive = true
    default = "xxxxxxxxxxxxx"
}
variable dns-zone {
    description = "Set the name of your zone"
    type = string
    default = "aws.<yourdomain>.com"
}
variable spoke-env {
    description = "Set the name / the cidr of the VPC and of the networks that will be created inside"
    default = {
        0 = ["spoke-dev","10.10.0.0/22","10.10.0.0/24","10.10.1.0/24","10.10.2.0/24"]
        1 = ["spoke-prod","10.20.0.0/22","10.20.0.0/24","10.20.1.0/24","10.20.2.0/24"]
      # 2 = ["spoke-name","vpc-net/cidr","net-gwlbe/cidr","net-untrust/cidr","net-trust/cidr"]
    }
}

variable linux-keypair {
    description = "Set the name of the key you want to use"
    type = string
    default = "key-xxxxxx"
}
