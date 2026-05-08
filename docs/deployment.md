# Deployment Guide

This guide walks you through deploying the Secure File Portal using **Terraform**, a full build that includes all 11 AWS services: S3, KMS, IAM, Cognito, Lambda, API Gateway, CloudTrail, CloudWatch Metric filters, Allarms, and SNS.

### Tech Stack
- Vault bucket + Trail bucket (S3)
- Encryption via CMK (KMS)
- IAM least-privilege roles + prefix control
- Cognito User Poll + Identity Pool (Viewer-only mapping)
- Lambda function for pre-signed URLs
- API Gateway HTTP API
- CloudTrail with S3 data events
- CloudWatch metrics + alarm (100+ events in 5 minutes)
- SNS alert notifications
- Lifecycle rules & versioning
- Windows terminal
- VSCode

### Prerequisits

- Terraform **v1.5+**
- AWS CLI **v2**
- IAM permissions to create:
S3, KMS, IAM Roles + Policies, Cognito, Lambda, CloudTrail, CloudWatch, SNS, API Gateway

### Verify tools

From the Windows terminal, or VSCode and go to the terminal
terraform --version (to verify you have terraform properly installed)
aws --version (to verify you have terraform properly installed)
aws sts get-caller-identity (to verify connectivity to your AWS account)

### Clone your repository (or create a project folder)

 From the terminal
 git clone https://github.com/<your-repo>/secure-file-portal.git
 cd secure-file-portal
```
# 3. Project Structure
Secure_File_Portal/
|
|-- README.md
|
|-- providers.tf
|-- versions.tf
|-- variables.tf
|-- terraform.tfvars
|-- outputs.tf
|-- random.tf
|-- locals.tf
|
|-- kms.tf
|-- iam_roles.tf
|-- cognito.tf
|-- s3_vault.tf
|-- cloudtrail_monitoring.tf
|-- lambda_api.tf
|
|-- lambda/
| |-- main.py
|
|-- docs/
| |-- architecture.md
| |-- deployment.md
| |-- testing-validation.md
| |-- limitations.md
| |-- troubleshooting.md
|
|-- diagrams/
| |-- architecture.png
```
### Configure 'terraform.tfvars'

Create your variable file:

aws_region = "us-east-1"
project = "secure-file-portal"
alert_email = "Type your email here" # Required action: to fill out with a designated address for receiving alerts. SNS sends confirmation to this address.

mfa_secret = "JBSWY#DPEHPK#PXP" #optional for future MFA enforcement

vault_prefixes = {
    viewer = "docs/viewer/"
    editor = "docs/editor/"
    admin  = "docs/admin/"
}

### 5. Initialize Terraform

In the terminal via VSCode, type:
terraform init and press Enter

You should see:

"Terraform has been successfully initialized!
If provider version mismatch, update Terraform or your lock file accordingly."

### 6. Validate & Plan

### Validate syntax:

In the termninal via VSCode, type:
terraform validate and press Enter (proceed to troubleshoot any errors in your code where indicated)

### Generate the execution Plan

terraform plan and press Enter

Look for approximately:

"Plan: 42 to add, o to change, 0 to destroy"

You should also see S3 buckets, CloudTrail, IAM roles, Cognito pools, Lambda, API Gateway, SNS and metric filters in the plan.

### 7. Apply the infrastructure

Deploy everything by typing:

Terraform apply and typing "yes" when prompted.

On success, you should see outputs like:

api_endpoint               = "https://xxx.execute-api-use-east-1.amazon.com"
vault_bucket               = "secure-file-portal-vault-abc123"
cloudtrail_bucket          = "secure-fiel-portal-trail-xyz456"
cognito_user_pool_id       = "us-east-1_xxxxx"
cognito_identity_pool_id   = "us-east-1:xxxxxx-xxx"
cognito_domain             = "secure-file-portal-xxxx.auth.us-east-1.amazoncognito.com"

These values will be used for testing.

### 8. Confirm SNS subscription

Within 1-2 minutes of deployment, check your inbox for:
** AWS Notification -Subscription Confirmation**

Click **Confirm substription**.

You can verify in the terminal via VSCode:

aws sns list-subscriptions

The subscription should no longer show 'Pending Confirmation'.

### 9. Export Outputs as Environment variables

This will speed up testing later

export VAULT_BUCKET=$(terraform output -raw vault_bucket)
export TRAIL_BUCKET=$(terraform output -raw cloudtrail_bucket)
export API_ENDPOINT=$(terraform output -raw api_endpoint)
export user_POOL_ID=$(terraform output -raw cognito_user_pool_id)
export CLIENT_ID=$(terreform output -raw cognito_user_pool_client_id)

These correspond to the exact variables used in the TESTING.md guide.

### 10. Quick Smoke Test (Pre-signed API)

Send a test request:

curl -X POST "$API_ENDPOINT/presign" \
-H "Content-Type: application/json" \
-d '{"action":"put","key":"docs/viewer/test.txt,"expires":300}'

Expected return:

-JSON containing a **pre-signed S3 URL**
- 300 second expiry
- Timestamp metadata

If you get '"Internal Server Error"', Check Lambda logs:
aws logs tail /aws/lambda/secure-file-portal-presign --follow

### 11. Full Testing

Run the full suite in:

testing-validation.md

To validate:

- Encryption
- Bucket blocking (public access)
- Pre-signed upload/doanload workflow
- CVloudTrail logging
- Metric filtering + alarm
- SNS notifications
- IAM prefix enforcement
- Lifecycle configuration
- Versioning & recovery

### 12. Cleanup (Avoid charges)

When you're done, type the following in ther terminal via VSCode:
terraform destroy

If deletion fails due to versioned objects, follow the instructions in troubleshooting.md






