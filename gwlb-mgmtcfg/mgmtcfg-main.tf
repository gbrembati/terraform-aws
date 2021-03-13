terraform {
  required_providers {
    checkpoint = {
      source = "CheckPointSW/checkpoint"
      version = ">= 1.3.0"
    }
  }
}

# Connecting to ckpmgmt
provider "checkpoint" {
  server = var.ckp-mgmt-ip
  username = var.api-username
  password = var.api-password
  context = var.provider-context
  timeout = "180"
}

# Create the dynamic-obj: LocalGatewayInternal
resource "checkpoint_management_dynamic_object" "dyn-obj-local-int" {
  name = "LocalGatewayInternal"
  comments = "Created by Terraform"
  color = "orange"
}

# Create the dynamic-obj: LocalGatewayExternal
resource "checkpoint_management_dynamic_object" "dyn-obj-local-ext" {
  name = "LocalGatewayExternal"
  comments = "Created by Terraform"
  color = "orange"
}

# Create a new policy package
resource "checkpoint_management_package" "aws-policy-pkg" {
  name = var.new-policy-pkg
  comments = "Created by Terraform"
  access = true
  threat_prevention = true
  color = "orange"
}

# Create the AWS Datacenter
resource "checkpoint_management_run_script" "datacenter-aws" {
  script_name = "Install AWS DC"
  script = "mgmt_cli add data-center-server name '${var.aws-dc-name}-${var.region}' type 'aws' authentication-method 'role-authentication' region '${var.region}' color 'orange' comments 'Created by Terraform' --user '${var.api-username}' --password '${var.api-password}' --version '1.6'"
  targets = [var.ckp-mgmt-name]
  depends_on = [checkpoint_management_package.aws-policy-pkg]
}

# Publish the session after the creation of the objects
resource "checkpoint_management_publish" "post-dc-publish" {
  depends_on = [checkpoint_management_dynamic_object.dyn-obj-local-ext,checkpoint_management_dynamic_object.dyn-obj-local-int,checkpoint_management_package.aws-policy-pkg,checkpoint_management_run_script.datacenter-aws]
}
# Put the user.def file
resource "checkpoint_management_put_file" "mgmt-put-userdef" {
  file_path = "/home/admin/"
  file_name = "user.def.FW1"
  file_content = <<CONTENT
/*
 * (c) Copyright 1993-2008 Check Point Software Technologies Ltd.
 * All rights reserved.
 *
 * This is proprietary information of Check Point Software Technologies
 * Ltd., which is provided for informational purposes only and for use
 * solely in conjunction with the authorized use of Check Point Software
 * Technologies Ltd. products.  The viewing and use of this information is
 * subject, to the extent appropriate, to the terms and conditions of the
 * license agreement that authorizes the use of the relevant product.
 *
 * $RCSfile: user.def,v $ $Revision: 1.2.1488.1.4.1 $ $Date: 2004/03/03 17:01:14 $
 */

#ifndef __user_def__
#define __user_def__

cloud_balancer_ips=${var.gwlb-subnets-range};

#endif /* __user_def__ */
  CONTENT
  targets = [var.ckp-mgmt-name]
  depends_on = [checkpoint_management_publish.post-dc-publish]
}

# Cloud Management Extension uninstall
resource "checkpoint_management_run_script" "script-config-files" {
  script_name = "Setting Configuration files"
  script = file("files/setting-files.sh")
  targets = [var.ckp-mgmt-name]
  depends_on = [checkpoint_management_put_file.mgmt-put-userdef]
}

# Cloud Management Extension installation
resource "checkpoint_management_run_script" "cme-install" {
  script_name = "Installing the latest CME"
  script = file("files/cme_installation.sh")
  targets = [var.ckp-mgmt-name]
  depends_on = [checkpoint_management_run_script.script-config-files]
}
# Install the latest GA Jumbo Hotfix 
resource "checkpoint_management_run_script" "management-jhf-install" {
  script_name = "Download & Install latest JHF"
  script = "lock database override \n clish -c 'installer agent update not-interactive' \n clish -c 'installer check-for-updates not-interactive' \n clish -c 'installer download-and-install '${var.last-jhf}' not-interactive'"
  targets = [var.ckp-mgmt-name]
  depends_on = [checkpoint_management_run_script.cme-install]
}

output "ckpmgmt-cme-configuration" {
  value = "When the update is completed, use command on the management server: \n  yes | autoprov_cfg init AWS -mn 'ckpgwlb-management' -tn '${var.ckp-mgmt-template}' -otp '${var.gateway-sic}' -ver R80.40 -po '${var.new-policy-pkg}' -cn '${var.ckp-mgmt-controller}' -r '${var.region}' -iam; yes | autoprov_cfg set controller AWS -cn '${var.ckp-mgmt-controller}' -sg -ss; yes | autoprov_cfg set template -tn '${var.ckp-mgmt-template}' -ia -ips -av -ab"
  depends_on = [checkpoint_management_run_script.cme-install]
}