# EC2 Rightsizing Lab — Terraform + GitHub Actions

Free-tier compatible EC2 rightsizing lab. Infrastructure is managed with
Terraform, deployed via GitHub Actions, and state is stored in Terraform Cloud.

## Project Structure

```
rightsizing-lab/
├── .github/
│   └── workflows/
│       ├── deploy.yml      # Runs on push to main — terraform apply
│       └── destroy.yml     # Runs on push to destroy — terraform destroy
├── main.tf                 # EC2 instances, provider, Terraform Cloud backend
├── iam.tf                  # CloudWatch agent IAM role + instance profile
├── variables.tf            # Input variables with defaults
├── outputs.tf              # Instance IDs printed after apply
├── user-data.sh            # Installs stress tool + CloudWatch agent on boot
├── example.tfvars          # Template — copy to terraform.tfvars locally
├── .gitignore
└── README.md
```

---

## One-Time Setup

### 1. Terraform Cloud (free)

1. Create a free account at https://app.terraform.io
2. Create an organization — note the name
3. Create a workspace named `ec2-rightsizing-lab`, set execution mode to **Local**
   (GitHub Actions runs Terraform locally; Terraform Cloud just stores state)
4. Generate an API token: **User Settings → Tokens → Create an API token**

### 2. AWS IAM credentials

Create an IAM user for GitHub Actions with these policies attached:
- `AmazonEC2FullAccess`
- `IAMFullAccess` (needed to create the CloudWatch agent role)
- `CloudWatchFullAccess`

Generate an access key for that user.

### 3. GitHub Secrets

In your repo go to **Settings → Secrets and variables → Actions** and add:

| Secret name              | Value                                      |
|--------------------------|--------------------------------------------|
| `AWS_ACCESS_KEY_ID`      | Your IAM user access key ID                |
| `AWS_SECRET_ACCESS_KEY`  | Your IAM user secret access key            |
| `AWS_REGION`             | e.g. `us-east-1`                           |
| `TF_API_TOKEN`           | Your Terraform Cloud API token             |
| `TF_CLOUD_ORGANIZATION`  | Your Terraform Cloud organization name     |

### 4. Update main.tf

Open `main.tf` and replace `YOUR_TFC_ORG` with your Terraform Cloud org name:

```hcl
cloud {
  organization = "your-actual-org-name"   # ← change this
  workspaces {
    name = "ec2-rightsizing-lab"
  }
}
```

---

## Workflow

### Deploy (push to main)

```bash
git checkout main
git add .
git commit -m "deploy lab infrastructure"
git push origin main
```

GitHub Actions runs `terraform init` → `plan` → `apply`.
Instance IDs are printed in the workflow summary.

### Run the lab

After the workflow completes, grab the instance IDs from the Actions summary
and run the metric/stress steps from the lab instructions using the AWS CLI:

```bash
# Stress the web-server (replace with your actual instance ID from outputs)
WEB_SERVER_ID="i-0abc123..."

aws ssm send-command \
  --instance-ids "$WEB_SERVER_ID" \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=[
    "stress --cpu 2 --vm 1 --vm-bytes 256M --timeout 600 &",
    "echo Load test started"
  ]' \
  --comment "Rightsizing lab stress test"
```

Wait 10–15 minutes, then query CloudWatch metrics per the lab instructions.

### Destroy (push to destroy branch)

When you are finished with the lab:

```bash
git checkout -b destroy
git push origin destroy
```

GitHub Actions runs `terraform destroy -auto-approve`, removing all EC2
instances, IAM roles, and instance profiles. Free tier hours stop immediately.

> After destroying, delete or reset the `destroy` branch so you don't
> accidentally re-trigger it:
> ```bash
> git push origin --delete destroy
> git checkout main
> ```

---

## Free Tier Impact

| Resource              | Free Tier Allowance          | This Lab              |
|-----------------------|-----------------------------|-----------------------|
| EC2 (t3.micro)        | 750 hrs/month combined      | ~6 hrs for a 2hr lab  |
| EBS (gp3)             | 30 GB/month                 | 24 GB (3 × 8 GB)      |
| CloudWatch metrics    | 10 custom metrics free      | 6 (mem + disk × 3)    |
| Terraform Cloud state | Free up to 500 resources    | ~10 resources         |
| SSM                   | Free                        | Free                  |

Public IPv4 addresses are **disabled** (`associate_public_ip_address = false`)
to avoid the $0.005/hr charge introduced in February 2024. SSM handles all
remote access without needing a public IP or open SSH port.

---

## Local Development

To run Terraform locally instead of via GitHub Actions:

```bash
# Authenticate to Terraform Cloud
terraform login

# Copy and fill in variables
cp example.tfvars terraform.tfvars

# Standard workflow
terraform init
terraform plan
terraform apply
terraform destroy
```