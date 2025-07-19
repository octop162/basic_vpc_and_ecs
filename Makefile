.PHONY: init plan apply destroy lint fmt validate clean ecspresso-deploy ecspresso-rollback ecspresso-status ecspresso-verify ecspresso-render deploy

# Initialize Terraform
init:
	terraform init

# Plan Terraform changes
plan:
	terraform plan

# Apply Terraform changes
apply:
	terraform apply

# Destroy Terraform infrastructure
destroy:
	terraform destroy

# Format Terraform files
fmt:
	terraform fmt -recursive

# Validate Terraform configuration
validate:
	terraform validate

# Run TFLint
lint:
	tflint --init
	tflint --recursive

# Run all checks
check: fmt validate lint

# Clean up
clean:
	rm -rf .terraform
	rm -f .terraform.lock.hcl
	rm -f terraform.tfstate*

# Security scan with tfsec
security:
	tfsec .

# Run all quality checks
quality: fmt validate lint security

# Development workflow
dev: init fmt validate lint plan

# Deploy ECS service using ecspresso
ecs-deploy:
	ecspresso deploy --config ecspresso.yml --no-wait

# Rollback ECS service using ecspresso
ecs-rollback:
	ecspresso rollback --config ecspresso.yml

# Check ECS service status
ecs-status:
	ecspresso status --config ecspresso.yml

# Check ECS diff
ecs-diff:
	ecspresso diff --config ecspresso.yml

# Verify ECS deployment
ecs-verify:
	ecspresso verify --config ecspresso.yml

# Render ecspresso configuration
ecs-render:
	ecspresso render --config ecspresso.yml

# Complete deployment workflow (Terraform + ecspresso)
deploy: apply ecs-deploy ecs-verify
