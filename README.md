# Simple Review App for SPA on AWS CDN

## Get Started

```bash
# Edit terraform.tfvars
cp terraform.tfvars.template terraform.tfvars

# Export your environment of AWS
export AWS_ACCESS_KEY_ID="xxxxxxxxxxxxxxxx"
export AWS_SECRET_ACCESS_KEY="xxxxxxxxxxxxxxx"
export AWS_DEFAULT_REGION="ap-northeast-1"

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

## Create Review App Example

```bash
# Build dist
mkdir -p dist
echo Hello World > dist/index.html

# Archive dist
tar czf dist.tar.gz dist

# Upload Review App
export GITHUB_TOKEN="your_github_access_token_have_repo_permissions"
curl -XPOST https://api-review-spa.example.com/upload -d @- << EOS
{
  "github_token": "${GITHUB_TOKEN}",
  "github_username": "your_user_or_organization_name",
  "github_reponame": "your_repository_name",
  "github_sha1": "optional_commit_sha1_when_you_want_to_notify_github_statuses",
  "statuses_context": "optional_github_statuses_context",
  "archive_base64": "$(base64 dist.tar.gz)",
  "public_path": "dist",
  "identifier": "pr-1234"
}
EOS

{"url": "https://pr-1234--your_repository_name--your_user_or_organization_name.review-spa.example.com"}
```
