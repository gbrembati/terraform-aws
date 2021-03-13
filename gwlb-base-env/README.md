# AWS Centralized Gateway Load-Balancer Architecture
This Terraform project is intended to be used as a template in a demonstration or to build a test environment.  
What it does is creating an infrastructure composed of four VPCs: one contains a Check Point management, two Spoke VPCs and one which contains a Gateway Load-Balancer configured to send the traffic to a Check Point Auto-Scaling Group for Inbound & Outbound protection.    
As per my deployments (made in France Ireland), this project creates all of the following in about __15 minutes__, where the actual creation time is about half of it and the other 7/8 minutes are the time the management server takes to finish the First Time Configuration.   


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
9. **Virtual machines**: An API-enabled Check Point R80.40 Management, Nginx-ready machines in the spokes and Autoscaling-group of Check Point gateways
10. **Public IPs**: associated with the management and the spoke VMs
11. **Gateway Load-Balancer**: A gateway load-balancer configured to send the traffic via GENEVE to the Autoscaling-group
12. **Gateway Load-Balancer Endpoints**: In each of the Spoke subnets an endpoint is created and connected to the GWLB

## Which are the outputs of the project?
The project gives as outputs the Public IP address of the management server as well as the GWLB controller and template tags to use in the configuration of the management server.

## How to use it
The only thing that you need to do is changing the __*terraform.tfvars*__ file located in this directory.

```hcl
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
```
If you want (or need) to further customize other project details, you can change defaults in the different __*name-variables.tf*__ files.   
Here you will also able to find the descriptions that explains what each variable is used for.

## The infrastruction created with the following design:
![Architectural Design](/zimages/aws-gwlb-simple-env.jpg)