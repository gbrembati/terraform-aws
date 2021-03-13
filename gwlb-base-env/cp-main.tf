# Create a VPC for our management
resource "aws_vpc" "vpc-checkpoint" {
  cidr_block       = "10.50.0.0/22"
  tags = {
    Name = "vpc-${var.vpc-checkpoint}"
    "Resource Group" = "rg-${var.vpc-checkpoint}"
  }
}
resource "aws_route_table" "rt-main-vpc-checkpoint" {
  vpc_id  = aws_vpc.vpc-checkpoint.id

  tags = {
    Name = "rt-main-vpc-${var.vpc-checkpoint}"
    "Resource Group" = "rg-${var.vpc-checkpoint}"
  }
  depends_on = [aws_vpc.vpc-checkpoint]
}
resource "aws_main_route_table_association" "rt-to-vpc-checkpoint" {
  vpc_id         = aws_vpc.vpc-checkpoint.id
  route_table_id = aws_route_table.rt-main-vpc-checkpoint.id
  depends_on = [aws_route_table.rt-main-vpc-checkpoint]  
}

resource "aws_security_group" "nsg-cp-allow-all" {
  name        = "nsg-${var.vpc-checkpoint}"
  description = "Allow inbound/outbound traffic"
  vpc_id      = aws_vpc.vpc-checkpoint.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "nsg-vpc-${var.vpc-checkpoint}"
    "Resource Group" = "rg-${var.vpc-checkpoint}"
  }
  depends_on = [aws_vpc.vpc-checkpoint]
}

# Create the subnets
resource "aws_subnet" "net-pub-checkpoint" {
  vpc_id     = aws_vpc.vpc-checkpoint.id
  availability_zone = "${var.region}a"
  cidr_block = "10.50.0.0/24"

  tags = {
    Name = "net-${var.vpc-checkpoint}-untrust"
    "Resource Group" = "rg-${var.vpc-checkpoint}"
  }
  depends_on = [aws_vpc.vpc-checkpoint]
}
resource "aws_subnet" "net-priv-checkpoint" {
  vpc_id     = aws_vpc.vpc-checkpoint.id
  availability_zone = "${var.region}a"
  cidr_block = "10.50.1.0/24"

  tags = {
    Name = "net-${var.vpc-checkpoint}-trust"
    "Resource Group" = "rg-${var.vpc-checkpoint}"
  }
  depends_on = [aws_vpc.vpc-checkpoint]
}

# The IGW for the subnets w/ routing
resource "aws_internet_gateway" "net-pub-igw" {
  vpc_id = aws_vpc.vpc-checkpoint.id
  tags = {
    Name = "igw-vpc-${var.vpc-checkpoint}"
    "Resource Group" = "rg-${var.vpc-checkpoint}"
  }
  depends_on = [aws_vpc.vpc-checkpoint]
}
resource "aws_route_table" "rt-vpc-checkpoint" {
  vpc_id = aws_vpc.vpc-checkpoint.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.net-pub-igw.id
  }
  tags = {
    Name = "rt-net-${var.vpc-checkpoint}-untrust"
    "Resource Group" = "rg-${var.vpc-checkpoint}"
  }
  depends_on = [aws_vpc.vpc-checkpoint,aws_internet_gateway.net-pub-igw]
}
resource "aws_route_table_association" "rt-to-public" {
  subnet_id      = aws_subnet.net-pub-checkpoint.id
  route_table_id = aws_route_table.rt-vpc-checkpoint.id
  depends_on = [aws_subnet.net-pub-checkpoint,aws_route_table.rt-vpc-checkpoint]  
}
resource "aws_resourcegroups_group" "resource-group-env" {
  name = "rg-${var.vpc-checkpoint}"

  resource_query {
    query = <<JSON
    {
      "ResourceTypeFilters": [
        "AWS::AllSupported"
      ],
      "TagFilters": [
        {
          "Key": "Resource Group",
          "Values": ["rg-${var.vpc-checkpoint}"]
        }
      ]
    }
    JSON
  }
}

