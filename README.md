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

It should only add `DeleteMarker` to the file

- List object versions:

```shell
aws s3api list-object-versions \
  --bucket my-immutable-bucket-1234-3 \
  --prefix test-worm.txt
```

It should return 2 versions of the file

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

Expected content (example):

```
3ca5d269 my-immutable-bucket-1234-3 [25/Mar/2025:21:13:10 +0000] 195.66.137.123 arn:aws:iam::523717802721:user/foo XSTKCNAKZCGSW4H5 REST.PUT.OBJECT logging-test.txt "PUT /logging-test.txt HTTP/1.1" 200 - - 45 40 14 "-" "aws-cli/2.25.2 md/awscrt#0.23.8 ua/2.1 os/linux#6.11.0-19-generic md/arch#x86_64 lang/python#3.12.9 md/pyimpl#CPython cfg/retry-mode#standard md/installer#exe md/distrib#ubuntu.24 md/prompt#off md/command#s3api.put-object" - VPQYErwJCagiIiyq3w= SigV4 TLS_AES_128_GCM_SHA256 AuthHeader my-immutable-bucket-1234-3.s3.eu-central-1.amazonaws.com TLSv1.3 - -
```
