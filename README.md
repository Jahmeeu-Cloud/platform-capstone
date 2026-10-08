# Project Outcome
The project successfully demonstrated the deployment of a three-tier containerized application platform on **Amazon EKS**, provisioned using Terraform and integrated with AWS networking, container registries, persistent storage, and load balancing.

The implementation successfully achieved:

* **Infrastructure as Code:** Reusable Terraform modules for VPC, ECR, and EKS infrastructure.
* **Remote Terraform State:** Amazon S3 backend with versioning and state locking.
* **Containerization:** Dockerized frontend and backend applications.
* **Container Registry:** Private Amazon ECR repositories with image scanning on push and immutable tags.
* **Kubernetes Workloads:** Deployments and Services for the frontend and backend, plus a PostgreSQL StatefulSet.
* **Persistent Database Storage:** Encrypted EBS gp3 storage dynamically provisioned through the EBS CSI driver.
* **Database Persistence Validation:** Verified that test data survived PostgreSQL pod deletion and recreation while the same PVC remained bound.
* **Application Health Checks:** Startup, readiness, and liveness probes for Kubernetes workloads.
* **AWS Load Balancing:** AWS Load Balancer Controller and an internet-facing Application Load Balancer provisioned through Kubernetes Ingress.
* **Horizontal Pod Autoscaling:** Configured CPU-based scaling and validated scale-up and scale-down behaviour under controlled load.
* **Resource Monitoring:** Metrics Server integration for Kubernetes resource metrics.
* **Container Security:** Non-root application containers, reduced Linux capabilities, and disabled privilege escalation.
* **Application Validation:** Verified frontend HTTP responses, backend health endpoints, and backend-to-PostgreSQL connectivity.

Most importantly, the project demonstrates how infrastructure, application workloads, persistent data, and scaling policies can work together as a reproducible cloud platform.

It also reinforces an important reliability principle: **restarting a stateful application should not mean losing its persistent data.**



# AWS Kubernetes Infrastructure Platform — Capstone

**Author:** Jamiu Olatunji Bakre  
**Project:** Platform Capstone  
**Environment:** Production-style demonstration  
**AWS Region:** `eu-west-1`

A three-tier container platform built with Terraform, Amazon EKS, Amazon ECR, Kubernetes, Docker, PostgreSQL, and the AWS Load Balancer Controller.

The project demonstrates reproducible infrastructure, container image publishing, persistent database storage, Kubernetes health checks, horizontal pod autoscaling, and public application access through an AWS Application Load Balancer.

> This is a learning and portfolio project, not a claim of a fully production-certified platform. Review the security, availability, and cost considerations below before using this architecture for real workloads.

## Architecture


                         Internet
                            |
                    AWS Application
                    Load Balancer
                            |
                  Kubernetes Ingress
                            |
                     Frontend Service
                       (ClusterIP)
                            |
                    Frontend Pods x2
                    Nginx / HTTP 8080
                            |
                 Internal service access
                            |
                     Backend Service
                       (ClusterIP)
                            |
                    Backend Pods x2
                  Node.js / Express :5000
                            |
                     PostgreSQL Service
                       (ClusterIP)
                            |
                    PostgreSQL Pod x1
                   StatefulSet + PVC
                            |
                    Encrypted EBS gp3
                         20 GiB


### Infrastructure overview

* Terraform: Reusable modules for networking, ECR, and EKS.

* Amazon VPC: Public and private subnets across two Availability Zones.

* Amazon EKS: Managed Kubernetes control plane and two managed worker nodes.

* Amazon ECR: Private repositories for frontend and backend container images.

* Amazon S3: Remote Terraform state for the production environment, with versioning and state locking.

* AWS Load Balancer Controller: Provisions and manages the internet-facing ALB for Kubernetes Ingress.

* Metrics Server: Supplies resource metrics used by `kubectl top` and the Horizontal Pod Autoscaler.

* EBS CSI driver: Dynamically provisions encrypted EBS volumes for persistent Kubernetes storage.

The ALB routes `/` to the frontend. The backend and PostgreSQL services use internal ClusterIP networking; this Ingress configuration does not expose `/api` publicly.


## Repository structure

```
.
├── app/
│   ├── backend/                 # Node.js and Express API
│   └── frontend/                # Static frontend served by Nginx
├── kubernetes/
│   ├── backend/                 # ConfigMap, Deployment, Service, HPA
│   ├── database/                # PostgreSQL StatefulSet, Service, storage
│   ├── frontend/                # Deployment, Service, HPA
│   └── platform/
│       ├── addons/              # Metrics Server version record
│       ├── ingress.yaml
│       └── aws-load-balancer-controller-serviceaccount.yaml
└── terraform/
    ├── bootstrap/               # Terraform state bucket bootstrap
    ├── environments/prod/       # Production environment
    └── modules/
        ├── ecr/
        ├── eks/
        └── vpc/
```