resource "aws_cloudformation_stack" "cft-gwlb-checkpoint" {
  name = "cft-${var.gateway-name}"
  template_url = "https://cgi-cfts-staging.s3.amazonaws.com/custom/gwlb-master.yaml"
  
  parameters = {
    AcceptConnectionRequired= "false"
    AdminCIDR               = "0.0.0.0/0"
    AdminEmail              = ""
    AllowUploadDownload     = "true"
    AvailabilityZones       = "${var.region}a,${var.region}b"
    CloudWatch              = "false"
    ControlGatewayOverPrivateOrPublicAddress = var.gateway-connection
    CrossZoneLoadBalancing  = "true"
    EnableInstanceConnect   = "true"
    EnableVolumeEncryption  = "true"
    GWLBName                = "elb-${var.gateway-name}"
    GatewayInstanceType     = "c5.large"
    GatewayManagement       = "Locally managed"
    GatewayName             = var.gateway-name
    GatewayPasswordHash     = var.admin-pwd-hash
    GatewaySICKey           = var.gateway-sic
    GatewayVersion          = var.gateway-version
    GatewaysAddresses       = "0.0.0.0/0"
    GatewaysMaxSize         = "3"
    GatewaysMinSize         = "2"
    GatewaysPolicy          = var.policy-pkg-gwlb
    HealthPort              = "8117"
    HealthProtocol          = "TCP"
    KeyName                 = var.ckpgw-keypair
    ManagementDeploy        = "false"
    ManagementInstanceType  = "m5.xlarge"
    ManagementPasswordHash  = var.admin-pwd-hash
    ManagementVersion       = var.gateway-version
    NumberOfAZs             = "2"
    ProvisionTag            = var.cme-provision-tag
    PublicSubnet1CIDR       = "10.60.0.0/24"
    PublicSubnet2CIDR       = "10.60.1.0/24"
    PublicSubnet3CIDR       = "10.60.2.0/24"
    PublicSubnet4CIDR       = "10.60.3.0/24"
    Shell                   = "/bin/bash"
    TargetGroupName         = "tg-${var.gateway-name}"
    VPCCIDR                 = var.vpc-checkpoint-cidr
  }
  tags = {
    "Resource Group" = "rg-cft-${var.gateway-name}"
  }
}
resource "aws_resourcegroups_group" "resource-group-ckpgwlb" {
  name  = "rg-cft-${var.gateway-name}"

  resource_query {
    query = <<JSON
    {
      "ResourceTypeFilters": [
        "AWS::AllSupported"
      ],
      "TagFilters": [
        {
          "Key": "Resource Group",
          "Values": ["rg-cft-${var.gateway-name}"]
        }
      ]
    }
    JSON
  }
}

resource "aws_vpc_endpoint" "gwlb-spoke-endpoint" {
  count             = length(var.spoke-env)
  service_name      = aws_cloudformation_stack.cft-gwlb-checkpoint.outputs.GWLBServiceName
  subnet_ids        = [aws_subnet.net-gwlbe-spoke[count.index].id]
  vpc_endpoint_type = "GatewayLoadBalancer"
  vpc_id            = aws_vpc.vpc-spoke[count.index].id
  
  tags = {
    Name = "gwlb-${lookup(var.spoke-env,count.index)[0]}-endpoint"
    "Resource Group" = "rg-${lookup(var.spoke-env,count.index)[0]}"
  }
  depends_on = [aws_subnet.net-gwlbe-spoke,aws_cloudformation_stack.cft-gwlb-checkpoint]
}

resource "aws_vpc_peering_connection" "peering-checkpoint-to-gwlb" {
  peer_vpc_id   = aws_vpc.vpc-checkpoint.id
  vpc_id        = aws_cloudformation_stack.cft-gwlb-checkpoint.outputs.VPCID
  auto_accept   = true

  tags = {
    Name = "peering-vpc-checkpoint-to-vpc-tgw"
    "Resource Group" = "rg-${var.vpc-checkpoint}"
  }
  depends_on = [aws_vpc.vpc-checkpoint,aws_cloudformation_stack.cft-gwlb-checkpoint]
}
resource "aws_route" "route-from-checkpoint-to-gwlb" {
  route_table_id            = aws_route_table.rt-vpc-checkpoint.id
  destination_cidr_block    = var.vpc-checkpoint-cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peering-checkpoint-to-gwlb.id
  depends_on                = [aws_route_table.rt-vpc-checkpoint,aws_vpc_peering_connection.peering-checkpoint-to-gwlb]
}

output "gwlb-cme-template" {
    description = "Use this template name"
    value = aws_cloudformation_stack.cft-gwlb-checkpoint.outputs.ConfigurationTemplateName
    depends_on = [aws_cloudformation_stack.cft-gwlb-checkpoint]
}
output "gwlb-cme-controller" {
    description = "Use this controller name"
    value = aws_cloudformation_stack.cft-gwlb-checkpoint.outputs.ControllerName
    depends_on = [aws_cloudformation_stack.cft-gwlb-checkpoint]
}

