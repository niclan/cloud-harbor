# Posit Studio Connect infrastructure
This directory contains Terraform code to provision the required AWS infrastructure for Posit Studio Connect.

***The following resources are provisioned with this code:***
* VPC and networking
* IPSec tunnel towards VG's datacenters / BigIP.
* EC2 instance
* Postgres RDS database.
* Security groups.
* DNS entries.

## How to deploy changes
* Check out this repository on your machine.
* Make changes.
* Log into vg-insight AWS account (070941167498) in the eu-north-1 region through CLI.
* Run ```terraform init``` if you haven't done it before to install dependencies on your machine.
* Run ```terraform plan``` and inspect your proposed changes thorougly before proceeding to the next step.
* Run ```terraform apply``` to actually apply your changes.

## Terraform state
Terraform state is hosted on S3 in the vg-insight AWS account.
