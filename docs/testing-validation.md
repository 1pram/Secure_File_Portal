# Testing and validation
This guide validates every security control in the Secure_File_Portal.  It confirms that encryption, access control, logging, alerting, Lifecycle rules, and versioning behave as expected.

All tests are designed to be repeatable and portable, proving the infrastructure fails **closed** even when the defensive layers are breached.

### 1. Prerequisits

Before running tests:

### 1. Deploy the infrastructure
Terraform deployment must be complete and successful.

### 2. SN Ssubscription cofirmed
Check your email and confirm the SNS subscription.

### 3. Export environment variables
These will be used throguout the tests:

In the terminal via VSCode:
export VAULT_BUCKET=$(terraform output -raw vault_bucket)
export TRAIL_BUCKET=$(terraform output -raw cloudtrail_bucket)
export API_ENDPOINT=$(terraform output -raw api_endpoint)
export USER_POOL_ID=$(terreform output -raw cognito_user_id)
export LIENT_POOL_ID=$(terraform output -raw cognito_user_pool_client_id)

### 4. AWS CLI authenticated
in the terminal via VSCode
aws sts get-caller_identity

### 5. Tools
aws cli
curl
gzip jq for (CloudTrail log examination)

# 2. Test 1 (Bucket encryption)

The goal here is to confirm S3 vault bucket enforces SSE-KMS with CMK (Sever Side Encryption with AWS Key Management Service using Customer-Managed keys).

## Command:
In the terminal via VSCode you will type:
aws s3api get-bucket-encryption bucket "VAULT_BUCKET"

## Expected:
"SSEALgorithm": "aws:kms"
"BucketKeyEnabled": true
"KMSMasterKeyID" matches the CMK ARN

You are validating: encryption at rest, CMK enforcement, and Bucket key enabled.

# 3. Test 2 (Block public access)

The goal is to ensure the bucket cannot be made public.

## Check existing block
in the terminal via VSCode, you will type:
aws s3api get-public-access-block --bucket "VAULT_BUCKET"

## Expected:All true!
BlockPublicAcls
IgnorePublicAcls
BlockPublicPolicy
RestrictPublicBuckets

## Attempt to make public should fail.
in the terminal
aws s3api put-bucket-acl --bucket "VSULT_BUCKET --acl public-read

## Expected:
Accessdenied

# 4. Test 3 (Cognito user creation and authentication)
The goal is to verify cognito signup and signin workflow.

## 1. Sign-up user
In the terminal:
 aws cognito-idp sign-up \
 --client-id "$CLIENTID" \
 --username testuser@testing.com \
 --password 'Password12345!'

 ## 2. Admin confirm
 aws cognito-idp admin-confirm-signup \
 --user-pool-id "$USER_POOL_ID" \
 --username testuser@testingcom

 ## 3. Authenticate:
 aws cognito-idp initiate-auth \
 --auth-flow USER_PASSWORD_AUTH \ 
 --client-id "$CLIENT_ID" \
 --auth-parameters USERNAME=testuser@testing.com, PASSWORD=Password12345!

 ## Executed:
 - Password policy enforced
 - Confirmation required
- Returns AccessToken, IDToken, RefreshToken

# 5. Test 4 (Generate pre-signed URL)

 The goal is to validate Lambda+API Gateway are wired correctly.

## Command
In the terminal:
curl -X POST "$API_ENDPOINT/presign" \
-H "Content-Type: application/json \
-d '{
    "action":"put",
    "key":"docs/viewer/test-file.txt",
    "expires":300
  }'

## Expected:
- JSON response
- 'url' field with s3 pre-signed URl
- 'expires_in' matches request

# 6. Test 5 (Upload using pre-signed URL)

The goal is to confirm upload works and the the object is encrypted.

1. Create test file in the terminal:
echo "Secure File Portal"  > test-file.txt

2. Upload using provided URL:
curl -X PUT -T "test-file.txt" "Paste pre-signed URL here"

3. Inspect object:
aws s3api head-object \
--bucket "VAULT_bucket \
--bucket "docs/viewer/test-file.txt"

## Expected:
Object exists
- '"ServerSideEncryption":"aws:kms"'
- '"SSEKMSKeyId"' = CMK ARN

