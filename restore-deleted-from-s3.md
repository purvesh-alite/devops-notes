---
title: Restoring Deleted Files from a Versioning-Enabled S3 Bucket
subtitle: Here's a comprehensive guide on how to restore deleted files from a
  versioning-enabled S3 bucket.
---
Amazon S3 is a widely used object storage service that provides versioning capabilities to protect against accidental deletions and overwrites. When versioning is enabled, each object in the bucket is given a unique version ID, and delete markers are used to indicate deleted objects. This guide will walk you through the process of restoring deleted files in a versioning-enabled S3 bucket.

**Prerequisites**

- AWS CLI installed and configured with the necessary permissions.
- A versioning-enabled S3 bucket.

### Step-by-Step Guide

### Step 1: List Deleted Objects

First, you need to list all the object versions and filter out the delete markers. Delete markers indicate that an object was deleted, but the previous versions are still stored in the bucket.

#### Using AWS CLI:

1\. **List All Object Versions:**

Use the following command to list all object versions in your S3 bucket:

```
   aws s3api list-object-versions --bucket your-bucket-name
```

2\. **Filter for Delete Markers:**

To filter only the delete markers, which are used to indicate deleted objects, use this command:

```
aws s3api list-object-versions --bucket your-bucket-name --query "DeleteMarkers[?IsLatest==\`true\`]"
```

### Step 2: Restore Deleted Objects

Restoring deleted objects involves removing the delete markers. This action makes the previous versions of the objects the current versions.

#### Using AWS CLI:

1\. **Retrieve and Delete Delete Markers:**

To restore all deleted files by removing the delete markers, you can use the following script:

> ```
>    aws s3api list-object-versions --bucket your-bucket-name --query "DeleteMarkers[?IsLatest==\`true\`].[Key, VersionId]" --output text | while read key version_id
> ```
> 
> ```
>    do
> ```
> 
> ```
>        aws s3api delete-object --bucket your-bucket-name --key "$key" --version-id "$version_id"
> ```
> 
> ```
>        echo "Restored $key with version $version_id"
> ```
> 
> ```
>    done
> ```

### Full Script to Restore All Deleted Files

Here’s a complete bash script that lists all delete markers and removes them to restore the deleted files:

> ```
> #!/bin/bash
> ```
> 
> ```
> BUCKET_NAME="your-bucket-name"
> ```
> 
> ```
> # List delete markers and delete them to restore deleted files
> ```
> 
> ```
> aws s3api list-object-versions --bucket "$BUCKET_NAME" --query "DeleteMarkers[?IsLatest==\`true\`].[Key, VersionId]" --output text | while read key version_id
> ```
> 
> ```
> do
> ```
> 
> ```
>     aws s3api delete-object --bucket "$BUCKET_NAME" --key "$key" --version-id "$version_id"
> ```
> 
> ```
>     echo "Restored $key with version $version_id"
> ```
> 
> ```
> done
> ```

### Step 3: Verify Restoration

After running the script, you should verify that the objects have been restored by listing the contents of the bucket:

aws s3 ls s3://your-bucket-name --recursive

### Important Considerations

- **IAM Permissions:** Ensure that your IAM user or role has the necessary permissions to list object versions and delete objects in the S3 bucket.

- **Data Backup:** Before performing the delete operation on delete markers, consider creating a backup of the list of deleted markers and their version IDs to ensure you can recover if something goes wrong.

### Conclusion

By following these steps, you can effectively restore deleted files in a versioning-enabled S3 bucket. This process involves listing delete markers and removing them to make the previous versions of the objects the current versions. With S3 versioning, you have an additional layer of protection against accidental deletions, ensuring your data is safe and recoverable.

\---

By enabling versioning and understanding how to manage object versions, you can leverage the full power of Amazon S3 to safeguard your data against accidental deletions and overwrites.
