SecureCart

Tech Stack: Terraform, AWS (VPC, EC2, ALB, RDS, CloudFront, Route 53, ECR, KMS, CloudWatch, SNS, WAF), Docker, Node.js, GitHub Actions

SecureCart is a cloud infrastructure project I built to practice deploying a secure, containerized web application on AWS using Terraform.  I built a multi-tier architecture where the application and database sit inside isolated private subnets, secrets are never hardcoded, and updates roll out automatically with zero downtime through GitHub Actions.

I also engineered the entire setup to stay within AWS Free Tier(There were a few excepctions to this) limits—including building a custom Amazon Linux 2023 NAT instance instead of paying for a managed AWS NAT Gateway.

How Traffic Flows

[ User ] ──HTTPS──▶ [ Route 53 ] ──▶ [ CloudFront ] 
                                           │
                      (Adds secret header + forwards Host)
                                           │
                                           ▼
                              [ Application Load Balancer ] (Public Subnets)
                                           │
                               (Checks /health on port 8080)
                                           │
                                           ▼
                    ┌─────────────────────────────────────────────┐
                    │           Private Subnets (Multi-AZ)        │
                    │                                             │
                    │  [ EC2 Auto Scaling Group (Ubuntu 24.04) ]  │
                    │  • Pulls immutable Docker image from ECR    │
                    │  • Grabs DB login from SSM/Secrets Manager  │
                    │  • Routes outbound updates via NAT Instance │
                    │                     │                       │
                    │                     ▼                       │
                    │        [ Encrypted RDS Database ]           │
                    └─────────────────────────────────────────────┘
```

1. DNS & CDN: Users visit "securetestkight.com", which routes through Route 53 to CloudFront using an ACM SSL certificate.
2. Load Balancing: CloudFront forwards traffic strictly over encrypted HTTPS (`https-only`) to an Application Load Balancer (ALB) in the public subnets.
3. App Tier: The ALB forwards valid requests to port 8080 on EC2 instances running inside private subnets with no public IP addresses. An Auto Scaling Group manages the servers and boots them using a hardened `user_data` script that installs Docker, pulls the exact commit's container image from ECR, and starts the Node.js app.
4. Database Tier: The app connects to an encrypted MySQL RDS database sitting in isolated private subnets with all outbound internet access blocked.

---

Security Choices I Made

Zero AWS Keys in GitHub: GitHub Actions uses OpenID Connect (OIDC) to assume an IAM role during deployments, meaning no long-lived AWS access keys are stored in repository secrets.

Double-Layer ALB Protection: Anyone who discovers the ALB's public ".elb.amazonaws.com" URL is dropped at the firewall because the ALB Security Group only accepts traffic from AWS's official CloudFront IP ranges. As a second layer, CloudFront injects a secret custom header (`X-Custom-SecureCart-Token`), and the ALB rejects any request missing that header with a `403 Forbidden` error.

Least-Privilege Secrets Management: EC2 instances use an IAM instance profile to silently fetch database credentials from AWS 

Systems Manager (SSM) Parameter Store and AWS Secrets Manager on boot without printing secrets into system logs.

Hardened Compute & Containers:

The Docker image builds deterministically with `npm ci --only=production` and runs as an unprivileged `node` user instead of `root`.

EC2 instances enforce IMDSv2 (`http_tokens = "required"`) to protect IAM credentials from SSRF attacks.

Amazon ECR uses `IMMUTABLE` image tags tied to each Git commit SHA and scans every push for vulnerabilities.

Encryption Everywhere: Traffic is encrypted from user to CloudFront and from CloudFront to the ALB; **RDS** storage is encrypted at rest; and Terraform's remote state is stored in an encrypted **S3** bucket.

Monitoring & Real-Time Alerts: ALB access logs stream to S3 every 5 minutes, and a **CloudWatch** alarm triggers **SNS** email alerts if `504 Gateway Timeout` errors occur.

Project Structure


secureCart/
├── .github/workflows/   # GitHub Actions CI/CD pipeline (OIDC + Zero-Downtime Refresh)
├── modules/
│   ├── cloudfront/      # CDN, SSL settings, and custom origin headers
│   ├── ec2/             # IMDSv2 Launch Template, Auto Scaling Group, and boot script
│   ├── ecr/             # Immutable private Docker image repository & cleanup policy
│   ├── loadBalancer/    # ALB, port 8080 target group, S3 access logs, and CloudWatch/SNS alerts
│   ├── rds/             # Encrypted MySQL database in private subnets
│   ├── s3/              # Remote Terraform state bucket
│   ├── securityGroup/   # Least-privilege firewall rules between CloudFront, ALB, EC2, and RDS
│   ├── vpc/             # VPC, public/private subnets, route tables, and AL2023 NAT instance
│   └── waf/             # Web Application Firewall rules
├── Dockerfile           # Hardened Node 20 Alpine image running as non-root user
├── server.js            # Node.js server with /health check route
├── package.json         # Node.js dependencies
├── package-lock.json    # Pinned dependency lockfile for deterministic builds
├── iam_github.tf        # Scoped OIDC role for GitHub Actions & EC2 instance profile
├── route53.tf           # Domain DNS and SSL cert validation
├── main.tf              # Connects all Terraform modules together
├── backend.tf           # S3 state backend config
└── outputs.tf           # Useful URLs and resource IDs after apply

Challenges & How I Solved Them

502 Bad Gateway from CloudFront:** CloudFront connected to the ALB's `.elb.amazonaws.com` domain while the ALB presented an SSL certificate for `securetestkight.com`. Because the hostnames didn't match, the TLS handshake failed. I fixed this by configuring CloudFront to forward the `Host` header to the origin.
403 Bad Request on Custom Domain:** Even after attaching the ACM SSL certificate to CloudFront, visiting `securetestkight.com` returned a 403 error because `securetestkight.com` wasn't listed under CloudFront's `aliases` in Terraform. Adding the domain alias resolved it.
Free-Tier NAT Routing on Amazon Linux 2023:** To avoid paying for a managed AWS NAT Gateway, I built a custom `t3.micro` NAT instance so private EC2 servers could download updates and pull ECR images. Minimal Amazon Linux 2023 images don't ship with `iptables` pre-installed, so private subnet traffic timed out until I configured `user_data` to install `iptables-nft`, enable IP forwarding, and apply `MASQUERADE` rules on boot.
Eliminating CI/CD Deployment Race Conditions:** Initially, Terraform updated the Auto Scaling Group before the new Docker image finished pushing to ECR. I reordered the GitHub Actions workflow to provision ECR and push the commit-tagged image first, run `terraform apply` second, and trigger a rolling Auto Scaling Group **Instance Refresh** last.

How Deployment Works

1. Push code changes to the `main` branch.
2. GitHub Actions authenticates to AWS via OIDC and ensures the **ECR** repository is ready.
3. GitHub Actions builds the non-root Docker image tagged with the Git commit SHA (`\${{ github.sha }}`), pushes it to ECR, and saves the active tag in **SSM Parameter Store**.
4. Terraform runs `plan` and `apply` to keep all cloud infrastructure in sync.
5. GitHub Actions triggers a rolling **Auto Scaling Group Instance Refresh**, seamlessly replacing EC2 instances with the new container image after they pass `/health` checks—achieving zero-downtime deployments.

 