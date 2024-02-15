# Infrastructure as Code - Terraform

# Google Cloud 

## Project Description:
This project automates the creation of a Virtual Private Cloud (VPC) network and two subnets (one for a web application and one for a database) in Google Cloud Platform using Terraform.

## Prerequisites
Before you begin, ensure you have the following installed:
1. Google Cloud SDK
2. Terraform

## To Install Terraform on mac:
1. Install the HashiCorp tap
> brew tap hashicorp/tap
2. Install Terraform'
> brew install hashicorp/tap/terraform
3. To update to the latest version of Terraform, first update Homebrew
> brew update
> brew upgrade hashicorp/tap/terraform
4. To verify Installation
> terraform -version

## Google cloud Setup:-
1. Sign up for a Google Cloud Platform account
2. Create a project in Google cloud
3. Enable Compute Engine API

## Instructions to run the project
1. Clone this repository into the local system 
> git clone url
2. Run the below terraform commands in the terminal
   
## Commands to run Terraform:
1. gcloud auth application-default login
2. terraform init
3. terraform init -upgrade
4. terraform fmt
5. terraform validate
6. terraform plan
7. terraform apply

### Other commands:
1. To clean up the resources created by Terraform, you can run:
> terraform destroy
2. To revoke gcloud access:
> gcloud auth application-default revoke