resource "aws_cloudformation_stack" "cft-iam-management" {
  name = "cft-iam-management"
  template_url = "https://cgi-cfts.s3.amazonaws.com/iam/cme-iam-role.yaml"
  
  parameters = {
    Permissions     =	var.iam-role-mgmt
  # STSRoles	      = ""
  # TrustedAccount  = ""
  }
  tags = {
    "Resource Group" = "rg-cft-iam-management"
  }
  capabilities = ["CAPABILITY_IAM"]
}

resource "aws_iam_policy" "iam-policy-gwlb" {
  name        = "iam-policy-gwlb"
  description = "Permission required by CME w/ GWLB"

  policy = jsonencode({
   "Version": "2012-10-17",
   "Statement": [
      {
         "Action": [
            "ec2:DescribeInternetGateways",
            "ec2:DescribeVpcEndpoints",
            "ec2:DescribeVpcEndpointServiceConfigurations",
            "ec2:CreateRoute",
            "ec2:ReplaceRoute",
            "ec2:DeleteRoute",
            "ec2:CreateRouteTable",
            "ec2:AssociateRouteTable",
            "ec2:CreateTags",
            "ec2:DescribeSubnets",
            "ec2:DescribeTags"
         ],
         "Resource": "*",
         "Effect": "Allow"
      }
   ]
 })
}

resource "aws_iam_policy_attachment" "iam-attachment-cme-gwlb" {
  name       = "iam-attachment-cme-gwlb"
  roles      = [aws_cloudformation_stack.cft-iam-management.outputs.CMEIAMRole]
  policy_arn = aws_iam_policy.iam-policy-gwlb.arn
  depends_on = [aws_iam_policy.iam-policy-gwlb,aws_cloudformation_stack.cft-iam-management]
}

resource "aws_cloudformation_stack" "cft-cp-management" {
  name = "cft-${var.mgmt-name}"
  template_url = "https://cgi-cfts.s3.amazonaws.com/management/management.yaml"
  
  parameters = {
    AdminCIDR	                = "0.0.0.0/0"
    AllocatePublicAddress     =	"true"
    AllowUploadDownload	      = "true"
    EnableInstanceConnect	    = "true"
    GatewayManagement	        = "Locally managed" # or "Over the internet"
    GatewaysAddresses         =	"0.0.0.0/0"
    KeyName	                  = var.ckpgw-keypair
    ManagementHostname	      = var.mgmt-name
    ManagementInstanceType	  = var.mgmt-size
    ManagementName	          = var.mgmt-name
    ManagementPasswordHash	  = var.admin-pwd-hash
    ManagementPermissions	    = "Use existing (specify an existing IAM role name)"
    ManagementPredefinedRole	= aws_cloudformation_stack.cft-iam-management.outputs.CMEIAMRole
    ManagementSubnet	        = aws_subnet.net-pub-checkpoint.id
    ManagementVersion	        = var.mgmt-version
    NTPPrimary	              = "169.254.169.123"
    NTPSecondary	            = "0.pool.ntp.org"
    PrimaryManagement	        = "true"
    Shell	                    = "/bin/bash"
    VPC	                      = aws_vpc.vpc-checkpoint.id
    VolumeEncryption          = "alias/aws/ebs"
    VolumeSize	              = "100"
    ManagementSICKey	        = ""
    ManagementSTSRoles	      = ""    
    ManagementBootstrapScript	= "mgmt_cli -r true set api-settings accepted-api-calls-from 'All IP addresses' --domain 'System Data'; api restart"
  }
  capabilities = ["CAPABILITY_IAM"]
  tags = {
    "Resource Group" = "rg-cft-${var.mgmt-name}"
  }
  depends_on = [aws_cloudformation_stack.cft-iam-management]
}
resource "aws_resourcegroups_group" "resource-group-mgmt" {
  name  = "rg-cft-${var.mgmt-name}"

  resource_query {
    query = <<JSON
    {
      "ResourceTypeFilters": [
        "AWS::AllSupported"
      ],
      "TagFilters": [
        {
          "Key": "Resource Group",
          "Values": ["rg-cft-${var.mgmt-name}"]
        }
      ]
    }
    JSON
  }
}

resource "aws_route53_record" "dns-zone-ckpmgmt" {
  zone_id = aws_route53_zone.dns-zone.zone_id
  name    = "${var.mgmt-name}.${var.dns-zone}"
  type    = "A"
  ttl     = "30"
  records = [aws_cloudformation_stack.cft-cp-management.outputs.PublicAddress]
  depends_on = [aws_cloudformation_stack.cft-cp-management]
}

output "management-pub-ip" {
    description = "That's you management IP"
    value = aws_cloudformation_stack.cft-cp-management.outputs.PublicAddress
    depends_on = [aws_cloudformation_stack.cft-cp-management]
}