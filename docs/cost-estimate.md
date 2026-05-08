This document provides a rough monthly cost -estimate for the Secure_File_Portal project.

The goal is not to predict aan exact AWS bill, but to: 
- understand which services generate cost
- explain why costs stay low by design
- highlight where costs would increase at scale

All estimates assume **light, lab-scale usage** and are meant for learning and architectural evaluation.

### Assumptions

The estimates below are based on the following assumptions:

- Region: us-east-1
- Users: between 5 -10
- Files stored: up to 5 GB total
- Average file size: between 5-10 MB
- Upload/downloads: up to 50/day
- Alerts: rare (only on abnormal behavior)

Real-world usage will change these numbers.

### Service-by-service breakdown

### Amazon S3 (Vault Bucket)

**What is billed**
- Storage (GB per month)
- PUT, GET, LIST requests
- Versioning storage overhead

**Why costs stay low**
- Small data volume
- No public access
- Lifecycle rules control old versions

**Estimated monthly cost**
- Storage (5 GB): approximately $0.12
- Requests: <$0.50
- Versioning overhead: negligible at this scale

** Estimated total: approximately $1/month

### AWS KMS (Customer-Managed Key)

**What is billed**
- One CMK/month
- Encrypt/decrypt requests made by S3

**Why costs stay predictable**
- S3 handles encryption automatically
- KMS calls scale with object access, not file size

**Estimated monthly cost**
- CMK: approximately $1.00
- Requests: <$0.10

** Estimated total: approximately $1-$1.50/month**

### AWS Lambda

**What is billed**
- Function invocations
- Execution time (milliseconds)

**Why cots are very low**
- Lambda only generates pre-signed URLs
- No file data is processed
- Execution time is extremly short

**Estimated monthly cost**
- Invocations: <$0.01
- Compute time: effectively free at this scale

**Estimated total: <$0.10/month**

### API Gateway (HTTP API)

**What is billed**
- Request to the presign endpoint

**Why cost stays low**
- Only lightwight API calls
- No file uploads through the API

**Estimated monthly cost**
Up to 1,500 requests/month: approxmately $1.50

**Estimated total: between $1-$2/month**

### Amazon Cognito

**What is billed**
- Monthly active users (MAUs)

**Why costs are minimal**
- First 50,000 MAU are free

**Estimated monthly cost**
- $0

### AWS CloudTrail (S3 Data Events)

**What is billed**
- Data events for S3 object access

**Why this is a known cost**
- Required for visibility and auditing
- Explitely enabled

**Estimated monthly cost**
- Light usage: between $1-$2

**Estimated total: between $1-$2/month**

### Amazon CloudWatch

**What is billed**
- Metric filters
- Alarms

**Why costs stay low**
- Few metrics
- Simple threshold

**Estimated monthly cost**
between $0.50 - $1.0

### Amazon SNS (Email Alerts)

**What is billed**
- Notification deliveries

**Why cost is negligible**
- Alerts are rare by design

**Estimated monthly cost**
<$0.10

### Estimated total for all services used: $6-$8 per month 


 