# 7. Test 6 (CloudTrail S3 Data events)

The goal is to ensure every S3 bucket access is logged.

1. Wait ~5 minutes (CloudTrail delivery line).
2. List CloudTrail files:

aws s3 ls "s3:/$TRAIL_BUCKET/AWSLogs/" --recursive | tail -10
In the terminal:

3. Download the newest log:
In te terminal:
 aws s3 cp "s3://$TRAIL_BUCKET/AWSLogs/.../your-latest-log.gz"
 gunzip your-latestlog.json.gz

4. Search for PutObject:
In the terminal:
jq 'select(.eventName=="PutObject")' your-latest-log.json

Expected:
- 'eventName': '"PutObject"'
- 'requestParameters.key' = '"docs/viwer/test-file.txt"'
- identity of caller captured

# 8. Test 7  (CloudWatch Alarm & SNS Alert)

The goal is to trigger the excess download alarms (100+ accesses in 5 minutes)

## Flood API Gateway
In the terminal:
for i in (1..110); do
curl -s -X POST "$API_ENDPOINT?presign" \
  -H "COntent-Type: application/json" \
  -d "{\"action\":\"get\",\"key\":\"docs/viewer/file${i}.txt\"}" > /dev/null

 if [ $($i % 10)) -eq 0 ]; then
   echo "Completed $i/110 requests..."
 fi
done 

## Check alarm:
In the terminal:
aws cloudwatch describe-alarms \
  --alarm-names "secure-file-portal-excess-downloads

Expected:
  - State = 'ALARM'
  - Datapoint ≥ 100

## Check email:
- SNS email with  alarm notification should appear within ~2 minutes.

# 9. Test 8 - IAM Prefix Enforcement

The goal is to ensure IAM blocks to unauthorized folders, even with pre-signed URL.

## Request a pre-signed GET for 'docs/editor/':
In the terminal:
curl -X POST "$API_ENDPOINT/presign" \
   -H "Content-Type: application/json" \
   -d '{
     "action":"get",
     "key":"docs/editor/secret.txt",
     "expires":300
    }'

## Attempt to use URL:
Should result in:

<error>
<Code>AccessDenied</Code>
<Message>Access Denied</Message>
</Error>

This proves defense in depth: IAM + S3 access even if Lambda misbehaves.

# 10. Test 9 (Lifecycle Configuration)
The goal is to Confirm lifecycle rules exist for transition + expiration.

## Command:
In the terminal:
aws s3api get-bucket-lifecycle-configuration \
  --bucket "$VAULT_BUCKET"

Expected:
- Transition to 'STANDARD_IA' at 30 days
- Transition to 'GLACIER' at 90 days
- Expiration at 365 days

Note: You can't observe actual transitions in a short testing testing window. Configuration presence is sufficient validation.

# 11. Test 10 (Versioning & Recovery)

Goal Validate versioning and delete markers

1. Upload two different versions:
In the terminal:
echo "v1" > version-test.txt
aws s3 cp version-tes.txt "s3://$VAULT_BUCKET/docs/viewer/version-test.txt"

echo "v2" > version-test.txt
aws s3 cp version-test.txt "s3://$VAULT_BUCKET/docs/viewer/version-test.txt"

2. List versions:
In the terminal:
aws s3api list-object-versions \
  --bucket "$VAULT_BUCKET" \
  --prefix "docs/viewer/version-test.txt

3. Delete object (creates delete marker)
In the terminal:
aws s3api delete-object \
  --bucket "$VAULT_BUCKET" \
  --key "docs/viewer/version-test.txt

4. Restore by removing delete marker:
In the terminal:
aws s3api delete-object \
  --bucket "$VAULT_BUCKET" \
  --version-id <DELETE_MARKER_VERSION_ID>

Expected:
- Multiple versions visible
- Multiple delete marker restores file

# 12. Summary Checklist

You should now be able to check off:
KMS encryption enforced
Public access blocked
Cognito user lifecycle working
Pre-sign URLs functional
Encrypted uploads validated
CloudTrail S3 data events captured
ClouWatch alarm triggered correctly
SNS alert received
IAM prefix restrictions enforced
Lifecycle rules present
Versioning and recovery tested

These tests collectively verify the system behaves exactly as intended and fails closed by default