## Prerequisites

Install and configure:

* AWS CLI v2

* Terraform compatible with the constraints in the Terraform configuration

* Docker

* `kubectl`

* Helm

* An AWS identity permitted to create and manage the required networking, IAM, ECR, EKS, S3, and load-balancing resources

Verify your tools and AWS identity:


Bash

```
aws --version
terraform version
docker --version
kubectl version --client
helm version
aws sts get-caller-identity
```

Use the AWS region `eu-west-1` consistently. Your AWS credentials should be provided through a supported AWS credential mechanism; do not commit credentials to this repository.

## 1. Configure Terraform

Review the example configuration files before deploying:


Bash

```
cat terraform/bootstrap/terraform.tfvars.example
cat terraform/environments/prod/terraform.tfvars.example
```


Create local variable files from the examples and edit them for your AWS account and requirements:

Bash

```
cp terraform/bootstrap/terraform.tfvars.example \
  terraform/bootstrap/terraform.tfvars

cp terraform/environments/prod/terraform.tfvars.example \
  terraform/environments/prod/terraform.tfvars
```

The production example defines the region, project name, environment, VPC CIDR, two Availability Zones, public and private subnet CIDRs, and resource tags.

The local `terraform.tfvars` files are ignored by Git. Do not add secret values to example files or commit credentials.

## 2. Bootstrap the Terraform state bucket

The bootstrap configuration creates the S3 bucket used for remote Terraform state. Inspect its variables and configuration first.

Bash

```
cd terraform/bootstrap
terraform init
terraform fmt -check
terraform validate
terraform plan
```

Review the plan, then create the state bucket:

Bash

```
terraform apply
```

Follow any variable prompts or use the local variable file if the configuration expects one.

The bootstrap configuration maintains its own local state. Keep that state secure and backed up; do not commit it to Git.

Return to the repository root:

Bash

```
cd ../..
```

## 3. Provision the production infrastructure

The production backend is configured in `terraform/environments/prod/backend.tf` to use S3 with a state key and lockfile.

Bash

```
cd terraform/environments/prod
terraform init
terraform fmt -check
terraform validate
terraform plan
```

Review the complete plan before applying it:

Bash

```
terraform apply
```

Useful outputs include:

Bash

```
terraform output vpc_id
terraform output eks_cluster_name
terraform output eks_cluster_endpoint
terraform output ecr_repository_urls
```

Connect `kubectl` to the cluster:

Bash

```
aws eks update-kubeconfig \
  --region eu-west-1 \
  --name platform-capstone-prod

kubectl get nodes
```

The EKS API endpoint has private access enabled and public access restricted to an approved CIDR. If your public IP changes, update the permitted CIDR in Terraform before attempting to connect.

## 4. Build and publish the container images

Authenticate Docker to ECR:

Bash

```
export AWS_REGION=eu-west-1
export AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
export ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

aws ecr get-login-password --region "$AWS_REGION" \
  | docker login \
      --username AWS \
      --password-stdin "$ECR_REGISTRY"
```

Build the backend and frontend from their respective directories:

Bash

```
docker build -t platform-capstone-backend:v1 ./app/backend
docker build -t platform-capstone-frontend:v2 ./app/frontend
```

Tag the images for the ECR repositories:

Bash

```
docker tag platform-capstone-backend:v1 \
  "$ECR_REGISTRY/platform-capstone-prod/backend:v1"

docker tag platform-capstone-frontend:v2 \
  "$ECR_REGISTRY/platform-capstone-prod/frontend:v2"
```

Push both images:

Bash

```
docker push "$ECR_REGISTRY/platform-capstone-prod/backend:v1"
docker push "$ECR_REGISTRY/platform-capstone-prod/frontend:v2"
```

Confirm the repositories and image tags exist:

Bash

```
aws ecr describe-repositories --region "$AWS_REGION"
aws ecr list-images \
  --region "$AWS_REGION" \
  --repository-name platform-capstone-prod/backend

aws ecr list-images \
  --region "$AWS_REGION" \
  --repository-name platform-capstone-prod/frontend
```

The repositories are configured for image scanning on push and immutable image tags. Use a new tag when publishing a new image version.

## 5. Install cluster add-ons

### Metrics Server

The file `kubernetes/platform/addons/metrics-server.yaml` records the pinned Metrics Server version and its upstream manifest URL. It is a ConfigMap, not the Metrics Server deployment itself.

Install the pinned upstream release:

Bash

```
kubectl apply -f \
  https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.9.0/components.yaml

kubectl rollout status deployment/metrics-server -n kube-system
kubectl get apiservice v1beta1.metrics.k8s.io
```

Apply the local version record if desired:

Bash

