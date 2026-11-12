SecureCart

Terraform, AWS (VPC, EC2, ALB, RDS, CloudFront, Route 53, ECR, WAF), Docker, Node.js, GitHub Actions

SecureCart is a cloud infrastructure project I built to practice deploying a secure, containerized web app on AWS using Terraform. Instead of just spinning up a single server and leaving ports open, I wanted to build an actual multi-tier setup where the app and database sit in private subnets, secrets aren't hardcoded anywhere, and deployments happen automatically through GitHub Actions.

I also kept the whole setup within AWS Free Tier limits where possible(Incredibly difficult to accomplish)

---

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
                    │  • Pulls Docker image from ECR              │
                    │  • Grabs DB login from SSM/Secrets Manager  │
                    │                     │                       │
                    │                     ▼                       │
                    │             [ RDS Database ]                │
                    └─────────────────────────────────────────────┘
                    

1. **DNS & CDN:** Users hit `securetestkight.com`, which points to **CloudFront** via **Route 53** with an **ACM** SSL certificate.
2. **Load Balancing:** CloudFront forwards traffic over HTTPS to an **Application Load Balancer (ALB)** in the public subnets.
3. **App Tier:** The ALB sends traffic to port `8080` on **EC2** instances running inside private subnets (no public IPs). An **Auto Scaling Group** manages the instances and runs a `user_data` script on boot to install Docker, pull my container image from **ECR**, and start the Node.js app.
4. **Database Tier:** The app connects to an **RDS** database in isolated private subnets.


These are the security choices I made

* **No AWS Keys in GitHub:** GitHub Actions uses OIDC (`sts:AssumeRoleWithWebIdentity`) to assume an IAM role when deploying Terraform, so there are no static AWS access keys saved in repo secrets.
* **Blocking Direct ALB Traffic:** Anyone who finds the ALB's public `.elb.amazonaws.com` URL gets a `403 Forbidden` error. CloudFront injects a secret custom header (`X-Custom-SecureCart-Token`), and the ALB drops any request that doesn't have it.
* **No Hardcoded Passwords:** When an EC2 instance boots up, it uses its IAM instance profile to fetch the database host, username, and password from **AWS Systems Manager (SSM) Parameter Store** and **AWS Secrets Manager**.
* **Encrypted Terraform State:** Remote state is saved in an encrypted **S3** bucket (`encrypt = true`), and `.tfstate` / `.tfvars` files are blocked in `.gitignore`.


secureCart/
├── .github/workflows/   # GitHub Actions CI/CD pipeline
├── modules/
│   ├── cloudfront/      # CDN, SSL settings, and custom origin headers
│   ├── ec2/             # Launch template, Auto Scaling Group, and boot script
│   ├── ecr/             # Private Docker image repository
│   ├── loadBalancer/    # ALB, port 8080 target group, and 403 header rules
│   ├── rds/             # Database setup
│   ├── s3/              # Remote Terraform state bucket
│   ├── securityGroup/   # Firewall rules between ALB, EC2, and RDS
│   ├── vpc/             # VPC, public/private subnets, and routing tables
│   └── waf/             # Web Application Firewall rules
├── Dockerfile           # Node 20 Alpine image
├── server.js            # Simple Node.js server with a /health route
├── iam_github.tf        # OIDC role for GitHub Actions & EC2 instance profile
├── route53.tf           # Domain DNS and SSL cert validation
├── main.tf              # Connects all the Terraform modules together
├── backend.tf           # S3 state backend config
└── outputs.tf           # Useful URLs and IDs after apply
```


These are some of the few problems I ran into while working on this project.

* **502 Bad Gateway from CloudFront:** CloudFront was connecting to the ALB's AWS URL (`*.elb.amazonaws.com`), while the ALB had an SSL certificate for `securetestkight.com`. Because the names didn't match, the SSL handshake failed. I fixed it by telling CloudFront to forward the `Host` header to the origin.
* **403 Bad Request on Custom Domain:** Even after attaching my SSL cert to CloudFront, my custom domain threw a 403 error because I forgot to add `securetestkight.com` to the `aliases` list in Terraform.


How this Deployment Works?

1. Push code changes to `main`.
2. GitHub Actions logs into AWS via OIDC and runs `terraform plan` and `terraform apply`.
3. New EC2 instances spin up in the Auto Scaling Group, pull the `:latest` Docker image from ECR, load the database credentials from SSM/Secrets Manager, and pass the ALB `/health` check before taking traffic.

Brewer Kight
