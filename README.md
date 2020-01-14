# Simple Review App for SPA on AWS CDN

## Get Started

```bash
# Edit terraform.tfvars
cp terraform.tfvars.template terraform.tfvars

# Export your environment of AWS
export AWS_ACCESS_KEY_ID=xxxxxxxxxxxxxxxx
export AWS_SECRET_ACCESS_KEY=xxxxxxxxxxxxxxx
export AWS_DEFAULT_REGION=ap-northeast-1

# Adjust your environment, specify backend first time only
terraform init \
  -backend-config="bucket=your-bucket-name" \
  -backend-config="key=terraform.tfstate" \
  -backend-config="region=ap-northeast-1"

# Plan
terraform plan

# Apply
terraform apply
```
