# Setup

## Create an S3 bucket and a DynamoDB table for the OpenTofu backend

### Set environment variables (auto-detect)
```bash
# Auto-detect AWS account ID and region from current profile
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION=$(aws configure get region)

# Verify the values
echo "AWS Account ID: $AWS_ACCOUNT_ID"
echo "AWS Region: $AWS_REGION"
```

### Alternative: Set environment variables manually
```bash
export AWS_REGION=eu-west-1
export AWS_ACCOUNT_ID=846173919647
```

### Create S3 bucket for Terraform state
```bash
# Create the bucket
aws s3api create-bucket --bucket terraform-backend-${AWS_ACCOUNT_ID}-${AWS_REGION} --region ${AWS_REGION} --create-bucket-configuration LocationConstraint=${AWS_REGION}

# Enable versioning
aws s3api put-bucket-versioning --bucket terraform-backend-${AWS_ACCOUNT_ID}-${AWS_REGION} --versioning-configuration Status=Enabled

# Enable server-side encryption
aws s3api put-bucket-encryption --bucket terraform-backend-${AWS_ACCOUNT_ID}-${AWS_REGION} --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
```

### Create DynamoDB table for state locking
```bash
aws dynamodb create-table --table-name terraform-backend-locks --key-schema AttributeName=LockID,KeyType=HASH --attribute-definitions AttributeName=LockID,AttributeType=S --billing-mode PAY_PER_REQUEST --region ${AWS_REGION}
```

### Verify resources
```bash
# Check S3 bucket
aws s3 ls s3://terraform-backend-${AWS_ACCOUNT_ID}-${AWS_REGION}

# Check DynamoDB table
aws dynamodb describe-table --table-name terraform-backend-locks --region ${AWS_REGION}
```

## Using Terragrunt

Once you've created the S3 bucket and DynamoDB table, you can use Terragrunt to manage your Terraform configurations with remote state.

### Terragrunt Configuration Explained

The [`terragrunt.hcl`](terragrunt.hcl:1) file contains:

1. **Remote State Configuration**: Configures S3 backend with state locking
   - `bucket`: Your S3 bucket for storing state files
   - `key`: Path within the bucket for this project's state file
   - `dynamodb_table`: DynamoDB table for state locking
   - `encrypt`: Enables encryption for state files

2. **Provider Generation**: Automatically generates [`provider.tf`](provider.tf:1) with AWS provider configuration

3. **Backend Generation**: Automatically generates [`backend.tf`](backend.tf:1) with S3 backend configuration

### Common Terragrunt Commands

```bash
# Initialize and download providers
terragrunt init

# Plan your infrastructure changes
terragrunt plan

# Apply your infrastructure changes
terragrunt apply

# Destroy your infrastructure
terragrunt destroy

# Format your Terraform files
terragrunt fmt

# Validate your configuration
terragrunt validate
```

### Project Structure
```
.
├── terragrunt.hcl          # Terragrunt configuration
├── main.tf                 # Your Terraform resources
├── backend.tf              # Auto-generated backend config
├── provider.tf             # Auto-generated provider config
└── README.md               # This file
```