```
kubectl apply -f kubernetes/platform/addons/metrics-server.yaml
```

### AWS Load Balancer Controller

The EKS infrastructure includes the IAM permissions and EKS Pod Identity association used by the controller. Install the matching controller chart version:

Bash

```
helm repo add eks https://aws.github.io/eks-charts
helm repo update

kubectl apply \
  -f kubernetes/platform/aws-load-balancer-controller-serviceaccount.yaml

helm upgrade --install aws-load-balancer-controller \
  eks/aws-load-balancer-controller \
  --namespace kube-system \
  --version 1.14.0 \
  --set clusterName=platform-capstone-prod \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

Verify the deployment:

Bash

```
kubectl rollout status deployment/aws-load-balancer-controller \
  -n kube-system

kubectl get pods -n kube-system \
  -l app.kubernetes.io/name=aws-load-balancer-controller
```

The controller chart is pinned to `1.14.0`, with controller application version `v2.14.0` in this deployment.

## 6. Deploy the application

Create the namespace:

Bash

```
kubectl create namespace platform \
  --dry-run=client -o yaml | kubectl apply -f -
```

### Configure the database Secret

The PostgreSQL username, password, and database name are supplied through a Kubernetes Secret. The real `kubernetes/database/secret.yaml` file is deliberately excluded from Git.

For a fresh checkout, create a local `kubernetes/database/secret.yaml` using this structure and replace the placeholders with your own strong, unique credentials:

YAML

```
apiVersion: v1
kind: Secret
metadata:
  name: postgres-secret
  namespace: platform
type: Opaque
stringData:
  POSTGRES_USER: REPLACE_WITH_DATABASE_USERNAME
  POSTGRES_PASSWORD: REPLACE_WITH_STRONG_DATABASE_PASSWORD
  POSTGRES_DB: REPLACE_WITH_DATABASE_NAME
```

Apply the Secret without printing its values:

Bash

```
kubectl apply -f kubernetes/database/secret.yaml
```

Do not commit the Secret file or share its contents in screenshots, logs, or public issue reports.

### Apply storage and workloads

Apply the database storage configuration before creating the database workload:

Bash

```
kubectl apply -f kubernetes/database/storageclass.yaml
kubectl apply -f kubernetes/database/service.yaml
kubectl apply -f kubernetes/database/statefulset.yaml
```

Apply the backend and frontend resources:

Bash

```
kubectl apply -f kubernetes/backend/configmap.yaml
kubectl apply -f kubernetes/backend/service.yaml
kubectl apply -f kubernetes/backend/deployment.yaml
kubectl apply -f kubernetes/backend/hpa.yaml

kubectl apply -f kubernetes/frontend/service.yaml
kubectl apply -f kubernetes/frontend/deployment.yaml
kubectl apply -f kubernetes/frontend/hpa.yaml
```

Create the public Ingress after the AWS Load Balancer Controller is ready:

Bash

```
kubectl apply -f kubernetes/platform/ingress.yaml
```

Wait for the application rollouts:

Bash

```
kubectl rollout status statefulset/postgres -n platform
kubectl rollout status deployment/backend -n platform
kubectl rollout status deployment/frontend -n platform
```

## 7. Verify the deployment

### Kubernetes resources

Bash

```
kubectl get nodes -o wide
kubectl get all -n platform
kubectl get pvc -n platform
kubectl get ingress -n platform
kubectl get hpa -n platform
```

### Resource metrics

Bash

```
kubectl top nodes
kubectl top pods -n platform
```

### Backend readiness and database connectivity

The backend has separate liveness and readiness endpoints:

* `/health/live` checks that the Node.js process is alive.

* `/health/ready` checks whether the backend can query PostgreSQL.

Test readiness from inside the cluster:

Bash

```
kubectl run backend-check \
  -n platform \
  --rm -i \
  --restart=Never \
  --image=curlimages/curl \
  -- curl -fsS http://backend:5000/health/ready
```

Test the backend root endpoint:

Bash

```
kubectl run backend-root-check \
  -n platform \
  --rm -i \
  --restart=Never \
  --image=curlimages/curl \
  -- curl -fsS http://backend:5000/
```

Expected readiness response:

JSON

```
{"status":"ready","database":"connected"}
```

### Frontend service

Bash

```
kubectl run frontend-check \
  -n platform \
  --rm -i \
  --restart=Never \
  --image=curlimages/curl \
  -- curl -fsS http://frontend/
```

### Public application endpoint

Retrieve the ALB hostname:

Bash

```
kubectl get ingress platform -n platform
```

Then test the public route:

Bash

```
ALB_HOST="$(kubectl get ingress platform -n platform \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"

