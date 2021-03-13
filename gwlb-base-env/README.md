# AWS Centralized Gateway Load-Balancer Architecture
This Terraform project is intended to be used as a template in a demonstration or to build a test environment.  
What it does is creating an infrastructure composed of four VPCs: one contains a Check Point management, two Spoke VPCs and one which contains a Gateway Load-Balancer configured to send the traffic to a Check Point Auto-Scaling Group for Inbound & Outbound protection.    
As per my deployments (made in France Ireland), this project creates all of the following in about __17 minutes__, where the actual creation time is about __7 minutes__ and the other __10 minutes__ are the time the management server takes to finish the First Time Configuration.   


## Which are the components created?
The project creates the following resources and combine them:
1. **Route53 DNS Zone**: A third level domain where the public-IP will be registered
2. **VPCs**: The VPC of the Check Point management / two Spoke VPCs / one that contains GWLB and ASG of Check Point Gateways
3. **Subnets**: Inside each of the VPCs (with the tags needed to make the inspections to the Check Point gateways)
4. **Internet Gateways**: In each of the VPCs an Internet Gateway is created
5. **Routing table**: associated with the subnets and VPCs, with the routes to the Internet Gateway
6. **Resource Group**: Per each of the resources is created a Resource Group to view them
7. **Vnet peering**: Between the management spoke and the GWLB one
8. **Network Security Groups**: associated with subnets and VMs, with the rules to allow the traffic
9. **Virtual machines**: An API-enabled Check Point R80.40 Management, Nginx-ready machines in the spokes and Autoscaling-group of Check Point R80.40 Security gateways
10. **Public IPs**: associated with the management and the spoke VMs
11. **Gateway Load-Balancer**: A gateway load-balancer configured to send the traffic via GENEVE to the Autoscaling-group
12. **Gateway Load-Balancer Endpoints**: In each of the Spoke VPCs an endpoint is created and connected to the GWLB    
    
All of the above is created by a mix of resources and three different [Check Point CloudFormation Templates](https://supportcenter.checkpoint.com/supportcenter/portal?eventSubmit_doGoviewsolutiondetails=&solutionid=sk111013)    

## Which are the outputs of the project?
The project gives as outputs the Public IP address of the management server as well as the GWLB controller and template tags to use in the configuration of the management server.   
    
__Warning:__ Once all of the project is created and you want to connect the gateways to the management, go to the _*GWLB route-table*_ created during the process and create a route to the management CIDR via the peering-connection (this is due to a limitation in CFT outputs).

## How to use it
The first thing that you want to do is to create EC2 Key-Pair that you will later need to connect to the EC2 Instances.
Then you would need to change the values inside the __*terraform.tfvars*__ file located in this directory.

```hcl
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
```
If you want (or need) to further customize other project details, you can change defaults in the different __*name-variables.tf*__ files.   
Here you will also able to find the descriptions that explains what each variable is used for.

## The Infrastructure is created with the following design:
![Architectural Design](/zimages/aws-gwlb-simple-env.jpg)