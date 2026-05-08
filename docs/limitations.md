# Known limitations

The Secure File Protal is a focused  security project, not a full featured product. This document describes what it does not cover to set realistic expectations going forward.

### 1. Simplified authentication

Authentication and identity federation are intentionally kept simple or abstracted.

- No support for complex identity providers or SSO flows
- No fine grained per user access control
- No user self service features

The main goal was to deeply understand CloudTrail data events, KMS policies, S3 lifecycle management, and IAM based access patterns before layering in full identity complexity.

### 2. Minimal user interface

The project does not include:

- A polished web UI
- Drag and drop uploads
- Real time collaboration
- Mobile applications

Security depth was prioritized over UI breadth. This is a deliberate trade-off, especially for a portfolio piece aimed at cloud infrastructure oriented roles.

### 3. Single region deployment

The current design assumes:

- One AWS region
- No cross region replication for data or logs
- No multi region failover strategy

In a production environment you would likely want:

- Region redundancy
- Disaster recovery plans
- Considerations for data residency and regulatory constraints

### 4. Basic alerting only

Alerting uses:

- A single CloudWatch alarm
- One threshold on download volume
- A single SNS topic email subsription

It does not include:

- Rich correlation of events
- Integration with SIEM or SOAR platform
- Tiered incident severity nd escalation workflows

Those could be added later, but are out of scope for this initial project.

### 5. Limited abuse scenarios

The primary detection scenario is bulk download of objects.

This project does not fully model:
- Slow exfiltration over long time windows
- Insider misuse with legitimate access
- Data tagging and classification to drive policy decisions
- Ransomware style encryption of stored data

The design choices are aligned with the goals of highlighting infrastructure controls and fail closed behavior rather than covering every possible threat model.

### 6. Cost modeling assumptions

The cost figures in the narrative are based on:

- Low traffic workloads
- Small volumes of CloudTrail data events
- Modest S3 storage and access patterns

At higher scale, CloudTrail and S3 costs will rise and need closer management. Even so, they are still small compared to the cost of large breaches and regulatory fines.
