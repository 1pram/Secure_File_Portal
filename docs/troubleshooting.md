# Troubleshooting

A few issues you might run into while deploying or tearing down the Secure File Portal and how to ifx them.

### Terraform destroy fails because S3 bucket is not empty

You may see an error similar to:

> _Error deleting S3 Bucket (...) BucketNotEmpty: The bucket you tried to delete is not empty. You must delete all versions in the bucket._

Because versioning is enabled, deleting objects in the console does not remove previous versions or delete markers.

### Fix

1. In the console, enable "Show versions" for the affected bucket.
2. Select all object versions and delete them/
3. Delete all delete markers as well.
4. Retry terraform destroy.

For automation, you can also use the AWS CLI:

'''
aws s3api delete-object --bucket <bucket> --key --version-id <version-id>

```
