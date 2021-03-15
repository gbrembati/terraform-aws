# Check Point Management Configuration
This Terraform project is intended to be used as a template in a demonstration or to build a test environment.  
What it does is configuring an existing Check Point Management with few key components that are needed during a deployment in AWS deployment of a Centralized Gateway Load-Balancer architecture.    
 
## Which are the components created / configured?
The project creates the following resources and combine them:
1. **Dynamic Objects**: the objects created are *LocalGatewayInternal* and *LocalGatewayExternal*
2. **A policy package**: a new policy package to be applied to AWS GatewayLoadBalancer Auto-Scaling Group
3. **AWS Datacenter object**: thanks to the CloudGuard Controller and the Datacentr object we can use AWS-defined entities in the rulebase
4. **Config the user.def.FW1 file**: this allows the gateway to correctly answers to the GWLB health-checks 
5. **Install the CME**: the Cloud Management Extension is used to dynamically provision VMSS Gateways
6. **Update to a specified JHF**: it downloads and installs a specific Jumbo-Hotfix (by default : R80.40 Jumbo HotFix Take 91)   

## Which are the outputs of the project?
The projects gives as output the command to configure the CME to onboard the Autoscaling-group, all of the other results are visible on the management server (using the SmartConsole application).   
Once you will give the command to configure the Cloud Management Extension this will happen:
1. **Onboarding**: The management will automatically onboard the gateways: performing the policy install and enabling all the required blade
2. **Create the subnet objects and policies**: The CME will scan all of the subnets to look for the tags (x-chkp-gwlb-outbound / x-chkp-gwlb-inbound), and for the subnets tagged will create objects and policies automatically inside the policy just created, doing a policy install at the end
3. **Change the routing of the tagged subnets**: The CME will add the routes (from the subnet and the Internet Gateway perspective) pointing to the GWLB endpoint to perform the required inspections

## How to use it
The only thing that you need to do is changing the __*terraform.tfvars*__ file located in this directory.

```hcl
# Set in this file your deployment variables
region              = "eu-west-1"
api-username        = "admin"
api-password        = "xxxxxxxxxx"

aws-dc-name         = "aws-dc"
gateway-sic         = "xxxxxxxxxx"
new-policy-pkg      = "pkg-gwlb-ingress"

ckp-mgmt-name       = "ckpmgmt"
ckp-mgmt-ip         = "xx.xx.xx.xx"
ckp-mgmt-template   = "ckpgwlb-template"
ckp-mgmt-controller = "ckpgwlb-controller"

gwlb-subnets-range  = "{<10.60.0.0,10.60.0.255>, <10.60.1.0,10.60.1.255>}"
last-jhf            = "Check_Point_R80_40_JUMBO_HF_Bundle_T94_sk165456_FULL.tgz"
```
If you want (or need) to further customize other project details, you can change defaults in the different __*name-variables.tf*__ files.   
Here you will also able to find the descriptions that explains what each variable is used for.