curl -I "http://${ALB_HOST}/"
```

The frontend is served over HTTP in this demonstration. HTTPS requires a certificate and corresponding listener configuration.

## 8. Kubernetes scaling and persistence

### Horizontal Pod Autoscaling

The frontend and backend HPAs target 70% average CPU utilization, with a minimum of two replicas and a maximum of five replicas. Scale-down stabilization helps prevent rapid oscillation.

Bash

```
kubectl get hpa -n platform
kubectl describe hpa backend -n platform
kubectl describe hpa frontend -n platform
```

Metrics Server must be healthy for CPU-based autoscaling to function.

### PostgreSQL persistence

PostgreSQL runs as a single-replica StatefulSet and uses a 20 GiB encrypted gp3 EBS PersistentVolumeClaim. The `gp3` StorageClass uses the EBS CSI provisioner and `WaitForFirstConsumer` volume binding.

The database persistence test was completed: a test table and row survived deletion and recreation of the PostgreSQL pod while the same PVC remained bound.

Inspect storage:

Bash

```
kubectl get pvc -n platform
kubectl describe pvc postgres-data-postgres-0 -n platform
```

Important: This is persistent storage, not a highly available PostgreSQL cluster. The StatefulSet has one database replica. The StorageClass uses `reclaimPolicy: Delete`, so deleting the PVC can cause its backing EBS volume to be deleted. Back up important data before any destructive operation.

## Security controls

Implemented controls include:

* Private worker nodes in private subnets.

* Restricted EKS public API CIDR access, with private endpoint access enabled.

* IAM roles and EKS Pod Identity for the AWS Load Balancer Controller.

* Dedicated IAM roles for EKS components such as VPC CNI and EBS CSI.

* Encrypted EBS storage.

* ECR image scanning on push and immutable image tags.

* Non-root frontend and backend containers.

* Dropped Linux capabilities and disabled privilege escalation in application workloads.

* Kubernetes startup, readiness, and liveness probes.

* Kubernetes Secret resources for database credentials.

* Remote production Terraform state in S3, with versioning and state locking.

* Git ignore rules for local state, variable files, credentials, and Kubernetes Secret manifests.

### Before using this for real production workloads

* Store database credentials in a managed secret service and establish appropriate encryption-at-rest and access policies.

* Configure HTTPS and a suitable certificate.

* Add database backups and test restoration procedures.

* Consider PostgreSQL high availability if the application requires it.

* Review Kubernetes network policies, IAM permissions, pod security, logging, monitoring, alerting, and disaster recovery.

* Review public ingress and API exposure; this deployment exposes the frontend route only.

* Review Terraform state access, retention, and recovery procedures.

* Pin and regularly review container base images and third-party chart versions.

## Cost considerations

AWS resources in this project can incur ongoing charges, including:

* EKS control plane

* Two EC2 worker nodes

* Two NAT gateways

* Application Load Balancer

* EBS volumes and snapshots

* Data transfer and related networking services

The two NAT gateways provide availability across the two Availability Zones but cost more than a single-NAT demonstration setup. Review current AWS pricing for your region and monitor actual billing.

## Cleanup

Do not destroy the infrastructure until you have decided that you no longer need the cluster, load balancer, database, storage, or Terraform state.

First review the resources that would be affected:

Bash

```
cd terraform/environments/prod
terraform plan -destroy
```

Destroying the production Terraform environment can remove the EKS cluster and networking resources. Kubernetes persistent storage may also be deleted depending on the resources removed and their reclaim policies. Back up any database data you need to retain.

Only when you explicitly intend to remove the infrastructure should you run:

Bash

```
terraform destroy
```

The state bucket is managed separately by the bootstrap configuration. Do not delete it casually: it stores Terraform state needed to manage or recover the environment.

## License

Add a license if you intend to distribute this project for reuse. Otherwise, all rights remain with the repository owner. EOF

````
## Next: review the README before committing

Run these commands and paste the output:

```bash
git diff --check
git status --short
git diff --stat
sed -n '1,100p' README.md
````

---


## Author

**Jamiu Bakre**

Cloud & DevOps Engineer | AWS | Kubernetes | Terraform | CI/CD

Focus areas:

* Cloud Engineering
* DevOps and Platform Engineering
* Kubernetes and Container Orchestration
* Infrastructure as Code
* AWS Networking and Compute
* CI/CD and Automation
* Observability and Reliability Engineering
* Secure and Scalable Infrastructure

## Project Status

**Status: Core infrastructure deployed and application validation completed.**

This repository represents a milestone in my Platform Engineering journey, combining Terraform-managed AWS infrastructure with containerized applications and Kubernetes operations.

Planned areas for further development include GitOps, automated CI/CD deployment pipelines, enhanced observability and alerting, secrets management integration, backup and recovery automation, and additional security and reliability testing.

*Note: This is a portfolio and learning project. Production use would require additional validation of high availability, database recovery, HTTPS, security policies, monitoring, and operational procedures.*

---
