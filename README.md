# Secure File Portal

This project implements a **security-by-default file sharing system** that assumes the application layer can fail and ensures the infrastructure layer is equipped to fail closed.
 Rather than relying on application logic to protect sensitive data, access control, encryption, monitoring, and auditability are enforced **at the storage and control plane layers**, using AWS managed services and Infrastructure as Code.

 ## Why this project exists

 Several high-profile file-sharing breaches in recent years (OneDrive, Dropbox, Mega, and Google Drive) were not caused by novel exploitation techniques, but by infrastructure-level breakdowns:
 - over-privileged service roles
 - misconfigured access controls
 - encryption enforced inconsistently
 - limited detection of abnormal access patterns

 This project explores a different assumption:
Compromise is expected at every end of the architecture. For more on this, go to: [my Medium page](https://ipyram.medium.com/when-file-storage-fails-open-what-the-onedrive-dropbox-mega-and-google-drive-breaches-taught-me-126ef7ab5c49)

## High-level design

At a high level, the system works as follows:

1.	The user authenticates with Cognito
2.	Then requests a pre-signed URL from the application.
3.	Once issued, the user interacts directly with S3 using the URL (after access is granted, the API Gateway and Lambda step out of the way). 
4.	Authorization and access are enforced by S3 through the URL signature, bucket policy, evaluated IAM permissions, and KMS encryption requirements.
5.	File transfers can now begin between the user and S3
6.	All access is logged via CloudTrail and monitored by CloudWatch.

The result is a design where **authorization and enforcement live at the infrastructure layer**, not inside application code.

## Core security principles demonstrated

- Infrastructure-first security
- Least privilege by default
- Fail-closed access controls
- Separation of control plane and data plane
- Defense in-depth
- Reproducibility through Infrastructure as Code

## Key components

### Identity and access
- Amazon Cognito User Pool for authentication
- Cognito Identity Pool for temporary AWS credentials
- Single, scoped IAM viewer role
- Path-based access controls ('docs/viewer/*)

### Storage and encryption
- Private S3 vault bucket for user files
- Public access blocked at the bucket level
- Server-side encryption enforced with **customer managed KMS keys**
- Bucket versioning enabled for recovery and forensics
- Lifecycle rules for cost control

### Application layer
- API Gateway endpoint for pre-signed URL requests
- AWS Lambda function to generate short-lived URLs
- No file data handled by the application

### Monitoring and detection
- CloudTrail S3 data events enabled
- CloudWatch metric filters for abnormal access patterns
- SNS notifications for alerting
- Immutable audit trail stored separately

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

## What this project demonstrates

- How pre-signed URLs remove the application (API Gateway + Lambda) from the data path
- How S3 and KMS enforce access regardless of client behavior
- How Infrastructure-level guardrails reduce blast radius
- How security controls become reproducible when encoded as IaC
