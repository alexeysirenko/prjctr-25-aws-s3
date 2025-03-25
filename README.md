# prjctr-25-aws-s3

Create resources

```shell
terraform init
terraform apply
```

List created bucket(s)

```shell
aws s3 ls
```

## Test WORM policy

- Upload the first version of the file

```shell
echo "Original content - Version 1" > test-worm.txt

aws s3api put-object \
  --bucket my-immutable-bucket-1234-3 \
  --key test-worm.txt \
  --body test-worm.txt

INITIAL_VERSION=$(aws s3api list-object-versions \
  --bucket my-immutable-bucket-1234-3 \
  --prefix test-worm.txt \
  --query 'Versions[0].VersionId' \
  --output text)

echo "Initial version ID: $INITIAL_VERSION"

aws s3api get-object-retention \
  --bucket my-immutable-bucket-1234-3 \
  --key test-worm.txt \
  --version-id $INITIAL_VERSION
```

- Upload the second version of the file

```shell

echo "Modified content - Version 2" > test-worm.txt

aws s3api put-object \
  --bucket my-immutable-bucket-1234-3 \
  --key test-worm.txt \
  --body test-worm.txt

SECOND_VERSION=$(aws s3api list-object-versions \
  --bucket my-immutable-bucket-1234-3 \
  --prefix test-worm.txt \
  --query 'Versions[0].VersionId' \
  --output text)

echo "Second version ID: $SECOND_VERSION"
```

- Try deleting the original file

```shell
aws s3api delete-object \
  --bucket my-immutable-bucket-1234-3 \
  --key test-worm.txt \
  --version-id $INITIAL_VERSION
```

It should return `Access Denied` error

- Try deleting the second file

```shell
aws s3api delete-object \
  --bucket my-immutable-bucket-1234-3 \
  --key test-worm.txt \
  --version-id $SECOND_VERSION
```

It should return `Access Denied` error as well

- Try deleting the object

```shell
aws s3api delete-object \
  --bucket my-immutable-bucket-1234-3 \
  --key test-worm.txt
```

It should only add `DeleteMarker` marked

- List object versions:

```shell
aws s3api list-object-versions \
  --bucket my-immutable-bucket-1234-3 \
  --prefix test-worm.txt
```

- Check files contents

```shell
aws s3api get-object \
  --bucket my-immutable-bucket-1234-3 \
  --key test-worm.txt \
  --version-id $INITIAL_VERSION \
  version1.txt

aws s3api get-object \
  --bucket my-immutable-bucket-1234-3 \
  --key test-worm.txt \
  --version-id $SECOND_VERSION \
  version2.txt

cat version1.txt
cat version2.txt

```

You should receive contents of the both files that were uploaded previously

## Test the logging

It may take 30-60 (or more) minutes for the logs to appear in the bucket

```shell
aws s3 ls s3://my-immutable-bucket-1234-3-logs/s3-access-logs/ --recursive

aws s3 cp s3://my-immutable-bucket-1234-3-logs/s3-access-logs/<log_file_name> .

cp <log_file_name>
```
