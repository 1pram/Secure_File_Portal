# Architecture

The Secure File Portal is a zero-trust, infrastructure-first file storage system.

### 1. Service inventory

This project uses the following AWS services:

**Amazon S3**: Vault bucket for user files + Trail bucket for CloudTrail logs
**AWS KMS**: Customer-managed CMK for encryption
**AWS IAM**: Least privilege roles and prefix-restricted policies
**Amazon Cognito**: User Pool + Identity Pool (simplified mapping)
**AWS Lambda**: Pre-signed URL generator
**Amazon API Gateway**: Public endpoint forwarding to Lambda
**AWS CloudTrail**: Management events + S3 data events
**Amazon CLoudWatch logs**: Log storage
**Amazon CloudWatch Metrics & Alarms**: Download surge detection
**Amazon SNS** Email alerts
**Teraform (archive/random providers)** Packaging Lambda + unique naming

### 2. Storage & Encryption

### Vault bucket (Primary Storage)
- Private S3 bucket for user files
**SSE-KMS enforced**: ('aws:kms') with a dedicated CMK
**Bucket Key enabled**: to reduce KMS cost
**Versioning enabled**: for recovery & forensics

### Public Access Block (all required)

BlockPublicAcls     = true
IgnorePublicAcls    = true
BlockPublicPolicy   = true
estrictPublicBucket = true

These prevent Capital-One style public bucket exposure.

### CloudWTrail Bucket (Log Storage)
- Separate bucket for CloudTrail logs
- Versioning enabled
- Restricted to CloudTrail + a security role only

### AWS KMS (Customer-Managed CMK)
- Automatic key rotation enabled
- Only S3, CloudTrail, and explicietly defined IAM roles can use the CMK
- Ensures all objects (vault + logs) remain encrypted at rest

### 3. IAM &Authorization Model

The project intentionally uses a **simplified authorization model** to focus on infrstructure control

### Current (Portfolio) Model
- All Cognito-authenticated users map to a **single IAM role** via the Identity Pool
- IAM restricts users to the **'docs/viewer/' prefix**
- IAM policies for 'docs/editor/' and 'docs/admin/' exist but are **not mapped**

This demonstrates ** prefix-level least privilege** and **defense in-depth** even with simplifiefd identity logic.

### Why this matters
Even if Lambda is overly permissive, **S3 + IAM** still enforce strict boundary controls.

### Production Evolution
- Add Cognito groups: Viewers, Editors, Admins
- Map groups -> roles via the identity Pool
- Enforce MFA for elevated roles
- Lambda validates 'cognito:groups' claims

### 4. Cognito Authentication

Cognito is used for basic sign-up/sign-in:

- **Cognito User Pool** for authentication
- **Cognito Identity Pool** for AWS credential issuance (Viewer role)
- MFA is **optional** in this project

### Planned enhancement
- Enforce MFA
- Mp user groups to IAM roles
- Add a JWT authorizer at API Gateway

### 5. API Gateway + Lambda (Pre-Signed URL System)

### API Gateway
- HTTP API
- ** No JWT authorizer configured** (design simplification)
- All calls forwarded directly lambda

### Lambda (Python Function)
Responsible for:

- Accepting JSON payloads:
  '''jason
  { "action": "put" | "get", "key": "...", "expires": 300}

- Validating the key prefix
- Generating short-lived **pre-signed URLs** (typically 300-900 seconds)
- Logging request metadata
- Respecting S3 + IAM policies (cannot override them)

  Lambda is packaged using Terraform 'archive_file' data source.

### 6. Logging, Monitoring & Alerting

### CloudTrail

- Multi-region
- **S3 data events enabled** for the vault bucket
- Logs delivered to a dedicated tril bucket
- versioning + validation enabled

This ensures every upload, download, and delete is captured.

### CloudWatch Metrics & Alarms
A metric filter counts high-velocity events (downloads or presign calls)

### Alarm: *Excess Downloads*
- Fires on **100+ accesses in 5minutes**
- Sends 'ALARM' state to SNS
   
### SNS Alerts

- SNS topic sends email notifications
- Requires manual subscription confirmation

### 7. Lifecycle Management & Cost Optimization

Vault bucket lifecycle rules:

- Day 30  -> Transition to **Standard_IA**
- Day 90 -> Transition to **Glacier**
- Day 365 -> Expire

This provides reletively 83% lower Long-term storage cost.

Trail bucket may use similar tiering depending on configuration.


### 8. Design Trade-offs (Intentional Simplifications)

To emphasize infrastructure security over product completeness:

- **Single Viewer IAM role** for all authenticated users
- **No JWT aythorizer** at API Gateway
- **No WAF, SIEM integration, dashboards, or web UI**

These constraints allow focus on mastering:

- Encryption
- IAM Least privilege & prefix control
- CloudTrail data events
- Lifecycle management
- Monitoring & alerting

### 9. Summary

'architecture.md' captures:

- What each AWS component does
- How they fit together
- Which constraints are intentional
- How the design fails **closed** by default

