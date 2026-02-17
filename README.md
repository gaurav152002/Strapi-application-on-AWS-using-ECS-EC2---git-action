# 🚀 Strapi Deployment on AWS ECS (EC2) using Terraform & GitHub Actions

This project demonstrates a fully automated CI/CD pipeline to deploy a **Strapi application** on **AWS ECS (EC2 launch type)** using:

- Docker
- Amazon ECR
- Amazon ECS (EC2)
- Terraform
- S3 Remote Backend
- GitHub Actions (CI/CD)

---

# 🐳 Docker

### Base Image
```
node:20-slim
```

### Production Build
- Installs dependencies
- Builds Strapi
- Exposes port 1337
- Starts using `npm run start`

Image is tagged using:

```
<commit-sha>
```

Example:
```
679500838196.dkr.ecr.us-east-1.amazonaws.com/strapi-task7:f7d8a613a55125d49c39102361db384658e4ca58
```

---

# 🔐 Required GitHub Secrets

Go to:

Repository → Settings → Secrets → Actions

Add:

```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_REGION=us-east-1
```

---

# 🗄 ECR Repository

ECR repository must exist:

```
strapi-task7
```

Region:
```
us-east-1
```

---

# 🏗 Terraform Infrastructure

Terraform provisions:

- ECS Cluster
- EC2 Instance (ECS Optimized AMI)
- IAM Roles
- Instance Profile
- Security Group
- ECS Task Definition
- ECS Service
- S3 Remote Backend
- DynamoDB Lock Table

---

# 🗂 Terraform Remote Backend

State stored in:

```
S3 Bucket: strapi-task7-terraform-state
Key: task7/terraform.tfstate
Region: us-east-1
DynamoDB Table: terraform-locks
```

---

# ⚙️ ECS Configuration

Launch Type:
```
EC2
```

Instance Type:
```
t2.micro (Free Tier)
```

Storage:
```
30 GB
```

Port:
```
1337
```
---

# 🔄 CI/CD Pipeline

## CI Workflow (ci.yaml)

Triggers on push to main branch.

Steps:
1. Checkout code
2. Login to ECR
3. Build Docker image
4. Tag with commit SHA
5. Push to ECR

---

## CD Workflow (terraform.yaml)

Runs after CI or manually.

Steps:
1. Setup Terraform
2. Configure AWS credentials
3. Terraform Init
4. Terraform Plan
5. Terraform Apply
6. Update ECS task definition revision
7. Deploy new image automatically

---

# 🌍 Accessing Strapi

After deployment:

```
http://<EC2-Public-IP>:1337
```
---

# 🧠 Key Learnings

This project demonstrates:

- Docker production builds
- ECR authentication
- ECS EC2 architecture
- IAM instance role vs execution role
- Terraform remote state (S3 + DynamoDB)
- GitHub Actions CI/CD
- Zero manual deployment

---

# 🚀 How to Deploy (Step-by-Step)

1. Clone repository
2. Add GitHub secrets
3. Push code to main branch
4. GitHub Actions builds & pushes image
5. Terraform deploys infrastructure
6. ECS runs new task revision automatically
7. Access Strapi via Public IP

---

# 🏁 Result

✔ Fully automated deployment  
✔ Infrastructure as Code  
✔ Remote Terraform state  
✔ Production Docker build  
✔ ECS EC2 launch type  
✔ No manual AWS console steps required  

---

