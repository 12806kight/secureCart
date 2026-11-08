resource "aws_ecr_repository" "this" {
  name                 = "${var.project}-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true # Triggers a free CVE vulnerability scan on every push
  }

  tags = {
    Name        = "${var.project}-ecr"
    Environment = var.environment
  }
}

# Lifecycle policy to automatically clean up old images and stay under the 500MB Free Tier
resource "aws_ecr_lifecycle_policy" "cleanup" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep only the last 3 untagged images to save Free Tier storage space"
        selection = {
          tagStatus   = "untagged"
          countType   = "imageCountMoreThan"
          countNumber = 3
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
