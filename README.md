# DevOps Challenge — Production-Grade CI/CD on AWS

## Architecture Overview

A fully automated CI/CD pipeline deploying a Node.js application to Amazon EKS using Jenkins, Terraform, and Kubernetes.
### Components
- **VPC** — Multi-AZ (us-east-1), public + private subnets, NAT gateway
- **Amazon ECR** — Container registry with image scanning and lifecycle policy
- **Amazon EKS** — Kubernetes 1.30, managed node group (t3.medium, min 1 / max 3)
- **Jenkins** — CI/CD server on EC2 (t3.small), IAM instance profile for ECR + EKS access
- **CloudWatch** — Container Insights, Fluent Bit log shipping, CPU + pod-restart alarms

---

## Prerequisites

- AWS CLI v2 configured with IAM credentials
- Terraform >= 1.5
- kubectl
- Docker

---

## Deployment Steps

### 1. Provision Infrastructure (Terraform)

```bash
# Create remote state backend
aws s3api create-bucket --bucket devops-challenge-tfstate-<account-id> --region us-east-1
aws s3api put-bucket-versioning --bucket devops-challenge-tfstate-<account-id> \
  --versioning-configuration Status=Enabled
aws dynamodb create-table --table-name devops-challenge-tflock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST --region us-east-1

# Deploy infrastructure
cd terraform
terraform init
terraform plan
terraform apply -auto-approve
```

### 2. Configure EKS Access for Jenkins

```bash
# Add Jenkins IAM role to EKS aws-auth ConfigMap
kubectl patch configmap aws-auth -n kube-system --patch '
data:
  mapRoles: |
    - rolearn: arn:aws:iam::<account-id>:role/devops-challenge-eks-node-role
      groups:
      - system:bootstrappers
      - system:nodes
      username: system:node:{{EC2PrivateDNSName}}
    - rolearn: arn:aws:iam::<account-id>:role/devops-challenge-jenkins-role
      groups:
      - system:masters
      username: jenkins
'
```

### 3. Deploy Kubernetes Manifests

```bash
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/hpa.yaml
```

### 4. Configure Jenkins

- Access Jenkins at `http://<jenkins-public-ip>:8080`
- Create Pipeline job → Pipeline script from SCM → GitHub repo
- Build Now to trigger the pipeline

### 5. Enable Monitoring

```bash
aws eks create-addon \
  --cluster-name devops-challenge-cluster \
  --addon-name amazon-cloudwatch-observability \
  --region us-east-1
```

---

## Pipeline Stages

| Stage | Description |
|---|---|
| Checkout | Pull source code from GitHub |
| Build | `docker build` tagged with `$BUILD_NUMBER` |
| Test | Run container, `curl /health` to verify |
| Push | Push image to ECR (`:$BUILD_NUMBER` + `:latest`) |
| Deploy | `kubectl set image` + rollout status check |

---

## Design Decisions

- **Remote state** — S3 + DynamoDB locking prevents concurrent state corruption
- **Module structure** — Separate Terraform modules for vpc, eks, ecr, jenkins
- **IRSA-ready** — OIDC provider provisioned for pod-level IAM (future use)
- **Rolling update** — `maxSurge: 1, maxUnavailable: 0` ensures zero-downtime deploys
- **HPA** — Horizontal Pod Autoscaler scales on 70% CPU, max 3 replicas
- **Health probes** — Liveness + readiness probes on `/health` prevent bad deploys
- **IAM instance profile** — Jenkins uses EC2 instance role (no hardcoded credentials)
- **Image lifecycle** — ECR retains last 10 images, older ones auto-expired

---

## Assumptions

- Single region deployment (us-east-1)
- Jenkins EC2 access restricted to deployer IP via security group
- GitHub repository is public (no credential configuration needed in Jenkins)

---

## Live Endpoints

- **App:** `http://ac34c4fd790c6442fb696d3b7ed85616-16177115.us-east-1.elb.amazonaws.com`
- **Health:** `http://ac34c4fd790c6442fb696d3b7ed85616-16177115.us-east-1.elb.amazonaws.com/health`
- **Jenkins:** `http://3.85.211.143:8080`

---

## Future Improvements

- HTTPS via ACM + ALB Ingress Controller
- Separate staging and production namespaces
- Slack/email notifications on pipeline failure
- Trivy image vulnerability scanning in pipeline
- Sealed Secrets for Kubernetes secret management
