# ==============================================================================
# Lambda Function: Pre-Signed URL Generator
# ==============================================================================

import json
import os
import boto3
import time

s3 = boto3.client('s3')

BUCKET = os.environ["BUCKET"]
VIEWER_PREFIX = os.environ["VIEWER_PREFIX"]
EDITOR_PREFIX = os.environ["EDITOR_PREFIX"]
ADMIN_PREFIX = os.environ["ADMIN_PREFIX"]


def in_any(prefixes, key):
    """Check if key starts with any of the allowed prefixes"""
    return any(key.startswith(p) for p in prefixes)


def handler(event, context):
    """
    Generate pre-signed URLs for S3 operations
    
    Request body:
    {
        "action": "get" or "put",
        "key": "docs/viewer/file.pdf",
        "expires": 900  (optional, default 15 minutes)
    }
    """
    
    # Parse request body
    body = json.loads(event.get("body") or "{}")
    action = body.get("action")
    key = body.get("key")
    expires = int(body.get("expires", 900))  # Default: 15 minutes
    
    # Validate required parameters
    if not action or not key:
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "action and key required"})
        }
    
    # Extract user role from request context
    role_arn = (event.get("requestContext") or {}).get("identity", {}).get("userArn", "")
    
    # Determine allowed prefixes based on role
    allowed_prefixes = [VIEWER_PREFIX]
    
    if "editor-role" in role_arn:
        allowed_prefixes.append(EDITOR_PREFIX)
    
    if "admin-role" in role_arn:
        allowed_prefixes.extend([ADMIN_PREFIX, VIEWER_PREFIX, EDITOR_PREFIX])
    
    # Validate user has access to requested prefix
    if not in_any(allowed_prefixes, key):
        return {
            "statusCode": 403,
            "body": json.dumps({"error": "forbidden for this prefix"})
        }
    
    # Generate pre-signed URL
    try:
        if action == "get":
            url = s3.generate_presigned_url(
                ClientMethod='get_object',
                Params={'Bucket': BUCKET, 'Key': key},
                ExpiresIn=expires
            )
        elif action == "put":
            url = s3.generate_presigned_url(
                ClientMethod='put_object',
                Params={'Bucket': BUCKET, 'Key': key},
                ExpiresIn=expires
            )
        else:
            return {
                "statusCode": 400,
                "body": json.dumps({"error": "unknown action"})
            }
    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }
    
    # Return pre-signed URL
    return {
        "statusCode": 200,
        "body": json.dumps({
            "url": url,
            "expires_in": expires,
            "ts": int(time.time())
        })
    }